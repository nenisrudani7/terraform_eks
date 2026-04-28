terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
  backend "s3" {
    bucket       = "state-locking-2123"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    profile      = "nr-root"
    use_lockfile = true
  }
}



# -------- AWS Provider (No hard-coded creds) --------
provider "aws" {
  region  = "us-east-1"
  profile = "nr-root"
}

locals {
  profile = "nr-root"
}

# -------- Helm Provider --------
# Note: These providers will only work AFTER the EKS cluster is created
# For initial deployment, you may need to use -target=module.vpc -target=module.precta first
provider "helm" {
  kubernetes {
    host                   = module.precta.cluster_endpoint
    cluster_ca_certificate = base64decode(module.precta.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", local.profile]
    }
  }
}

# -------- Kubernetes Provider --------
provider "kubernetes" {
  host                   = module.precta.cluster_endpoint
  cluster_ca_certificate = base64decode(module.precta.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", local.profile]
  }
}

# -------- Kubectl Provider --------
provider "kubectl" {
  host                   = module.precta.cluster_endpoint
  cluster_ca_certificate = base64decode(module.precta.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", local.profile]
  }
}

