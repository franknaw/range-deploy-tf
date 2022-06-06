terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.54"
    }
  }
}

locals {
  image_tag = "latest"
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
  This needs to be created in IAM.  TODO programmatically generate it.
  Role: ECSTaskExecutionRole - select trusted entity ECS
    AWS managed policy: AmazonElasticFileSystemFullAccess
    AWS managed policy: EC2InstanceProfileForImageBuilderECRContainerBuilds
    AWS managed policy: SecretsManagerReadWrite
    AWS managed policy: CloudWatchLogsFullAccess
    AWS managed policy: AmazonECSTaskExecutionRolePolicy
    AWS managed policy: AmazonECS_FullAccess
    AWS managed policy: AmazonS3FullAccess
*/
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ECSTaskExecutionRole"
}

output "ecs_task_execution_role" {
  value = data.aws_iam_role.ecs_task_execution_role.arn
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
   RDS Data
*/

//data "aws_rds_cluster" "range-rds-aurora-cluster" {
//  cluster_identifier = "range-rds-aurora-cluster"
//}
//
//output "rds-aurora-cluster" {
//  value = data.aws_rds_cluster.range-rds-aurora-cluster.endpoint
//}


/*
    Setup Cloudwatch Log Groups
*/

resource "aws_cloudwatch_log_group" "log-group" {
  for_each          = module.global_vars.cvle_version[var.cvle_version]
  name              = "/ecs/${each.value.api}"
  retention_in_days = 30
}


resource "aws_ecs_cluster" "range-api-cluster" {
  name = "range-api-cluster"

  tags = {
    Name = "RANGE-API-Cluster"
  }
}



/*
    Setup RANGE ECS SG
*/

resource "aws_security_group" "range-ecs-sg" {
  vpc_id = module.data.vpc_gateway.id
  name   = "RANGE-ECS-SG"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    "Name"        = "RANGE-ECS-SG"
    "Environment" = module.global_vars.environment[var.env]
  }
}


/**
* Range Micro 1
*/

data "aws_ecr_repository" "range-micro-1-repo" {
  count = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-1") ? 1 : 0
  name  = module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api
}

data "aws_ecr_image" "range-micro-1-image" {
  count           = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-1") ? 1 : 0
  repository_name = data.aws_ecr_repository.range-micro-1-repo[count.index].name
  image_tag       = local.image_tag
}

data "aws_lb_target_group" "range-micro-1-tg" {
  count = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-1") ? 1 : 0
  name  = module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api
}

resource "aws_ecs_service" "range-micro-1-service" {
  count           = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-1") ? 1 : 0
  name            = "${module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api}-service"
  cluster         = aws_ecs_cluster.range-api-cluster.id
  task_definition = aws_ecs_task_definition.range-micro-1-task[count.index].arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.data.vpc_gateway_subs_private
    assign_public_ip = false
    security_groups  = [aws_security_group.range-ecs-sg.id]
  }
  desired_count = 1

  load_balancer {
    target_group_arn = data.aws_lb_target_group.range-micro-1-tg[count.index].arn
    container_name   = module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api
    container_port   = 8080
  }

  tags = {
    "Name"        = "${module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api}-service"
    "Environment" = module.global_vars.environment[var.env]
  }
}

resource "aws_ecs_task_definition" "range-micro-1-task" {
  count        = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-1") ? 1 : 0
  family       = module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"]
  cpu                = 256
  memory             = 1024
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name             = module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api,
      image            = "${data.aws_ecr_repository.range-micro-1-repo[count.index].repository_url}:${data.aws_ecr_image.range-micro-1-image[count.index].image_tag}@${data.aws_ecr_image.range-micro-1-image[count.index].image_digest}"
      cpu              = 256,
      memory           = 1024,
      essential        = true,
//      cpuUnits         = 4000,
//      workingDirectory = "/opt/app",
      environment = [
        {
          name = "DEPLOY_ENV"
          value = var.env
        }
      ],
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080,
          protocol      = "tcp"
        }
      ],
//      ulimits = [
//        {
//          name      = "memlock",
//          softLimit = 4000,
//          hardLimit = 10000
//        }
//      ],
      logConfiguration = {
        logDriver = "awslogs",
        options : {
          awslogs-group         = "/ecs/${module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api}",
          awslogs-region        = module.global_vars.region[var.region],
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    "Name"        = "${module.global_vars.cvle_version[var.cvle_version]["range-micro-1"].api}-task"
    "Environment" = module.global_vars.environment[var.env]
  }
}


/**
* Range Micro 2
*/

data "aws_ecr_repository" "range-micro-2-repo" {
  count = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-2") ? 1 : 0
  name  = module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api
}

data "aws_ecr_image" "range-micro-2-image" {
  count           = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-2") ? 1 : 0
  repository_name = data.aws_ecr_repository.range-micro-2-repo[count.index].name
  image_tag       = local.image_tag
}

data "aws_lb_target_group" "range-micro-2-tg" {
  count = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-2") ? 1 : 0
  name  = module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api
}

resource "aws_ecs_service" "range-micro-2-service" {
  count           = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-2") ? 1 : 0
  name            = "${module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api}-service"
  cluster         = aws_ecs_cluster.range-api-cluster.id
  task_definition = aws_ecs_task_definition.range-micro-2-task[count.index].arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.data.vpc_gateway_subs_private
    assign_public_ip = false
    security_groups  = [aws_security_group.range-ecs-sg.id]
  }
  desired_count = 1

  load_balancer {
    target_group_arn = data.aws_lb_target_group.range-micro-2-tg[count.index].arn
    container_name   = module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api
    container_port   = 8080
  }

  tags = {
    "Name"        = "${module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api}-service"
    "Environment" = module.global_vars.environment[var.env]
  }
}

resource "aws_ecs_task_definition" "range-micro-2-task" {
  count        = contains(keys(module.global_vars.cvle_version[var.cvle_version]), "range-micro-2") ? 1 : 0
  family       = module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"]
  cpu                = 256
  memory             = 1024
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name             = module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api,
      image            = "${data.aws_ecr_repository.range-micro-2-repo[count.index].repository_url}:${data.aws_ecr_image.range-micro-2-image[count.index].image_tag}@${data.aws_ecr_image.range-micro-2-image[count.index].image_digest}"
      cpu              = 256,
      memory           = 1024,
      essential        = true,
//      cpuUnits         = 4000,
//      workingDirectory = "/opt/app",
      environment = [
        {
          name = "DEPLOY_ENV"
          value = var.env
        }
      ],
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080,
          protocol      = "tcp"
        }
      ],
//      ulimits = [
//        {
//          name      = "memlock",
//          softLimit = 4000,
//          hardLimit = 10000
//        }
//      ],
      logConfiguration = {
        logDriver = "awslogs",
        options : {
          awslogs-group         = "/ecs/${module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api}",
          awslogs-region        = module.global_vars.region[var.region],
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    "Name"        = "${module.global_vars.cvle_version[var.cvle_version]["range-micro-2"].api}-task"
    "Environment" = module.global_vars.environment[var.env]
  }
}
