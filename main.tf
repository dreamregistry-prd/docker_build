terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {}
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

module "docker_build" {
  source    = "github.com/hereya/terraform-modules//docker-build/module?ref=v0.13.0"
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
  source_dir              = var.dream_project_dir
  is_public_image         = var.is_public_image
  image_tags              = var.image_tags
  image_name              = var.image_name
  builder                 = var.builder
  force_delete_repository = var.force_delete_repository
  codecommit_password_key = var.codecommit_password_key
  codecommit_username     = var.codecommit_username
}

output "DOCKER_IMAGES" {
  value = module.docker_build.images
}
