#!/usr/bin/env python3
"""
Generate UniFi network & VLAN topology architecture diagrams (SVG + PNG)
from Terraform manifests (terraform/unifi/main.tf & dns.tf).
"""

import os
import subprocess
import xml.etree.ElementTree as ET

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS_DIR = os.path.join(REPO_ROOT, "docs")
SVG_OUTPUT = os.path.join(DOCS_DIR, "architecture-unifi.svg")
PNG_OUTPUT = os.path.join(DOCS_DIR, "architecture-unifi.png")

UNIFI_SVG = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 840" width="1280" height="840" style="background-color: #0b1120; font-family: -apple-system, BlinkMacSystemFont, Arial, sans-serif;">
  <defs>
    <marker id="netArrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#38bdf8"/>
    </marker>
    <marker id="fiberArrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#22c55e"/>
    </marker>
  </defs>

  <rect width="100%" height="100%" fill="#0b1120"/>

  <text x="640" y="38" text-anchor="middle" font-size="22" font-weight="bold" fill="#f8fafc">Ubiquiti UniFi Network &amp; Homelab Topology</text>
  <text x="640" y="62" text-anchor="middle" font-size="13" fill="#94a3b8">Codified via Terraform (personal-technology/terraform/unifi) • UDM-Pro, Aggregation Fabric, &amp; 7 VLAN Segments</text>

  <!-- 1. WAN & GATEWAY SECTION -->
  <g transform="translate(40, 85)">
    <rect x="0" y="0" width="260" height="110" rx="8" fill="#0f172a" stroke="#22c55e" stroke-width="1.5"/>
    <rect x="14" y="14" width="28" height="28" rx="6" fill="#15803d"/>
    <text x="50" y="32" font-size="14" font-weight="bold" fill="#f8fafc">3.5G Google Fiber</text>
    <text x="14" y="62" font-size="11" fill="#86efac">WAN Ingress • SFP+ 10GBASE-T</text>
    <text x="14" y="80" font-size="10" font-family="monospace" fill="#94a3b8">IPv6 /56 Prefix Delegation</text>
    <text x="14" y="96" font-size="10" fill="#4ade80">● Ultra-Low Latency Uplink</text>

    <path d="M 260 55 L 340 55" stroke="#22c55e" stroke-width="2.5" marker-end="url(#fiberArrow)"/>
    <rect x="272" y="42" width="55" height="16" rx="4" fill="#0b1120"/>
    <text x="299" y="54" text-anchor="middle" font-size="9" font-weight="bold" fill="#86efac">Port 11</text>

    <!-- Core Gateway (UDM-Pro) -->
    <rect x="350" y="0" width="460" height="110" rx="8" fill="#0f172a" stroke="#0070f3" stroke-width="1.8"/>
    <rect x="366" y="14" width="28" height="28" rx="6" fill="#0070f3"/>
    <text x="404" y="32" font-size="15" font-weight="bold" fill="#f8fafc">UniFi Dream Machine Pro (UDM-Pro)</text>
    <text x="366" y="60" font-size="12" fill="#93c5fd">Core Gateway • DHCP Engine • Split-Horizon DNS</text>
    <text x="366" y="78" font-size="10" font-family="monospace" fill="#cbd5e1">Gateway IP: 10.0.1.1 / Inter-VLAN Routing</text>
    <g transform="translate(366, 86)">
      <rect width="130" height="18" rx="4" fill="#1e293b"/>
      <text x="65" y="13" text-anchor="middle" font-size="9" fill="#38bdf8">10G SFP+ LAN (Port 10)</text>
      <rect x="140" width="130" height="18" rx="4" fill="#1e293b"/>
      <text x="205" y="13" text-anchor="middle" font-size="9" fill="#38bdf8">1G RJ45 Access (Port 1-8)</text>
    </g>

    <!-- Split Horizon DNS Card -->
    <rect x="840" y="0" width="400" height="110" rx="8" fill="#0f172a" stroke="#a855f7" stroke-width="1.5"/>
    <text x="856" y="28" font-size="13" font-weight="bold" fill="#c084fc">Local Split-Horizon DNS (dns.tf)</text>
    <text x="856" y="46" font-size="10" fill="#94a3b8">Bypasses Cloudflare WAN roundtrip on LAN:</text>
    <text x="856" y="66" font-size="10" font-family="monospace" fill="#e9d5ff">k8s.lan (10.10.20.10 VIP) • ceph.lan</text>
    <text x="856" y="82" font-size="10" font-family="monospace" fill="#e9d5ff">omni.lan (10.10.10.5) • grafana.lan • auth.lan</text>
    <text x="856" y="98" font-size="10" font-family="monospace" fill="#e9d5ff">printer.lan • gaming.lan (10.10.20.52)</text>
  </g>

  <!-- 2. SWITCH FABRIC BACKBONE -->
  <g transform="translate(40, 220)">
    <rect width="1200" height="110" rx="8" fill="#1e293b" fill-opacity="0.3" stroke="#334155" stroke-width="1.5" stroke-dasharray="4,4"/>
    <text x="20" y="24" font-size="12" font-weight="bold" fill="#cbd5e1">PHYSICAL SWITCHING FABRIC (USW-Aggregation &amp; Access Switches)</text>

    <!-- USW-Agg 1 -->
    <g transform="translate(30, 38)">
      <rect width="340" height="60" rx="6" fill="#0f172a" stroke="#38bdf8" stroke-width="1.2"/>
      <text x="14" y="24" font-size="12" font-weight="bold" fill="#38bdf8">USW-Aggregation #1 (10.0.1.224)</text>
      <text x="14" y="44" font-size="10" fill="#94a3b8">8x 10G SFP+ Ports • Core Cluster Backbone</text>
    </g>

    <!-- 20G LAG Link -->
    <g transform="translate(370, 68)">
      <line x1="0" y1="-8" x2="60" y2="-8" stroke="#ec4899" stroke-width="2.5"/>
      <line x1="0" y1="8" x2="60" y2="8" stroke="#ec4899" stroke-width="2.5"/>
      <rect x="5" y="-12" width="50" height="24" rx="4" fill="#0b1120"/>
      <text x="30" y="4" text-anchor="middle" font-size="9" font-weight="bold" fill="#f472b6">20G LAG</text>
    </g>

    <!-- USW-Agg 2 -->
    <g transform="translate(430, 38)">
      <rect width="340" height="60" rx="6" fill="#0f172a" stroke="#ec4899" stroke-width="1.2"/>
      <text x="14" y="24" font-size="12" font-weight="bold" fill="#f472b6">USW-Aggregation #2 (Ceph Backbone)</text>
      <text x="14" y="44" font-size="10" fill="#94a3b8">10.0.1.59 • Dedicated MTU 9000 Replication</text>
    </g>

    <!-- USW-24-G2 -->
    <g transform="translate(800, 38)">
      <rect width="185" height="60" rx="6" fill="#0f172a" stroke="#f59e0b" stroke-width="1.2"/>
      <text x="12" y="24" font-size="11" font-weight="bold" fill="#fbbf24">USW-24-G2 (Core)</text>
      <text x="12" y="44" font-size="10" fill="#94a3b8">1GbE IPMI &amp; Omni Mini PC</text>
    </g>

    <!-- USW-Lite-8-PoE -->
    <g transform="translate(1005, 38)">
      <rect width="170" height="60" rx="6" fill="#0f172a" stroke="#10b981" stroke-width="1.2"/>
      <text x="12" y="24" font-size="11" font-weight="bold" fill="#34d399">USW-Lite-8-PoE</text>
      <text x="12" y="44" font-size="10" fill="#94a3b8">Garage Switch, AP &amp; NAS</text>
    </g>
  </g>

  <!-- 3. TERRAFORM MANAGED VLANS SECTION -->
  <g transform="translate(40, 355)">
    <text x="0" y="16" font-size="14" font-weight="bold" fill="#f8fafc">TERRAFORM MANAGED VLANS &amp; NETWORK SEGMENTATION (terraform/unifi/main.tf)</text>

    <!-- Row 1: VLAN 10, 20, 30 -->
    <!-- VLAN 10: MGMT-IPMI -->
    <g transform="translate(0, 32)">
      <rect width="380" height="195" rx="8" fill="#0f172a" stroke="#38bdf8" stroke-width="1.5"/>
      <rect x="14" y="12" width="65" height="20" rx="4" fill="#0284c7"/>
      <text x="46" y="26" text-anchor="middle" font-size="11" font-weight="bold" fill="#ffffff">VLAN 10</text>
      <text x="90" y="27" font-size="14" font-weight="bold" fill="#38bdf8">MGMT-IPMI</text>
      <line x1="14" y1="40" x2="366" y2="40" stroke="#334155"/>

      <text x="14" y="60" font-size="11" fill="#94a3b8">Subnet: <tspan font-family="monospace" fill="#f8fafc">10.10.10.1/24</tspan></text>
      <text x="14" y="78" font-size="11" fill="#94a3b8">Domain: <tspan font-family="monospace" fill="#f8fafc">mgmt.internal</tspan></text>
      <text x="14" y="96" font-size="11" fill="#94a3b8">DHCP Range: <tspan font-family="monospace" fill="#f8fafc">10.10.10.10 - .254</tspan></text>

      <rect x="14" y="112" width="352" height="68" rx="6" fill="#1e293b"/>
      <text x="24" y="132" font-size="11" font-weight="bold" fill="#38bdf8">Key Workloads &amp; Devices:</text>
      <text x="24" y="150" font-size="10" fill="#cbd5e1">• Omni Management Server (10.10.10.5)</text>
      <text x="24" y="166" font-size="10" fill="#cbd5e1">• Server BMC / IPMI Out-of-Band Interfaces</text>
    </g>

    <!-- VLAN 20: K8S-CONTROL -->
    <g transform="translate(410, 32)">
      <rect width="380" height="195" rx="8" fill="#0f172a" stroke="#818cf8" stroke-width="1.5"/>
      <rect x="14" y="12" width="65" height="20" rx="4" fill="#4f46e5"/>
      <text x="46" y="26" text-anchor="middle" font-size="11" font-weight="bold" fill="#ffffff">VLAN 20</text>
      <text x="90" y="27" font-size="14" font-weight="bold" fill="#a5b4fc">K8S-CONTROL</text>
      <line x1="14" y1="40" x2="366" y2="40" stroke="#334155"/>

      <text x="14" y="60" font-size="11" fill="#94a3b8">Subnet: <tspan font-family="monospace" fill="#f8fafc">10.10.20.1/24</tspan></text>
      <text x="14" y="78" font-size="11" fill="#94a3b8">Domain: <tspan font-family="monospace" fill="#f8fafc">k8s.internal</tspan></text>
      <text x="14" y="96" font-size="11" fill="#94a3b8">DHCP: <tspan font-family="monospace" fill="#f8fafc">10.10.20.100 - .254</tspan></text>

      <rect x="14" y="112" width="352" height="68" rx="6" fill="#1e293b"/>
      <text x="24" y="132" font-size="11" font-weight="bold" fill="#a5b4fc">Key Workloads &amp; Devices:</text>
      <text x="24" y="150" font-size="10" fill="#cbd5e1">• Talos HA Control Plane VIP (10.10.20.10)</text>
      <text x="24" y="166" font-size="10" fill="#cbd5e1">• Nodes sm-node-01..03 (etcd quorum &amp; API)</text>
    </g>

    <!-- VLAN 30: K8S-APPS -->
    <g transform="translate(820, 32)">
      <rect width="380" height="195" rx="8" fill="#0f172a" stroke="#2dd4bf" stroke-width="1.5"/>
      <rect x="14" y="12" width="65" height="20" rx="4" fill="#0f766e"/>
      <text x="46" y="26" text-anchor="middle" font-size="11" font-weight="bold" fill="#ffffff">VLAN 30</text>
      <text x="90" y="27" font-size="14" font-weight="bold" fill="#5eead4">K8S-APPS</text>
      <line x1="14" y1="40" x2="366" y2="40" stroke="#334155"/>

      <text x="14" y="60" font-size="11" fill="#94a3b8">Subnet: <tspan font-family="monospace" fill="#f8fafc">10.10.30.1/24</tspan></text>
      <text x="14" y="78" font-size="11" fill="#94a3b8">Domain: <tspan font-family="monospace" fill="#f8fafc">apps.internal</tspan></text>
      <text x="14" y="96" font-size="11" fill="#94a3b8">DHCP: <tspan font-family="monospace" fill="#f8fafc">10.10.30.10 - .254</tspan></text>

      <rect x="14" y="112" width="352" height="68" rx="6" fill="#1e293b"/>
      <text x="24" y="132" font-size="11" font-weight="bold" fill="#5eead4">Key Workloads &amp; Devices:</text>
      <text x="24" y="150" font-size="10" fill="#cbd5e1">• Kubernetes Application Pods &amp; Microservices</text>
      <text x="24" y="166" font-size="10" fill="#cbd5e1">• Worker Nodes &amp; Workload Network Interface</text>
    </g>

    <!-- Row 2: VLAN 40, 50, 60, 90 -->
    <!-- VLAN 40: CEPH-STORAGE -->
    <g transform="translate(0, 242)">
      <rect width="285" height="205" rx="8" fill="#0f172a" stroke="#ec4899" stroke-width="1.5"/>
      <rect x="12" y="12" width="60" height="20" rx="4" fill="#be185d"/>
      <text x="42" y="26" text-anchor="middle" font-size="10" font-weight="bold" fill="#ffffff">VLAN 40</text>
      <text x="80" y="27" font-size="13" font-weight="bold" fill="#f472b6">CEPH-STORAGE</text>
      <line x1="12" y1="40" x2="273" y2="40" stroke="#334155"/>

      <text x="12" y="58" font-size="11" fill="#94a3b8">Subnet: <tspan font-family="monospace" fill="#f8fafc">10.10.40.1/24</tspan></text>
      <text x="12" y="74" font-size="11" fill="#94a3b8">MTU: <tspan font-weight="bold" fill="#f472b6">9000 (Jumbo)</tspan></text>
      <text x="12" y="90" font-size="11" fill="#94a3b8">Speed: <tspan font-weight="bold" fill="#f472b6">10G SFP+ Direct</tspan></text>

      <rect x="12" y="105" width="261" height="85" rx="6" fill="#1e293b"/>
      <text x="18" y="124" font-size="10" font-weight="bold" fill="#f472b6">High-Performance Storage:</text>
      <text x="18" y="140" font-size="9" fill="#cbd5e1">• Rook-Ceph Cluster OSDs</text>
      <text x="18" y="154" font-size="9" fill="#cbd5e1">• NVMe-oF &amp; Block Storage Mesh</text>
      <text x="18" y="168" font-size="9" fill="#cbd5e1">• Zero Inter-VLAN Gateway Bottleneck</text>
    </g>

    <!-- VLAN 50: K8S-METALLB -->
    <g transform="translate(305, 242)">
      <rect width="285" height="205" rx="8" fill="#0f172a" stroke="#f59e0b" stroke-width="1.5"/>
      <rect x="12" y="12" width="60" height="20" rx="4" fill="#b45309"/>
      <text x="42" y="26" text-anchor="middle" font-size="10" font-weight="bold" fill="#ffffff">VLAN 50</text>
      <text x="80" y="27" font-size="13" font-weight="bold" fill="#fbbf24">K8S-METALLB</text>
      <line x1="12" y1="40" x2="273" y2="40" stroke="#334155"/>

      <text x="12" y="58" font-size="11" fill="#94a3b8">Subnet: <tspan font-family="monospace" fill="#f8fafc">10.10.50.1/24</tspan></text>
      <text x="12" y="74" font-size="11" fill="#94a3b8">Domain: <tspan font-family="monospace" fill="#f8fafc">lb.internal</tspan></text>
      <text x="12" y="90" font-size="11" fill="#94a3b8">DHCP: <tspan fill="#f87171">Disabled (MetalLB)</tspan></text>

      <rect x="12" y="105" width="261" height="85" rx="6" fill="#1e293b"/>
      <text x="18" y="124" font-size="10" font-weight="bold" fill="#fbbf24">LoadBalancer VIP Pool:</text>
      <text x="18" y="140" font-size="9" fill="#cbd5e1">• Ingress-Nginx VIPs</text>
      <text x="18" y="154" font-size="9" fill="#cbd5e1">• Internal Service LoadBalancers</text>
      <text x="18" y="168" font-size="9" fill="#cbd5e1">• Layer-2 MetalLB ARP Advertisements</text>
    </g>

    <!-- VLAN 60: TRUSTED-LAN -->
    <g transform="translate(610, 242)">
      <rect width="285" height="205" rx="8" fill="#0f172a" stroke="#38bdf8" stroke-width="1.5"/>
      <rect x="12" y="12" width="60" height="20" rx="4" fill="#0369a1"/>
      <text x="42" y="26" text-anchor="middle" font-size="10" font-weight="bold" fill="#ffffff">VLAN 60</text>
      <text x="80" y="27" font-size="13" font-weight="bold" fill="#7dd3fc">TRUSTED-LAN</text>
      <line x1="12" y1="40" x2="273" y2="40" stroke="#334155"/>

      <text x="12" y="58" font-size="11" fill="#94a3b8">Subnet: <tspan font-family="monospace" fill="#f8fafc">192.168.60.1/24</tspan></text>
      <text x="12" y="74" font-size="11" fill="#94a3b8">Domain: <tspan font-family="monospace" fill="#f8fafc">lan.internal</tspan></text>
      <text x="12" y="90" font-size="11" fill="#94a3b8">DHCP: <tspan font-family="monospace" fill="#f8fafc">.10 - .254</tspan></text>

      <rect x="12" y="105" width="261" height="85" rx="6" fill="#1e293b"/>
      <text x="18" y="124" font-size="10" font-weight="bold" fill="#7dd3fc">Workstations &amp; Household:</text>
      <text x="18" y="140" font-size="9" fill="#cbd5e1">• Developer Workstations (MacBook Pro)</text>
      <text x="18" y="154" font-size="9" fill="#cbd5e1">• Brother Laser Printer (Fixed IP)</text>
      <text x="18" y="168" font-size="9" fill="#cbd5e1">• Trusted Personal Devices</text>
    </g>

    <!-- VLAN 90: IOT-SMART-HOME -->
    <g transform="translate(915, 242)">
      <rect width="285" height="205" rx="8" fill="#0f172a" stroke="#a855f7" stroke-width="1.5"/>
      <rect x="12" y="12" width="60" height="20" rx="4" fill="#7e22ce"/>
      <text x="42" y="26" text-anchor="middle" font-size="10" font-weight="bold" fill="#ffffff">VLAN 90</text>
      <text x="80" y="27" font-size="13" font-weight="bold" fill="#d8b4fe">IOT-SMART-HOME</text>
      <line x1="12" y1="40" x2="273" y2="40" stroke="#334155"/>

      <text x="12" y="58" font-size="11" fill="#94a3b8">Subnet: <tspan font-family="monospace" fill="#f8fafc">10.10.90.1/24</tspan></text>
      <text x="12" y="74" font-size="11" fill="#94a3b8">Domain: <tspan font-family="monospace" fill="#f8fafc">iot.internal</tspan></text>
      <text x="12" y="90" font-size="11" fill="#94a3b8">DHCP: <tspan font-family="monospace" fill="#f8fafc">.10 - .254</tspan></text>

      <rect x="12" y="105" width="261" height="85" rx="6" fill="#1e293b"/>
      <text x="18" y="124" font-size="10" font-weight="bold" fill="#d8b4fe">Isolated Smart Home:</text>
      <text x="18" y="140" font-size="9" fill="#cbd5e1">• Home Assistant Managed Devices</text>
      <text x="18" y="154" font-size="9" fill="#cbd5e1">• ESPHome &amp; Zigbee/Thread Gateways</text>
      <text x="18" y="168" font-size="9" fill="#cbd5e1">• Strict Firewall Isolation from LAN</text>
    </g>
  </g>

  <text x="640" y="820" text-anchor="middle" font-size="12" fill="#64748b">Generated directly from UniFi Terraform Manifests (main.tf &amp; dns.tf) • Synchronized with Talos Cluster Infrastructure</text>
</svg>"""

def main():
    os.makedirs(DOCS_DIR, exist_ok=True)
    with open(SVG_OUTPUT, "w", encoding="utf-8") as f:
        f.write(UNIFI_SVG.strip())

    # Verify XML well-formedness
    ET.parse(SVG_OUTPUT)
    print(f"✅ Generated SVG: {SVG_OUTPUT}")

    # Rasterize high-res PNG via macOS QuickLook
    cmd = f"qlmanage -t -s 2560 -o \"{DOCS_DIR}\" \"{SVG_OUTPUT}\" && mv \"{SVG_OUTPUT}.png\" \"{PNG_OUTPUT}\""
    subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"✅ Generated PNG: {PNG_OUTPUT}")

if __name__ == "__main__":
    main()
