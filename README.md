# Employee Management System

A production-ready Employee Management System deployed on AWS using a multi-tier architecture.

## Architecture

```
Frontend                          Backend
─────────                         ────────
Developer                         Users
    ↓                                ↓
GitHub Repository                 Route53
    ↓                                ↓
AWS Amplify                      Application Load Balancer
    ↓                                ↓
Amazon S3                        Amazon EC2 (Node.js + Express)
    ↓                                ↓
CloudFront                       Amazon RDS (MySQL)
    ↓
Users
```

### AWS Service Breakdown

| Service | Purpose |
|---------|---------|
| **EC2** | Hosts Node.js/Express backend API behind ALB, managed via PM2 |
| **RDS MySQL** | Persistent storage for admins and employees in private subnets |
| **Amplify** | CI/CD for React frontend, auto-builds on push, deploys to S3+CloudFront |
| **S3** | Static hosting of React build artifacts |
| **CloudFront** | CDN with global edge caching, HTTPS termination, DDoS protection |
| **Route53** | DNS routing: api.domain.com → ALB, app.domain.com → CloudFront |
| **ALB** | Distributes API traffic across EC2, handles SSL termination, health checks |
| **CloudWatch** | Centralized logging (app logs, system metrics), CloudWatch Agent on EC2 |

### Network Architecture

- **VPC**: `10.0.0.0/16`
- **Public Subnets** (2 AZs): ALB, NAT Gateway, Bastion
- **Private Subnets** (2 AZs): EC2, RDS
- **Internet Gateway** for public internet access
- **NAT Gateway** for private subnet outbound traffic
- **Security Groups**: Least-privilege, layer-specific ingress rules

## CI/CD Pipeline

### Frontend (AWS Amplify)

Push to `main` → Amplify detects change → Installs deps → `npm run build` → Deploys to S3 → Invalidates CloudFront cache

### Backend (GitHub Actions)

Push to `main` with backend changes → Runs lint + tests → SSH into EC2 → Pulls latest → `npm ci --production` → Restarts PM2 → Health check verification

## Tech Stack

- **Frontend**: React 19, Vite, React Router, Axios, Tailwind CSS, Context API
- **Backend**: Node.js, Express.js, JWT, bcrypt, express-validator, mysql2, Winston
- **Database**: Amazon RDS MySQL 8.0
- **Infrastructure**: Terraform (VPC, EC2, RDS, ALB, Security Groups)
- **Monitoring**: CloudWatch Logs + Metrics + CloudWatch Agent

## Project Structure

```
├── backend/
│   ├── config/          # Database, constants
│   ├── controllers/     # Auth, Employee CRUD
│   ├── middleware/       # Auth, validation, error handling
│   ├── routes/          # Express route definitions
│   ├── utils/           # Logger, response helpers
│   └── server.js        # Entry point
├── frontend/
│   ├── src/
│   │   ├── api/         # Axios config with interceptors
│   │   ├── components/  # Navbar, ProtectedRoute
│   │   ├── context/     # AuthContext
│   │   └── pages/       # Login, Dashboard, CRUD pages
│   └── vite.config.js   # Vite config with API proxy
├── terraform/
│   ├── modules/         # VPC, EC2, RDS, ALB, Security Groups
│   └── environments/    # Dev & Prod configurations
├── .github/workflows/   # Backend CI/CD
├── amplify.yml          # Amplify build spec
├── cloudwatch/          # CloudWatch Agent config
└── scripts/             # Deployment & setup scripts
```

## Getting Started

### Prerequisites

- Node.js 20+
- AWS CLI configured
- Terraform 1.5+
- MySQL client

### Local Development

```bash
# Backend
cd backend
cp .env.example .env
npm install
npm run dev

# Frontend
cd frontend
npm install
npm run dev
```

### Infrastructure Deployment

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/login` | No | Admin login |
| GET | `/api/auth/profile` | Yes | Get admin profile |
| GET | `/api/employees` | Yes | List employees (paginated, searchable) |
| GET | `/api/employees/stats` | Yes | Employee statistics |
| GET | `/api/employees/:id` | Yes | Get employee by ID |
| POST | `/api/employees` | Yes | Create employee |
| PUT | `/api/employees/:id` | Yes | Update employee |
| DELETE | `/api/employees/:id` | Yes | Delete employee |
| GET | `/api/health` | No | Health check |

## Database Schema

### Admins

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK | Auto increment |
| name | VARCHAR(100) | |
| email | VARCHAR(100) | Unique |
| password | VARCHAR(255) | bcrypt hashed |
| createdAt | TIMESTAMP | |
| updatedAt | TIMESTAMP | |

### Employees

| Column | Type | Notes |
|--------|------|-------|
| id | INT PK | Auto increment |
| firstName | VARCHAR(50) | |
| lastName | VARCHAR(50) | |
| email | VARCHAR(100) | Unique |
| phone | VARCHAR(20) | |
| department | VARCHAR(100) | |
| position | VARCHAR(100) | |
| salary | DECIMAL(10,2) | |
| address | TEXT | |
| hireDate | DATE | |
| status | ENUM | active/inactive/terminated |
| createdAt | TIMESTAMP | |
| updatedAt | TIMESTAMP | |

## Security

- JWT authentication with 24h expiry
- bcrypt password hashing (12 rounds)
- Helmet security headers
- CORS whitelisting
- Input validation (express-validator)
- SQL injection prevention (parameterized queries)
- Least-privilege security groups
- RDS in private subnets
- Encrypted EBS and RDS storage
- HTTPS via ALB/CloudFront
Test Auto Deploy