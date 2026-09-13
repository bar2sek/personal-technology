#!/usr/bin/env python3
"""
UniFi Network Discovery & Terraform Inventory Generator
Extracts networks, VLANs, switches, port mappings, and client devices from UniFi OS (UDM-Pro).
"""

import argparse
import getpass
import json
import os
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import http.cookiejar


class UniFiClient:
    def __init__(self, base_url: str, site: str = "default", verify_ssl: bool = False):
        self.base_url = base_url.rstrip("/")
        self.site = site
        self.verify_ssl = verify_ssl

        self.cookie_jar = http.cookiejar.CookieJar()
        ctx = ssl.create_default_context()
        if not verify_ssl:
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE

        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.cookie_jar),
            urllib.request.HTTPSHandler(context=ctx),
        )
        self.headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "UniFi-Terraform-Discovery/1.0",
        }
        self.csrf_token = None
        self.is_unifi_os = True

    def login(self, username, password) -> bool:
        login_payload = json.dumps({
            "username": username,
            "password": password,
            "token": "",
            "rememberMe": False,
        }).encode("utf-8")

        # Try UniFi OS login endpoint first
        unifi_os_url = f"{self.base_url}/api/auth/login"
        req = urllib.request.Request(unifi_os_url, data=login_payload, headers=self.headers, method="POST")

        try:
            with self.opener.open(req) as resp:
                if resp.status in (200, 204):
                    self.csrf_token = resp.headers.get("X-CSRF-Token")
                    if self.csrf_token:
                        self.headers["X-CSRF-Token"] = self.csrf_token
                    self.is_unifi_os = True
                    return True
        except urllib.error.HTTPError as e:
            if e.code == 404:
                # Try legacy pre-UniFi-OS endpoint
                legacy_url = f"{self.base_url}/api/login"
                legacy_req = urllib.request.Request(legacy_url, data=login_payload, headers=self.headers, method="POST")
                try:
                    with self.opener.open(legacy_req) as resp:
                        if resp.status in (200, 204):
                            self.is_unifi_os = False
                            return True
                except Exception as ex:
                    print(f"[-] Legacy login failed: {ex}")
                    return False
            else:
                print(f"[-] Login failed with HTTP {e.code}: {e.reason}")
                try:
                    err_body = e.read().decode("utf-8")
                    err_json = json.loads(err_body)
                    print(f"    Message: {err_json.get('errors') or err_json.get('message') or err_body}")
                except Exception:
                    pass
                return False
        except Exception as e:
            print(f"[-] Connection error during login: {e}")
            return False

        return False

    def get_endpoint(self, path: str):
        if self.is_unifi_os:
            url = f"{self.base_url}/proxy/network/api/s/{self.site}/{path.lstrip('/')}"
        else:
            url = f"{self.base_url}/api/s/{self.site}/{path.lstrip('/')}"

        req = urllib.request.Request(url, headers=self.headers, method="GET")
        try:
            with self.opener.open(req) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                return data.get("data", [])
        except urllib.error.HTTPError as e:
            print(f"[-] Error fetching {path} (HTTP {e.code}): {e.reason}")
            return []
        except Exception as e:
            print(f"[-] Failed to fetch {path}: {e}")
            return []


def format_mac(mac: str) -> str:
    return mac.lower() if mac else ""


