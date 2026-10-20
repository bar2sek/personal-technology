#!/usr/bin/env python3
"""
sync_steam_shortcuts.py
Puts Battle.net and the installed Blizzard games into Steam as non-Steam
shortcuts, all sharing one GE-Proton prefix (compatdata/3234450451).

Two phases, same script (run by the Bazzite playbook):
  * Bootstrap: Battle.net is not installed yet. Creates a "Battle.net" shortcut
    with the fixed AppID that runs ~/Downloads/Battle.net-Setup.exe, so pressing
    Play installs Battle.net into the right prefix.
  * Sync: Battle.net is installed. Repoints that shortcut at the launcher, adds
    a shortcut for each Blizzard game found in the prefix, symlinks each game's
    compatdata to the shared prefix, and tunes Battle.net.config.
Either way, installed native Flatpak games (NATIVE_FLATPAKS, e.g. DevilutionX)
get a plain shortcut with no Proton mapping.

Steam reads shortcuts.vdf only at startup and rewrites config.vdf on exit, so
Steam must be stopped before a real run. `--check` changes nothing and prints
CHANGES_PENDING or UP_TO_DATE, so the playbook only stops Steam when needed.
"""

import os
import re
import sys
import glob
import json
import zlib
import struct
import shutil

STEAM_DIR = os.environ.get("STEAM_DIR", os.path.expanduser("~/.local/share/Steam"))
PROTON_TOOL = "GE-Proton10-34"
COMPAT_PREFIX_ID = "3234450451"
PRIMARY_PREFIX = os.path.join(STEAM_DIR, "steamapps/compatdata", COMPAT_PREFIX_ID)
PROGRAM_FILES = os.path.join(PRIMARY_PREFIX, "pfx/drive_c/Program Files (x86)")
BNET_START_DIR = os.path.join(PROGRAM_FILES, "Battle.net")
BNET_EXE = os.path.join(BNET_START_DIR, "Battle.net Launcher.exe")
BNET_SETUP = os.environ.get("BNET_SETUP", os.path.expanduser("~/Downloads/Battle.net-Setup.exe"))
ICON_BASE = os.path.join(PRIMARY_PREFIX, "pfx/drive_c/proton_shortcuts/icons/256x256/apps")
BNET_CONFIG_PATH = os.path.join(
    PRIMARY_PREFIX,
    "pfx/drive_c/users/steamuser/AppData/Roaming/Battle.net/Battle.net.config"
)

# Blizzard checks for a Windows NVIDIA driver >= 595.71. DXVK-NVAPI reports the
# Linux driver (e.g. 580.x), so this deliberately reports a newer version.
NVAPI = "DXVK_NVAPI_DRIVER_VERSION=59571"

BATTLENET = {
    "name": "Battle.net",
    "fixed_appid": int(COMPAT_PREFIX_ID),
    "launch_options": f"{NVAPI} %command%",
    "icon": "1AC2_Battle.net Launcher.0.png",
}

# install_dir: Battle.net's default folder under Program Files (x86); a shortcut
# is only added once that folder exists. launch: Battle.net's product code.
GAMES = [
    {"name": "Diablo IV", "install_dir": "Diablo IV", "launch": "Fen",
     "icon": "B790_Diablo IV Launcher.0.png"},
    {"name": "StarCraft II", "install_dir": "StarCraft II", "launch": "S2",
     "icon": "5F50_StarCraft II.0.png"},
    {"name": "Diablo II: Resurrected", "install_dir": "Diablo II Resurrected", "launch": "OSI",
     "icon": "B271_Diablo II Resurrected Launcher.0.png"},
    {"name": "Warcraft III", "install_dir": "Warcraft III", "launch": "W3",
     "icon": "23A7_Warcraft III Launcher.0.png"},
    {"name": "StarCraft", "install_dir": "StarCraft", "launch": "S1", "icon": ""},
    # Not "DRTL" (its product_id): launch codes are the prefix of the
    # productCode Battle.net logs at startup, here "D1_retail".
    {"name": "Diablo", "install_dir": "Diablo", "launch": "D1", "icon": ""},
]

