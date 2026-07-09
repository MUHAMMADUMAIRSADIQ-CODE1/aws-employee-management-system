terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ems-terraform-state-210965991883"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "employee-management"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  environment          = "dev"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id            = module.vpc.vpc_id
  environment       = "dev"
  public_subnet_cidrs = module.vpc.public_subnet_cidrs
}

module "rds" {
  source = "../../modules/rds"

  environment         = "dev"
  subnet_ids          = module.vpc.private_subnet_ids
  rds_sg_id           = module.security_groups.rds_sg_id
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  instance_class      = var.rds_instance_class
  allocated_storage   = var.rds_allocated_storage
  skip_final_snapshot = true
}

module "ec2" {
  source = "../../modules/ec2"

  environment  = "dev"
  subnet_id    = module.vpc.public_subnet_ids[0]
  ec2_sg_id    = module.security_groups.ec2_sg_id
  instance_type = var.ec2_instance_type
  key_name     = var.ec2_key_name

  rds_endpoint = module.rds.db_address
  rds_db_name  = module.rds.db_name
  rds_username = module.rds.db_username
  rds_password = var.db_password
}

module "alb" {
  source = "../../modules/alb"

  environment      = "dev"
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id        = module.security_groups.alb_sg_id
  ec2_instance_id  = module.ec2.instance_id
  domain_name      = var.domain_name
  certificate_arn  = var.certificate_arn
}
