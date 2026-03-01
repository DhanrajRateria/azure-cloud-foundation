variable "environment" {
  type        = string
  description = "Environment name — controls policy effect levels"
}

variable "scope" {
  type        = string
  description = <<-EOT
    Scope at which to assign policies.
    In production this would be a Management Group or Subscription ID.
    For our setup, we use the resource group ID.
    Format: /subscriptions/{id}/resourceGroups/{name}
  EOT
}