# Native Linux games installed as system Flatpaks (by the playbook). They get a
# plain shortcut, no Proton mapping and no shared prefix. Added once installed.
FLATPAK_ROOT = os.environ.get("FLATPAK_ROOT", "/var/lib/flatpak")
NATIVE_FLATPAKS = [
    {"name": "Diablo (DevilutionX)", "app_id": "org.diasurgical.DevilutionX"},
]

# The script owns only the keys of the entries it builds; everything else in an
# existing shortcut (play time, collections, hidden flag) is Steam's and is left
# alone. These defaults fill in the rest of a newly added shortcut.
NEW_SHORTCUT_DEFAULTS = {
    "ShortcutPath": "", "IsHidden": 0, "AllowDesktopConfig": 1, "AllowOverlay": 1,
    "OpenVR": 0, "Devkit": 0, "DevkitGameID": "", "DevkitOverrideAppID": 0,
    "LastPlayTime": 0, "FlatpakAppID": "", "sortas": "", "tags": {},
}


def parse_bin_vdf(data: bytes):
    pos = 0

    def read_str():
        nonlocal pos
        end = data.find(b"\x00", pos)
        if end == -1:
            raise ValueError("Unterminated string in binary VDF")
        s = data[pos:end].decode("utf-8")
        pos = end + 1
        return s

    def parse_dict():
        nonlocal pos
        res = {}
        while pos < len(data):
            t = data[pos:pos+1]
            pos += 1
            if t == b"\x08":
                return res
            key = read_str()
            if t == b"\x00":
                res[key] = parse_dict()
            elif t == b"\x01":
                res[key] = read_str()
            elif t == b"\x02":
                res[key] = struct.unpack("<I", data[pos:pos+4])[0]
                pos += 4
            else:
                # Unknown type: refuse rather than misread and rewrite the file.
                raise ValueError(f"Unsupported binary VDF type {t!r} at key {key!r}")
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


def quoted(path: str) -> str:
    return f'"{path}"'


def desired_shortcuts(bnet_installed: bool):
    """Return the shortcut entries (managed fields only) that should exist."""
    icon = lambda f: (p if f and os.path.exists(p := os.path.join(ICON_BASE, f)) else "")
    if not bnet_installed:
        # Bootstrap: same name and AppID as the final launcher shortcut, so the
        # installer creates the prefix the launcher and games will use.
        return [{
            "appid": BATTLENET["fixed_appid"],
            "AppName": BATTLENET["name"],
            "Exe": quoted(BNET_SETUP),
            "StartDir": quoted(os.path.dirname(BNET_SETUP) + "/"),
            "icon": "",
            "LaunchOptions": "",
        }]

    exe, start_dir = quoted(BNET_EXE), quoted(BNET_START_DIR + "/")
    entries = [{
        "appid": BATTLENET["fixed_appid"],
        "AppName": BATTLENET["name"],
        "Exe": exe,
        "StartDir": start_dir,
        "icon": icon(BATTLENET["icon"]),
        "LaunchOptions": BATTLENET["launch_options"],
    }]
    for g in GAMES:
        if not os.path.isdir(os.path.join(PROGRAM_FILES, g["install_dir"])):
            continue
        # Steam derives a non-Steam AppID from Exe + AppName; computing it the
        # same way keeps it stable across runs (and matches Steam's own value).
        appid = (zlib.crc32((exe + g["name"]).encode("utf-8")) & 0xFFFFFFFF) | 0x80000000
        entries.append({
            "appid": appid,
            "AppName": g["name"],
            "Exe": exe,
            "StartDir": start_dir,
            "icon": icon(g["icon"]),
            "LaunchOptions": f'{NVAPI} %command% --exec="launch {g["launch"]}"',
        })
    return entries


def native_shortcuts():
    """Shortcut entries for the installed native Flatpak games."""
    exe = quoted("/usr/bin/flatpak")
    entries = []
    for g in NATIVE_FLATPAKS:
        if not os.path.isdir(os.path.join(FLATPAK_ROOT, "app", g["app_id"])):
            continue
        # Largest exported icon, e.g. .../hicolor/512x512/apps/<app_id>.png
        icons = glob.glob(os.path.join(
            FLATPAK_ROOT, "exports/share/icons/hicolor/*/apps", g["app_id"] + ".png"))
        icons.sort(key=lambda p: int(re.match(r"\d+", p.split("/")[-3]).group())
                   if re.match(r"\d+", p.split("/")[-3]) else 0)
        entries.append({
            "appid": (zlib.crc32((exe + g["name"]).encode("utf-8")) & 0xFFFFFFFF) | 0x80000000,
            "AppName": g["name"],
            "Exe": exe,
            "StartDir": quoted("/usr/bin/"),
            "icon": icons[-1] if icons else "",
            "LaunchOptions": f"run {g['app_id']}",
            "FlatpakAppID": g["app_id"],
        })
    return entries


