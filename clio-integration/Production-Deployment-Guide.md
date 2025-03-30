# Clio Integration Service - Production Deployment Guide

This guide provides detailed instructions for deploying the Clio Integration Service in a production environment, including infrastructure sizing, monitoring setup, and rollback procedures.

## Infrastructure Requirements

### Compute Resources

| Component | Minimum | Recommended | High-Volume |
|-----------|---------|-------------|------------|
| CPU | 2 vCPU | 4 vCPU | 8 vCPU |
| Memory | 2 GB | 4 GB | 8 GB |
| Storage | 20 GB SSD | 50 GB SSD | 100 GB SSD |
| Instances | 2 | 3 | 5+ |

**Sizing Considerations:**
- Each service instance can handle approximately 50 concurrent webhook requests
- Memory usage increases with the number of active Clio connections
- For firms with >500 matters, use high-volume configuration

### Database (PostgreSQL)

| Resource | Minimum | Recommended | High-Volume |
|----------|---------|-------------|------------|
| Instance Type | db.t3.small | db.t3.medium | db.m5.large |
| Storage | 20 GB | 50 GB | 100+ GB |
| IOPS | 1000 | 3000 | 5000+ |
| Read Replicas | 0 | 1 | 2 |

**Sizing Considerations:**
- Database size grows linearly with number of Clio entities synced
- For every 1000 matters, allocate approximately 500 MB of storage
- Read replicas recommended for deployments with >20 firm connections

### Redis

| Resource | Minimum | Recommended | High-Volume |
|----------|---------|-------------|------------|
| Instance Type | cache.t3.small | cache.t3.medium | cache.m5.large |
| Memory | 1 GB | 2 GB | 4+ GB |
| Shards | 1 | 2 | 3+ |

**Sizing Considerations:**
- Redis primarily used for webhook metrics and alerting
- 1 GB can handle metrics for approximately 1 million webhook events
- For high throughput (>100 webhooks/second), use multiple shards

### Network

| Component | Requirement |
|-----------|-------------|
| Bandwidth | 50+ Mbps |
| Load Balancer | Application Load Balancer with TLS termination |
| CDN | Not required |
| WAF | Recommended |

## Step-by-Step Deployment Procedure

### 1. Infrastructure Provisioning

#### AWS CloudFormation/Terraform (recommended)

```bash
# Navigate to infrastructure directory
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file=production.tfvars

# Apply configuration
terraform apply -var-file=production.tfvars
```

#### Manual Provisioning

1. Create VPC with public and private subnets
2. Deploy PostgreSQL RDS instance in private subnet
3. Create ElastiCache Redis cluster in private subnet
4. Set up ECS cluster or EC2 instances with auto-scaling
5. Configure Application Load Balancer with TLS certificate
6. Set up security groups allowing necessary traffic

### 2. Database Initialization

```bash
# Generate Prisma client
npm run db:generate

# Run database migrations
DATABASE_URL=postgresql://user:password@rds-endpoint:5432/clio_integration npm run db:migrate
```

### 3. Service Deployment

#### Using Docker and ECS

1. Build and tag the Docker image:
   ```bash
   docker build -t your-ecr-repo/clio-integration-service:v1.0.0 .
   ```

2. Push to container registry:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin your-account.dkr.ecr.us-east-1.amazonaws.com
   docker push your-ecr-repo/clio-integration-service:v1.0.0
   ```

3. Update ECS task definition with new image version

4. Deploy the updated task definition:
   ```bash
   aws ecs update-service --cluster production-cluster --service clio-service --force-new-deployment
   ```

#### Using EC2 Instances

1. SSH into instances
2. Pull latest code
3. Install dependencies and build application
4. Update environment variables
5. Restart application using process manager:
   ```bash
   pm2 restart ecosystem.config.js --env production
   ```

### 4. Environment Configuration

Create a `.env` file with production configuration:

```
# Core Configuration
NODE_ENV=production
PORT=3001
LOG_LEVEL=info
CORS_ALLOWED_ORIGINS=https://app.smarter-firms.com

# Database Configuration
DATABASE_URL=postgresql://user:password@prod-db.example.com:5432/clio_integration

