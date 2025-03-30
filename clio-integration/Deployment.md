# Clio Integration Service Deployment Guide

This document provides detailed instructions for deploying the Clio Integration Service in various environments.

## Prerequisites

Before deployment, ensure you have:

- Access to Clio Developer Portal to create an OAuth application
- Access to the private NPM registry for `@smarter-firms/common-models`
- PostgreSQL database (v14+)
- Redis instance (v6+)
- Node.js v18+ for building the application
- Docker for containerized deployment
- AWS account with necessary permissions (for production)

## Environment Configuration

The service requires the following environment variables:

### Core Configuration
```
NODE_ENV=production                         # Environment (development, test, production)
PORT=3001                                   # Port for the service to listen on
LOG_LEVEL=info                              # Logging level (debug, info, warn, error)
CORS_ALLOWED_ORIGINS=https://example.com    # Comma-separated list of allowed origins
```

### Database Configuration
```
DATABASE_URL=postgresql://user:password@host:5432/clio_integration    # PostgreSQL connection string
```

### Redis Configuration
```
REDIS_HOST=redis-host                       # Redis host
REDIS_PORT=6379                             # Redis port
REDIS_PASSWORD=redis-password               # Redis password (if required)
REDIS_DB=0                                  # Redis database to use
```

### Clio API Configuration
```
CLIO_CLIENT_ID=your-client-id               # Clio OAuth client ID
CLIO_CLIENT_SECRET=your-client-secret       # Clio OAuth client secret
CLIO_REDIRECT_URI=https://your-app/callback # OAuth callback URL
CLIO_API_BASE_URL=https://app.clio.com/api/v4 # Clio API base URL
```

### Webhook Configuration
```
WEBHOOK_SECRET=your-webhook-secret          # Secret for webhook signature validation
WEBHOOK_BASE_URL=https://your-service.com   # Base URL for webhook endpoints
```

### API Gateway Integration
```
API_GATEWAY_URL=http://api-gateway:3000     # API Gateway URL
API_GATEWAY_KEY=your-gateway-key            # API key for Gateway registration
SERVICE_URL=http://clio-service:3001        # URL where this service is accessible
SERVICE_VERSION=1.0.0                       # Service version
```

### Alerting Configuration
```
ALERT_THRESHOLD_SUCCESS_RATE=95             # Success rate threshold for alerts (percentage)
ALERT_THRESHOLD_FAILURE_COUNT=10            # Failure count threshold for alerts
ALERT_THRESHOLD_ERROR_RATE=5                # Error rate threshold for alerts (percentage)
ALERT_SLACK_WEBHOOK=https://hooks.slack.com/services/XXX # Slack webhook URL for alerts
ALERT_EMAIL_ENDPOINT=https://email-service/send # Email service endpoint
ALERT_PAGERDUTY_ENDPOINT=https://events.pagerduty.com/v2/enqueue # PagerDuty endpoint
PAGERDUTY_ROUTING_KEY=your-routing-key      # PagerDuty routing key
ALERT_CHECK_INTERVAL=300000                 # Alert check interval in milliseconds (5 min)
```

## Development Deployment

For local development:

1. Clone the repository:
   ```bash
   git clone https://github.com/smarter-firms/clio-integration-service.git
   cd clio-integration-service
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. Set up the database:
   ```bash
   npm run db:migrate
   ```

5. Start the service:
   ```bash
   npm run dev
   ```

## Docker Deployment

For Docker-based deployment:

1. Build the Docker image:
   ```bash
   docker build -t clio-integration-service:latest .
   ```

2. Create a `.env` file with your environment variables.

3. Run the container:
   ```bash
   docker run -d --name clio-integration \
     --env-file .env \
     -p 3001:3001 \
     clio-integration-service:latest
   ```

## Docker Compose Deployment

For a complete local environment with PostgreSQL and Redis:

1. Create a `docker-compose.yml` file:
   ```yaml
   version: '3.8'
   
   services:
     clio-integration:
       build: .
       ports:
         - "3001:3001"
       environment:
         - NODE_ENV=production
         - PORT=3001
         - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/clio_integration
         - REDIS_HOST=redis
         - REDIS_PORT=6379
         # Add other environment variables
       depends_on:
         - postgres
         - redis
   
     postgres:
       image: postgres:14
       environment:
         - POSTGRES_USER=postgres
         - POSTGRES_PASSWORD=postgres
         - POSTGRES_DB=clio_integration
       volumes:
         - postgres-data:/var/lib/postgresql/data
       ports:
         - "5432:5432"
   
     redis:
       image: redis:6
       volumes:
         - redis-data:/data
       ports:
         - "6379:6379"
   
   volumes:
     postgres-data:
     redis-data:
   ```

2. Start the services:
   ```bash
   docker-compose up -d
   ```

## AWS Deployment

For production deployment on AWS:

### Using Elastic Container Service (ECS)

1. Create an ECR repository:
   ```bash
   aws ecr create-repository --repository-name clio-integration-service
   ```

2. Build and push the Docker image:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
   
   docker build -t <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/clio-integration-service:latest .
   
   docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/clio-integration-service:latest
   ```

3. Create an ECS cluster, task definition, and service using AWS CLI or CloudFormation.

