# EKS cluster Terraform module

This module creates the EKS **control plane only**. A separate node-group module
should consume `cluster_name` and `cluster_security_group_id`.

## What it creates

- EKS cluster and IAM role
- API-based EKS access configuration
- CloudWatch control-plane log group
- Optional KMS key for Kubernetes Secrets envelope encryption
- Optional EKS access entries and policy associations

## Example

```hcl
provider "aws" {
  region = var.aws_region
}

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  name_prefix               = "orders-platform"
  environment               = "dev"
  aws_region_for_kubeconfig = var.aws_region
  kubernetes_version        = "REPLACE_WITH_SUPPORTED_EKS_VERSION"

  # Rename this output to match your VPC module.
  subnet_ids = module.vpc.private_subnet_ids

  # For a laptop-based lab, enable the public endpoint and restrict it to your
  # current public IP. Do not use 0.0.0.0/0.
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs      = ["203.0.113.10/32"]

  bootstrap_cluster_creator_admin_permissions = true

  tags = {
    Project    = "eks-learning"
    CostCenter = "personal-lab"
  }
}
```

Do not copy a Kubernetes version from an old tutorial. Select a version currently
under EKS standard support in your AWS Region and pin it explicitly.

## Shared-environment access example

```hcl
bootstrap_cluster_creator_admin_permissions = false

access_entries = {
  platform_admin = {
    principal_arn = "arn:aws:iam::123456789012:role/platform-admin"
    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = { type = "cluster" }
      }
    }
  }
}
```

## Apply and connect

```bash
terraform init
terraform validate
terraform plan
terraform apply

aws eks update-kubeconfig --region <region> --name <cluster-name>
kubectl get nodes
```

`kubectl get nodes` will be empty until the node-group module is applied.

If you keep the default private-only API endpoint, run these commands from a
host with network connectivity to the VPC (for example, a VPN-connected machine
or an administration instance). For a learning cluster accessed from your
laptop, use the restricted public-endpoint example above.

## Design notes

- Uses EKS access entries (`authentication_mode = "API"`) instead of managing
  the legacy `aws-auth` ConfigMap.
- The public API endpoint is disabled by default. When enabled, this module
  rejects unrestricted IPv4 and IPv6 CIDRs.
- All five EKS control-plane log types are enabled by default.
- `upgrade_support_type` defaults to `STANDARD` to avoid unintended EKS
  extended-support charges.
- Add-ons and worker nodes are outside this module so their lifecycles remain
  independent.
