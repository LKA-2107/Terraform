provider "aws" {
  region = "us-east-1"
}

module "vpc-create" {
  source = "../modules/vpc"

  environment  = "dev"
  project_name = "migration"
  vpc_cidr     = "10.0.0.0/16"

  public_subnets = {
    us-east-1a = "10.0.1.0/24"
    us-east-1b = "10.0.2.0/24"
  }
}

module "eks-cluster" {
  source = "../modules/eks-cluster-module"

  environment               = "dev"
  name_prefix               = "migration"
  aws_region_for_kubeconfig = "us-east-1"
  kubernetes_version        = var.eks_kubernetes_version
  subnet_ids                = module.vpc-create.public_subnet_ids
  endpoint_private_access   = true
  endpoint_public_access    = true
  public_access_cidrs       = var.eks_public_access_cidrs

}

module "eks-node-cluster" {
  source             = "../modules/eks-node-group-module"
  environment        = "dev"
  name_prefix        = "migration"
  cluster_name       = module.eks-cluster.cluster_name
  kubernetes_version = var.eks_kubernetes_version
  subnet_ids         = module.vpc-create.public_subnet_ids
  instance_types     = ["t3.small"]
  capacity_type      = "ON_DEMAND"
  ami_type           = "AL2023_x86_64_STANDARD"
  disk_size_gib      = 30
  min_size           = 1
  desired_size       = 2
  max_size           = 3
  labels = {
    workload = "general"
  }
  attach_vpc_cni_policy = true

  tags = {
    Project = "migration"
  }

  depends_on = [module.eks-cluster]

}
module "ecr" {
  source = "../modules/ecr"

  project_name = "migration"
  environment  = "dev"

  repository_names = [
    "frontend",
    "orders-api",
    "order-worker"
  ]

  images_to_keep = 10

  tags = {
    Project = "migration"
  }
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}



terraform {
  backend "s3" {
    bucket         = "aws-terraform-statefiles-417731044254-us-east-1-an"
    key            = "dev/terraform.tfstate" # The path inside the bucket
    region         = "us-east-1"
    dynamodb_table = "tf-statelock" # For state locking
    encrypt        = true
  }
}

