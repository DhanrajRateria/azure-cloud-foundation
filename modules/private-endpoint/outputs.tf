output "private_endpoint_id" {
  value       = azurerm_private_endpoint.this.id
  description = "Resource ID of the private endpoint"
}

output "private_ip_address" {
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
  description = "Private IP assigned to this endpoint — the IP your VNet resources connect to"
}
