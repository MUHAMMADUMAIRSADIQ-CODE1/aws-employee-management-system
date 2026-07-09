#!/bin/bash
set -e

echo "Setting up EC2 instance for Employee Management System..."

# Update system
sudo yum update -y

# Install essential packages
sudo yum install -y git curl wget

# Install Node.js 20
curl -sL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Verify Node.js and npm
node --version
npm --version

# Install PM2 globally
sudo npm install -g pm2

# Create application directory
sudo mkdir -p /opt/employee-management
sudo chown ec2-user:ec2-user /opt/employee-management

# Install and configure CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent

sudo mkdir -p /opt/employee-management/logs

# Configure CloudWatch Agent
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'EOF'
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
    }
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
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
EOF

sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent

# Configure PM2 startup
pm2 startup systemd -u ec2-user --hp /home/ec2-user

# Set up swap for t3.micro (optional, good for small instances)
sudo dd if=/dev/zero of=/swapfile bs=128M count=4
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

echo "EC2 setup complete!"
echo ""
echo "Next steps:"
echo "1. Clone the repository to /opt/employee-management"
echo "2. Create .env file with correct database credentials"
echo "3. Run 'npm ci --production' in the backend directory"
echo "4. Start the app: pm2 start server.js --name ems-api"
