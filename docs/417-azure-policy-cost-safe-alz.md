---
title: "Cost-Safe ALZ Policy: What Was Removed, Hidden Defender Traps & Guardrails"
date: 2026-11-09
tags:
  - azure
  - azure/policy
  - azure/landing-zone
  - finops
  - terraform
status: in-progress
aliases:
  - "Cost-Safe ALZ Policy"
  - "ALZ Policy Inventory"
---

# 🛡️ Cost-Safe ALZ Policy: What Was Removed, Hidden Defender Traps & Guardrails

Policy half of [[416-azure-management-groups-and-policy|Phase 1]]. The goal: keep as much of the Azure Landing Zones (ALZ) policy baseline as possible, because that's what enterprises run, while making sure **no assignment can create anything billable**. The previous ALZ deployment failed exactly there ([[412-azure-lab-cost-guardrails#🚨 Incident: Defender CSPM Charges from ALZ Policy|docs/412]]).

Library: `platform/alz` **2026.11.0**, 95 assignments across 12 archetypes. Inventory method: `bootstrap/azure-governance/scripts/alz_inventory.py`, plus `az policy set-definition show` for the built-in initiatives the script can't expand offline.

---

## 🧠 How Policy Creates Cost

| Effect | Does it change anything? | Cost risk |
|---|---|---|
| `Audit`, `AuditIfNotExists` | No: compliance record only | None |
| `Deny`, `DenyAction` | Blocks the request | None (it can block a deployment you wanted, which is a different risk) |
| `Modify`, `Append` | Rewrites the resource's properties on create/update | Low, **unless** the property attaches a paid thing (e.g. a DDoS plan) |
| `DeployIfNotExists` (DINE) | Deploys a related resource or setting with the assignment's managed identity | **High**: Defender plans, backup vaults, agents and data collection rules (→ Log Analytics ingestion) |

> [!IMPORTANT] Rule used for every decision below
> Keep an assignment unless its DINE/Modify path creates or attaches something billable, or needs a resource that doesn't exist yet (Log Analytics workspace, DDoS plan, private DNS zones). Removed is not "bad policy": most of these come back in the phase that builds the thing they need.

`DoNotEnforce` is **not** the same as removal. It stops Deny from blocking and stops DINE from remediating *new* resources, but anyone can still run a **remediation task** against a DoNotEnforce DINE assignment, and a later flip to `Default` arms it. Cost-bearing assignments are therefore removed outright, not just left unenforced.

---

## ❌ Removed Assignments (30)

Implemented as `policy_assignments_to_remove` in `lib/homelab_*.alz_archetype_override.yaml`. Overrides are the approach the AVM module recommends over `creation_enabled = false`, because the library then stays the single source of truth.

| Assignment | Removed at | Why | Comes back |
|---|---|---|---|
| `Deploy-MDFC-Config-H224` | root | Turns on every paid Defender plan: **the 2026-10 incident** | Never in this lab |
| `Deploy-MDFC-OssDb`, `Deploy-MDFC-SqlAtp` | root | Defender for OSS DBs / SQL (paid) | Never |
| `Deploy-MDEndpoints`, `Deploy-MDEndpointsAMA` | root | Defender for Endpoint needs Defender for Servers (paid) | Never |
| `Deploy-AzActivity-Log` | root | Needs a Log Analytics workspace | Phase 5 (activity log ingestion is free) |
| `Deploy-Diag-LogsCat` | root | Diagnostic logs for every resource into Log Analytics: billed ingestion | Phase 5, scoped down |
| `Deploy-SvcHealth-BuiltIn` | root | Creates an RG + alert rules in every subscription | Phase 5 |
| `Deploy-MDFC-DefSQL-AMA` | platform, landingzones | Defender for SQL on VMs + AMA | Never |
| `Deploy-VM/VMSS/vmArc-ChangeTrack` (3) | platform, landingzones | AMA + data collection rule → ingestion | Maybe Phase 5 |
| `Deploy-VM/VMSS/vmHybr-Monitoring` (3) | platform, landingzones | VM Insights → ingestion | Maybe Phase 5 |
| `DenyAction-DeleteUAMIAMA` | platform | Protects an AMA identity that doesn't exist | With AMA |
| `Deploy-VM-Backup` | identity, landingzones | Creates Recovery Services vaults; protected-instance fees | Phase 3 does backup on purpose |
| `Enable-DDoS-VNET` | connectivity, landingzones | Attaches VNets to a DDoS Network Protection plan (~$2,944/mo) | Never |
| `Deploy-AzSqlDb-Auditing` | landingzones | SQL auditing into Log Analytics | Phase 5 if SQL is used |
| `Deploy-SQL-Threat` | landingzones | SQL Advanced Threat Protection = Defender for SQL (paid) | Never |
| `Deploy-Private-DNS-Zones` | corp | Needs the hub's private DNS zones | **Phase 2** |

