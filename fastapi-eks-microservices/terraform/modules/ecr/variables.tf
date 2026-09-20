variable "project_name" {
  description = "Prefix used for ECR repository names."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "repository_names" {
  description = "Application image repository names."
  type        = list(string)
  default     = ["frontend", "orders-api", "order-worker"]
}

variable "images_to_keep" {
  description = "Maximum recent images retained per repository."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}

