output "budget_id" {
  value       = azurerm_consumption_budget_resource_group.this.id
  description = "Resource ID of the budget"
}

output "budget_name" {
  value       = azurerm_consumption_budget_resource_group.this.name
  description = "Name of the budget"
}

output "budget_amount" {
  value       = azurerm_consumption_budget_resource_group.this.amount
  description = "Monthly budget amount in USD"
}