The `local` archetype (Azure Local) isn't used at all: no `local` MG.

---

## 🪤 Hidden Traps Inside "Guardrail" Initiatives

The headline effect of the ALZ `Enforce-GR-*` initiatives is parameterised, so the assignment list makes them look harmless. Expanding their members showed **six that enable a paid per-resource Defender plan**. A per-resource plan bills even while the subscription-level plan is Free, so the custom deny below wouldn't catch them.

| Assignment (platform + landingzones) | Member | Parameter set to `Disabled` |
|---|---|---|
| `Enforce-GR-Storage0` | `Dine-Storage-Threat-Protection` (Defender for Storage) | `storageThreatProtection` |
| `Enforce-GR-CosmosDb0` | `Dine-CosmosDb-Atp` | `cosmosDbAtp` |
| `Enforce-GR-MySQL0` | `Dine-MySql-Adv-Threat-Protection` | `mySqlAdvThreatProtection` |
| `Enforce-GR-PostgreSQL0` | `Dine-PostgreSql(-Flexible)-Adv-Threat-Protection` | `postgreSqlAdvThreatProtection` |
| `Enforce-GR-SQL0` | `Dine-Sql-Managed-Defender` | `sqlManagedDefender` |
| `Enforce-GR-Synapse0` | `Dine-Synapse-Defender` | `synapseDefender` |
| `Enforce-GR-Network0` | `Modify-vNet-DDoS` (attach a DDoS plan) | `vnetModifyDdos` |

These stay **assigned** (the other ~20 members of each are useful Deny/Modify guardrails: no public endpoints, no local auth, TLS minimums). Only the paid member is switched off, through `local.assignment_parameters` in `main.tf`. Checked in the 2026-11-09 plan: all seven show `"Disabled"` in both the platform and landingzones assignments.

> [!TIP] Interview takeaway
> "We removed the Defender policy" isn't enough. Cost can hide in initiatives whose names say *guardrails*. Expand every initiative to its members and resolve each effect parameter before trusting an archetype.

### Checked and kept

