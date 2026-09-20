data "aws_partition" "current" {}

locals {
  name = "${var.name_prefix}-${var.environment}"
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "eks-cluster"
  }, var.tags)
  kms_key_arn = var.create_kms_key ? aws_kms_key.eks[0].arn : var.kms_key_arn
}

resource "aws_iam_role" "cluster" {
  name = "${local.name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.name}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.cloudwatch_log_kms_key_arn
  tags              = local.common_tags
}

resource "aws_kms_key" "eks" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "Envelope encryption for Kubernetes secrets in ${local.name}"
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true
  tags                    = merge(local.common_tags, { Name = "${local.name}-secrets" })
}

resource "aws_kms_alias" "eks" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${local.name}-eks-secrets"
  target_key_id = aws_kms_key.eks[0].key_id
}

resource "aws_eks_cluster" "this" {
  name     = local.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = var.enabled_cluster_log_types

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.additional_security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  dynamic "encryption_config" {
    for_each = local.kms_key_arn == null ? [] : [local.kms_key_arn]
    content {
      provider {
        key_arn = encryption_config.value
      }
      resources = ["secrets"]
    }
  }

  upgrade_policy {
    support_type = var.upgrade_support_type
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.cluster
  ]

  lifecycle {
    precondition {
      condition     = var.endpoint_private_access || var.endpoint_public_access
      error_message = "At least one Kubernetes API endpoint (private or public) must be enabled."
    }

    precondition {
      condition     = !var.endpoint_public_access || length(var.public_access_cidrs) > 0
      error_message = "public_access_cidrs must contain at least one restricted CIDR when the public endpoint is enabled."
    }

    precondition {
      condition     = var.bootstrap_cluster_creator_admin_permissions || length(var.access_entries) > 0
      error_message = "At least one access entry is required when cluster-creator admin permissions are disabled."
    }
  }

  tags = merge(local.common_tags, { Name = local.name })
}

resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value.principal_arn
  type              = each.value.type
  user_name         = each.value.user_name
  kubernetes_groups = each.value.kubernetes_groups
  tags              = local.common_tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each = {
    for association in flatten([
      for entry_key, entry in var.access_entries : [
        for policy_key, policy in entry.policy_associations : {
          key           = "${entry_key}-${policy_key}"
          principal_arn = entry.principal_arn
          policy_arn    = policy.policy_arn
          access_scope  = policy.access_scope
        }
      ]
    ]) : association.key => association
  }

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope.type
    namespaces = each.value.access_scope.namespaces
  }

  depends_on = [aws_eks_access_entry.this]
}
