output "ekscluster_name" {
  value = aws_eks_cluster.precta_dev.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.precta_dev.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.precta_dev.certificate_authority[0].data
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.prectaoidc.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.prectaoidc.url
}

output "node_role_arn" {
  value = module.eks_cluster_role.node_role
}

output "karpenter_node_role_arn" {
  value = module.eks_cluster_role.karpenter_node_role_arn
}

