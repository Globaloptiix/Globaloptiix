terraform {
    backend "s3" {
      bucket = "tf-state-eks-f79ff897b8"
      key            = "eks/terraform.tfstate"
      region = "us-east-1"
    }
}

### Stores AWS credentials
### Stores terraform state files
### Setup Versioning
