variable "name_prefix" {
  description = "Short project or platform name used in resource names."
  type        = string
}

variable "environment" {
  description = "Environment name, for example dev, staging, or prod."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster that will own this node group."
  type        = string
}

variable "node_group_name" {
  description = "Logical name appended to the project and environment."
  type        = string
  default     = "general"
}

variable "subnet_ids" {
  description = "Subnets in which EKS creates worker nodes."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "Provide at least one worker-node subnet ID."
  }
}

variable "kubernetes_version" {
  description = "Optional Kubernetes version for the node group. Null uses the cluster-compatible default."
  type        = string
  default     = null
}

variable "ami_type" {
  description = "EKS optimized AMI type."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "capacity_type" {
  description = "ON_DEMAND or SPOT capacity."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "instance_types" {
  description = "EC2 instance types available to the managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "disk_size_gib" {
  description = "Root EBS volume size for each node."
  type        = number
  default     = 30
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "desired_size" {
  description = "Initial desired number of worker nodes."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "max_unavailable" {
  description = "Maximum unavailable nodes during a managed update."
  type        = number
  default     = 1
}

variable "attach_vpc_cni_policy" {
  description = "Attach AmazonEKS_CNI_Policy to the node role. Keep true initially; set false after assigning the CNI its own IAM role."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Additional Kubernetes labels applied to nodes."
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Optional Kubernetes taints applied to nodes."
  type = map(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for taint in values(var.taints) : contains(
        ["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], taint.effect
      )
    ])
    error_message = "Taint effect must be NO_SCHEDULE, NO_EXECUTE, or PREFER_NO_SCHEDULE."
  }
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}

