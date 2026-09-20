variable "environment" {
  type        = string
  description = "The target deployment environment (dev, staging, prod)."
}

variable "project_name" {
  type        = string
  description = "The name of the project or application."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The primary IPv4 CIDR block for the VPC."

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The vpc_cidr must be a valid IPv4 CIDR block notation (e.g., 10.0.0.0/16)."
  }
}

variable "public_subnets" {
  description = "Map of Availability Zones to public subnet CIDRs."
  type        = map(string)

  validation {
    condition     = length(var.public_subnets) >= 2
    error_message = "At least two subnets in different Availability Zones are required."
  }
}

variable "custom_tags" {
  type        = map(string)
  default     = {}
  description = "Optional extra tags to apply to all resources."
}
