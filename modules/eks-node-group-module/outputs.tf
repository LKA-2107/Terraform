output "node_group_name" {
  description = "Managed node-group name."
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  description = "Managed node-group ARN."
  value       = aws_eks_node_group.this.arn
}

output "node_group_status" {
  description = "Managed node-group status."
  value       = aws_eks_node_group.this.status
}

output "node_role_arn" {
  description = "IAM role assumed by EC2 worker nodes."
  value       = aws_iam_role.node.arn
}

output "autoscaling_group_names" {
  description = "Auto Scaling groups created and managed by EKS."
  value       = aws_eks_node_group.this.resources[0].autoscaling_groups[*].name
}

