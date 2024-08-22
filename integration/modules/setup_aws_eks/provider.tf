# https://www.terraform.io/language/expressions/version-constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.4"
    }
  }
  backend "s3" {
    bucket = "helm-charts-agent-terraform-state"
    key    = "modules/setup_aws_eks/.tfstate"
    region = "us-west-1"
    assume_role = {
      role_arn = "arn:aws:iam::767397788203:role/OrganizationAccountAccessRole"
    }
  }
  required_version = ">= 1.3"
}

provider "aws" {
  region = var.region # Specify the AWS region
  profile = "blunderdome"
  assume_role {
    role_arn = "arn:aws:iam::767397788203:role/OrganizationAccountAccessRole"   
  }
}


