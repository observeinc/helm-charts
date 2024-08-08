# https://www.terraform.io/language/expressions/version-constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.11"
    }
  }
  backend "s3" {
    bucket = "helm-charts-agent-terraform-state"
    key    = "modules/setup_aws_eks/.tfstate"
    region = "us-west-1"
    assume_role = {
      #role_arn = "arn:aws:iam::767397788203:role/OrganizationAccountAccessRole"
      role_arn = "arn:aws:iam::767397788203:role/gh-helm-charts-repo"
    }
  }
  required_version = ">= 1.2"
}

provider "aws" {
  region  = "us-west-1" # Specify the AWS region
  profile = "blunderdome"
  assume_role {
    #role_arn = "arn:aws:iam::767397788203:role/OrganizationAccountAccessRole"
    role_arn = "arn:aws:iam::767397788203:role/gh-helm-charts-repo"
  }
}
