variable "project_name" {
  type = string
}

variable "cluster_name" {
  type = string
}
variable "desired_size" {
  type = number
}

variable "min_size" {
  type = number

}
variable "public_subnet_az2_cidr" {}


variable "max_size" {
  type = number
}

# -----
variable "region" {}


variable "vpc_cidr" {}

variable "public_subnet_az1_cidr" {}

variable "private_subnet_az1_cidr" {
  type = string
}

variable "private_subnet_az2_cidr" {
  type = string
}



variable "enable_nat_gateway" {
  type    = bool
  default = true
}

# variable "vpc_id" {
#   type = string
# }
// variable "aws_access_key" {
//   type = string
// }
// variable "aws_secret_key" {
//   type = string
// }

# variable "disk_size" {
#   type = number
# }

# variable "node_role_arn" {}



# variable "karpenter_node_sg_id" {
#   description = "Security group ID for Karpenter nodes"
#   type        = string
# }