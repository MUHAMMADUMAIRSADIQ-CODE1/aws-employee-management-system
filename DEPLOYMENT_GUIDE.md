# Complete Deployment Guide

## Employee Management System — From Zero to Production on AWS

This guide assumes you are starting with **nothing** — no AWS account, no GitHub repo, no code. Every single step is included.

---

## Table of Contents

1. [Prerequisites Setup](#1-prerequisites-setup)
2. [GitHub Repository Setup](#2-github-repository-setup)
3. [Local Development Setup](#3-local-development-setup)
4. [AWS Account Setup](#4-aws-account-setup)
5. [Terraform Infrastructure Deployment](#5-terraform-infrastructure-deployment)
6. [Amazon RDS Configuration](#6-amazon-rds-configuration)
7. [EC2 Configuration & Backend Deployment](#7-ec2-configuration--backend-deployment)
8. [GitHub Actions Secrets Setup](#8-github-actions-secrets-setup)
9. [AWS Amplify Frontend Deployment](#9-aws-amplify-frontend-deployment)
10. [Route53 DNS Configuration](#10-route53-dns-configuration)
11. [CloudWatch Monitoring Verification](#11-cloudwatch-monitoring-verification)
12. [End-to-End Verification](#12-end-to-end-verification)
13. [Troubleshooting](#13-troubleshooting)
14. [Architecture Summary](#14-architecture-summary)

---

## 1. Prerequisites Setup

### 1.1 Create an AWS Account

1. Go to https://aws.amazon.com/
2. Click **Create an AWS Account**
3. Enter email address and AWS account name
4. Choose **Personal** or **Professional** (Personal is fine for learning)
5. Enter payment information (you will be charged for resources used)
6. Verify your identity via phone call
7. Choose the **Basic (Free)** support plan
8. Sign in to the **AWS Management Console** at https://console.aws.amazon.com/

### 1.2 Install Required Software on Your Local Machine

**Windows:**

1. **Git:** Download from https://git-scm.com/download/win — run the installer, accept all defaults
2. **Node.js 20:** Download from https://nodejs.org/ (LTS version 20.x) — run the installer
3. **VS Code:** Download from https://code.visualstudio.com/ — run the installer
4. **AWS CLI:**
   - Download from https://awscli.amazonaws.com/AWSCLIV2.msi
   - Run the installer
   - Open **Command Prompt** (cmd.exe) — NOT PowerShell for this step
   - Run: `aws --version` — verify it shows `aws-cli/2.x.x`
5. **Terraform:**
   - Download from https://developer.hashicorp.com/terraform/install
   - Choose **Windows** → **AMD64**
   - Download the zip file
   - Extract `terraform.exe` to `C:\Windows\System32\`
   - Open **Command Prompt** and run: `terraform --version`

**macOS:**
```bash
# Install Homebrew first if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install everything
brew install git node@20 awscli terraform

# Download VS Code from https://code.visualstudio.com/
```

**Linux (Ubuntu/Debian):**
```bash
# Git
sudo apt update && sudo apt install -y git

# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# VS Code
sudo snap install code
```

### 1.3 Verify All Tools Are Installed

Open a **new** terminal window and run:

```bash
git --version          # Should show git version 2.x
node --version         # Should show v20.x.x
npm --version           # Should show 10.x.x
code --version          # Should show version
aws --version           # Should show aws-cli/2.x.x
terraform --version     # Should show Terraform v1.5.x or higher
```

If any command fails, install the missing tool before proceeding.

### 1.4 Create an IAM User for Programmatic Access

1. In AWS Console, search for **IAM** in the top search bar
2. Click **Users** in the left menu
3. Click **Create user**
4. **User name:** `ems-deployer`
5. Check **Provide user access to the AWS Management Console** (optional — for this guide we need programmatic access)
6. Click **Next**
7. Under **Set permissions**, click **Attach policies directly**
8. Search for and check these policies:
   - `AmazonEC2FullAccess`
   - `AmazonRDSFullAccess`
   - `AmazonS3FullAccess`
   - `CloudWatchFullAccess`
   - `IAMFullAccess`
   - `ElasticLoadBalancingFullAccess`
   - `AmazonRoute53FullAccess`
   - `AWSAmplifyFullAccess`
9. Click **Next**, then **Create user**
10. Click on the user `ems-deployer`
11. Click the **Security credentials** tab
12. Scroll to **Access keys** and click **Create access key**
13. Choose **Command Line Interface (CLI)**
14. Check the confirmation box, click **Next**
15. Click **Create access key**
16. **IMPORTANT:** Click **Download .csv file** — save this file somewhere safe. You will NOT be able to see the secret key again.

### 1.5 Configure AWS CLI

Open a terminal and run:

```bash
aws configure
```

You will be prompted for:
```
AWS Access Key ID: [Paste from the .csv file you downloaded]
AWS Secret Access Key: [Paste from the .csv file]
Default region name: us-east-1
Default output format: json
```

Verify it works:
```bash
aws sts get-caller-identity
```

You should see output like:
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/ems-deployer"
}
```

### 1.6 Create an EC2 Key Pair

This key pair allows you to SSH into your EC2 instance.

1. In AWS Console, search for **EC2**
2. In the left sidebar, under **Network & Security**, click **Key Pairs**
3. Click **Create key pair**
4. **Name:** `ems-key`
5. **Key pair type:** `RSA`
6. **Private key file format:** `.pem`
7. Click **Create key pair**
8. The `.pem` file will be downloaded automatically

**Windows (move key file):**
```bash
# Move the key file to a safe location (e.g., your user profile .ssh folder)
mkdir "%USERPROFILE%\.ssh"
move "%USERPROFILE%\Downloads\ems-key.pem" "%USERPROFILE%\.ssh\ems-key.pem"

# Set correct permissions (required for SSH)
icacls "%USERPROFILE%\.ssh\ems-key.pem" /inheritance:r
icacls "%USERPROFILE%\.ssh\ems-key.pem" /grant:r "%USERNAME%:(R)"
```

**macOS/Linux:**
```bash
mv ~/Downloads/ems-key.pem ~/.ssh/ems-key.pem
chmod 400 ~/.ssh/ems-key.pem
```

### 1.7 Create an S3 Bucket for Terraform State

Terraform needs a remote backend to store its state file. We use S3 (NOT DynamoDB, since DynamoDB is banned).

1. Go to AWS Console → search **S3**
2. Click **Create bucket**
3. **Bucket name:** `ems-terraform-state-dev-[YOUR-UNIQUE-STRING]`
   - Example: `ems-terraform-state-dev-abc123`
   - S3 bucket names must be globally unique. Replace `[YOUR-UNIQUE-STRING]` with something random (e.g., your initials + birth year).
4. **AWS Region:** `us-east-1` (N. Virginia)
5. **Block all public access:** ✓ checked (default)
6. **Bucket Versioning:** Enable (recommended)
7. **Default encryption:** Enable (SSE-S3)
8. Click **Create bucket**

> **Note for production:** You would also create a bucket for prod state: `ems-terraform-state-prod-[unique]`. For this guide we just need the dev bucket.

### 1.8 Create an SSH Key on Your EC2 Instance (For GitHub Actions)

We need an SSH key that GitHub Actions will use to connect to EC2.

**Option A: Generate on your local machine (recommended):**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github-actions -N ""
```

This creates two files:
- `~/.ssh/github-actions` — **private key** (keep secret)
- `~/.ssh/github-actions.pub` — **public key** (we'll add this to EC2)

**Option B: (Windows)**
```bash
# In Command Prompt or PowerShell
ssh-keygen -t rsa -b 4096 -f "%USERPROFILE%\.ssh\github-actions" -N ""
```

**View and copy the public key:**
```bash
# macOS/Linux
cat ~/.ssh/github-actions.pub

# Windows (PowerShell)
Get-Content "$env:USERPROFILE\.ssh\github-actions.pub"
```

Keep the terminal open — we'll use this public key later when Terraform provisions the EC2 instance.

---

## 2. GitHub Repository Setup

### 2.1 Create a GitHub Account

1. Go to https://github.com/
2. Click **Sign up**
3. Enter your email, create a password, choose a username
4. Verify your email address
5. Choose the **Free** plan

### 2.2 Create a Personal Access Token (PAT)

1. On GitHub, click your profile picture (top-right) → **Settings**
2. Scroll down to **Developer settings** (bottom of left sidebar)
3. Click **Personal access tokens** → **Tokens (classic)**
4. Click **Generate new token** → **Generate new token (classic)**
5. **Note:** `ems-git-deploy`
6. **Expiration:** `No expiration`
7. Check: **repo** (all sub-options), **workflow**
8. Click **Generate token**
9. **IMPORTANT:** Copy the token immediately. It looks like `ghp_xxxxxxxxxxxxxxxxxxxx`. You won't be able to see it again.

### 2.3 Create a New GitHub Repository

1. Go to https://github.com/new
2. **Repository name:** `employee-management`
3. **Description:** `Employee Management System`
4. **Public** or **Private** — your choice (Public is free, Private also free)
5. **DO NOT** check "Add a README", "Add .gitignore", or "Add a license"
6. Click **Create repository**

### 2.4 Initialize Git Locally and Push the Project

**Option A: You have the project files already from the codebase**

```bash
# Navigate to the project root
cd "C:\Users\ghula\OneDrive\Desktop\AWS ARCHITECTURE"

# Initialize git
git init

# Add all files
git add -A

# Commit
git commit -m "Initial commit: Employee Management System with full AWS architecture"

# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/employee-management.git

# Push to GitHub (use the token as password when prompted)
git push -u origin main
```

When prompted for a password, paste your Personal Access Token (ghp_...).

**Option B: Create the project from scratch**

```bash
# Create project directory
mkdir employee-management
cd employee-management

# Initialize git
git init

# [You would create all the project files here manually]
# For this guide, we assume you have the project files from the codebase.

# Add and commit
git add -A
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/employee-management.git
git push -u origin main
```

---

## 3. Local Development Setup

### 3.1 Install Backend Dependencies

```bash
# Navigate to backend directory
cd C:\Users\ghula\OneDrive\Desktop\AWS ARCHITECTURE\backend

# Install dependencies
npm install
```

### 3.2 Configure Backend Environment

```bash
# Copy the example .env file
cp .env.example .env
```

Edit `.env` and set:
```
NODE_ENV=development
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=employee_management
JWT_SECRET=dev_secret_key_12345
JWT_EXPIRES_IN=24h
CORS_ORIGIN=http://localhost:5173
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=Admin@123
ADMIN_NAME=Super Admin
LOG_LEVEL=debug
```

### 3.3 Install MySQL Locally (Optional — for local testing)

**Option A: Install MySQL Server**

Download from https://dev.mysql.com/downloads/installer/

1. Download **MySQL Installer for Windows**
2. Run the installer
3. Choose **Developer Default**
4. Set root password to match your `.env` file
5. Complete the installation

**Option B: Use XAMPP (easier)**

Download from https://www.apachefriends.org/

1. Install XAMPP
2. Open XAMPP Control Panel
3. Click **Start** next to **MySQL**
4. MySQL runs on port 3306

### 3.4 Test the Backend Locally

```bash
# Start the backend in development mode
cd backend
npm run dev
```

You should see:
```
[nodemon] starting `node server.js`
info: Database initialized successfully
info: Default admin account created
info: Server running on port 3000 in development mode
```

Test in another terminal:
```bash
curl http://localhost:3000/api/health
```

Expected response:
```json
{"success":true,"message":"Employee Management API is running","timestamp":"...","environment":"development"}
```

### 3.5 Test the Frontend Locally

Open a **new** terminal:

```bash
cd frontend
npm install
npm run dev
```

Open your browser to: http://localhost:5173

You should see the **Login** page.

**Login with:**
- Email: `admin@example.com`
- Password: `Admin@123`

After login, you should see the **Dashboard**.

### 3.6 Stop Local Servers

Press `Ctrl + C` in both terminal windows to stop the servers.

---

## 4. AWS Account Setup (Additional)

### 4.1 Request an SSL Certificate via ACM (for HTTPS)

We need an SSL certificate so our ALB can serve HTTPS traffic. Skip this section if you don't have a domain name — the HTTP redirect will work.

1. Go to AWS Console → search **ACM**
2. Click **Request a certificate**
3. Choose **Request a public certificate**
4. Click **Next
5. **Fully qualified domain name:** `*.example.com` (replace with your domain)
6. **Add another name:** `example.com`
7. Click **Next**
8. Choose **DNS validation** (recommended)
9. Click **Review**, then **Request**
10. After creation, click on the certificate
11. Under **Domains**, click **Create record in Route53** (this adds CNAME records automatically)
12. Wait 5-10 minutes for validation
13. Copy the **Certificate ARN** — it looks like: `arn:aws:acm:us-east-1:123456789012:certificate/xxxx-xxxx-xxxx`

---

## 5. Terraform Infrastructure Deployment

### 5.1 Update Terraform Configuration Files

Before running Terraform, we need to update some configuration values.

**Step 1: Update the Terraform State S3 Bucket Name**

Open `terraform/environments/dev/main.tf` in VS Code.

Change line 12:
```hcl
bucket = "ems-terraform-state-dev-[YOUR-UNIQUE-STRING]"
```

Replace `[YOUR-UNIQUE-STRING]` with whatever you used when creating the S3 bucket in Section 1.7.

**Step 2: Update SSH Key Name for EC2**

Open `terraform/environments/dev/terraform.tfvars`.

Find the line:
```hcl
ec2_key_name = ""
```

Change it to:
```hcl
ec2_key_name = "ems-key"
```

If you have a domain and SSL certificate, also update:
```hcl
domain_name     = "example.com"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-arn"
```

Otherwise, leave them empty — the site will work over HTTP.

**Step 3: Update the SSH Key in EC2 User Data**

**Critical step:** We need to add the GitHub Actions public SSH key to the EC2 instance so GitHub Actions can deploy.

Open `terraform/modules/ec2/user_data.sh`.

Add these lines BEFORE the `echo "EC2 initialization complete"` line:

```bash
# Add GitHub Actions public SSH key for deployment
mkdir -p /home/ec2-user/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... (paste your entire public key here)" >> /home/ec2-user/.ssh/authorized_keys
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
```

Get your public key from:
```bash
cat ~/.ssh/github-actions.pub
```

Paste the entire output (starting with `ssh-rsa` or `ssh-ed25519`) between the quotes in the `echo` command.

### 5.2 Initialize Terraform

Open a terminal in the Terraform dev environment:

```bash
cd terraform/environments/dev
terraform init
```

You should see:
```
Initializing modules...
Initializing the backend...
Terraform has been successfully initialized!
```

### 5.3 Review the Terraform Plan

```bash
terraform plan
```

This will show every resource that Terraform will create. Look for:
- `aws_vpc` — the VPC
- `aws_subnet.public[0]` and `aws_subnet.public[1]` — public subnets
- `aws_subnet.private[0]` and `aws_subnet.private[1]` — private subnets
- `aws_internet_gateway` — IGW
- `aws_nat_gateway` — NAT Gateway
- `aws_security_group.alb`, `aws_security_group.ec2`, `aws_security_group.rds`
- `aws_db_instance.main` — RDS MySQL
- `aws_instance.app` — EC2 instance
- `aws_lb.main` — ALB
- `aws_lb_target_group.main` — Target group
- `aws_lb_listener.http` — HTTP listener
- `aws_lb_listener.https` — HTTPS listener (if you have a cert)
- `aws_route53_record.api` — Route53 record (if you have a domain)
- `aws_cloudwatch_metric_alarm.ec2_cpu` — CPU alarm

**The plan should say:** `Plan: 20 to add, 0 to change, 0 to destroy.` (numbers may vary slightly)

### 5.4 Apply Terraform

```bash
terraform apply
```

Terraform will show the plan and ask:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Type `yes` and press Enter.

**This will take 10-15 minutes.** Terraform is creating:
- VPC, subnets, IGW, NAT Gateway (2-3 minutes)
- Security groups (30 seconds)
- RDS MySQL instance (5-8 minutes)
- EC2 instance with user_data (2-3 minutes)
- ALB and target group (2 minutes)

### 5.5 Verify Terraform Applied Successfully

After completion, you'll see output similar to:
```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.

Outputs:
```

The outputs come from each module. The key outputs are:

```hcl
module.vpc.vpc_id = "vpc-0xxxxxxx"
module.vpc.public_subnet_ids = ["subnet-0xxx", "subnet-0xxx"]
module.vpc.private_subnet_ids = ["subnet-0xxx", "subnet-0xxx"]
module.ec2.instance_id = "i-0xxxxxxxxx"
module.ec2.instance_public_ip = "54.xxx.xxx.xxx"
module.ec2.instance_private_ip = "10.0.1.xxx"
module.rds.db_address = "ems-mysql-dev.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com"
module.rds.db_endpoint = "ems-mysql-dev.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com:3306"
module.rds.db_name = "employee_management"
module.rds.db_username = "ems_admin"
module.alb.alb_dns_name = "ems-alb-dev-xxxxxx.us-east-1.elb.amazonaws.com"
module.security_groups.alb_sg_id = "sg-0xxxxx"
module.security_groups.ec2_sg_id = "sg-0xxxxx"
module.security_groups.rds_sg_id = "sg-0xxxxx"
```

**Write down these values** — you'll need them:
- `module.ec2.instance_public_ip` — the EC2 public IP
- `module.rds.db_address` — the RDS endpoint
- `module.alb.alb_dns_name` — the ALB DNS name

### 5.6 Update Terraform Variables for Future Runs

If you want to check the outputs later:
```bash
terraform output
```

### 5.7 (Optional) Verify Infrastructure in AWS Console

1. Go to **EC2 Console** → **Instances** → You should see `ems-ec2-dev` running
2. Go to **RDS Console** → **Databases** → You should see `ems-mysql-dev` with status **Available**
3. Go to **Load Balancers** → You should see `ems-alb-dev` with state **Active**
4. Go to **VPC Console** → **Your VPCs** → You should see `ems-vpc-dev`

---

## 6. Amazon RDS Configuration

### 6.1 Get RDS Endpoint

From the Terraform output, get the `module.rds.db_address`. It should look like:
```
ems-mysql-dev.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com
```

### 6.2 Verify RDS is Accessible

While the EC2 instance is in a private subnet, we can test connectivity from the EC2 instance itself.

SSH into the EC2 instance:
```bash
ssh -i ~/.ssh/ems-key.pem ec2-user@54.xxx.xxx.xxx
```

(Replace `54.xxx.xxx.xxx` with your EC2 public IP from Terraform output)

Once inside the EC2 instance, check if MySQL is accessible:
```bash
mysql -h ems-mysql-dev.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com -u ems_admin -p
```

When prompted, enter the password from `terraform.tfvars` (`ChangeMe123!`).

If successful:
```sql
SHOW DATABASES;
```

You should see:
```
+-------------------------+
| Database                |
+-------------------------+
| employee_management     |
| information_schema      |
| mysql                   |
| performance_schema      |
+-------------------------+
```

Exit MySQL:
```sql
EXIT;
```

Stay in the EC2 SSH session for the next section.

### 6.3 Verify Backend is Running on EC2

From within the EC2 SSH session:
```bash
# Check if PM2 is running the app
pm2 list
```

You should see:
```
┌────┬────────────┬──────────┬──────┬───────────┬──────────┬──────────┐
│ id │ name       │ mode     │ ↺    │ status     │ cpu      │ memory   │
├────┼────────────┼──────────┼──────┼───────────┼──────────┼──────────┤
│ 0  │ ems-api    │ cluster  │ 0    │ online     │ 0%       │ 50.3mb   │
└────┴────────────┴──────────┴──────┴───────────┴──────────┴──────────┘
```

Check the application logs:
```bash
pm2 logs ems-api --lines 20
```

You should see:
```
Server running on port 3000 in production mode
Database initialized successfully
Default admin account created
```

Test the API:
```bash
curl http://localhost:3000/api/health
```

Expected response:
```json
{"success":true,"message":"Employee Management API is running","timestamp":"...","environment":"production"}
```

Exit the SSH session:
```bash
exit
```

---

## 7. EC2 Configuration & Backend Deployment

### 7.1 Verify PM2 is Running

SSH into EC2:
```bash
ssh -i ~/.ssh/ems-key.pem ec2-user@54.xxx.xxx.xxx
```

Check PM2:
```bash
pm2 list
pm2 logs ems-api --lines 30
exit
```

### 7.2 Test the ALB Endpoint

The ALB DNS name should work even in a browser. Open a browser and go to:
```
http://ems-alb-dev-xxxxxxx.us-east-1.elb.amazonaws.com/api/health
```

You should see the JSON health response.

If you have a domain configured, also test:
```
http://api.yourdomain.com/api/health
```

### 7.3 Seed the Admin User if Not Already Done

If the admin user wasn't seeded during boot (possible timing issues), trigger it manually:

SSH into EC2:
```bash
ssh -i ~/.ssh/ems-key.pem ec2-user@54.xxx.xxx.xxx
```

Check the database:
```bash
mysql -h ems-mysql-dev.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com -u ems_admin -p

# Enter password: ChangeMe123!

USE employee_management;
SELECT * FROM admins;
EXIT;
```

If no admin exists, restart the app to trigger seeding:
```bash
pm2 restart ems-api
pm2 logs ems-api --lines 20
# Look for: "Default admin account created"
exit
```

### 7.4 Create a Test Employee (via API)

```bash
# Login as admin (first get a token)
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"Admin@123"}'
```

You'll get back a token. Use it to create an employee:
```bash
# Replace YOUR_TOKEN with the token from the previous command
curl -X POST http://localhost:3000/api/employees \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"firstName":"John","lastName":"Doe","email":"john@example.com","department":"Engineering","position":"Developer","salary":75000,"status":"active"}'
```

Verify the employee was created:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/employees
```

---

## 8. GitHub Actions Secrets Setup

### 8.1 Navigate to GitHub Repository Secrets

1. Go to https://github.com/YOUR_USERNAME/employee-management
2. Click the **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 8.2 Add Each Secret

Click **New repository secret** for each item below. Add them one by one.

**Secret 1: `EC2_HOST`**
```
Value: 54.xxx.xxx.xxx (your EC2 instance public IP from Terraform output)
```

**Secret 2: `EC2_SSH_KEY`**
```
Value: (the entire contents of your private key file)
```

To get the contents:
```bash
# macOS/Linux
cat ~/.ssh/github-actions

# Windows PowerShell
Get-Content "$env:USERPROFILE\.ssh\github-actions" -Raw
```

Copy the **entire output** including the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines.

**Secret 3: `DB_HOST`**
```
Value: ems-mysql-dev.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com (from Terraform output)
```

**Secret 4: `DB_USER`**
```
Value: ems_admin
```

**Secret 5: `DB_PASSWORD`**
```
Value: ChangeMe123!
```

**Secret 6: `DB_NAME`**
```
Value: employee_management
```

**Secret 7: `JWT_SECRET`**
```
Value: (generate a random string)
```

To generate a random secret:
```bash
# macOS/Linux
openssl rand -base64 32

# Windows (PowerShell)
[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

**Secret 8: `CORS_ORIGIN`**
```
Value: * (for now; in production set to your CloudFront domain)
```

**Secret 9: `ADMIN_EMAIL`**
```
Value: admin@example.com
```

**Secret 10: `ADMIN_PASSWORD`**
```
Value: Admin@123
```

### 8.3 Verify Secrets Are Listed

After adding all secrets, the **Actions secrets** section should show these 10 secrets (their names, with values hidden):

- `EC2_HOST`
- `EC2_SSH_KEY`
- `DB_HOST`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`
- `JWT_SECRET`
- `CORS_ORIGIN`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`

### 8.4 Trigger the GitHub Actions Workflow

The workflow is triggered automatically when you push code:

```bash
git add .
git commit -m "Update: configure deployment secrets"
git push origin main
```

### 8.5 Monitor the GitHub Actions Run

1. Go to https://github.com/YOUR_USERNAME/employee-management
2. Click the **Actions** tab
3. You should see a workflow run titled "Backend CI/CD"
4. Click on it to see details
5. It will show two jobs:
   - **Lint & Test** (should complete within 30 seconds)
   - **Deploy to EC2** (should complete within 60 seconds)

### 8.6 Verify the Deployment Succeeded

Check the **Deploy to EC2** job logs. The last lines should show:

```
Run echo "Deployment to EC2 completed successfully"
Deployment to EC2 completed successfully
```

If it fails, expand the failed step to see the error. Common causes:
- SSH key permission issues
- EC2 Host IP changed (if EC2 restarted)
- Database connection refused

---

## 9. AWS Amplify Frontend Deployment

### 9.1 Create IAM Service Role for Amplify

Before configuring Amplify, we need an IAM role that Amplify will assume to deploy to S3/CloudFront.

1. Go to AWS Console → **IAM** → **Roles** → **Create role**
2. **Trusted entity type:** `Custom trust policy`
3. Paste this JSON:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "amplify.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
4. Click **Next**
5. Search for and check:
   `AdministratorAccess-Amplify` (Full access to Amplify)
6. Click **Next**
7. **Role name:** `AmplifyServiceRole-EMS`
8. Click **Create role**

### 9.2 Set Up Amplify

1. Go to AWS Console → search **AWS Amplify**
2. Click **New app** → **Host web app**
3. Choose **GitHub** as the source control provider
4. Click **Continue**

### 9.3 Connect GitHub to Amplify

1. Click **Authorize with GitHub** (first time only)
2. You'll be redirected to GitHub
3. Click **Authorize AWS-Amplify** (green button)
4. You'll be redirected back to AWS

### 9.4 Select Repository and Branch

1. **Repository:** `YOUR_USERNAME/employee-management`
2. **Branch:** `main`
3. Click **Next**

### 9.5 Configure Build Settings

Amplify automatically detects the `amplify.yml` file.

**App name:** `employee-management-frontend`

Under **Frontend build settings**, verify:
```
baseDirectory: frontend/dist
Build command: cd frontend && npm run build
```

Under **Advanced settings** → **Service role**, select the role:
`AmplifyService-EMS`

Click **Next**, then **Save and deploy**.

### 9.6 Monitor the Amplify Deployment

1. You'll be redirected to the Amplify deployment dashboard
2. The first deployment will start automatically
3. **Phase 1: Provision** — setting up resources
4. **Phase 2: Pre-Build** — `npm ci`
5. **Phase 3: Build** — `npm run build`
6. **Phase 4: Post-Build** — preparing artifacts
7. **Phase 5: Deploy** — uploading to S3 and CloudFront

Total time: ~3-5 minutes

### 9.7 Get the Amplify/CloudFront URL

1. After deployment succeeds, scroll to the top
2. You'll see a URL like: `https://main.xxxxxxxxxxx.amplifyapp.com`
3. Click on it — it should open your application!
4. Login with: `admin@example.com` / `Admin@123`
5. You should see the Dashboard

This URL is already served through CloudFront (Amplify manages CloudFront automatically).

### 9.8 Setup a Custom Domain (Optional)

If you want to use a custom domain instead of the `amplifyapp.com` URL:

1. In the Amplify dashboard, click on **Domain management** (left sidebar)
2. Click **Add domain**
3. Enter your domain name: `app.yourdomain.com`
4. Click **Configure domain**
5. Amplify will detect if the domain is in Route53
6. Follow the prompts to create DNS records
7. Wait 10-15 minutes for SSL certificate provisioning
8. Your app will be accessible at: `https://app.yourdomain.com`

### 9.9 Connect Backend API URL

In production, the frontend (CloudFront) needs to talk to the backend (ALB).

In the Amplify dashboard:
1. Click **Environment variables** (left sidebar)
2. Click **Add**
3. **Variable name:** `VITE_API_URL`
4. **Value:** `http://ems-alb-dev-xxxxxxx.us-east-1.elb.amazonaws.com/api` (or `https://api.yourdomain.com` if you have a domain)
5. Click **Save**
6. Click **Start a new deploy** to rebuild the frontend with this env variable

---

## 10. Route53 DNS Configuration

### 10.1 Prerequisites

- You must own a domain (registered via Route53 or another registrar)
- For Route53 registered domains: the hosted zone is created automatically
- For external domains: you need to create a hosted zone

### 10.2 Create a Hosted Zone (if domain is not in Route53)

1. Go to AWS Console → **Route53** → **Hosted zones**
2. Click **Create hosted zone**
3. **Domain name:** `yourdomain.com`
4. **Type:** `Public hosted zone`
5. Click **Create**
6. After creation, note the **Name servers** (NS records) — 4 values like `ns-xxx.awsdns-xxx.com`
7. Go to your domain registrar (e.g., GoDaddy, Namecheap, etc.)
8. Update the nameservers to the 4 Route53 NS values
9. Wait 24-48 hours for DNS propagation

### 10.3 Point api.yourdomain.com to the ALB

1. In Route53 Console, click on your hosted zone (`yourdomain.com`)
2. Click **Create record**
3. **Record name:** `api`
4. **Record type:** `A`
5. Turn on **Alias** (toggle)
6. **Route traffic to:** `Alias to Application and Classic Load Balancer`
7. **Region:** `us-east-1`
8. Select your ALB from the dropdown (`ems-alb-dev`)
9. **Evaluate target health:** Yes
10. Click **Create records**

Now `http://api.yourdomain.com/api/health` should work.

### 10.4 Point app.yourdomain.com to CloudFront

1. In Route53 Console, click your hosted zone
2. Click **Create record**
3. **Record name:** `app`
4. **Record type:** `A`
5. Turn on **Alias**
6. **Route traffic to:** `Alias to CloudFront distribution`
7. Select your CloudFront distribution
8. **Evaluate target health:** No (not applicable for CloudFront)
9. Click **Create records**

Now `https://app.yourdomain.com` should load your application.

### 10.5 Verify Route53 Records

```bash
# Test backend DNS
curl http://api.yourdomain.com/api/health

# Test frontend DNS (open in browser)
# https://app.yourdomain.com
```

---

## 11. CloudWatch Configuration Verification

### 11.1 Verify CloudWatch Agent is Running on EC2

SSH into EC2:
```bash
ssh -i ~/.ssh/ems-key.pem ec2-user@54.xxx.xxx.xxx
```

Check the CloudWatch Agent:
```bash
# Check if agent is running
sudo systemctl status amazon-cloudwatch-agent

# Check agent logs
sudo cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log | tail -30
```

You should see logs like:
```
Successfully loaded the configuration from /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json.
Start AWS Systems Manager CloudWatch Agent
Amazon CloudWatch Agent has started.
```

### 11.2 Verify Application Logs

```bash
# Check the application log files
sudo tail -f /opt/employee-management/logs/combined.log
```

You should see JSON-format log entries.

### 11.3 Verify CloudWatch Log Groups

1. Go to AWS Console → **CloudWatch** → **Log groups**
2. You should see:
   - `/ems/backend` — application combined logs
   - `/ems/backend/error` — application error logs
   - `/ems/system` — system messages

Click on `/ems/backend` to see log streams. You should see logs streaming in real-time.

### 11.4 Verify CloudWatch Metrics

1. Go to AWS Console → **CloudWatch** → **Metrics** → **All metrics**
2. Under **Browse**, choose:
   - **Custom Namespaces** → **EMS/Backend** → you should see CPU, Memory, Disk metrics
   - **AWS/EC2** → **InstanceId** → CPUUtilization, NetworkIn/Out
   - **AWS/RDS** → **DBInstanceIdentifier** → DatabaseConnections, CPUUtilization

### 11.5 Verify CloudWatch Alarm

1. Go to AWS Console → **CloudWatch** → **Alarms**
2. You should see: `ems-ec2-cpu-high-dev`
3. Status should be **OK** (unless you've been pounding the server)

---

## 12. End-to-End Verification

### 12.1 Complete API Test

Test every API endpoint from your local machine (through the ALB):

```bash
# Set variables
ALB_URL="http://ems-alb-dev-xxxxxxx.us-east-1.elb.amazonaws.com"

# 1. Health check
curl "$ALB_URL/api/health"
echo "---"

# 2. Login
TOKEN=$(curl -s -X POST "$ALB_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"Admin@123"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Token: $TOKEN"
echo "---"

# 3. Get dashboard stats
curl -s -H "Authorization: Bearer $TOKEN" "$ALB_URL/api/employees/stats"
echo "---"

# 4. Create employee
curl -s -X POST "$ALB_URL/api/employees" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"firstName":"Jane","lastName":"Smith","email":"jane@example.com","department":"Marketing","position":"Manager","salary":80000,"status":"active"}'
echo "---"

# 5. Get all employees
curl -s -H "Authorization: Bearer $TOKEN" "$ALB_URL/api/employees"
echo "---"

# 6. Search employees
curl -s -H "Authorization: Bearer $TOKEN" "$ALB_URL/api/employees?search=Jane"
echo "---"

# 7. Update employee (replace 1 with actual employee ID)
curl -s -X PUT "$ALB_URL/api/employees/1" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"firstName":"Jane","lastName":"Johnson","email":"jane@example.com","department":"Marketing","position":"Senior Manager","salary":"85000","status":"active"}'
echo "---"

# 8. Delete employee (uncomment to test)
# curl -s -X DELETE "$ALB_URL/api/employees/1" -H "Authorization: Bearer $TOKEN"
# echo "---"

echo "All API tests completed!"
```

### 12.2 Test the Full Flow Through a Browser

1. Open a browser to: `https://main.xxxxxxxxxxx.amplifyapp.com` (or `https://app.yourdomain.com`)
2. **Login page:** Should load with a gradient blue background and centered login form
3. Enter: `admin@example.com` / `Admin@123`
4. Click **Sign In** — you should be redirected to the **Dashboard**
5. **Dashboard:** Should show 4 stat cards (Total Employees, Active, Inactive, Departments) and a recent employees table
6. Navigate to **Employees** page — click "Employees" in the navbar
7. **Employee List:** Shows a table with header columns, search bar, and "Add Employee" button
8. Click **+ Add Employee**
9. **Add Employee form:** Fill in: First Name = "Alice", Last Name = "Williams", Email = "alice@test.com", Department = "Engineering", Position = "Frontend Developer", Salary = "90000"
10. Click **Save Employee** — should redirect back to Employee List showing Alice in the table
11. Click **Edit** on Alice's row — should open the edit form with pre-filled data
12. Change the Position to "Senior Frontend Developer"
13. Click **Update Employee** — should update and redirect to list
14. Click **Delete** on Alice's row — a confirmation modal should appear
15. Click **Delete** in the modal — Alice should be removed from the list
16. Use the **Search** bar: type "Smith" and click **Search** — should filter to show only employees with "Smith"
17. Click **Clear** — should reset the search
18. Navigate to **Dashboard** — the stats should reflect changes
19. Click **Logout** in the navbar — should redirect to the Login page
20. Try accessing `/dashboard` directly — should redirect to Login (protected route)
21. Try accessing `/nonexistent` — should show the **404 page**

### 12.3 Verify PM2 Process Management

SSH into EC2 and verify:
```bash
ssh -i ~/.ssh/ems-key.pem ec2-user@54.xxx.xxx.xxx

pm2 status
pm2 monit  # Interactive monitor (press 'q' to quit)
```

### 12.4 Verify Deployments Via CI/CD

**Backend (GitHub Actions):**
1. Make a small change to a backend file:
   ```bash
   echo "" >> backend/server.js  # Add a blank line
   git add .
   git commit -m "Test: trigger backend deployment"
   git push origin main
   ```
2. Go to GitHub → Actions tab → watch the "Backend CI/CD" workflow run
3. It should: checkout → install deps → lint (skipped if no eslint) → test → deploy to EC2
4. The deployment step should show: "Deployment to EC2 completed successfully"

**Frontend (Amplify):**
1. Make a small change to a frontend file:
   ```bash
   echo "/* test */" >> frontend/src/index.css
   git add .
   git commit -m "Test: trigger frontend deployment"
   git push origin main
   ```
2. Go to AWS Amplify Console
3. You should see a new build automatically starting
4. Wait 3-4 minutes for it to complete
5. Refresh your application URL — the change should be visible

---

## 13. Troubleshooting

### 13.1 Terraform Plan Fails

**Error: "No valid credential sources found"**
- Run `aws configure` again
- Verify `aws sts get-caller-identity` shows your user

**Error: "Bucket ... does not exist"**
- You didn't create the S3 bucket in step 1.7, or the name doesn't match
- Check S3 Console and create the bucket, then update `dev/main.tf`

**Error: "Your account has not been approved" about NAT Gateway**
- Some new accounts have service limits. Request a limit increase in AWS Console → Service Quotas

### 13.2 Terraform Apply Fails Midway

**RDS creation fails:**
- "DB instance created, but not available" — wait 10 minutes and run `terraform apply` again (it will pick up from where it left off)
- "Storage limit exceeded" — request a limit increase

**EC2 user_data script fails:**
- SSH into the EC2 instance
- Check: `sudo cat /var/log/user-data.log` or `sudo cat /var/log/cloud-init-output.log`

### 13.3 Backend API Not Responding

**Check if the app is running on EC2:**
```bash
ssh -i ~/.ssh/ems-key.pem ec2-user@54.xxx.xxx.xxx
ps aux | grep node
pm2 list
```

**Check logs:**
```bash
pm2 logs ems-api
```

**Check if port 3000 is listening:**
```bash
sudo netstat -tlnp | grep 3000
```

**Restart the app:**
```bash
pm2 restart ems-api
pm2 logs ems-api --lines 20
```

### 13.4 ALB Health Check Fails

- The target group health check hits `/api/health` on port 3000
- If the EC2 security group doesn't allow port 3000 from ALB, it will fail
- Verify in EC2 Console: click the target group → **Targets** tab → check if targets show "healthy"
- If "unhealthy": SSH into EC2 and check if the app is running on 3000

### 13.5 Database Connection Fails

**From EC2:**
```bash
mysql -h ems-mysql-dev.xxxxxx.rds.amazonaws.com -u ems_admin -p
```

**Common issues:**
- RDS security group doesn't allow port 3306 from EC2 security group
- RDS endpoint in `.env` is incorrect
- Wrong username/password

### 13.6 GitHub Actions Workflow Fails

**Click on the failed step in the GitHub Actions UI to see the raw error:**

**"Host key verification failed":**
- The EC2 host key has changed (EC2 was terminated and recreated)
- Update your local known_hosts and the workflow secret `EC2_HOST`

**"Permission denied (publickey)":**
- The SSH private key (stored in `EC2_SSH_KEY` secret) doesn't match the public key added to EC2
- Regenerate keys: `ssh-keygen -f ~/.ssh/github-actions`
- Add the new public key to EC2
- Update the `EC2_SSH_KEY` GitHub secret with the new private key

**Timeout connecting to EC2:**
- EC2 might have changed IP (if stopped and started)
- Update the `EC2_HOST` secret with the new IP

### 13.7 Amplify Build Fails

**In the Amplify Console, click the failed build to see logs:**

**"npm ERR! Could not read package.json":**
- The `amplify.yml` specifies `baseDirectory: frontend/dist` — verify the build is running from the correct directory

**Build succeeded but site shows blank page:**
- Open browser console (F12) — look for errors
- Most common: API URL not configured, CORS errors
- Set environment variable `VITE_API_URL` in Amplify

### 13.8 CORS Errors in Browser

If you see "CORS error" in the browser console:
- The backend CORS_ORIGIN must include the frontend URL
- In production, update `CORS_ORIGIN` to `https://app.yourdomain.com`
- In development with Amplify, set it to `https://main.xxxxxxx.amplifyapp.com`

### 13.9 Reset / Redeploy Everything

If you want to start from scratch:

**Destroy all Terraform resources:**
```bash
cd terraform/environments/dev
terraform destroy
```

**Delete S3 bucket:**
```bash
aws s3 rb s3://ems-terraform-state-dev-[YOUR-UNIQUE-STRING] --force
```

**Delete Amplify app:**
1. Go to Amplify Console
2. Select the app
3. Click **Actions** → **Delete app**

**Remove GitHub secrets:**
1. GitHub → Settings → Secrets and variables → Actions
2. Click **Remove** on each secret

**Delete GitHub repository and recreate:**
```bash
rm -rf .git
# Create new repo on GitHub
git init
git add .
git commit -m "Fresh start"
git remote add origin https://github.com/your/employee-management.git
git push -u origin main
```

---

## 14. Architecture Summary

Once everything is deployed, the complete architecture looks like this:

```
                          AWS Cloud
                          ─────────
┌─────────────────────────────────────────────────────────────────────┐
│                           VPC (10.0.0.0/16)                        │
│                                                                     │
│   ┌───────────── Public Subnets ──────────────┐                     │
│   │  Subnet 1 (10.0.1.0/24)                   │                     │
│   │  Subnet 2 (10.0.2.0/24)                   │                     │
│   │                                           │                     │
│   │  Internet Gateway ─── NAT Gateway         │                     │
│   │       │                                    │                     │
│   │  Application Load Balancer               │                     │
│   │       │ (port 443 HTTPS, port 80 HTTP→443)│                     │
│   │       │ health check: /api/health          │                     │
│   └───────│─────────────────────────────────────┘                     │
│           │                                                         │
│           ▼                                                         │
│   ┌───────┴───────────── Private Subnets ────────────┐           │
│   │  Subnet 1 (10.0.10.0/24)                          │           │
│   │  Subnet 2 (10.0.11.0/24)                          │           │
│   │                                                   │           │
│   │  EC2 (t3.micro amazon linux 2)                    │           │
│   │  ├── PM2 (cluster mode, 2 instances)              │           │
│   │  │   └── Express API (port 3000)                  │           │
│   │  ├── CloudWatch Agent (logs → CloudWatch)         │           │
│   │  └── /opt/employee-management/                     │           │
│   │                                                   │           │
│   │  RDS MySQL 8.0 (db.t3.micro)                     │           │
│   │  ├── encrypted gp3 storage                        │           │
│   │  ├── 7-day backups                               │           │
│   │  └── CloudWatch log exports                        │           │
│   └───────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                  Frontend                          │
│                                                    │
│  GitHub → AWS Amplify → S3 → CloudFront → User     │
│                                                    │
│  CI/CD:                                            │
│  git push → Amplify detects → npm build → S3      │
│  → CloudFront invalidation                         │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                  Backend                           │
│                                                    │
│  GitHub → GitHub Actions → SSH → EC2              │
│  → npm ci --production → pm2 restart                │
│                                                    │
│  User → Route53 → ALB → EC2:3000 → RDS:3306       │
└──────────────────────────────────────────────────┘
```

### Cost Estimate

| Service | Approx. Monthly Cost (us-east-1) |
|---------|----------------------------------|
| EC2 (t3.micro, 1 instance) | ~$8.50 |
| RDS (db.t3.micro, MySQL) | ~$15.00 |
| ALB (1 LCU average) | ~$16.00 |
| NAT Gateway | ~$32.00 |
| CloudWatch (logs + metrics) | ~$5.00 |
| S3 (minimal storage) | ~$0.50 |
| CloudFront (minimal traffic) | ~$1.00 |
| **Total** | **~$78/month** |

**To save costs in development:**
- Destroy RDS when not in use (takes 5 minutes to recreate)
- Destroy the NAT Gateway and use a cheaper route (but private subnets lose internet access)
- Use `t4g.nano` instead of `t3.micro` (ARM-based, ~15% cheaper)
- Set `terraform destroy` as a cron job overnight

---

## Quick Reference

### Common Commands

```bash
# Local development
cd backend && npm run dev        # Start backend
cd frontend && npm run dev       # Start frontend

# Terraform
cd terraform/environments/dev
terraform init                   # First time only
terraform plan                   # Preview changes
terraform apply                  # Apply changes
terraform destroy                # Destroy everything

# EC2 SSH
ssh -i ~/.ssh/ems-key.pem ec2-user@54.xxx.xxx.xxx

# PM2 (on EC2)
pm2 list                         # List processes
pm2 logs ems-api                  # View logs
pm2 restart ems-api               # Restart
pm2 stop ems-api                  # Stop
pm2 delete ems-api                 # Remove process

# Git push (triggers CI/CD)
git add .
git commit -m "Message"
git push origin main

# API testing
curl http://localhost:3000/api/health
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"Admin@123"}'
```

### Important Files Reference

| File | Purpose |
|------|---------|
| `backend/server.js` | Express entry point |
| `backend/.env.example` | Environment variable template |
| `backend/routes/employees.js` | Employee API routes |
| `backend/controllers/authController.js` | Login + profile + seed admin |
| `frontend/src/App.jsx` | React app with routes |
| `frontend/src/context/AuthContext.jsx` | Auth state management |
| `frontend/src/pages/Login.jsx` | Login page |
| `frontend/src/pages/Dashboard.jsx` | Dashboard page |
| `amplify.yml` | Amplify build specification |
| `.github/workflows/backend-deploy.yml` | GitHub Actions workflow |
| `terraform/environments/dev/main.tf` | Dev infrastructure |
| `terraform/modules/ec2/user_data.sh` | EC2 initialization script |
| `cloudwatch/cloudwatch-agent-config.json` | CloudWatch Agent config |

### GitHub Secrets Required

| Secret Name | Description |
|-------------|-------------|
| `EC2_HOST` | EC2 public IP address |
| `EC2_SSH_KEY` | SSH private key content (full file) |
| `DB_HOST` | RDS endpoint hostname |
| `DB_USER` | RDS username (ems_admin) |
| `DB_PASSWORD` | RDS password |
| `DB_NAME` | Database name (employee_management) |
| `JWT_SECRET` | Random base64 string for JWT signing |
| `CORS_ORIGIN` | Frontend URL for CORS whitelist |
| `ADMIN_EMAIL` | Default admin email |
| `ADMIN_PASSWORD` | Default admin password |