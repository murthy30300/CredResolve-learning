terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Credentials via environment variables (recommended):
  # export AWS_ACCESS_KEY_ID=your_key
  # export AWS_SECRET_ACCESS_KEY=your_secret
  # OR use: aws configure
}
