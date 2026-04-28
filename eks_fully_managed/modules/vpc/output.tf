output "region" {
  value = var.region
}

output "project_name" {
  value = var.project_name
}

output "vpc_id" {
  value = aws_vpc.precta.id
}

output "public_subnet_az1" {
  value = aws_subnet.public_subnet_az1.id
}

output "public_az1" {
  value = aws_subnet.public_subnet_az1.availability_zone
}

output "public_subnet_az2" {
  value = aws_subnet.public_subnet_az2.id
}

output "public_az2" {
  value = aws_subnet.public_subnet_az2.availability_zone
}

output "private_subnet_az1" {
  value = aws_subnet.private_subnet_az1.id
}

output "private_az1" {
  value = aws_subnet.private_subnet_az1.availability_zone
}

output "private_subnet_az2" {
  value = aws_subnet.private_subnet_az2.id
}

output "private_az2" {
  value = aws_subnet.private_subnet_az2.availability_zone
}

output "internet_gateway" {
  value = aws_internet_gateway.internet_gateway
}

output "security_group_id" {
  value = aws_security_group.karpenter_nodes.id
}

output "lb_security_group_id" {
  value = aws_security_group.load_balancer.id
}