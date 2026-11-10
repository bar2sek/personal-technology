---
title: "Azure Lab Cost Guardrails & Admin-Only Bootstrap State (Phase 0)"
date: 2026-11-09
tags:
  - azure
  - finops
  - azure/cost-management
  - terraform/state
  - runbook
status: in-progress
aliases:
  - "Azure Cost Guardrails"
  - "Azure Phase 0"
---

# 💰 Azure Lab Cost Guardrails & Admin-Only Bootstrap State (Phase 0)

Phase 0 of the [[411-azure-mini-enterprise-architecture|Azure Mini Enterprise]]. It contains nothing billable except a few KB of state, and it's applied before anything else, so every later phase lands inside working cost alarms.

Code: `bootstrap/azure/budgets.tf`, `bootstrap/azure/storage.tf` (applied locally with `just tf-plan azure` / `just tf-apply azure`).

---

## 🧠 How Azure Cost Controls Actually Work

> [!WARNING] Budgets never stop spending
> An Azure budget is a **notification rule**, not a spending cap. When it fires, nothing is stopped, scaled down, or deleted. (Budgets *can* call an action group that runs automation, but that is code you write and maintain.) Pay-as-you-go subscriptions have no hard spending limit.

| Control | What it does | Latency | Cost |
|---|---|---|---|
| **Budget, Actual threshold** | Emails when month-to-date spend crosses 50 / 80 / 100 % | 8–24 h (Cost Management data lag) | Free |
| **Budget, Forecasted threshold** | Emails when the month's *projected* spend crosses 100 %, before the money is spent | Same lag, earlier signal | Free |
| **Cost anomaly alert** | ML model on daily spend per subscription; emails on unusual jumps | ~1 day | Free |
| **On-demand root + nightly teardown** (Phase 6) | Destroys hourly-billed resources every night | Hours | Free (GitHub Actions minutes) |
| **Azure Policy SKU denies** (Phase 1) | Blocks expensive SKUs at creation time | Immediate | Free |

The first three only **tell** you. The last two actually **prevent** spend. A lab needs both kinds.

### Budgets in this repo

| Subscription | Budget (USD/mo) | Why |
|---|---|---|
| connectivity | 15 | Hosts the on-demand Firewall / VPN sessions |
| management | 10 | State, monitoring, backup, later app workloads |
| identity | 5 (default) | Identity only, should stay near $0 |
| security | 5 (default) | Defender Foundational CSPM is free |

Each budget notifies `alert_emails` (gitignored tfvars) **and** every subscription Owner (`contact_roles = ["Owner"]`) at 50 / 80 / 100 % actual and 100 % forecasted. Subscriptions are found at plan time by the `subscr-azure-` display-name prefix (`data "azurerm_subscriptions"`), so no IDs appear in code. Amounts come from `monthly_budgets` (keyed by the `<category>` name node), else from the `<env>` node: `prod` $5, `nonprod` $5, `lab` $3. A new `subscr-azure-*` subscription gets a budget on the next apply with no code change.

---

## 🚨 Incident: Defender CSPM Charges from ALZ Policy

**Found 2026-11-09** while planning the lab rebuild.

