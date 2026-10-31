terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }

  backend "s3" {
    bucket       = "togglemaster-tfstate-980228515477"
    key          = "togglemaster/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
