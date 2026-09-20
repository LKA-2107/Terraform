data "aws_partition" "current" {}

locals {
  name = "${var.name_prefix}-${var.environment}-${var.node_group_name}"

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "eks-node-group"
  }, var.tags)
}

resource "aws_iam_role" "node" {
  name = "${local.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_pull" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  count = var.attach_vpc_cni_policy ? 1 : 0

  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = local.name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version

  ami_type       = var.ami_type
  capacity_type  = var.capacity_type
  disk_size      = var.disk_size_gib
  instance_types = var.instance_types

  scaling_config {
    min_size     = var.min_size
    desired_size = var.desired_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  labels = merge({
    environment  = var.environment
    "node-group" = var.node_group_name
  }, var.labels)

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node,
    aws_iam_role_policy_attachment.ecr_pull,
    aws_iam_role_policy_attachment.vpc_cni
  ]

  lifecycle {
    precondition {
      condition     = var.min_size <= var.desired_size && var.desired_size <= var.max_size
      error_message = "Scaling sizes must satisfy min_size <= desired_size <= max_size."
    }
  }

  tags = merge(local.common_tags, { Name = local.name })
}
