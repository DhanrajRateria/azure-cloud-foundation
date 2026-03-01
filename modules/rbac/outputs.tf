output "assignment_ids" {
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
  description = "Map of assignment name to role assignment resource ID"
}
