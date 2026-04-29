🚀 EKS + Karpenter Setup (Terraform)

This project creates an EKS cluster with Karpenter using Terraform.

⚙️ Prerequisites
Terraform
AWS CLI
AWS Account
🔐 AWS Setup

Go to:

~/.aws/

Add credentials:

[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
🪣 S3 Backend (Important)
Create an S3 bucket manually
Add bucket name in provider.tf:
backend "s3" {
  bucket = "your-bucket-name"
  key    = "eks/terraform.tfstate"
  region = "ap-south-1"
}
🚀 Run Terraform
terraform init
terraform fmt
terraform validate
terraform plan -out=plan.txt
terraform apply plan.txt
🌐 Connect to Cluster
aws eks --region ap-south-1 update-kubeconfig --name <cluster-name>
🤖 Karpenter Setup

Follow this blog:
👉 (Add your Medium link here)