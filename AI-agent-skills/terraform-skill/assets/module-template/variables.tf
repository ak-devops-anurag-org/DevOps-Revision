# variables.tf
#
# Every variable needs a description and a type. Add a validation block
# for anything with meaningful constraints (allowed values, format, etc).

variable "project" {
  description = "Project/system name, used as a naming prefix."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Common tags/labels to apply to all resources in this module."
  type        = map(string)
  default     = {}
}

# Add module-specific variables below.