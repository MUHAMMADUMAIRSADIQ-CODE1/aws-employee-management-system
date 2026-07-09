variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2"
  type        = string
}

variable "ec2_sg_id" {
  description = "EC2 security group ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = ""
}

variable "rds_endpoint" {
  description = "RDS endpoint"
  type        = string
  default     = ""
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  default     = ""
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = ""
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  default     = ""
  sensitive   = true
}
