#!/bin/bash
set -e

# Update system
yum update -y

# Install Node.js 20
curl -sL https://rpm.nodesource.com/setup_20.x | bash -
yum install -y nodejs git

# Install PM2 globally
npm install -g pm2

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent

# Create application directory
mkdir -p /opt/employee-management
chmod 755 /opt/employee-management

# Create .env file
cat > /opt/employee-management/.env << EOF
NODE_ENV=${environment}
PORT=3000
DB_HOST=${rds_endpoint}
DB_PORT=3306
DB_USER=${rds_username}
DB_PASSWORD=${rds_password}
DB_NAME=${rds_db_name}
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRES_IN=24h
CORS_ORIGIN=*
LOG_LEVEL=info
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=Admin@123
ADMIN_NAME=Super Admin
EOF

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/employee-management/logs/combined.log",
            "log_group_name": "/ems/backend",
            "log_stream_name": "{instance_id}/combined",
            "timestamp_format": "%Y-%m-%d %H:%M:%S",
            "encoding": "utf-8"
          },
          {
            "file_path": "/opt/employee-management/logs/error.log",
            "log_group_name": "/ems/backend",
            "log_stream_name": "{instance_id}/error",
            "timestamp_format": "%Y-%m-%d %H:%M:%S",
            "encoding": "utf-8"
          }
        ]
      }
    },
    "log_stream_name": "ems-{instance_id}"
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  }
}
CWCONFIG

# Start CloudWatch Agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Set up PM2 startup
pm2 startup systemd -u ec2-user --hp /home/ec2-user

echo "EC2 initialization complete"
