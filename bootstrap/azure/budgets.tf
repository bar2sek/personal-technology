# ==============================================================================
# Cost Guardrails: budgets + cost-anomaly alerts on every lab subscription
# ==============================================================================
# IMPORTANT: Azure budgets NOTIFY, they never stop or delete anything. They are
# an early-warning system. The hard backstops are (a) on-demand resources living
# in their own state with a nightly auto-teardown, and (b) Policy SKU denies.
#
# Budgets read from Cost Management, which lags real usage by ~8-24 hours.
# The "Forecasted" notification exists to close that gap: it fires when the
# month's projected spend crosses the threshold, before the money is spent.

data "azurerm_subscriptions" "lab" {
  display_name_prefix = var.lab_subscription_prefix
}

locals {
  # Keyed by display name so the IDs never need to appear in code or tfvars.
  lab_subscriptions = {
    for s in data.azurerm_subscriptions.lab.subscriptions : s.display_name => s.id
  }

  # Parse the docs/105 nodes out of each name:
  #   subscr-azure-<category>-<product>-<env>-<tenant-4>
  #   "subscr-azure-identity-homelab-prod-0bb5" -> category "identity", env "prod"
  lab_subscription_labels = {
    for name, _ in local.lab_subscriptions :
    name => split("-", trimprefix(name, var.lab_subscription_prefix))[0]
  }
  lab_subscription_envs = {
    for name, _ in local.lab_subscriptions :
    name => try(reverse(split("-", name))[1], "")
  }

  # Override by category first, then the env default, then the fallback.
  lab_subscription_budgets = {
    for name, _ in local.lab_subscriptions :
    name => lookup(
      var.monthly_budgets,
      local.lab_subscription_labels[name],
      lookup(var.default_monthly_budget_by_env, local.lab_subscription_envs[name], var.monthly_budget_fallback)
    )
  }

  actual_thresholds = [50, 80, 100]
}

resource "azurerm_consumption_budget_subscription" "lab" {
  for_each = local.lab_subscriptions

  name            = "budget-${local.lab_subscription_labels[each.key]}-monthly"
  subscription_id = each.value # "/subscriptions/<guid>" from the data source
  amount          = local.lab_subscription_budgets[each.key]
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  dynamic "notification" {
    for_each = local.actual_thresholds
    content {
      enabled        = true
      threshold      = notification.value
      threshold_type = "Actual"
      operator       = "GreaterThanOrEqualTo"
      contact_emails = var.alert_emails
      contact_roles  = ["Owner"]
    }
  }

  notification {
    enabled        = true
    threshold      = 100
    threshold_type = "Forecasted"
    operator       = "GreaterThanOrEqualTo"
    contact_emails = var.alert_emails
    contact_roles  = ["Owner"]
  }

  lifecycle {
    # Azure rejects a start_date in a past month, so changing the default later
    # would only ever cause churn. The start date is set once at creation.
    ignore_changes = [time_period]
  }
}

# Cost anomaly alerts use Cost Management's ML model on daily spend. They catch
# what a monthly budget misses: a $3/day jump in a $10/month budget (like
# Defender CSPM quietly switching on) fires here within ~1 day.
resource "azurerm_cost_anomaly_alert" "lab" {
  for_each = local.lab_subscriptions

  name            = "anomaly-${local.lab_subscription_labels[each.key]}"
  display_name    = "Cost anomaly - ${local.lab_subscription_labels[each.key]}"
  subscription_id = each.value
  email_subject   = "Azure lab cost anomaly: ${local.lab_subscription_labels[each.key]}"
  email_addresses = var.alert_emails
  # Azure caps this at 100 characters (InvalidScheduledActionEmailMessage);
  # the provider schema doesn't enforce it, so `validate` can't catch it.
  message = "Unusual daily spend. Check Cost analysis by service, Defender plans and on-demand labs."
}
