variable "region" {}

variable "project_name" {}

variable "cluster_name" {
  type = string
}
variable "vpc_cidr" {}

variable "public_subnet_az1_cidr" {}
variable "public_subnet_az2_cidr" {}

variable "private_subnet_az1_cidr" {}

variable "private_subnet_az2_cidr" {
  type = string
}


variable "enable_nat_gateway" {
  type    = bool
  default = true
}
  