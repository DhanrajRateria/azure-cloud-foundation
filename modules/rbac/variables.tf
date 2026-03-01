variable "assignments" {
  type = map(object({
    scope                = string
    role_definition_name = string
    principal_id         = string
    description          = optional(string, "")
  }))
  description = <<-EOT
    Map of role assignments to create. Key is a unique assignment name.

    Example:
    {
      "devops-contributor" = {
        scope                = "/subscriptions/xxx"
        role_definition_name = "Contributor"
        principal_id         = "object-id-of-group-or-user"
      }
    }
  EOT
}
