# FastAPI EKS microservices lab

This project initially deploys two container images:

- `frontend`: unprivileged Nginx UI and reverse proxy
- `orders-api`: FastAPI service with temporary in-memory order storage

The `order-worker` source remains as a later exercise but is not deployed now.

## 1. Create ECR repositories

Copy `terraform/modules/ecr` to your repository's `modules/ecr` directory and
add this to the root module:

```hcl
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
```

Run:

```bash
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## 2. Build and push images

Run from this project's root directory:

```bash
chmod +x scripts/build-and-push.sh
AWS_REGION=us-east-1 PROJECT_NAME=migration IMAGE_TAG=v1 \
  ./scripts/build-and-push.sh
```

The tag is immutable. For a new build, use `v2`, a Git commit SHA, or another
new tag instead of overwriting `v1`.

Verify:

```bash
aws ecr describe-repositories \
  --region us-east-1 \
  --query "repositories[?starts_with(repositoryName, 'migration/')].repositoryUri"

aws ecr list-images \
  --region us-east-1 \
  --repository-name migration/orders-api
```

## 3. Build the SQS-free API image

The existing `v1` API expects SQS. Build the in-memory version as `v2`:

```bash
aws_account_id="$(aws sts get-caller-identity --query Account --output text)"
registry="${aws_account_id}.dkr.ecr.us-east-1.amazonaws.com"
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin "${registry}"
docker build --tag "${registry}/migration/orders-api:v2" applications/orders-api
docker push "${registry}/migration/orders-api:v2"
```

## 4. Deploy to EKS

```bash
aws_account_id="$(aws sts get-caller-identity --query Account --output text)"
kubectl apply -f deploy/kubernetes/namespace.yaml
sed "s/ACCOUNT_ID/${aws_account_id}/g" deploy/kubernetes/orders-api.yaml | kubectl apply -f -
sed "s/ACCOUNT_ID/${aws_account_id}/g" deploy/kubernetes/frontend.yaml | kubectl apply -f -
kubectl rollout status deployment/orders-api -n orders
kubectl rollout status deployment/frontend -n orders
kubectl get pods,services -n orders -o wide
```

Access it locally:

```bash
kubectl port-forward -n orders service/frontend 8080:8080
```

Open `http://localhost:8080`, submit an order, then inspect logs:

```bash
kubectl logs -n orders deployment/orders-api
```

## Important limitation

Orders exist only in one pod's memory. A restart deletes them, and replicas do
not share data. This is intentional for the first deployment.

## Next stage

After verifying the internal deployment, install the AWS Load Balancer
Controller and expose the frontend through an ALB Ingress.
