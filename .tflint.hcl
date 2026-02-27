config {
  # Check all modules recursively
  call_module_type = "local"
}

plugin "azurerm" {
  enabled = true
  version = "0.26.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Enforce variable descriptions — good documentation practice
rule "terraform_documented_variables" {
  enabled = true
}

# Enforce output descriptions
rule "terraform_documented_outputs" {
  enabled = true
}

# Warn on deprecated interpolation syntax
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Enforce naming conventions
rule "terraform_naming_convention" {
  enabled = true
}
