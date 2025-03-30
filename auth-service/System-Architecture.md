# Smarter Firms System Architecture

## System Overview

Smarter Firms is a microservices-based platform designed to help law firms manage their practice more efficiently by integrating with Clio and providing enhanced analytics and automation. The system is composed of the following services:

- **API Gateway**: Entry point for all client requests, handles routing, authentication verification, and rate limiting
- **Auth Service**: Manages user authentication, authorization, and user profile data
- **Clio Integration Service**: Handles integration with the Clio API, including OAuth flow and data synchronization
- **Account & Billing Service**: Manages firm accounts, subscriptions, and payment processing
- **Data Service**: Stores and processes firm data, documents, and analytics
- **Notifications Service**: Handles email, SMS, and push notifications
- **UI Service**: Next.js frontend application

## Service Interaction Diagram

```
┌─────────────┐                 ┌───────────────┐
│             │                 │               │
│  UI Service ├─────────────────┤  API Gateway  │
│             │                 │               │
└─────────────┘                 └───────┬───────┘
                                        │
                                        │
                 ┌────────────┬─────────┼──────────┬────────────┐
                 │            │         │          │            │
        ┌────────┴───────┐  ┌─┴──────────────┐  ┌─┴───────────┐  ┌─────────────────┐
        │                │  │                │  │             │  │                 │
        │  Auth Service  │  │ Clio Service   │  │ Account &   │  │ Notifications   │
        │                │  │                │  │ Billing     │  │ Service         │
        └────────────────┘  └────────────────┘  └─────────────┘  └─────────────────┘
                │                   │                  │                  │
                │                   │                  │                  │
                └───────────────────┴──────────────────┼──────────────────┘
                                                       │
                                               ┌───────┴────────┐
                                               │                │
                                               │  Data Service  │
                                               │                │
                                               └────────────────┘
```

## Clio Integration Service Architecture

The Clio Integration Service uses AWS serverless architecture for efficient and scalable data synchronization:

```
┌─────────────────┐     ┌─────────────┐     ┌───────────────┐
│                 │     │             │     │               │
│  API Endpoints  ├─────┤  SQS Queue  ├─────┤ Lambda Worker │
│  (Express)      │     │             │     │               │
└─────────────────┘     └─────────────┘     └───────┬───────┘
                                                    │
                                                    │
                              ┌─────────────────────┼─────────────────────┐
                              │                     │                     │
                     ┌────────┴─────────┐  ┌────────┴────────┐  ┌─────────┴────────┐
                     │                  │  │                 │  │                  │
                     │  Clio API        │  │  PostgreSQL     │  │  DynamoDB        │
                     │  (External)      │  │  (Data Storage) │  │  (Job State)     │
                     │                  │  │                 │  │                  │
                     └──────────────────┘  └─────────────────┘  └──────────────────┘
```

### Clio Integration Components

1. **API Endpoints (Express)**: 
   - Handles OAuth authentication flow with Clio
   - Provides endpoints for manual sync triggering
   - Offers sync status reporting
   - Accepts webhook calls from Clio

2. **SQS Queue**:
   - Manages sync job requests
   - Ensures reliable job processing
   - Handles retry logic
   - Provides dead-letter queue for failed jobs

3. **Lambda Workers**:
   - Process jobs from the queue
   - Fetch data from Clio API
   - Transform and store data in PostgreSQL
   - Update sync status in DynamoDB
   - Handle chunking for large data sets

4. **DynamoDB Tables**:
   - SyncJob: Tracks sync job status and progress
   - ClioConnection: Stores Clio connection details and tokens
   - SyncError: Records detailed error information

5. **Error Handling and Monitoring**:
   - CloudWatch for Lambda monitoring
   - SNS alerts for critical failures
   - Comprehensive error logging
   - Automated retry with exponential backoff

## Data Flow

### Authentication Flow
1. User initiates login from UI Service
2. Request is routed through API Gateway to Auth Service
3. Auth Service validates credentials and issues JWT tokens
4. UI Service stores tokens and includes them in subsequent requests
5. API Gateway validates tokens for all protected routes