### Using Elastic Beanstalk

1. Install the EB CLI:
   ```bash
   pip install awsebcli
   ```

2. Initialize EB application:
   ```bash
   eb init
   ```

3. Create environment:
   ```bash
   eb create clio-integration-production
   ```

4. Configure environment variables:
   ```bash
   eb setenv NODE_ENV=production DATABASE_URL=postgresql://... # Set all required variables
   ```

5. Deploy:
   ```bash
   eb deploy
   ```

## Continuous Deployment

The service includes a GitHub Actions workflow for CI/CD in `.github/workflows/ci.yml`.

To set up continuous deployment:

1. Configure the following secrets in your GitHub repository:
   - `SSH_PRIVATE_KEY`: SSH key for deployment server access
   - `CODECOV_TOKEN`: Token for uploading coverage reports
   - `NPM_TOKEN`: Token for private NPM registry

2. The workflow will automatically:
   - Run linting and tests
   - Build the application
   - Deploy to the dev environment on push to `dev` branch
   - Deploy to production on push to `main` branch

## Configuring Clio OAuth Application

1. Log in to the Clio Developer Portal (https://app.clio.com/settings/developer_applications)

2. Create a new application with:
   - **Name**: Smarter Firms Integration
   - **Redirect URI**: Your callback URL (e.g., https://your-service.com/api/clio/oauth/callback)
   - **Scopes**: Select all required scopes (matters, contacts, calendar, etc.)

3. Copy the provided Client ID and Client Secret to your environment configuration.

## Post-Deployment Steps

After deployment, you need to:

1. **Register with API Gateway**:
   ```bash
   curl -X POST \
     -H "Authorization: Bearer <gateway-key>" \
     -H "Content-Type: application/json" \
     -d '{"name":"clio-integration-service","version":"1.0.0","baseUrl":"http://clio-service:3001","healthCheckPath":"/api/health"}' \
     http://api-gateway:3000/admin/services/register
   ```
   
   Or use the built-in script:
   ```bash
   npm run register-service
   ```

2. **Verify Webhook Endpoint Registration**:
   - Test that webhook registration works: `curl -X POST http://your-service/api/webhooks/register/test-user-id`
   - Confirm in Clio that webhooks are registered

3. **Test Health Endpoint**:
   ```bash
   curl http://your-service/api/health
   ```

## Monitoring Setup

The service exposes metrics that should be monitored:

1. **Health Check Monitoring**:
   - Configure a monitoring service to periodically check the `/api/health` endpoint
   - Set up alerts for failed health checks

2. **Webhook Metrics**:
   - Monitor webhook success rate via the `/api/metrics/webhooks/success-rate` endpoint
   - Track webhook processing time using the `/api/metrics/webhooks/processing-time` endpoint
   - Monitor error distribution through `/api/metrics/webhooks/errors`

3. **Logs**:
   - Configure log shipping to a centralized logging service
   - Set up alerts for ERROR level logs
   - Monitor for authentication failures

4. **Database and Redis Monitoring**:
   - Monitor PostgreSQL connection pool usage
   - Monitor Redis memory usage and connection count
   - Set up alerts for database connectivity issues

## Troubleshooting

### Database Migration Issues
If migrations fail:
```bash
# Check migration status
npx prisma migrate status

# Reset database (CAUTION: This deletes all data)
npm run db:reset

# Apply migrations manually
npx prisma migrate deploy
```

### Service Not Starting
Check logs for common issues:
```bash
# Check service logs
docker logs clio-integration

# Check environment variables
docker exec clio-integration env | grep CLIO
```

### Webhook Registration Issues
If webhooks aren't being registered:
```bash
# Check connectivity to Clio API
curl -v https://app.clio.com/api/v4

# Verify OAuth tokens
curl -X POST -d "client_id=<client_id>&client_secret=<client_secret>&refresh_token=<refresh_token>&grant_type=refresh_token" https://app.clio.com/oauth/token
```

### API Gateway Integration Issues
If API Gateway integration fails:
```bash
# Check service registration
curl -H "Authorization: Bearer <gateway-key>" http://api-gateway:3000/admin/services

# Manually register service
npm run register-service
```

## Backup and Recovery

To back up the service data:

1. **Database Backup**:
   ```bash
   # PostgreSQL backup
   pg_dump -h <host> -U <user> -d clio_integration > clio_integration_backup.sql
   ```

2. **Redis Backup** (if stateful data is stored):
   ```bash
   # Redis backup
   redis-cli -h <host> -a <password> --rdb redis_backup.rdb
   ```

To restore from backups:

1. **Database Restore**:
   ```bash
   # PostgreSQL restore
   psql -h <host> -U <user> -d clio_integration < clio_integration_backup.sql
   ```

2. **Redis Restore**:
   ```bash
   # Stop Redis
   redis-cli -h <host> -a <password> shutdown
   
   # Copy RDB file to Redis data directory
   cp redis_backup.rdb /var/lib/redis/dump.rdb
   
   # Start Redis
   service redis start
   ```

## Security Considerations

Refer to the [Security-Review-OAuth.md](./Security-Review-OAuth.md) document for detailed security considerations related to OAuth token handling. 