# AWS Infrastructure Automation with Terraform

This project demonstrates the use of **Terraform** to provision and manage AWS infrastructure using Infrastructure as Code (IaC) principles.

The infrastructure is defined in reusable and version-controlled Terraform configuration files, allowing environments to be deployed consistently and repeatedly without manual configuration through the AWS Console.

## Overview

The project focuses on automating AWS infrastructure provisioning while following common Terraform and DevOps practices.

Key areas covered include:

* Infrastructure as Code using Terraform
* AWS networking and compute resources
* Reusable Terraform configuration
* Variables and outputs
* Resource dependency management
* Remote Terraform state
* Infrastructure version control with Git
* Repeatable infrastructure deployment and destruction

## Technologies Used

* Terraform
* Amazon Web Services (AWS)
* AWS VPC
* EC2
* IAM
* Security Groups
* Subnets
* Route Tables
* Internet Gateway
* S3
* DynamoDB
* Git
* GitHub

## Architecture

The Terraform configuration provisions AWS infrastructure such as:

* Virtual Private Cloud (VPC)
* Public and/or private subnets
* Internet Gateway
* Route tables and route table associations
* Security groups
* EC2 instances
* IAM roles and policies
* Supporting AWS resources

Where configured, Terraform state can be stored remotely using:

* Amazon S3 for Terraform state storage
* DynamoDB for state locking

## Project Structure

```text
terraform-aws-project/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── versions.tf
├── terraform.tfvars
├── backend.tf
├── modules/
│   ├── network/
│   ├── compute/
│   └── security/
│
├── .gitignore
└── README.md
```

The exact structure may vary depending on the implementation.

### File Description

`main.tf`

Contains the primary AWS resources and module definitions.

`variables.tf`

Defines input variables used throughout the Terraform configuration.

`outputs.tf`

Defines important information that Terraform displays after infrastructure deployment, such as instance IDs, IP addresses, or VPC IDs.

`providers.tf`

Configures the AWS provider and associated provider settings.

`versions.tf`

Defines Terraform and provider version requirements.

`terraform.tfvars`

Stores values assigned to Terraform variables.

Sensitive values should not be committed to source control.

`backend.tf`

Configures remote Terraform state storage when an S3 backend is used.

## Prerequisites

Before running this project, ensure the following tools are installed and configured:

* Terraform
* AWS CLI
* Git

An AWS account with appropriate IAM permissions is also required.

Verify Terraform installation:

```bash
terraform --version
```

Verify AWS CLI installation:

```bash
aws --version
```

Configure AWS credentials:

```bash
aws configure
```

You will be prompted to provide:

```text
AWS Access Key ID
AWS Secret Access Key
Default region
Default output format
```

For production environments, IAM roles or other secure credential mechanisms should be preferred over long-lived access keys.

## Getting Started

Clone the repository:

```bash
git clone https://github.com/LKA-2107/<repository-name>.git
```

Move into the project directory:

```bash
cd <repository-name>
```

## Terraform Initialization

Initialize the Terraform working directory:

```bash
terraform init
```

This downloads the required Terraform providers and initializes the configured backend.

## Format Terraform Files

Format the Terraform configuration:

```bash
terraform fmt -recursive
```

## Validate Configuration

Validate the Terraform files:

```bash
terraform validate
```

A successful validation should return:

```text
Success! The configuration is valid.
```

## Review Infrastructure Changes

Generate a Terraform execution plan:

```bash
terraform plan
```

Alternatively:

```bash
terraform plan -out=tfplan
```

This allows the proposed infrastructure changes to be reviewed before deployment.

## Deploy Infrastructure

Apply the Terraform configuration:

```bash
terraform apply
```

If a saved plan was created:

```bash
terraform apply tfplan
```

Terraform will provision the infrastructure defined in the configuration.

## View Terraform Outputs

After deployment, Terraform outputs can be displayed with:

```bash
terraform output
```

To retrieve an individual output:

```bash
terraform output <output-name>
```

## View Terraform State

Terraform tracks deployed infrastructure using its state file.

To view resources managed by Terraform:

```bash
terraform state list
```

To inspect a specific resource:

```bash
terraform state show <resource-address>
```

## Destroy Infrastructure

To remove all infrastructure created by the project:

```bash
terraform destroy
```

Review the resources Terraform plans to delete before confirming the operation.

## Remote State

For collaborative or production Terraform environments, remote state can be configured using an Amazon S3 bucket.

Example:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Remote state provides a central location for Terraform state and supports collaboration between engineers.

State locking can be used to prevent multiple Terraform operations from modifying the infrastructure simultaneously.

## Variables

Variables allow the infrastructure configuration to be reused across multiple environments.

Example:

```hcl
variable "aws_region" {
  description = "AWS region used to deploy infrastructure"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

Example `terraform.tfvars`:

```hcl
aws_region    = "eu-west-1"
environment   = "dev"
instance_type = "t3.micro"
```

## Outputs

Outputs provide useful information after infrastructure deployment.

Example:

```hcl
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}
```

## Terraform Modules

Terraform modules can be used to organize infrastructure into reusable components.

Example project structure:

```text
modules/
├── network/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
└── security/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

This structure improves maintainability and makes infrastructure components easier to reuse across environments.

## Security Considerations

The project follows several infrastructure security practices:

* Avoid storing AWS credentials in Terraform files.
* Do not commit `.tfstate` files to public repositories.
* Do not commit sensitive `.tfvars` files.
* Use IAM roles and least-privilege permissions.
* Restrict security group rules to required ports and trusted networks.
* Enable encryption for remote Terraform state.
* Store secrets using services such as AWS Secrets Manager or AWS Systems Manager Parameter Store.

Recommended `.gitignore` entries:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
terraform.tfvars
*.auto.tfvars
.terraform.lock.hcl
crash.log
```

Depending on the project, `.terraform.lock.hcl` may instead be committed to ensure consistent provider versions.

## Terraform Workflow

The typical workflow used by this project is:

```text
Write Infrastructure Code
        |
        v
terraform fmt
        |
        v
terraform validate
        |
        v
terraform plan
        |
        v
Review Changes
        |
        v
terraform apply
        |
        v
AWS Infrastructure
```

Infrastructure changes can then follow the same workflow through subsequent Terraform plans and deployments.

## DevOps and Infrastructure as Code Benefits

Using Terraform provides several operational benefits:

* Repeatable infrastructure deployment
* Consistent environments
* Reduced manual configuration
* Infrastructure change tracking through Git
* Faster provisioning
* Easier disaster recovery
* Improved collaboration
* Reusable infrastructure components

## Future Improvements

Potential improvements to the project include:

* GitHub Actions-based Terraform CI/CD
* Automated `terraform fmt` and `terraform validate`
* Terraform security scanning
* Multiple environments such as dev, staging, and production
* Reusable Terraform modules
* Automated Terraform plan generation for pull requests
* Policy-as-Code implementation
* AWS monitoring with CloudWatch
* Infrastructure monitoring using Prometheus and Grafana
* Secrets management
* Cost estimation and optimization

## Author

**LKA-2107**

GitHub:
https://github.com/LKA-2107

## License

This project is intended for learning, demonstration, and portfolio purposes.
