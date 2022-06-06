
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


#### Uncomment to enable RDS.


/*
    Setup RDS for RANGE
*/
//
//resource "aws_security_group" "range-rds-aurora-sg" {
//  vpc_id = module.data.vpc_range.id
//  name   = "RANGE-RDS-aurora-sg"
//
//  ingress {
//    from_port = 0
//    to_port   = 0
//    protocol  = "-1"
//    cidr_blocks = [
//    "0.0.0.0/0"]
//  }
//
//  egress {
//    from_port = 0
//    to_port   = 0
//    protocol  = "-1"
//    cidr_blocks = [
//    "0.0.0.0/0"]
//  }
//
//  tags = {
//    "Name"        = "RANGE-RDS-aurora-sg"
//    "Environment" = module.global_vars.environment[var.env]
//  }
//}
//
//# Create PGSQL Cluster
//resource "aws_rds_cluster" "range-rds-aurora-cluster" {
//  cluster_identifier = "range-rds-aurora-cluster"
//  engine             = "aurora-postgresql"
//  engine_version     = "11.9"
//  vpc_security_group_ids = [
//  aws_security_group.range-rds-aurora-sg.id]
//  database_name   = "range"
//  master_username = "rangeadmin"
//  master_password = "9uT6Are3mf7yp92"
//
//  backup_retention_period = 5
//  preferred_backup_window = "07:00-09:00"
//  deletion_protection     = false
//  # true
//
//  storage_encrypted   = true
//  kms_key_id          = aws_kms_key.range-rds-key.arn
//  skip_final_snapshot = true
//  #false
//  db_subnet_group_name = aws_db_subnet_group.range-aurora-sub-grp.name
//
//  //  enabled_cloudwatch_logs_exports = [
//  //    "postgresql"]
//
//  tags = {
//    "Name"        = "RANGE-RDS-aurora-cluster"
//    "Environment" = module.global_vars.environment[var.env]
//  }
//}
//
//# Create PGSQL Instance
//resource "aws_rds_cluster_instance" "range-rds-aurora-cluster_instances" {
//  identifier           = "range-rds-aurora-instance"
//  cluster_identifier   = aws_rds_cluster.range-rds-aurora-cluster.id
//  instance_class       = "db.r4.large"
//  engine               = aws_rds_cluster.range-rds-aurora-cluster.engine
//  engine_version       = aws_rds_cluster.range-rds-aurora-cluster.engine_version
//  db_subnet_group_name = aws_db_subnet_group.range-aurora-sub-grp.name
//
//  tags = {
//    "Name"        = "RANGE-RDS-aurora-cluster-instance"
//    "Environment" = module.global_vars.environment[var.env]
//  }
//}
//
//resource "aws_db_subnet_group" "range-aurora-sub-grp" {
//  name       = "range-rds-aurora-subnet-group"
//  subnet_ids = module.data.vpc_range_subs_private
//
//  tags = {
//    "Name"        = "RANGE-RDS-aurora-subnet-group"
//    "Environment" = module.global_vars.environment[var.env]
//  }
//}
//
//# Create KMS key for encryption
//resource "aws_kms_key" "range-rds-key" {
//  description              = "RANGE RDS KMS key"
//  deletion_window_in_days  = 10
//  key_usage                = "ENCRYPT_DECRYPT"
//  customer_master_key_spec = "SYMMETRIC_DEFAULT"
//}
//
