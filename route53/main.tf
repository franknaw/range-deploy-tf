
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
    Setup Route53
*/

data "aws_route53_zone" "zone" {
  name         = module.global_vars.route_domain
  private_zone = true
}

output "zone_id" {
  value = data.aws_route53_zone.zone.zone_id
}

resource "aws_route53_record" "record" {
  for_each = module.global_vars.cvle_version[var.cvle_version]

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${each.value.api}.${module.global_vars.route_domain}"
  type    = "A"
  ttl     = "300"
  records = ["192.16.16.200"]
}
