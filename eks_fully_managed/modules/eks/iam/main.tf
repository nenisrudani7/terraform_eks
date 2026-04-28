locals {
  project_name = var.project_name
  module_name  = var.module_name
}
# IAM role for eks

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}_eks_cluster_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = {
        mode = "precta"
        tag-key = "eks-cluster-demo"
    }
}


resource "aws_iam_role" "node_role" {
  name = "${var.project_name}_eks_nodegroup_role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = {
        mode = "precta"
    }
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
  
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "AWSCSIProvisionerRolePolicy_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AWSCSIProvisionerRolePolicy_node" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}



# --------------for karpenter------------------
resource "aws_iam_policy" "karpenter_controller" {
  name        = "KarpenterControllerPolicy-${var.cluster_name}"
  description = "Permissions for Karpenter controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
           "ec2:CreateLaunchTemplate",
           "ec2:CreateFleet",
           "ec2:RunInstances",
           "ec2:CreateTags",
           "ec2:DescribeInstances",
           "ec2:DescribeInstanceTypes",
           "ec2:DescribeInstanceTypeOfferings",
           "ec2:DescribeSubnets",
           "ec2:DescribeSecurityGroups",
           "ec2:DescribeImages",
           "ec2:DescribeAvailabilityZones",
           "ec2:DescribeLaunchTemplates",
           "ec2:DescribeSpotPriceHistory",
           "ec2:TerminateInstances",
           "iam:PassRole",
           "iam:GetInstanceProfile",
           "iam:CreateInstanceProfile",
           "iam:AddRoleToInstanceProfile",
           "iam:RemoveRoleFromInstanceProfile",
           "iam:DeleteInstanceProfile",
           "eks:DescribeCluster",
           "pricing:GetProducts"
        ]
        Resource = "*"
      }
    ]
  })
}

# Karpenter controller role is now created in the EKS module (modules/eks/main.tf)
# to avoid circular dependency with OIDC provider

# --------karpenter node iam role-----
# -------- Karpenter Node IAM Role --------
resource "aws_iam_role" "karpenter_node" {
  name = "KarpenterNodeRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        } 
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    mode = "precta"
  }
}

# Attach required policies for Karpenter nodes
resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile required for EC2 instances
resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node.name
}


# bare minimum requirement of eks
# # aws node group 
# resource "aws_eks_node_group" "private-nodes" {
#   cluster_name    = var.project_name
#   node_group_name = "private-nodes"
#   node_role_arn   = aws_iam_role.node_role.arn

#   subnet_ids = [
#     module.vpc.private-us-east-1a.id,
#     module.vpc.private-us-east-1b.id
#   ]

#   capacity_type  = "ON_DEMAND"
#   instance_types = ["t2.medium"]

#   scaling_config {
#     desired_size = 1
#     max_size     = 10
#     min_size     = 0
#   }

#   update_config {
#     max_unavailable = 1
#   }

#   labels = {
#     node = "kubenode02"
#   }

  # taint {
  #   key    = "team"
  #   value  = "devops"
  #   effect = "NO_SCHEDULE"
  # }

  # launch_template {
  #   name    = aws_launch_template.eks-with-disks.name
  #   version = aws_launch_template.eks-with-disks.latest_version
  # }

#   depends_on = [
#     aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
#   ]
# }

# launch template if required

# resource "aws_launch_template" "eks-with-disks" {
#   name = "eks-with-disks"

#   key_name = "local-provisioner"

#   block_device_mappings {
#     device_name = "/dev/xvdb"

#     ebs {
#       volume_size = 50
#       volume_type = "gp2"
#     }
#   }
# }
