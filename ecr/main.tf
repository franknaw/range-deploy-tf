
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.54"
    }
  }
}

provider "aws" {
  region  = module.global_vars.region[var.region]
  profile = "infra"
}

variable "env" {
  type    = string
  default = ""
}

output "env" {
  value = var.env
}

variable "region" {
  type    = string
  default = "east"
}

output "region" {
  value = module.global_vars.region[var.region]
}

variable "cvle_version" {
  type    = string
  default = "0.0.0"
}

output "cvle_version" {
  value = var.cvle_version
}

/*
  Global Variables
*/
module "global_vars" {
  source = "../../infra-aws-module-tf/global_vars"
}

/*
    Data Sources
*/
module "data" {
  source = "../../infra-aws-module-tf/data"
}

/*
    Setup ECR
*/

resource "aws_ecr_repository" "repository" {
  for_each = module.global_vars.cvle_version[var.cvle_version]

  name                 = each.value.api
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name        = "${each.value.api}_${each.value.version}",
    Environment = module.global_vars.environment[var.env]
  }
}

resource "aws_ecr_repository_policy" "repository-policy" {
  for_each   = module.global_vars.cvle_version[var.cvle_version]
  repository = aws_ecr_repository.repository[each.value.api].name
  policy     = module.global_vars.ecr_policy
}