def run_discovery(host, username, password, site, out_dir):
    print("=" * 70)
    print("🚀 UniFi Network Discovery & Inventory Extraction")
    print("=" * 70)
    print(f"[*] Connecting to UniFi Gateway at: {host}")
    print(f"[*] Authenticating as user:        {username}")

    client = UniFiClient(host, site=site, verify_ssl=False)
    if not client.login(username, password):
        print("\n❌ Failed to authenticate with UniFi Controller.")
        print("   Please check:")
        print("   1. Is the UDM-Pro IP correct (default: https://10.0.1.1)?")
        print("   2. Is 'terraform-admin' created as 'Local Access Only' with Super Admin / Network permissions?")
        print("   3. Is the password correct?")
        return False

    print("✅ Successfully authenticated!\n")

    # Fetch resources
    print("[*] Fetching configured networks & VLANs...")
    networks = client.get_endpoint("rest/networkconf")

    print("[*] Fetching UniFi hardware devices (switches, APs, gateway)...")
    devices = client.get_endpoint("stat/device")

    print("[*] Fetching port profiles...")
    port_profiles = client.get_endpoint("rest/portconf")

    print("[*] Fetching configured users & fixed IP reservations...")
    users = client.get_endpoint("rest/user")

    print("[*] Fetching currently connected client stations...")
    stations = client.get_endpoint("stat/sta")

    # 1. Print Networks Table
    print("\n" + "=" * 70)
    print("📋 CONFIGURED NETWORKS / SUBNETS")
    print("=" * 70)
    print(f"{'Name':<20} {'VLAN':<8} {'Subnet / Gateway':<20} {'DHCP Range':<22} {'UniFi ID'}")
    print("-" * 85)
    default_network_id = None
    for net in sorted(networks, key=lambda x: x.get("vlan", 0) or 0):
        name = net.get("name", "Unknown")
        vlan = net.get("vlan", 1) if net.get("vlan") is not None else 1
        subnet = net.get("ip_subnet", "N/A")
        dhcp_start = net.get("dhcpd_start", "")
        dhcp_stop = net.get("dhcpd_stop", "")
        dhcp_range = f"{dhcp_start} - {dhcp_stop}" if dhcp_start else "Disabled / Manual"
        net_id = net.get("_id", "")
        if net.get("is_nat") is False or vlan == 1 or "LAN" in name.upper() or net.get("default"):
            if not default_network_id:
                default_network_id = net_id
        print(f"{name:<20} {str(vlan):<8} {subnet:<20} {dhcp_range:<22} {net_id}")

    # 2. Print Adopted Hardware Devices
    print("\n" + "=" * 70)
    print("🖥️ ADOPTED UNIFI HARDWARE (SWITCHES, APS & GATEWAYS)")
    print("=" * 70)
    print(f"{'Device Name':<22} {'Model':<18} {'IP Address':<16} {'MAC Address':<18} {'Ports'}")
    print("-" * 85)
    switches = []
    for dev in sorted(devices, key=lambda x: x.get("name", "") or x.get("model", "")):
        name = dev.get("name") or dev.get("model", "UniFi Device")
        model = dev.get("model", "N/A")
        ip = dev.get("ip", "N/A")
        mac = format_mac(dev.get("mac", ""))
        num_ports = dev.get("total_max_port_idx", len(dev.get("port_table", [])))
        dev_type = dev.get("type", "")
        print(f"{name:<22} {model:<18} {ip:<16} {mac:<18} {num_ports}")
        if dev_type in ("usw", "udm") or "USW" in model.upper():
            switches.append(dev)

    # 3. Print Port Profiles
    print("\n" + "=" * 70)
    print("🔌 CONFIGURED PORT PROFILES")
    print("=" * 70)
    print(f"{'Profile Name':<28} {'Native VLAN ID':<16} {'UniFi Profile ID'}")
    print("-" * 75)
    for p in sorted(port_profiles, key=lambda x: x.get("name", "")):
        p_name = p.get("name", "Unknown")
        p_id = p.get("_id", "")
        native_id = p.get("native_networkconf_id", "Default / None")
        print(f"{p_name:<28} {native_id:<16} {p_id}")

    # 4. Print Known Clients / Homelab Candidates
    print("\n" + "=" * 70)
    print("🎯 ACTIVE & CONFIGURED CLIENTS (SERVERS, PCS, IPMI)")
    print("=" * 70)
    print(f"{'Hostname / Alias':<25} {'IP Address':<16} {'MAC Address':<18} {'Switch / Port'}")
    print("-" * 85)

    all_clients = {}
    for u in users:
        mac = format_mac(u.get("mac", ""))
        if mac:
            all_clients[mac] = {
                "name": u.get("name") or u.get("hostname") or "Unknown",
                "ip": u.get("fixed_ip") or u.get("last_ip") or "N/A",
                "mac": mac,
                "port": "Fixed User Record",
            }

    for s in stations:
        mac = format_mac(s.get("mac", ""))
        sw_name = s.get("last_uplink_name") or s.get("sw_name") or "Switch"
        sw_port = s.get("last_uplink_port") or s.get("sw_port") or "?"
        all_clients[mac] = {
            "name": s.get("name") or s.get("hostname") or all_clients.get(mac, {}).get("name", "Unknown"),
            "ip": s.get("ip") or all_clients.get(mac, {}).get("ip", "N/A"),
            "mac": mac,
            "port": f"{sw_name} Port {sw_port}",
        }

    for mac, info in sorted(all_clients.items(), key=lambda x: x[1]["name"].lower()):
        if info["ip"] != "N/A":
            print(f"{info['name']:<25} {info['ip']:<16} {info['mac']:<18} {info['port']}")

    # 5. Export JSON and Starter tfvars
    os.makedirs(out_dir, exist_ok=True)
    json_path = os.path.join(out_dir, "unifi-inventory.json")
    with open(json_path, "w") as f:
        json.dump({
            "networks": networks,
            "devices": devices,
            "port_profiles": port_profiles,
            "users": users,
            "stations": stations,
        }, f, indent=2)
    print(f"\n[+] Raw inventory exported to: {json_path}")

    # Generate starter tfvars
    tfvars_path = os.path.join(out_dir, "terraform.tfvars.discovered")
    with open(tfvars_path, "w") as f:
        f.write("# Generated by client-tools/unifi-discover.py\n")
        f.write(f'unifi_api_url  = "{host}"\n')
        f.write(f'unifi_username = "{username}"\n')
        f.write('unifi_password = "<your-local-password>"\n\n')
        f.write('# Discovered Default Network ID (for Terraform import)\n')
        if default_network_id:
            f.write(f'# default_network_id = "{default_network_id}"\n\n')
        f.write('# Discovered UniFi Hardware MAC Addresses:\n')
        for dev in devices:
            d_name = dev.get("name") or dev.get("model", "device")
            d_name_safe = d_name.lower().replace(" ", "_").replace("-", "_")
            d_mac = format_mac(dev.get("mac", ""))
            f.write(f'# {d_name_safe}_mac = "{d_mac}" # {dev.get("model")}\n')

        f.write('\n# Target Homelab Machine MACs (Select the correct MAC for omni_mac_address):\n')
        for mac, info in all_clients.items():
            if info["ip"] != "N/A":
                f.write(f'# omni_mac_candidate: "{mac}" # {info["name"]} ({info["ip"]}) on {info["port"]}\n')

    print(f"[+] Starter Terraform vars template generated at: {tfvars_path}")
    print("\n🎉 Discovery complete!")
    return True


def main():
    parser = argparse.ArgumentParser(description="UniFi Network Discovery & Inventory Extractor")
    parser.add_argument("--host", default="https://10.0.1.1", help="UniFi Gateway API URL (default: https://10.0.1.1)")
    parser.add_argument("--user", default="terraform-admin", help="UniFi local admin username (default: terraform-admin)")
    parser.add_argument("--password", help="UniFi local admin password (prompted if omitted)")
    parser.add_argument("--site", default="default", help="UniFi site name (default: default)")
    parser.add_argument("--out", default="client-tools", help="Output directory for inventory files (default: client-tools)")

    args = parser.parse_args()

    password = args.password
    if not password:
        password = getpass.getpass(f"Enter local UniFi password for '{args.user}': ")

    success = run_discovery(args.host, args.user, password, args.site, args.out)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
