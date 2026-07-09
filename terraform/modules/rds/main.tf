resource "aws_db_subnet_group" "main" {
  name       = "ems-rds-subnet-group-${var.environment}"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "ems-rds-subnet-group-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_parameter_group" "main" {
  name   = "ems-mysql-params-${var.environment}"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = {
    Name        = "ems-rds-params-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  identifier = "ems-mysql-${var.environment}"

  engine         = "mysql"
  engine_version = "8.0.46"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  parameter_group_name = aws_db_parameter_group.main.name

  backup_retention_period = 0
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "ems-mysql-${var.environment}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = var.environment == "prod" ? true : false

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name        = "ems-mysql-${var.environment}"
    Environment = var.environment
    Project     = "employee-management"
  }
}
