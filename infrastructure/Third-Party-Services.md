# Infrastructure and Third-Party Services

This document outlines the infrastructure and third-party services used in the Smarter Firms platform. All development teams should reference this document to ensure consistent implementation and integration.

## Infrastructure Overview

### Development Environment
- **Local Development**: Direct local machine setup (no Docker containers due to Prisma compatibility issues)
- **Database**: Local PostgreSQL instance for development
- **Redis**: Local Redis instance for development (caching, queues)

### Production Environment
- **Cloud Provider**: AWS
- **Deployment**: AWS services (detailed below)
- **Database**: AWS RDS PostgreSQL
- **Caching/Queues**: AWS ElastiCache (Redis)

### AWS Services
The following AWS services are used in our production environment:
- **EC2**: For service hosting
- **RDS**: For PostgreSQL databases
- **ElastiCache**: For Redis instances
- **S3**: For file storage
- **Lambda**: For serverless functions
- **API Gateway**: For API management (in addition to our custom API Gateway)
- **CloudWatch**: For logging and monitoring
- **IAM**: For access management
- **CloudFront**: For content delivery
- **SQS**: For message queuing (in addition to Redis)

## Third-Party Services

### Domain and Security
- **DNS Management**: Cloudflare
- **DDoS Protection**: Cloudflare (paid plan)
- **SSL Certificates**: Cloudflare

### Communication Services
- **Email Delivery**: Mailgun (NOT AWS SES)
- **SMS Notifications**: Twilio (primarily for 2FA)

### Payment Processing
- **Payment Gateway**: Stripe
- **Subscription Management**: Stripe

### External Integrations
- **Legal Practice Management**: Clio API

## Service-Specific Integration Points

### API Gateway
- Integrates with Cloudflare for edge security
- Interfaces with AWS services for hosting

### Auth Service
- Interfaces with Twilio for 2FA SMS delivery

### Notification Service
- Integrates with Mailgun for email delivery
- Integrates with Twilio for SMS notifications

### Account & Billing Service
- Integrates with Stripe for payment processing and subscription management

### Data Service
- Uses AWS S3 for report storage
- Uses AWS RDS for data persistence

## Environment Configuration

All environment-specific configuration should be managed through environment variables. In production, these should be securely stored and managed through AWS Parameter Store or Secrets Manager.

Example `.env` structure (for local development):
```
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/smarterfirms?schema=public

# Redis
REDIS_URL=redis://localhost:6379

# Mailgun
MAILGUN_API_KEY=your-mailgun-api-key
MAILGUN_DOMAIN=mail.smarterfirms.com
MAILGUN_FROM_EMAIL=no-reply@smarterfirms.com

# Twilio
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_FROM_NUMBER=+1234567890

# Stripe
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key

# JWT
JWT_SECRET=your-jwt-secret
JWT_REFRESH_SECRET=your-jwt-refresh-secret

# Clio
CLIO_CLIENT_ID=your-clio-client-id
CLIO_CLIENT_SECRET=your-clio-client-secret
```

## Authentication Flow

Our authentication flow uses JWT tokens and integrates with Twilio for 2FA when enabled. This is handled by the Auth Service and is used across all other services.

## Security Considerations

- All API credentials should be stored in environment variables or AWS Secrets Manager
- No hardcoded credentials in any codebase
- All communication with third-party services should occur over HTTPS
- API keys should have the minimum necessary permissions
- Implement proper error handling and don't expose sensitive information in error messages

## Service Deployment Architecture

### Development and Staging

```
┌───────────────────┐     ┌───────────────────┐      ┌───────────────────┐
│   AWS CodeBuild   │────▶│   AWS CodeDeploy  │─────▶│   EC2 Instances   │
└───────────────────┘     └───────────────────┘      └───────────────────┘
         │                                                    │
         │                                                    │
         ▼                                                    ▼
┌───────────────────┐                               ┌───────────────────┐
│   ECR Registry    │                               │   RDS PostgreSQL  │
└───────────────────┘                               └───────────────────┘
                                                             │
                                                             │
                                                             ▼
                                                    ┌───────────────────┐
                                                    │  ElastiCache Redis│
                                                    └───────────────────┘
```

### Production

```
┌───────────────────┐     ┌───────────────────┐      ┌───────────────────┐
│   Cloudflare DNS  │────▶│ AWS Load Balancer │─────▶│   EC2 Instances   │
└───────────────────┘     └───────────────────┘      └───────────────────┘
         │                                                    │
         │                                                    │
         ▼                                                    ▼
┌───────────────────┐                               ┌───────────────────┐
│  Cloudflare WAF   │                               │   RDS PostgreSQL  │
└───────────────────┘                               │   (Multi-AZ)      │
                                                    └───────────────────┘
                                                             │
                                                             │
                                                             ▼
                                                    ┌───────────────────┐
                                                    │  ElastiCache Redis│
                                                    │   (Clustered)     │
                                                    └───────────────────┘
```

## Backup and Disaster Recovery

- **Database**: Point-in-time recovery enabled on RDS
- **S3 Files**: Versioning enabled on S3 buckets
- **Code**: All code repositories backed up in GitHub
- **Configuration**: Infrastructure as code managed in GitHub
- **Disaster Recovery**: Multi-AZ deployment for high availability
- **Backup Retention**: 30 days for database backups

## Monitoring and Alerting

- **Infrastructure Monitoring**: AWS CloudWatch
- **Application Monitoring**: Integrated logging with CloudWatch
- **Performance Metrics**: Custom CloudWatch dashboards
- **Alerting**: CloudWatch Alarms with SNS notifications
- **Error Tracking**: Centralized error logging

## Resource Allocation Guidelines

### Minimum Requirements for Production

| Service              | Instance Type | CPU  | Memory | Storage |
|----------------------|---------------|------|--------|---------|
| API Gateway          | t3.medium     | 2    | 4 GB   | 20 GB   |
| Auth Service         | t3.small      | 2    | 2 GB   | 20 GB   |
| Data Service         | t3.medium     | 2    | 4 GB   | 20 GB   |
| Notifications Service| t3.small      | 2    | 2 GB   | 20 GB   |
| Clio Integration     | t3.medium     | 2    | 4 GB   | 20 GB   |
| Account & Billing    | t3.small      | 2    | 2 GB   | 20 GB   |
| RDS Database         | db.t3.medium  | 2    | 4 GB   | 100 GB  |
| Redis Cache          | cache.t3.small| 2    | 1.5 GB | N/A     |

## Scaling Considerations

- Horizontal scaling for all services
- Auto-scaling groups for EC2 instances
- Read replicas for RDS under high load
- Connection pooling for database connections
- Redis cluster for distributed caching
``` 