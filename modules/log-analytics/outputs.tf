output "workspace_id" {
  value       = azurerm_log_analytics_workspace.this.id
  description = "Resource ID of the Log Analytics Workspace — passed to diagnostic settings"
}

output "workspace_name" {
  value       = azurerm_log_analytics_workspace.this.name
  description = "Name of the workspace"
}

output "primary_shared_key" {
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  description = "Primary shared key — used by agents to authenticate to the workspace"
  sensitive   = true
}

output "customer_id" {
  value       = azurerm_log_analytics_workspace.this.workspace_id
  description = "Workspace GUID — used in KQL queries and agent configuration"
}
