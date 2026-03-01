# =============================================================================
# Budget Module
#
# Creates a cost budget with email alerts at configurable thresholds.
#
# How it works:
# Azure Cost Management tracks actual and forecasted spend against the budget.
# When spend crosses a threshold (e.g. 75%), Azure sends an email immediately.
# You get one alert per threshold crossing per budget period (monthly).
#
# Two alert types:
# - Actual: triggered when real spend crosses the threshold
# - Forecasted: triggered when Azure predicts you WILL cross the threshold
#   even if you haven't yet. This gives you time to act before the bill lands.
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100"
    }
  }
}

resource "azurerm_consumption_budget_resource_group" "this" {
  name              = var.name
  resource_group_id = var.scope
  amount            = var.amount
  time_grain        = var.time_grain

  time_period {
    start_date = "${var.start_date}T00:00:00Z"
    # No end_date = budget runs indefinitely and resets each period
  }

  # Create one actual-spend notification per threshold
  dynamic "notification" {
    for_each = var.thresholds
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"

      contact_emails = [var.alert_email]
    }
  }

  # Forecasted notifications warn you before the bill actually lands.
  # Azure caps total notification blocks at 5 across both types combined.
  dynamic "notification" {
    for_each = var.forecasted_thresholds
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Forecasted"
      contact_emails = [var.alert_email]
    }
  }
}
