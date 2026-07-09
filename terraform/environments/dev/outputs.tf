output "alb_dns_name" {
  description = "Application Load Balancer DNS Name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer Zone ID"
  value       = module.alb.alb_zone_id
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "EC2 Public IP"
  value       = module.ec2.instance_public_ip
}

output "ec2_private_ip" {
  description = "EC2 Private IP"
  value       = module.ec2.instance_private_ip
}

output "rds_endpoint" {
  description = "RDS Database Endpoint"
  value       = module.rds.db_endpoint
}

output "rds_address" {
  description = "RDS Database Address"
  value       = module.rds.db_address
}

output "rds_port" {
  description = "RDS Database Port"
  value       = module.rds.db_port
}

output "rds_database_name" {
  description = "Database Name"
  value       = module.rds.db_name
}

output "rds_username" {
  description = "Database Username"
  value       = module.rds.db_username
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}