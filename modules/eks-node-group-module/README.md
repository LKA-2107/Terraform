# EKS managed node-group Terraform module

This module adds EC2 worker nodes to an existing EKS cluster. It creates the
node IAM role, attaches the minimum initial AWS-managed policies, and creates an
EKS managed node group.

## Root-module example

Place the module at `../modules/eks-node-group`, then add:

```hcl
module "eks-node-group" {
  source = "../modules/eks-node-group"

  name_prefix     = "migration"
  environment     = "dev"
  cluster_name    = module.eks-cluster.cluster_name
  subnet_ids      = module.vpc-create.public_subnet_ids
  node_group_name = "general"

  # Keep the version aligned with the control plane.
  kubernetes_version = var.eks_kubernetes_version

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2023_x86_64_STANDARD"
  disk_size_gib  = 30

  min_size     = 1
  desired_size = 2
  max_size     = 3

  labels = {
    workload = "general"
  }

  tags = {
    Project = "migration"
  }

  depends_on = [module.eks-cluster]
}
```

The explicit module-level `depends_on` is not strictly required because
`cluster_name` already establishes a dependency, but keeping it in a learning
project makes the intended creation order obvious.

## Public-subnet prerequisite

This project currently uses public subnets to avoid NAT Gateway cost. Each
worker subnet must have:

- `map_public_ip_on_launch = true`
- a route for `0.0.0.0/0` through an Internet Gateway
- network ACLs and security groups that allow the required traffic

For a production-style design, move worker nodes to private subnets and provide
NAT or the necessary VPC endpoints.

## Verify

```bash
terraform init
terraform validate
terraform plan
terraform apply

aws eks update-kubeconfig --region us-east-1 --name migration-dev
kubectl get nodes -o wide
kubectl get pods -A
```

Wait several minutes after apply for nodes to become `Ready`.

## CNI permissions

`attach_vpc_cni_policy` defaults to `true`, allowing the VPC CNI to obtain
permissions from the node role. This makes the initial cluster functional.
Later, assign the VPC CNI add-on its own Pod Identity or IRSA role and set this
input to `false` to reduce node-role permissions.

## Cost control

The default creates two on-demand `t3.small` nodes. For shorter experiments,
set `desired_size = 1`. Do not leave the cluster running when you are finished.
