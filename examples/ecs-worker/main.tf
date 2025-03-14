terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

locals {
  azs = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]

  vpc_name                = "example-ecs-vpc"
  base_vpc_cidr           = "10.0.0.0/16"
  flow_log_retention_days = 7
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = local.vpc_name
  cidr = local.base_vpc_cidr
  azs  = local.azs

  # Enable a NAT gateway to allow private subnets to route traffic to the internet.
  enable_nat_gateway = true
  enable_vpn_gateway = false

  # So as to not waste IP addresses, we only create one NAT gateway per AZ.
  one_nat_gateway_per_az = true

  # Create an internet gateway to allow public subnets to route traffic to the internet.
  create_igw = true

  # The public subnets are used to route traffic from private subnets to the internet through the NAT gateway.
  # We only need one public subnet per AZ to route traffic to the internet from the private subnets.
  public_subnets = [for k, v in local.azs : cidrsubnet(local.base_vpc_cidr, 4, k)]

  # The private subnets are used to run the Prefect Server in Fargate.
  private_subnets = concat(
    # Assign primary VPC CIDR blocks to the private subnets
    [for k, v in local.azs : cidrsubnet(local.base_vpc_cidr, 4, k + 3)],
  )

  private_subnet_names = [for k, v in local.azs : "${local.vpc_name}-private-${local.azs[k]}"]
  public_subnet_names  = [for k, v in local.azs : "${local.vpc_name}-public-${local.azs[k]}"]

  # Enable flow logs to capture all traffic in and out of the VPC.
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_retention_in_days = local.flow_log_retention_days

  # The default security group is not used and by default the default security group
  # is deny on all ports and protocols both ingress and egress.
  manage_default_security_group = false

  # The default route table is not used and does not need to be managed by Terraform.
  manage_default_route_table = false

  tags = {
    Name = local.vpc_name
  }
}

resource "aws_ecr_repository" "example" {
  name                 = "example-ecs-worker"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = local.vpc_name
  }
}

module "prefect_ecs_worker" {
  source  = "prefecthq/ecs-worker/prefect"
  version = "1.0.0"

  name = "example-ecs-worker"

  vpc_id         = module.vpc.vpc_id
  worker_subnets = module.vpc.private_subnets

  prefect_api_key      = var.prefect_api_key
  prefect_account_id   = "6e02a1db-07de-4760-a15d-60d8fe0b04e1"
  prefect_workspace_id = "54cdfc71-9f13-41ba-9492-e1cf24eed185"

  worker_work_pool_name = "example-ecs-pool"
}
