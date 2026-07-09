data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.ec2_sg_id]
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user_data.sh", {
    environment   = var.environment
    rds_endpoint  = var.rds_endpoint
    rds_db_name   = var.rds_db_name
    rds_username  = var.rds_username
    rds_password  = var.rds_password
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  monitoring = true

  tags = {
    Name        = "ems-ec2-${var.environment}"
    Environment = var.environment
    Project     = "employee-management"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "ems-ec2-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization exceeds 80%"
  dimensions = {
    InstanceId = aws_instance.app.id
  }
}
