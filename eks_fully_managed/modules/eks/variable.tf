variable "project_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "module_name" {
  type = string
}

variable "subnet_ids" {}

variable "instance_type" {
  type = list(string) 
}


variable "desired_size" {
  type    = number
 
}

variable "min_size" {
  type    = number
 
}

variable "max_size" {
  type    = number
}

variable "usage_label" {
  type = string
}

variable "eks_version" {

}

variable "nodegroup_subnet_ids" {
  type = list(string)
}
variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to access EKS public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "karpenter_node_sg_id" {
  description = "Security group ID for Karpenter nodes"
  type        = string
}