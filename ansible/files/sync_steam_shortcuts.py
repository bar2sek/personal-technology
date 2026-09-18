#!/usr/bin/env python3
"""
sync_steam_shortcuts.py
Synchronizes installed Blizzard games directly into Steam shortcuts.vdf,
assigns GE-Proton compatibility mapping in config.vdf, symlinks compatdata
prefixes to the primary Battle.net prefix, and tunes Battle.net.config.
"""

import os
import sys
import glob
import json
import zlib
import struct
import shutil
import subprocess

STEAM_DIR = os.path.expanduser("~/.local/share/Steam")
COMPAT_PREFIX_ID = "3234450451"
PRIMARY_PREFIX = os.path.join(STEAM_DIR, "steamapps/compatdata", COMPAT_PREFIX_ID)
BNET_EXE = os.path.join(
    PRIMARY_PREFIX,
    "pfx/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"
)
BNET_START_DIR = os.path.join(
    PRIMARY_PREFIX,
    "pfx/drive_c/Program Files (x86)/Battle.net"
)
ICON_BASE = os.path.join(
    PRIMARY_PREFIX,
    "pfx/drive_c/proton_shortcuts/icons/256x256/apps"
)
BNET_CONFIG_PATH = os.path.join(
    PRIMARY_PREFIX,
    "pfx/drive_c/users/steamuser/AppData/Roaming/Battle.net/Battle.net.config"
)

GAMES = [
    {
        "name": "Battle.net",
        "fixed_appid": 3234450451,
        "launch_options": "DXVK_NVAPI_DRIVER_VERSION=59571 %command%",
        "icon": os.path.join(ICON_BASE, "1AC2_Battle.net Launcher.0.png"),
    },
    {
        "name": "Diablo IV",
        "launch_options": 'DXVK_NVAPI_DRIVER_VERSION=59571 %command% --exec="launch Fen"',
        "icon": os.path.join(ICON_BASE, "B790_Diablo IV Launcher.0.png"),
    },
    {
        "name": "StarCraft II",
        "launch_options": 'DXVK_NVAPI_DRIVER_VERSION=59571 %command% --exec="launch S2"',
        "icon": os.path.join(ICON_BASE, "5F50_StarCraft II.0.png"),
    },
    {
        "name": "Warcraft III",
        "launch_options": 'DXVK_NVAPI_DRIVER_VERSION=59571 %command% --exec="launch W3"',
        "icon": os.path.join(ICON_BASE, "23A7_Warcraft III Launcher.0.png"),
    },
]


def parse_bin_vdf(data: bytes):
    pos = 0

    def read_str():
        nonlocal pos
        end = data.find(b"\x00", pos)
        if end == -1:
            raise ValueError("Unterminated string in binary VDF")
        s = data[pos:end].decode("utf-8", "ignore")
        pos = end + 1
        return s

    def parse_dict():
        nonlocal pos
        res = {}
        while pos < len(data):
            t = data[pos:pos+1]
            pos += 1
            if t == b"\x08":
                break
            key = read_str()
            if t == b"\x00":
                res[key] = parse_dict()
            elif t == b"\x01":
                res[key] = read_str()
            elif t == b"\x02":
                val = struct.unpack("<I", data[pos:pos+4])[0]
                pos += 4
                res[key] = val
        return res

    return parse_dict()


def encode_bin_vdf(d: dict) -> bytes:
    res = bytearray()
    for k, v in d.items():
        if isinstance(v, dict):
            res.append(0)
            res.extend(k.encode("utf-8") + b"\x00")
            res.extend(encode_bin_vdf(v))
        elif isinstance(v, str):
            res.append(1)
            res.extend(k.encode("utf-8") + b"\x00")
            res.extend(v.encode("utf-8") + b"\x00")
        elif isinstance(v, int):
            res.append(2)
            res.extend(k.encode("utf-8") + b"\x00")
            res.extend(struct.pack("<I", v & 0xFFFFFFFF))
    res.append(8)
    return bytes(res)


