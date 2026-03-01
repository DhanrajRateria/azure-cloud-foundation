variable "name" {
  type        = string
  description = "Name of the budget"
}

variable "scope" {
  type        = string
  description = "Scope for the budget — subscription ID or resource group ID"
}

variable "amount" {
  type        = number
  description = "Monthly budget amount in USD"
}

variable "alert_email" {
  type        = string
  description = "Email address to send budget alert notifications to"
}

variable "time_grain" {
  type        = string
  default     = "Monthly"
  description = "Budget reset period. Monthly resets on the 1st of each month."
}

variable "start_date" {
  type        = string
  description = "Budget start date in YYYY-MM-DD format. Must be first of a month."
}

variable "thresholds" {
  type        = list(number)
  default     = [50, 75, 90, 100]
  description = "List of actual-spend percentage thresholds that trigger email alerts"
}

variable "forecasted_thresholds" {
  type        = list(number)
  default     = [100]
  description = "List of forecasted-spend percentage thresholds that trigger email alerts. Total notification blocks (thresholds + forecasted_thresholds) must not exceed 5."
}
