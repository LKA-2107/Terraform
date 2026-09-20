output "vpc_id" {
  value       = aws_vpc.this
  description = "This is the VPC id created"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "The unique ID of the security group."
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, ordered by Availability Zone."
  value = [
    for availability_zone in sort(keys(aws_subnet.public)) :
    aws_subnet.public[availability_zone].id
  ]
}

output "public_subnets_by_az" {
  description = "Map of Availability Zones to public subnet IDs."
  value = {
    for availability_zone, subnet in aws_subnet.public :
    availability_zone => subnet.id
  }
}