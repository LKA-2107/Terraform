output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA data."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "EKS-managed primary cluster security group ID. Reference this from the node-group module."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role used by the EKS control plane."
  value       = aws_iam_role.cluster.arn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL. Useful if you later implement IRSA."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "kms_key_arn" {
  description = "KMS key used for Kubernetes Secrets, if configured."
  value       = local.kms_key_arn
}

output "kubectl_update_kubeconfig_command" {
  description = "Command that configures kubectl for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region_for_kubeconfig} --name ${aws_eks_cluster.this.name}"
}