def update_shortcuts_vdf(shortcuts_path: str):
    print(f"[*] Processing shortcuts file: {shortcuts_path}")
    if os.path.exists(shortcuts_path):
        with open(shortcuts_path, "rb") as f:
            data = f.read()
        try:
            parsed = parse_bin_vdf(data)
        except Exception as e:
            print(f"[-] Warning: Failed to parse existing shortcuts.vdf ({e}), creating fresh.")
            parsed = {"shortcuts": {}}
    else:
        parsed = {"shortcuts": {}}

    existing_shortcuts = parsed.get("shortcuts", {})
    by_name = {}
    for k, v in existing_shortcuts.items():
        if isinstance(v, dict) and "AppName" in v:
            by_name[v["AppName"]] = (k, v)

    if os.path.exists(shortcuts_path):
        shutil.copy2(shortcuts_path, shortcuts_path + ".bak")

    exe_quoted = f'"{BNET_EXE}"'
    start_dir_quoted = f'"{BNET_START_DIR}/"'

    appids = []
    for g in GAMES:
        name = g["name"]
        appid = g.get("fixed_appid")
        if not appid:
            crc = zlib.crc32((exe_quoted + name).encode("utf-8"))
            appid = (crc & 0xFFFFFFFF) | 0x80000000
        appids.append((str(appid), name))

        icon_path = g.get("icon", "")
        if not os.path.exists(icon_path):
            icon_path = ""

        entry = {
            "appid": appid,
            "AppName": name,
            "Exe": exe_quoted,
            "StartDir": start_dir_quoted,
            "icon": icon_path,
            "ShortcutPath": "",
            "LaunchOptions": g.get("launch_options", ""),
            "IsHidden": 0,
            "AllowDesktopConfig": 1,
            "AllowOverlay": 1,
            "OpenVR": 0,
            "Devkit": 0,
            "DevkitGameID": "",
            "DevkitOverrideAppID": 0,
            "LastPlayTime": 0,
            "FlatpakAppID": "",
            "sortas": "",
            "tags": {},
        }

        if name in by_name:
            key, existing = by_name[name]
            existing.update(entry)
            print(f"  [+] Updated shortcut: {name} (AppID: {appid})")
        else:
            new_idx = str(len(existing_shortcuts))
            existing_shortcuts[new_idx] = entry
            by_name[name] = (new_idx, entry)
            print(f"  [+] Added new shortcut: {name} (AppID: {appid})")

    parsed["shortcuts"] = existing_shortcuts
    with open(shortcuts_path, "wb") as f:
        f.write(encode_bin_vdf(parsed))
    print(f"[✔] Successfully saved: {shortcuts_path}")
    return appids


