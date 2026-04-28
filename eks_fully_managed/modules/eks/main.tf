terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
}

# Base IAM roles for EKS cluster and nodes (no OIDC dependency)
module "eks_cluster_role" {
  source       = "./iam"
  project_name = var.project_name
  module_name  = "precta_role"
  cluster_name = var.cluster_name
  oidc_arn     = ""  # Will be empty initially, Karpenter role created separately below
  oidc_url     = ""
}


resource "aws_eks_cluster" "precta_dev" {
  name     = var.cluster_name
  role_arn = module.eks_cluster_role.eks_cluster_role
  version  = var.eks_version
  enabled_cluster_log_types = ["audit", "api", "authenticator", "scheduler", "controllerManager"]
  vpc_config {
    subnet_ids           = var.subnet_ids
    public_access_cidrs  = var.eks_public_access_cidrs
  }
  depends_on = [module.eks_cluster_role]

  tags = {
     mode = "precta"
  }
 
}

# OIDC Provider - created after EKS cluster
data "tls_certificate" "precta_dev" {
  url = aws_eks_cluster.precta_dev.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "prectaoidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.precta_dev.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.precta_dev.identity.0.oidc.0.issuer

  depends_on = [aws_eks_cluster.precta_dev]
}

# -----Karpenter Controller Role with proper OIDC trust policy-----
resource "aws_iam_role" "karpenter_controller" {
  name = "KarpenterControllerRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.prectaoidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.prectaoidc.url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
            "${replace(aws_iam_openid_connect_provider.prectaoidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  depends_on = [aws_iam_openid_connect_provider.prectaoidc]
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = module.eks_cluster_role.karpenter_policy_arn
}

module "demand_instance_nodegroup" {
  source        = "./node_group"
  project_name  = var.project_name
  module_name   = "dev_eks_node_role"
  cluster_name  = aws_eks_cluster.precta_dev.name
  node_role_arn = module.eks_cluster_role.node_role
  instance_type = var.instance_type
  desired_size  = var.desired_size
  min_size      = var.min_size
  max_size      = var.max_size
  subnet_ids    = var.nodegroup_subnet_ids
  usage_label   = var.usage_label
  depends_on = [aws_eks_cluster.precta_dev]
}

data "aws_iam_policy_document" "ebs_csi_irsa" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.prectaoidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.prectaoidc.url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:ebs-csi-controller-sa"
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "EBSIrsaDevCluster"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_irsa.json

  depends_on = [aws_iam_openid_connect_provider.prectaoidc]
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}



data "aws_iam_policy_document" "efs_csi_irsa" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.prectaoidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.prectaoidc.url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:efs-csi-controller-sa"
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "efs_csi" {
  name               = "EFSIrsaDevCluster"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_irsa.json

  depends_on = [aws_iam_openid_connect_provider.prectaoidc]
}

resource "aws_iam_role_policy_attachment" "AmazonEFSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi.name
}

resource "aws_eks_addon" "efs_csi" {
  cluster_name             = aws_eks_cluster.precta_dev.name
  addon_name               = "aws-efs-csi-driver"
  service_account_role_arn = aws_iam_role.efs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.precta_dev.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.precta_dev.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.precta_dev.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.precta_dev.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.precta_dev.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
}

# resource "aws_eks_addon" "metrics_server" {
#   cluster_name                = aws_eks_cluster.precta_dev.name
#   addon_name                  = "metrics-server"
#   resolve_conflicts_on_create = "OVERWRITE"
# }
