## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Optional extra tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The target deployment environment (dev, staging, prod). | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The name of the project or application. | `string` | n/a | yes |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | The IPv4 CIDR block for the public subnet. | `string` | `"10.0.1.0/24"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The primary IPv4 CIDR block for the VPC. | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The unique ID of the security group. |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | This is the subnet id created |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | This is the VPC id created |