# Redis Configuration
REDIS_HOST=prod-redis.example.com
REDIS_PORT=6379
REDIS_PASSWORD=secure-password
REDIS_DB=0

# Clio API Configuration
CLIO_CLIENT_ID=production-client-id
CLIO_CLIENT_SECRET=production-client-secret
CLIO_REDIRECT_URI=https://app.smarter-firms.com/api/clio/oauth/callback
CLIO_API_BASE_URL=https://app.clio.com/api/v4

# Webhook Configuration
WEBHOOK_SECRET=production-webhook-secret
WEBHOOK_BASE_URL=https://app.smarter-firms.com

# API Gateway Integration
API_GATEWAY_URL=http://api-gateway-internal.prod.svc.cluster.local:3000
API_GATEWAY_KEY=production-gateway-key
SERVICE_URL=http://clio-service.prod.svc.cluster.local:3001
SERVICE_VERSION=1.0.0

# Alerting Configuration
ALERT_THRESHOLD_SUCCESS_RATE=98
ALERT_THRESHOLD_FAILURE_COUNT=5
ALERT_THRESHOLD_ERROR_RATE=2
ALERT_SLACK_WEBHOOK=https://hooks.slack.com/services/PRODUCTION_HOOK
ALERT_EMAIL_ENDPOINT=https://email-service.prod.svc.cluster.local/send
ALERT_PAGERDUTY_ENDPOINT=https://events.pagerduty.com/v2/enqueue
PAGERDUTY_ROUTING_KEY=production-key
ALERT_CHECK_INTERVAL=180000
```

### 5. Service Registration with API Gateway

```bash
# Register service with the API Gateway
npm run register-service
```

### 6. Verify Deployment

```bash
# Check service health
curl https://app.smarter-firms.com/api/health

# Verify webhook registration functionality
curl -X POST -H "Authorization: Bearer <valid-token>" https://app.smarter-firms.com/api/webhooks/register/test-user-id
```

## Monitoring Setup

### Key Metrics to Monitor

| Metric | Warning Threshold | Critical Threshold | Action |
|--------|-------------------|-------------------|--------|
| Service Health | 2 failed checks | 5 failed checks | Trigger alert, investigate logs |
| Webhook Success Rate | <98% | <95% | Check error distribution, verify Clio API status |
| Webhook Processing Time | >500ms avg | >1000ms avg | Scale up instances, check database performance |
| Database Connections | >80% pool | >90% pool | Increase connection pool, check for leaks |
| Redis Memory Usage | >70% | >85% | Increase Redis capacity, check key expiration |
| Error Rate | >2% | >5% | Investigate logs, check Clio API status |
| CPU Usage | >70% sustained | >85% sustained | Scale up instances or increase instance size |
| Memory Usage | >80% | >90% | Increase memory allocation, check for leaks |

### Prometheus/Grafana Setup (Recommended)

1. Deploy Prometheus server with the following scrape configuration:

```yaml
scrape_configs:
  - job_name: 'clio-integration'
    metrics_path: '/api/metrics/prometheus'
    scrape_interval: 15s
    static_configs:
      - targets: ['clio-service:3001']
```

2. Import the provided Grafana dashboard from `monitoring/grafana/clio-integration-dashboard.json`

3. Configure alerting rules in Prometheus:

```yaml
groups:
- name: clio-integration-alerts
  rules:
  - alert: HighWebhookFailureRate
    expr: webhook_success_rate < 95
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Webhook success rate below 95%"
      description: "The webhook success rate has been below 95% for 5 minutes."
  
  - alert: SlowWebhookProcessing
    expr: webhook_processing_time_avg > 1000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Slow webhook processing"
      description: "Average webhook processing time is above 1000ms for 5 minutes."