### Clio Integration Flow
1. User initiates Clio connection from UI Service
2. Request is routed through API Gateway to Clio Integration Service
3. Clio Integration Service redirects to Clio OAuth authorization page
4. User authorizes the application in Clio
5. Clio redirects back to Clio Integration Service with authorization code
6. Clio Integration Service exchanges code for access/refresh tokens
7. Clio Integration Service stores tokens and creates synchronization jobs in SQS
8. Lambda workers consume jobs from SQS to fetch and process Clio data
9. Workers store data in PostgreSQL database and update sync status in DynamoDB
10. UI can poll sync status endpoints to show progress to users

### Clio Incremental Sync Process
1. Scheduled Lambda function triggers incremental sync job creation
2. SQS message created for each entity type that needs synchronization
3. Lambda workers process each entity type with pagination
4. Workers track last sync timestamp to fetch only new/modified data
5. Webhook endpoints receive real-time updates from Clio when data changes
6. Webhook processor creates targeted sync jobs for affected entities

### Billing Flow
1. User initiates subscription or payment from UI Service
2. Request is routed through API Gateway to Account & Billing Service
3. Account & Billing Service processes payment through Stripe
4. Account & Billing Service updates subscription status
5. Notifications Service sends confirmation email

## Service Boundaries and Responsibilities

### API Gateway
- **Responsibilities**: Request routing, authentication verification, rate limiting, request logging
- **Interacts with**: All services
- **Data owned**: None (stateless)

### Auth Service
- **Responsibilities**: User authentication, authorization, user profile management
- **Interacts with**: API Gateway
- **Data owned**: User profiles, authentication tokens, roles, permissions

### Clio Integration Service
- **Responsibilities**: Clio OAuth flow, data synchronization, API mapping, webhook processing
- **Interacts with**: API Gateway, Data Service, AWS SQS, AWS Lambda, Clio API
- **Data owned**: Clio integration settings, OAuth tokens, sync status, sync jobs
- **Serverless components**: Lambda functions for data synchronization, SQS for job queuing, DynamoDB for state tracking

### Account & Billing Service
- **Responsibilities**: Firm account management, subscription handling, payment processing
- **Interacts with**: API Gateway, Auth Service, Notifications Service
- **Data owned**: Firm accounts, subscription plans, payment records, invoices

### Data Service
- **Responsibilities**: Data storage, processing, analytics, document management
- **Interacts with**: API Gateway, all other services
- **Data owned**: Firm data, client records, documents, analytics data

### Notifications Service
- **Responsibilities**: Email, SMS, and push notification delivery
- **Interacts with**: API Gateway, all other services
- **Data owned**: Notification templates, delivery status, notification preferences

### UI Service
- **Responsibilities**: User interface rendering, client-side state management
- **Interacts with**: API Gateway
- **Data owned**: None (client-side state only)

## Database Architecture

Each service maintains its own database to ensure service isolation:

- **Auth Service**: PostgreSQL - user profiles, credentials, sessions
- **Clio Integration Service**: PostgreSQL - integration settings, connection status, entity data
  - DynamoDB - sync job tracking, performance-sensitive state data
- **Account & Billing Service**: PostgreSQL - accounts, subscriptions, payment history
- **Data Service**: PostgreSQL - structured data, with S3 for document storage
- **Notifications Service**: PostgreSQL - notification history, templates, preferences

## Security Architecture

- All service-to-service communication is authenticated using JWT tokens
- All external APIs are secured with HTTPS
- Authentication is centralized in the Auth Service
- The API Gateway validates tokens before routing requests
- Sensitive data is encrypted at rest
- Rate limiting is implemented at the API Gateway level
- AWS IAM roles control access to serverless components
- Clio OAuth tokens are encrypted in storage

## Deployment Architecture

The services are designed to be deployed as containerized applications in a Kubernetes cluster or similar container orchestration system, with serverless components managed by AWS:

- Each service has its own deployment configuration
- Services scale independently based on load
- Health checks monitor service availability
- Automated rollbacks ensure system stability
- Lambda functions scale automatically based on queue depth
- SQS provides durability for jobs during service disruptions

## Monitoring Architecture

- Distributed tracing across services
- Centralized logging
- Service health monitoring
- Performance metrics collection
- Alerting based on predefined thresholds
- CloudWatch metrics for Lambda function performance
- SQS queue depth monitoring
- Dead-letter queue alerts 