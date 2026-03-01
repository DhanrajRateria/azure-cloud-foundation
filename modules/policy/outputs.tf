output "deny_public_ip_assignment_id" {
  value       = azurerm_resource_group_policy_assignment.deny_public_ip.id
  description = "Assignment ID for deny-public-ip policy"
}

output "deny_open_nsg_assignment_id" {
  value       = azurerm_resource_group_policy_assignment.deny_open_nsg.id
  description = "Assignment ID for deny-open-nsg policy"
}

output "require_tags_assignment_id" {
  value       = azurerm_resource_group_policy_assignment.require_tags.id
  description = "Assignment ID for require-tags policy"
}