```

### CloudWatch Setup (AWS)

1. Create the following CloudWatch alarms:

   - **High CPU Utilization**:
     ```
     AWS/ECS ClusterName=production-cluster ServiceName=clio-service CPUUtilization > 80% for 5 minutes
     ```

   - **High Memory Utilization**:
     ```
     AWS/ECS ClusterName=production-cluster ServiceName=clio-service MemoryUtilization > 85% for 5 minutes
     ```

   - **Service Health**:
     ```
     AWS/ApplicationELB TargetGroup=clio-service-target UnHealthyHostCount > 0 for 2 minutes
     ```

2. Configure CloudWatch Logs:
   - Set up Log Groups for application logs
   - Create metric filters for ERROR level logs
   - Configure alarms on error rate

### Alerting Setup

Configure notification channels for alerts:

1. **PagerDuty**: Critical production issues (24/7 response)
2. **Slack**: Warning level alerts and operational notifications
3. **Email**: Daily summary reports and non-urgent issues

## Rollback Procedures

### 1. Service Deployment Rollback

#### ECS Deployment Rollback

```bash
# List task definition revisions
aws ecs list-task-definitions --family clio-service

# Update service to the previous working task definition
aws ecs update-service --cluster production-cluster --service clio-service --task-definition clio-service:123
```

#### EC2 Deployment Rollback

```bash
# SSH into instance
ssh user@instance

# Navigate to application directory
cd /opt/clio-integration-service

# Check out previous version
git checkout v1.0.0

# Reinstall dependencies and rebuild
npm ci
npm run build

# Restart application
pm2 restart ecosystem.config.js --env production
```

### 2. Database Migration Rollback

```bash
# List migrations
npx prisma migrate status

# Roll back to a specific migration
npx prisma migrate resolve --rolled-back 20230710120000_add_webhook_metrics
```

### 3. Configuration Rollback

1. Store configuration versions in a secure location (e.g., AWS Parameter Store)
2. Restore previous configuration:
   ```bash
   aws ssm get-parameter --name /clio-service/production/env/v1.0.0 --with-decryption > .env.rollback
   mv .env.rollback .env
   ```
3. Restart the service with the restored configuration

### 4. Complete Environment Rollback

For catastrophic failures, restore the entire environment from backups:

1. Restore RDS database from latest snapshot:
   ```bash
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier clio-db-restored \
     --db-snapshot-identifier clio-db-snapshot-20230720
   ```

2. Update database connection string to point to restored instance

3. Deploy known working version of the application

## Performance Tuning

### Node.js Configuration

Optimize Node.js performance with the following environment variables:

```
NODE_OPTIONS="--max-old-space-size=3072 --max-http-header-size=16384"
UV_THREADPOOL_SIZE=16
```

### Database Optimization

1. Create indexes for frequently queried fields:
   ```sql
   CREATE INDEX idx_clio_connections_user_id ON clio_connections(user_id);
   CREATE INDEX idx_clio_matters_external_id ON clio_matters(external_id);
   CREATE INDEX idx_clio_contacts_external_id ON clio_contacts(external_id);
   ```

2. Configure PostgreSQL for production:
   ```
   max_connections = 200
   shared_buffers = 1GB
   work_mem = 32MB
   maintenance_work_mem = 256MB
   effective_cache_size = 3GB
   ```

### Redis Optimization

1. Set appropriate key expiration policies:
   ```
   webhook:metrics:* -> 7 days
   webhook:processing:* -> 24 hours
   ```

2. Configure Redis for production:
   ```
   maxmemory 2gb
   maxmemory-policy allkeys-lru
   ```

## Maintenance Procedures

### Scheduled Maintenance

1. **Database Maintenance**:
   - Run VACUUM ANALYZE weekly during low-traffic periods
   - Rotate logs monthly

2. **Redis Maintenance**:
   - Monitor memory usage weekly
   - Clear stale metrics quarterly

3. **Application Updates**:
   - Schedule non-critical updates during business hours
   - Schedule critical security updates immediately with proper testing

### Backup Procedures

1. **Database**:
   - Daily automated snapshots (retain 7 days)
   - Weekly full backups (retain 1 month)
   - Monthly backups (retain 1 year)

2. **Configuration**:
   - Version all configuration in source control
   - Store encrypted environment variables in secure parameter store

## Security Procedures

1. **Credential Rotation**:
   - Rotate API Gateway keys quarterly
   - Update Clio OAuth client secrets annually
   - Rotate database credentials quarterly

2. **Audit Reviews**:
   - Review service logs weekly for suspicious activities
   - Monitor authentication failures daily
   - Perform security scans monthly

3. **OAuth Token Security**:
   - Follow recommendations in `Security-Review-OAuth.md`
   - Implement token encryption in database
   - Regular audits of token usage patterns 