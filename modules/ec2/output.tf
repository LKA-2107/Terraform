
output "instance_id" {
  value       = aws_instance.webserver.id
  description = "The ID of the EC2 instance."
}

output "instance_arn" {
  value       = aws_instance.webserver.arn
  description = "The ARN of the EC2 instance."
}
