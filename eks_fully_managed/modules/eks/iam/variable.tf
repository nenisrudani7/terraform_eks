variable "project_name" {
  type = string
}

variable "module_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

# These are kept for backwards compatibility but not used for Karpenter role
# Karpenter role is now created in the parent EKS module with proper OIDC dependency
variable "oidc_arn" {
  type    = string
  default = ""
}

variable "oidc_url" {
  type    = string
  default = ""
}
