#!/bin/bash
set -e

DEPLOY_DIR="/opt/employee-management"
REPO_URL="https://github.com/your-org/employee-management.git"
BRANCH="main"

echo "Starting backend deployment..."

# Update system packages
sudo yum update -y

# Ensure Node.js and PM2 are installed
if ! command -v node &> /dev/null; then
    curl -sL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo yum install -y nodejs
fi

if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
fi

# Clone or pull latest code
if [ -d "$DEPLOY_DIR" ]; then
    cd "$DEPLOY_DIR"
    git fetch origin "$BRANCH"
    git reset --hard "origin/$BRANCH"
else
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown ec2-user:ec2-user "$DEPLOY_DIR"
    git clone -b "$BRANCH" "$REPO_URL" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi

# Install dependencies
cd backend
npm ci --production

# Restart application
pm2 delete ems-api 2>/dev/null || true
pm2 start server.js --name ems-api -i max --log-date-format "YYYY-MM-DD HH:mm:ss"
pm2 save

# Verify
sleep 3
if curl -f http://localhost:3000/api/health; then
    echo "Backend deployed successfully"
else
    echo "Deployment verification failed"
    exit 1
fi
