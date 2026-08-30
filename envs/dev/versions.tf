terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Uncomment after running bootstrap-state:
  #
  # backend "s3" {
  #   bucket         = "REPLACE_WITH_STATE_BUCKET"
  #   key            = "ecommerce/dev/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "ecommerce-terraform-locks"
  #   encrypt        = true
  # }
}
