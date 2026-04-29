# Terraform EKS with Karpenter


## 1. AWS Credentials Setup

**Option A: AWS Profile**
```bash
cd ~/.aws
vim credentials
# Add:
[your-profile]
aws_access_key_id = YOUR_KEY
aws_secret_access_key = YOUR_SECRET

vim config 
# Add:
[profile your-profile]
region = us-east-1
```





## 2. Create S3 Bucket for State locking 

```bash
aws s3api create-bucket \
  --bucket your-unique-bucket-name \
  --region us-east-1 \
  --profile your-profile

```
and then add bucket name to provider.tf

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

That you will find here 

- [EKS Docs](https://docs.aws.amazon.com/eks/)

## Important

⚠️ S3 bucket names must be globally unique  
⚠️ Never commit AWS credentials  
⚠️ This incurs AWS charges  
⚠️ Keep terraform.tfstate secure
