variable "name_prefix" {
  description = "Short project or platform name used in resource names."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,35}$", var.name_prefix))
    error_message = "name_prefix must start with a letter and contain 2-36 letters, digits, or hyphens."
  }
}

variable "environment" {
  description = "Environment name, for example dev, staging, or prod."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{2,12}$", var.environment))
    error_message = "environment must contain 2-12 lowercase letters, digits, or hyphens."
  }
}

variable "aws_region_for_kubeconfig" {
  description = "AWS Region inserted into the convenience kubeconfig command output."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version, for example 1.34. Pin this in the environment configuration."
  type        = string
}

variable "subnet_ids" {
  description = "At least two subnet IDs in different Availability Zones. Private subnets are recommended."
  type        = list(string)
  validation {
    condition     = length(distinct(var.subnet_ids)) >= 2
    error_message = "Provide at least two distinct subnet IDs."
  }
}

variable "additional_security_group_ids" {
  description = "Additional security groups attached to EKS control-plane ENIs. EKS also creates a primary cluster security group."
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable the private Kubernetes API endpoint."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable the public Kubernetes API endpoint. When enabled, restrict public_access_cidrs."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint. Use your current public IP with /32 for a lab."
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for cidr in var.public_access_cidrs : can(cidrhost(cidr, 0)) && cidr != "0.0.0.0/0" && cidr != "::/0"
    ])
    error_message = "Every value must be a valid CIDR; unrestricted 0.0.0.0/0 and ::/0 are rejected."
  }
}

variable "enabled_cluster_log_types" {
  description = "EKS control-plane log types sent to CloudWatch."
  type        = set(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  validation {
    condition = alltrue([
      for value in var.enabled_cluster_log_types : contains(
        ["api", "audit", "authenticator", "controllerManager", "scheduler"], value
      )
    ])
    error_message = "Unsupported EKS control-plane log type."
  }
}

variable "log_retention_days" {
  description = "CloudWatch retention for EKS control-plane logs."
  type        = number
  default     = 30
}

variable "cloudwatch_log_kms_key_arn" {
  description = "Optional KMS key ARN for encrypting the CloudWatch log group."
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Create a KMS key for Kubernetes Secrets envelope encryption."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing KMS key ARN for Kubernetes Secrets. Used only when create_kms_key is false; null disables envelope encryption."
  type        = string
  default     = null
}

variable "kms_key_deletion_window_days" {
  description = "Waiting period before the module-created KMS key can be deleted."
  type        = number
  default     = 7
  validation {
    condition     = var.kms_key_deletion_window_days >= 7 && var.kms_key_deletion_window_days <= 30
    error_message = "kms_key_deletion_window_days must be between 7 and 30."
  }
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Give the Terraform caller cluster-admin access. Convenient for a lab; use explicit access_entries in shared environments."
  type        = bool
  default     = true
}

variable "upgrade_support_type" {
  description = "EKS version support policy. STANDARD avoids extended-support pricing."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.upgrade_support_type)
    error_message = "upgrade_support_type must be STANDARD or EXTENDED."
  }
}

variable "access_entries" {
  description = "IAM principals granted Kubernetes API access and their EKS access policies."
  type = map(object({
    principal_arn     = string
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    kubernetes_groups = optional(list(string))
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string))
      })
    })), {})
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}