def update_config_vdf(config_path: str, appids: list):
    if not os.path.exists(config_path):
        print(f"[-] config.vdf not found at {config_path}")
        return

    print(f"[*] Updating Proton mapping in: {config_path}")
    with open(config_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    shutil.copy2(config_path, config_path + ".bak")

    idx = content.find('"CompatToolMapping"')
    if idx == -1:
        print("[-] Could not find CompatToolMapping block in config.vdf")
        return

    brace_start = content.find("{", idx)
    if brace_start == -1:
        return

    depth = 1
    pos = brace_start + 1
    while pos < len(content) and depth > 0:
        if content[pos] == "{":
            depth += 1
        elif content[pos] == "}":
            depth -= 1
        pos += 1

    compat_block = content[brace_start:pos]

    # Map global default ("0") + every game AppID
    targets = [("0", "Global Default")] + [
        (str(aid), name) for aid, name in appids
    ]

    new_entries = []
    for aid, name in targets:
        if f'"{aid}"' not in compat_block:
            entry = (
                f'\n\t\t\t\t\t"{aid}"\n'
                f'\t\t\t\t\t{{\n'
                f'\t\t\t\t\t\t"name"\t\t"GE-Proton11-7-x86_64"\n'
                f'\t\t\t\t\t\t"config"\t\t""\n'
                f'\t\t\t\t\t\t"priority"\t\t"250"\n'
                f'\t\t\t\t\t}}'
            )
            new_entries.append(entry)
            print(f"  [+] Mapped {name} (AppID: {aid}) to GE-Proton11-7-x86_64")

    if new_entries:
        content = (
            content[:brace_start + 1]
            + "".join(new_entries)
            + content[brace_start + 1:]
        )
        with open(config_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"[✔] Successfully updated {config_path}")
    else:
        print("[*] All games already mapped in CompatToolMapping")


def update_compatdata_symlinks(appids: list):
    compatdata_dir = os.path.join(STEAM_DIR, "steamapps/compatdata")
    if not os.path.exists(compatdata_dir):
        return

    for appid, name in appids:
        if appid == COMPAT_PREFIX_ID:
            continue
        target_link = os.path.join(compatdata_dir, appid)
        if not os.path.exists(target_link):
            try:
                os.symlink(COMPAT_PREFIX_ID, target_link)
                print(f"  [+] Symlinked compatdata/{appid} -> {COMPAT_PREFIX_ID} for {name}")
            except Exception as e:
                print(f"  [-] Failed to symlink {target_link}: {e}")


def tune_battlenet_config():
    if not os.path.exists(BNET_CONFIG_PATH):
        print(f"[-] Battle.net.config not found at {BNET_CONFIG_PATH}")
        return

    try:
        with open(BNET_CONFIG_PATH, "r", encoding="utf-8") as f:
            cfg = json.load(f)

        changed = False
        client_cfg = cfg.setdefault("Client", {})
        if client_cfg.get("GameLaunchWindowBehavior") != "2":
            client_cfg["GameLaunchWindowBehavior"] = "2"
            changed = True
            print("  [+] Configured Battle.net to exit automatically on game launch")

        if client_cfg.get("HardwareAcceleration") != "false":
            client_cfg["HardwareAcceleration"] = "false"
            changed = True
            print("  [+] Disabled browser hardware acceleration in Battle.net")

        games_cfg = cfg.setdefault("Games", {})
        fenris_cfg = games_cfg.setdefault("fenris", {})
        if fenris_cfg.get("AdditionalLaunchArguments") != "-bypassgpudrivercheck":
            fenris_cfg["AdditionalLaunchArguments"] = "-bypassgpudrivercheck"
            changed = True
            print("  [+] Configured -bypassgpudrivercheck for Diablo IV")

        if changed:
            shutil.copy2(BNET_CONFIG_PATH, BNET_CONFIG_PATH + ".bak")
            with open(BNET_CONFIG_PATH, "w", encoding="utf-8") as f:
                json.dump(cfg, f, indent=4)
            print("[✔] Battle.net.config successfully tuned!")
    except Exception as e:
        print(f"[-] Failed to tune Battle.net.config: {e}")


def main():
    if not os.path.exists(BNET_EXE):
        print(f"[!] Battle.net launcher executable not found at {BNET_EXE}")
        print("    Ensure Battle.net has been installed first.")
        sys.exit(1)

    # Find all shortcuts.vdf files under userdata/*/config/
    shortcuts_pattern = os.path.join(STEAM_DIR, "userdata/*/config/shortcuts.vdf")
    matched_files = glob.glob(shortcuts_pattern)

    if not matched_files:
        print(f"[-] No shortcuts.vdf found under {shortcuts_pattern}")
        sys.exit(1)

    appids = []
    for sf in matched_files:
        appids = update_shortcuts_vdf(sf)

    config_path = os.path.join(STEAM_DIR, "config/config.vdf")
    update_config_vdf(config_path, appids)
    update_compatdata_symlinks(appids)
    tune_battlenet_config()
    print("\n[🎉] All Blizzard games are now registered directly in Steam!")


if __name__ == "__main__":
    main()
