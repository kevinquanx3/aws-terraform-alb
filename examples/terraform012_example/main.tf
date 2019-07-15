###############################################################################
# Providers
###############################################################################
provider "aws" {
  version             = "~> 2.8.0"
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}

provider "random" {
  version = "~> 2.0"
}

provider "template" {
  version = "~> 2.0"
}

###############################################################################
# Terraform main config - Remote State
# Values must be hardcoded
# Get S3 Bucket name from layer _main (terraform output)
# Key must be unique for each layer
###############################################################################
terraform {
  required_version = ">= 0.12"

  backend "s3" {
    key            = "100compute-dr/terraform.tfstate"
    bucket         = "rs-tfstate-123456789012-ap-southeast-1"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state"
    encrypt        = "true"
  }
}

