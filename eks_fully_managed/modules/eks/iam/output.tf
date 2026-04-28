output "eks_cluster_role" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "node_role" {
  value = aws_iam_role.node_role.arn
}

output "karpenter_policy_arn" {
  value = aws_iam_policy.karpenter_controller.arn
}

output "karpenter_node_role_arn" {
  value = aws_iam_role.karpenter_node.arn
}