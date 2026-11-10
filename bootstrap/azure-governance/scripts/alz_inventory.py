#!/usr/bin/env python3
"""Inventory an ALZ library release for cost-bearing policy (docs/417).

Run it BEFORE bumping the `ref` in providers.tf. A new library release can add
assignments to archetypes this root inherits (root, platform, landing_zones, ...),
and anything that deploys (DeployIfNotExists / Modify) may create billable
resources, as Deploy-MDFC-Config did in 2026-10 (docs/412).

Usage (stdlib only, no install):
    mkdir -p /tmp/alzlib && curl -sL \
      https://codeload.github.com/Azure/Azure-Landing-Zones-Library/tar.gz/refs/tags/platform/alz/<ref> \
      | tar xz -C /tmp/alzlib
    python3 -I scripts/alz_inventory.py /tmp/alzlib/*/platform/alz

Output, per archetype: every assignment with its kind (def/set, builtin/alz),
headline effect, identity, the policy default values it needs (a Log Analytics
workspace, DDoS plan, ...), and for ALZ initiatives the members whose effect
resolves to DeployIfNotExists / Modify / Append. Built-in initiatives can't be
expanded offline; check those with `az policy set-definition show`.
"""
import glob
import json
import re
import sys

DEPLOYS = {"deployifnotexists", "modify", "append"}
PARAM = re.compile(r"\[parameters\('([^']+)'\)\]")


def load_dir(lib, sub):
    out = {}
    for p in glob.glob(f"{lib}/{sub}/*.json"):
        with open(p) as f:
            d = json.load(f)
        out[d["name"]] = d
    return out


def deploying_members(assignment, set_def):
    """Members of an initiative whose effect resolves to a deploying effect."""
    set_params = set_def["properties"].get("parameters", {})
    asg_params = assignment["properties"].get("parameters", {})
    hits = []
    for m in set_def["properties"]["policyDefinitions"]:
        eff = (m.get("parameters") or {}).get("effect", {}).get("value")
        if eff is None:
            continue
        mm = PARAM.match(str(eff))
        if mm:
            name = mm.group(1)
            eff = (asg_params.get(name) or {}).get("value", (set_params.get(name) or {}).get("defaultValue"))
            label = f"{m['policyDefinitionReferenceId']}[{name}]"
        else:
            label = m["policyDefinitionReferenceId"]
        if str(eff).lower() in DEPLOYS:
            hits.append(f"{label}={eff}")
    return hits


def main(lib):
    assignments = load_dir(lib, "policy_assignments")
    defs = load_dir(lib, "policy_definitions")
    sets = load_dir(lib, "policy_set_definitions")
    with open(f"{lib}/alz_policy_default_values.json") as f:
        defaults = json.load(f)
    needs = {}
    for d in defaults.get("defaults", []):
        for pa in d.get("policy_assignments", []):
            needs.setdefault(pa["policy_assignment_name"], []).append(d["default_name"])

    for path in sorted(glob.glob(f"{lib}/archetype_definitions/*.json")):
        with open(path) as f:
            arch = json.load(f)
        print(f"\n## {arch['name']}")
        for name in sorted(arch.get("policy_assignments", [])):
            a = assignments[name]
            props = a["properties"]
            pid = props["policyDefinitionId"]
            short = pid.split("/")[-1]
            kind = "set" if "policySetDefinitions" in pid else "def"
            origin = "builtin" if pid.startswith("/providers/Microsoft.Authorization") else "alz"
            eff = (props.get("parameters", {}).get("effect") or {}).get("value")
            if eff is None and short in defs:
                eff = (defs[short]["properties"].get("parameters", {}).get("effect") or {}).get("defaultValue")
            ident = a.get("identity", {}).get("type", "-")
            line = f"- {name} | {kind}/{origin} | effect={eff} | identity={ident}"
            if needs.get(name):
                line += f" | needs={','.join(needs[name])}"
            print(line)
            if kind == "set" and short in sets:
                hits = deploying_members(a, sets[short])
                if hits:
                    print(f"    deploying members: {'; '.join(hits)}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
