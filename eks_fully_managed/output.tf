
output "ekscluster_name" {
  value = module.precta.ekscluster_name
}

output "cluster_endpoint" {
  value = module.precta.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.precta.cluster_certificate_authority_data
}

# output "demand_instance_nodegroup" {
#   value = module.precta.aws_iam_openid_connect_provider
# }

# output "aws_iam_openid_connect_provider" {
#   value = module.precta.aws_iam_openid_connect_provider
# }
output "region" {
  value = module.vpc.region
}
output "private_subnet_az1" {
  value = module.vpc.private_subnet_az1
}
output "private_subnet_az2" {
  value = module.vpc.private_subnet_az2
}
output "public_subnet_az1" {
  value = module.vpc.public_subnet_az1
}
output "public_subnet_az2" {
  value = module.vpc.public_subnet_az2
}

output "internet_gateway" {
  value = module.vpc.internet_gateway
}
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "sg_group_id" {
  value = module.vpc.security_group_id
}

output "lb_sg_group_id" {
  value = module.vpc.lb_security_group_id
}