variable "eks_kubernetes_version" {
  description = "Kubernetes version used by the EKS cluster."
  type        = string
  default     = "1.34"
}

variable "eks_public_access_cidrs" {
  description = "Public CIDRs allowed to connect to the EKS API endpoint."
  type        = list(string)
  default     = ["89.100.249.248/32"]

  validation {
    condition = (
      length(var.eks_public_access_cidrs) > 0 &&
      alltrue([
        for cidr in var.eks_public_access_cidrs :
        can(cidrhost(cidr, 0)) &&
        cidr != "0.0.0.0/0" &&
        cidr != "::/0"
      ])
    )

    error_message = "Provide at least one restricted CIDR. Unrestricted public access is not allowed."
  }
}