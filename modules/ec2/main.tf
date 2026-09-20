resource "aws_instance" "webserver" {
  ami           = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = var.instance_type
  subnet_id = var.subnet_id

  tags = {
    Name = var.environment
  }
    lifecycle {
    ignore_changes = [ami]
  }
}