| Assignment | Why it's safe |
|---|---|
| `Deploy-MCSB2-Monitoring`, `Deploy-ASC-Monitoring` (MCSB v2/v1) | Every `*_DINE`-named member is pinned to `AuditIfNotExists`. Free, and it feeds the Defender for Cloud secure score (Foundational CSPM, free). |
| `Deploy-GuestAttest` | No deploying members resolved; installs a free attestation extension on Trusted Launch VMs |
| `Enable-AUM-CheckUpdates` | Periodic update assessment is free on Azure VMs. **Billed on Arc-enabled servers**, but none are planned (Talos can't run Arc for Servers). |
| `Enforce-ACSB` | Guest Configuration audit: free on Azure VMs, billed per Arc server (same note) |
| `Enforce-TLS-SSL-Q225`, `Enforce-GR-AppServices0`, `-KeyVaultSup0`, ... | DINE/Modify members only change settings (TLS, debugging, public access); they create nothing billable |

---

## ➕ Custom Cost Guardrails (added at the intermediate root)

All `lib/*.alz_policy_assignment.json`, added through `homelab_root`'s `policy_assignments_to_add`. List values come from Terraform variables, so they're changed in `variables.tf`, not JSON.

| Assignment | Policy | Effect | Value |
|---|---|---|---|
| `Allowed-Locations` | built-in `e56962a6…` | Deny | `centralus`, `eastus2` (`global` resources are exempt) |
| `Allowed-RG-Locations` | built-in `e765b5de…` | Deny | same |
| `Allowed-VM-SKUs` | built-in `cccc23c7…` | Deny | B-series v1/v2 up to 2 vCPU (also covers VMSS and AKS node pools) |
| `Deny-Costly-ResTypes` | built-in `6c112d4e…` | Deny | DDoS plans, ExpressRoute circuits/ports/gateways, AVS, SQL MI |
| `Deny-Storage-SharedKey` | built-in `8c6a50c6…` | Deny | Entra-only storage; stops anyone re-enabling keys on the state accounts ([[412-azure-lab-cost-guardrails#🔐 Admin-Only Bootstrap State\|412]]) |
| `Deny-Paid-Defender` | **custom** `Deny-Paid-Defender-Plans` | Deny | Any `Microsoft.Security/pricings` set to `Standard`, except `Discovery` and `FoundationalCspm` (both always report Standard and are free) |

`Deny-Paid-Defender-Plans` is the *preventive* control the incident lacked: budgets and anomaly alerts only tell you a day later. It uses the `Microsoft.Security/pricings/pricingTier` alias (verified to exist on 2026-11-09). Because pricings is a subscription-level extension resource, its Deny behaviour must be **proven by test** before it's trusted (M5 step 4).

---

## 🚦 Audit → Enforce Plan (M5)

Everything starts `DoNotEnforce` (`policy_enforcement_default`). Flip per MG with `policy_enforcement_by_mg` in the governance root's `terraform.tfvars`, applying and checking after each step:

1. **Read compliance** (about 30 min after M3, or `az policy state trigger-scan`). Almost nothing is deployed, so expect findings mainly on the two state accounts in management (LRS fails the zone-resiliency audit; the public endpoint fails the private-endpoint audits), both accepted in [[412-azure-lab-cost-guardrails|docs/412]]. Note anything that would be *denied* under enforcement before flipping its MG.
2. **Empty MGs first:** `sandbox`, `decommissioned`, `landingzones`, `corp`. Nothing lives there, so enforcement can't break anything, and Phase 4 starts on enforced ground.
   ```hcl
   policy_enforcement_by_mg = { sandbox = "Default", decommissioned = "Default", landingzones = "Default", corp = "Default" }
   ```
3. **Platform MGs:** `platform`, `identity`. Re-check that the two state accounts are compliant with `Deny-Storage-SharedKey` (they're keyless) and that nothing in identity has a public IP.
4. **Intermediate root last** (`homelab = "Default"`), because it carries the custom denies that reach every subscription. Then **test the Defender deny** in the security subscription with the cheapest plan (Key Vault, billed per transaction):
   ```bash
   az security pricing create -n KeyVaults --tier standard --subscription subscr-azure-security-homelab-prod-0bb5
   # expect: RequestDisallowedByPolicy ... Deny-Paid-Defender
   # if it SUCCEEDS, the deny doesn't work on pricings: set it straight back and record it here
   az security pricing create -n KeyVaults --tier free --subscription subscr-azure-security-homelab-prod-0bb5
   ```
5. Once everything is enforced, set `policy_enforcement_default = "Default"` and drop the per-MG map.

> [!WARNING] Enforcing DINE is not retroactive
> Flipping a DINE/Modify assignment to `Default` only affects resources created or updated afterwards. Existing resources need a **remediation task** (`az policy remediation create`). That's the step that could create cost, so run one only after re-reading the assignment.

---

## 🔁 Before Every Library Upgrade

```bash
mkdir -p /tmp/alzlib && curl -sL \
  https://codeload.github.com/Azure/Azure-Landing-Zones-Library/tar.gz/refs/tags/platform/alz/<new-ref> | tar xz -C /tmp/alzlib
python3 -I bootstrap/azure-governance/scripts/alz_inventory.py /tmp/alzlib/*/platform/alz > /tmp/alz-new.txt
# Compare against this note: any NEW assignment or deploying member on root, platform,
# landing_zones, identity, connectivity, corp, sandbox or decommissioned needs a decision.
```

Then bump `ref` in `providers.tf`, plan, and read the diff. The plan is the second safety net, because a new assignment shows up as `will be created`.

---

## 🔗 Related

- [[416-azure-management-groups-and-policy|416 - Phase 1 Hub & Runbook]]
- [[412-azure-lab-cost-guardrails|412 - Cost Guardrails & the Defender Incident]]
- [[411-azure-mini-enterprise-architecture|411 - Azure Mini Enterprise Roadmap]] (Phase 7 "policy creep" check on Arc)
