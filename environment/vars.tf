variable "environment" {
  type = map(string)
  default = {
    "dev" : "dev"
  }
  description = "Set the environment for provisioning"
}

variable "role_part_id" {
  type = map(string)
  default = {
    "dev" : "dev"
  }
  description = "Set the environment role partition Id"
}

variable "role_part" {
  default     = "aws"
  description = "Set the environment role partition"
}

variable "region" {
  type = map(string)
  default = {
    "com-east" = "us-east-1"
  }
  description = "Region to be used"
}


