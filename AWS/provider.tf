terraform {
    backend "s3" {
      bucket = "tf-state-eks-123c9329cf"
      key            = "eks/terraform.tfstate"
      region = "us-east-1"
    }
}

### Stores AWS credentials
### Stores terraform state files
### Setup Versioning
