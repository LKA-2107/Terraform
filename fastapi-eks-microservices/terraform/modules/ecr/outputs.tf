output "repository_urls" {
  description = "Map of logical repository names to ECR URLs."
  value = {
    for name, repository in aws_ecr_repository.this : name => repository.repository_url
  }
}

output "repository_arns" {
  description = "Map of logical repository names to ECR ARNs."
  value = {
    for name, repository in aws_ecr_repository.this : name => repository.arn
  }
}

