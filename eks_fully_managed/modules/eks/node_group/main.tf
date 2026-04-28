locals {
  project_name = var.project_name
  module_name  = var.module_name
}

resource "aws_eks_node_group" "demand_instance_nodegroup" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}_demand_node_group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.instance_type
  disk_size       = 150
  # 150 GB of EBS storage attached to EACH worker node (EC2 instance)
  
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }
  capacity_type = "ON_DEMAND"
  update_config {
    max_unavailable = 1
  }
  labels = {
    Name  = "${var.project_name}_demand_node"
    role  = "${var.project_name}_general_node"
    usage = "${var.usage_label}_general_node"
  }
   
}