- **Symptom:** a few dollars a month (Sep $3.08, Oct $5.19) with almost nothing deployed. It looked like "storage".
- **Real cause:** `Microsoft Defender for Cloud / Defender CSPM`, billed per resource it covers. The only billable resource was the Terraform-state storage account.
- **Why it kept coming back:** the ALZ policy assignment `Deploy-MDFC-Config-H224` (DeployIfNotExists, enforced at the `alz` management group) turns every paid Defender plan back on during remediation. Most plans in all four subscriptions showed `enabledOn: 2026-10-10`. Switching a plan off in the portal would not have stuck.
- **Fix (in order):**
  1. Set the Defender policy assignments to `DoNotEnforce`, so the policy stops re-enabling plans.
  2. Set all 10 paid plans to Free in every subscription.
  3. Tear down the ALZ footprint ([[411-azure-mini-enterprise-architecture#Why a Rebuild (2026-11-09)|docs/411]]).

```bash
# Find what is actually billing: cost by service for a subscription
az rest --method post \
  --url "https://management.azure.com/subscriptions/<sub-id>/providers/Microsoft.CostManagement/query?api-version=2023-11-01" \
  --body '{"type":"ActualCost","timeframe":"MonthToDate","dataset":{"granularity":"None","aggregation":{"cost":{"name":"Cost","function":"Sum"}},"grouping":[{"type":"Dimension","name":"MeterCategory"},{"type":"Dimension","name":"MeterSubCategory"}]}}'

# Which Defender plans are paid? (Discovery and FoundationalCspm always show Standard and are free.)
az rest --method get \
  --url "https://management.azure.com/subscriptions/<sub-id>/providers/Microsoft.Security/pricings?api-version=2024-01-01" \
  --query "value[?properties.pricingTier!='Free'].name"
```

> [!TIP] Lesson for Phase 1
> Before deploying `avm-ptn-alz`, remove or set to `DoNotEnforce` every assignment that **creates billable things**: `Deploy-MDFC-Config*` (Defender plans), `Enable-DDoS-VNET` (a DDoS plan is ~$2,944/mo), `Deploy-VM-Backup`, `Deploy-MDFC-DefSQL-AMA`. With a $5/day plan switched on, the anomaly alert above would fire within about a day.

---

## 🔐 Admin-Only Bootstrap State

This root's state holds the **Authentik client secret** in plaintext (Terraform stores sensitive values in state unencrypted). It used to sit in the Google Drive–synced vault. Phase 0 moves it into Azure, following the findings in [[409-github-cloud-oidc-gitops#⚠️ Known Risk: Bootstrap State Lives in the Drive-Synced Vault (accepted 2026-10-19)|docs/409]]:

| Finding (docs/409) | Azure implementation |
|---|---|
| Never share the CI state store | A dedicated account, `stazubootstrap…`, separate from any CI state account |
| CI must not have management-plane rights over it | It lives in the **management** subscription. The GitHub Actions SP has Contributor on **identity** only. (Contributor on the account could re-enable shared keys, list them, and read every blob.) |
| Versioning + purge of old versions, no immutability | Versioning on; lifecycle rule deletes noncurrent versions after 30 days; 30-day blob and container soft delete |
| Destroy protection | `prevent_destroy` on the account, plus a `CanNotDelete` resource lock on the RG |
| Second access gate | Shared keys disabled; only the operator holds `Storage Blob Data Contributor` (even an Owner gets 403 without it) |

> [!WARNING] Keep CI away from it in Phase 1
> When CI RBAC is redesigned, **never** grant the pipeline any role on the management subscription that covers `rg-azure-tfstate-bootstrap-*`. Phase 1 adds the policy "Storage accounts should prevent shared key access" with a Deny effect, which blocks re-enabling keys whatever any role allows.

### Runbook: apply and migrate (two steps)

The root creates the account its own state moves into, so it runs in two steps.

**Step 1: apply with local state.** ✅ Done 2026-11-09 and verified: budgets and anomaly alerts on all 4 subscriptions, account keyless (shared-key access refused), versioning on, lock in place, and a `plan` showing no changes. It took two applies because of the two gotchas under Troubleshooting.

```bash
just tf-plan azure      # review: budgets x4, anomaly alerts x4, state RG/account/container/policy/lock/role
just tf-apply azure
```

**Step 2: migrate the state into the new account.** ✅ Done 2026-11-09: 22 resources moved (serial 53 → 54, since the migration write bumps it), `plan` shows no changes, the blob lease releases after each run, and the local `terraform.tfstate*` files were deleted from the vault. The interactive `yes` prompt was answered with `-force-copy`, which was safe because the container was empty.

```bash
# a) Back up the local state OUTSIDE Google Drive first.
mkdir -p ~/.terraform-backups/azure && cp bootstrap/azure/terraform.tfstate* ~/.terraform-backups/azure/

# b) Create the gitignored partial backend config (it holds the management subscription ID).
cat > bootstrap/azure/backend.hcl <<'EOF'
subscription_id      = "<management-subscription-id>"
resource_group_name  = "rg-azure-tfstate-bootstrap-prod-cus-001"
storage_account_name = "stazubootstrapprodcus001"
container_name       = "tfstate"
key                  = "bootstrap/azure/terraform.tfstate"
use_azuread_auth     = true
EOF

# c) Uncomment the `backend "azurerm" {}` block in providers.tf, then:
just tf-init azure -migrate-state     # answer "yes" to copy local state to Azure

# d) Prove it worked: no changes, state is remote.
just tf-plan azure
just tf azure state list | head
```

Then delete `bootstrap/azure/terraform.tfstate*` from the vault and **empty the Google Drive trash**.

> [!CAUTION] Drive keeps old file versions
> Drive's version history still holds earlier copies of the state, including the Authentik secret. Rotating the secret makes those copies useless. That is a separate, planned change because Authentik must be updated at the same time.

---

## ✅ Verification

```bash
# Budgets exist on all four subscriptions with the expected amounts
just tf azure output budgets

# Each subscription: budget + anomaly alert visible to Cost Management
for s in $(az account list --query "[?starts_with(name,'subscr-azure-')].id" -o tsv); do
  az consumption budget list --subscription "$s" --query "[].{name:name, amount:amount}" -o tsv
done

# State account is locked, keyless, and versioned
az storage account show -n stazubootstrapprodcus001 \
  --subscription subscr-azure-management-homelab-prod-0bb5 \
  --query "{sharedKey:allowSharedKeyAccess, tls:minimumTlsVersion, infraEnc:encryption.requireInfrastructureEncryption}"
az lock list -g rg-azure-tfstate-bootstrap-prod-cus-001 \
  --subscription subscr-azure-management-homelab-prod-0bb5 -o table

# Negative test: shared-key access must be refused
az storage blob list --account-name stazubootstrapprodcus001 -c tfstate --auth-mode key   # expect an error
```

---

## 🛠️ Troubleshooting

- **`The start date must be the first day of a month and not before the current month`.** Budgets can't start in the past. Set `budget_start_date` to the first of the current month. `ignore_changes = [time_period]` stops later drift.
- **Anomaly alert created but never emails.** Cost Management needs a few days of cost history on a subscription before the model produces alerts. A brand-new or $0 subscription stays quiet.
- **`403 AuthorizationPermissionMismatch` on `terraform init`.** Role assignments take up to ~5 minutes to propagate. Wait, then retry.
- **`ScopeLocked` when deleting the state RG.** That's the `CanNotDelete` lock doing its job. Remove the lock first, on purpose.
- **`400 InvalidScheduledActionEmailMessage` on `azurerm_cost_anomaly_alert`** (hit on the first apply, 2026-11-09). Azure caps `message` at **100 characters**. The provider schema doesn't enforce it, so `terraform validate` passes and only the API rejects it. Find the real error text in the Activity Log: `az monitor activity-log list --offset 3h --status Failed`.
- **`ResourceGroupNotFound` on `azurerm_storage_container`** (also hit on the first apply). With `storage_account_id`, azurerm v4 creates the container through ARM in the **provider's** subscription, so a container whose account uses `provider = azurerm.management` needs the same alias. Without it, the request goes to the default (identity) subscription.
