variable "environment" {
  type        = string
  description = "The target deployment environment"

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment should contain dev, staging or prod"
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "subnet_id" {
  type = string
  description = "Subnet id in which ec2 instance to spin up"
}