def plan_shortcuts(shortcuts_path: str, entries: list):
    """Return (new_file_bytes or None, change descriptions)."""
    if os.path.exists(shortcuts_path):
        with open(shortcuts_path, "rb") as f:
            parsed = parse_bin_vdf(f.read())  # raises: never clobber other shortcuts
    else:
        parsed = {"shortcuts": {}}

    shortcuts = parsed.setdefault("shortcuts", {})
    by_name = {v["AppName"]: v for v in shortcuts.values()
               if isinstance(v, dict) and "AppName" in v}
    changes = []
    for entry in entries:
        existing = by_name.get(entry["AppName"])
        if existing is None:
            new = {**NEW_SHORTCUT_DEFAULTS, **entry}
            shortcuts[str(len(shortcuts))] = new
            by_name[entry["AppName"]] = new
            changes.append(f"add shortcut {entry['AppName']} (AppID {entry['appid']})")
        elif any(existing.get(k) != v for k, v in entry.items()):
            existing.update(entry)
            changes.append(f"update shortcut {entry['AppName']} (AppID {entry['appid']})")
    return (encode_bin_vdf(parsed) if changes else None), changes


def plan_config_vdf(config_path: str, appids: list):
    """Map every Proton shortcut AppID to PROTON_TOOL.

    Deliberately no global default ("0"): Steam applies it to every unmapped
    non-Steam shortcut too, which would run native games (DevilutionX's
    /usr/bin/flatpak) inside Wine. Older versions of this script set "0" to
    PROTON_TOOL, so that entry is removed; any other "0" choice is left alone.
    """
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"config.vdf not found at {config_path}")
    with open(config_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    idx = content.find('"CompatToolMapping"')
    if idx == -1:
        # Steam only writes the block once some compatibility tool is chosen,
        # so a fresh install has none: add an empty one to Software/Valve/Steam.
        steam = re.search(r'"Software"\s*\{\s*"Valve"\s*\{\s*"Steam"\s*\{\n', content, re.IGNORECASE)
        if not steam:
            raise ValueError("No Software/Valve/Steam section in config.vdf (start Steam once first)")
        content = (content[:steam.end()] + '\t\t\t\t"CompatToolMapping"\n\t\t\t\t{\n\t\t\t\t}\n'
                   + content[steam.end():])
        idx = content.find('"CompatToolMapping"')
    brace_start = content.find("{", idx)
    depth, pos = 1, brace_start + 1
    while pos < len(content) and depth > 0:
        if content[pos] == "{":
            depth += 1
        elif content[pos] == "}":
            depth -= 1
        pos += 1

    block = content[brace_start:pos]
    changes = []
    legacy_default = re.search(
        rf'\n\s*"0"\s*\{{[^}}]*"name"\s*"{re.escape(PROTON_TOOL)}"[^}}]*\}}', block)
    if legacy_default:
        block = block.replace(legacy_default.group(0), "")
        changes.append(f"remove global default (0) -> {PROTON_TOOL}")

    for aid, name in appids:
        match = re.search(rf'"{aid}"\s*\{{[^}}]*"name"\s*"([^"]*)"[^}}]*\}}', block, re.DOTALL)
        if match:
            if match.group(1) != PROTON_TOOL:
                block = block.replace(match.group(0),
                                      match.group(0).replace(f'"{match.group(1)}"', f'"{PROTON_TOOL}"'))
                changes.append(f"map {name} ({aid}) {match.group(1) or 'default'} -> {PROTON_TOOL}")
        else:
            new_entry = (
                f'\n\t\t\t\t\t"{aid}"\n'
                f'\t\t\t\t\t{{\n'
                f'\t\t\t\t\t\t"name"\t\t"{PROTON_TOOL}"\n'
                f'\t\t\t\t\t\t"config"\t\t""\n'
                f'\t\t\t\t\t\t"priority"\t\t"250"\n'
                f'\t\t\t\t\t}}'
            )
            last = block.rfind("}")
            block = block[:last] + new_entry + "\n\t\t\t\t" + block[last:]
            changes.append(f"map {name} ({aid}) -> {PROTON_TOOL}")

    new_content = content[:brace_start] + block + content[pos:] if changes else None
    return new_content, changes


def plan_symlinks(appids: list):
    """Each game's compatdata/<appid> points at the shared Battle.net prefix."""
    compatdata = os.path.join(STEAM_DIR, "steamapps/compatdata")
    return [(os.path.join(compatdata, aid), name) for aid, name in appids
            if aid != COMPAT_PREFIX_ID and not os.path.lexists(os.path.join(compatdata, aid))]


def plan_battlenet_config():
    """Battle.net closes when a game starts; CEF GPU acceleration off (deadlocks)."""
    if not os.path.exists(BNET_CONFIG_PATH):
        return None, []  # written by Battle.net on first login
    with open(BNET_CONFIG_PATH, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    wanted = [
        (("Client", "GameLaunchWindowBehavior"), "2", "Battle.net exits on game launch"),
        (("Client", "HardwareAcceleration"), "false", "Battle.net browser GPU acceleration off"),
        (("Games", "fenris", "AdditionalLaunchArguments"), "-bypassgpudrivercheck",
         "Diablo IV -bypassgpudrivercheck"),
    ]
    changes = []
    for path, value, desc in wanted:
        node = cfg
        for key in path[:-1]:
            node = node.setdefault(key, {})
        if node.get(path[-1]) != value:
            node[path[-1]] = value
            changes.append(desc)
    return (cfg if changes else None), changes


def write_with_backup(path: str, data, mode: str):
    if os.path.exists(path):
        shutil.copy2(path, path + ".bak")
    with open(path, mode, **({} if "b" in mode else {"encoding": "utf-8"})) as f:
        f.write(data)


def main():
    check = "--check" in sys.argv[1:]
    bnet_installed = os.path.exists(BNET_EXE)
    if not bnet_installed and not os.path.exists(BNET_SETUP):
        sys.exit(f"[!] Neither the Battle.net launcher nor {BNET_SETUP} exists")

    user_configs = glob.glob(os.path.join(STEAM_DIR, "userdata/*/config"))
    if not user_configs:
        sys.exit("[!] No Steam userdata found: log in to Steam once first")

    print(f"[*] Phase: {'sync' if bnet_installed else 'bootstrap (Battle.net not installed yet)'}")
    proton_entries = desired_shortcuts(bnet_installed)
    # Only the Proton shortcuts get a compat tool mapping and prefix symlink.
    appids = [(str(e["appid"]), e["AppName"]) for e in proton_entries]
    entries = proton_entries + native_shortcuts()

    writes, changes = [], []
    for cfg_dir in user_configs:
        path = os.path.join(cfg_dir, "shortcuts.vdf")
        data, c = plan_shortcuts(path, entries)
        if data is not None:
            writes.append(lambda p=path, d=data: write_with_backup(p, d, "wb"))
        changes += c

    config_path = os.path.join(STEAM_DIR, "config/config.vdf")
    content, c = plan_config_vdf(config_path, appids)
    if content is not None:
        writes.append(lambda: write_with_backup(config_path, content, "w"))
    changes += c

    links = plan_symlinks(appids)
    for link, name in links:
        writes.append(lambda l=link: os.symlink(COMPAT_PREFIX_ID, l))
        changes.append(f"symlink compatdata/{os.path.basename(link)} -> {COMPAT_PREFIX_ID} ({name})")

    bnet_cfg, c = plan_battlenet_config()
    if bnet_cfg is not None:
        writes.append(lambda: write_with_backup(BNET_CONFIG_PATH, json.dumps(bnet_cfg, indent=4), "w"))
    changes += c

    for c in changes:
        print(f"  [{'~' if check else '+'}] {c}")
    if check:
        print("CHANGES_PENDING" if changes else "UP_TO_DATE")
        return
    for w in writes:
        w()
    print(f"[✔] Applied {len(changes)} change(s)" if changes else "[*] Already up to date")


if __name__ == "__main__":
    main()
