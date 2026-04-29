# Terraform EKS with Karpenter

## Prerequisites
- Terraform >= 1.0
- AWS CLI
- kubectl
- Helm

## 1. AWS Credentials Setup

**Option A: AWS Profile**
```bash
cd ~/.aws
nano credentials
# Add:
[your-profile]
aws_access_key_id = YOUR_KEY
aws_secret_access_key = YOUR_SECRET

nano config
# Add:
[profile your-profile]
region = us-east-1
```

**Option B: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=us-east-1
```

## 2. Create S3 Bucket for State

```bash
aws s3api create-bucket \
  --bucket your-unique-bucket-name \
  --region us-east-1 \
  --profile your-profile

aws s3api put-bucket-versioning \
  --bucket your-unique-bucket-name \
  --versioning-configuration Status=Enabled \
  --profile your-profile
```

## 3. Configure Terraform

```bash
cp sample_provider.tf provider.tf
cp sample_terraform.tfvars terraform.tfvars
```

**Edit provider.tf:**
```hcl
backend "s3" {
  bucket  = "your-bucket-name"
  key     = "eks/terraform.tfstate"
  region  = "us-east-1"
  encrypt = true
  profile = "your-profile"
}
```

**Edit terraform.tfvars:**
```hcl
aws_region   = "us-east-1"
cluster_name = "my-eks-cluster"
```

## 4. Initialize & Validate

```bash
terraform init
terraform validate
terraform fmt -recursive
```

## 5. Plan & Apply

```bash
terraform plan -out=plan.txt
terraform apply plan.txt
```

## 6. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name your-cluster-name \
  --profile your-profile
```

## 7. Install Karpenter

```bash
cd karpenter-install
bash get_helm.sh
kubectl apply -f aws-auth.yaml
helm install karpenter ./karpenter -n karpenter --create-namespace
kubectl apply -f pool-system.yml
kubectl apply -f pool-1.yml
```

**Verify:**
```bash
kubectl get nodes
kubectl logs -n karpenter deployment/karpenter
```

## Common Commands

```bash
terraform show                          # View state
terraform output                        # Get outputs
terraform destroy                       # Destroy resources
kubectl get nodes                       # List nodes
kubectl get all -n karpenter            # Karpenter status
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| terraform init fails | Check AWS credentials and profile |
| Access Denied | Verify IAM permissions |
| S3 bucket exists | Use unique bucket name |
| kubectl connection fails | Run `aws eks update-kubeconfig` |

## Links

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Karpenter Docs](https://karpenter.sh/)
- [EKS Docs](https://docs.aws.amazon.com/eks/)

## Important

⚠️ S3 bucket names must be globally unique  
⚠️ Never commit AWS credentials  
⚠️ This incurs AWS charges  
⚠️ Keep terraform.tfstate secure