# Smarter Firms System Architecture

## System Overview

Smarter Firms is a microservices-based platform designed to help law firms manage their practice more efficiently by integrating with Clio and providing enhanced analytics and automation. The system is composed of the following services:

- **API Gateway**: Entry point for all client requests, handles routing, authentication verification, caching, and rate limiting
- **Auth Service**: Manages user authentication, authorization, and user profile data
- **Clio Integration Service**: Handles integration with the Clio API, including OAuth flow, data synchronization, and webhooks
- **Account & Billing Service**: Manages firm accounts, subscriptions, and payment processing
- **Data Service**: Stores and processes firm data, documents, and analytics
- **Notifications Service**: Handles email, SMS, and push notifications
- **UI Service**: Provides reusable React components and integration layers for frontend applications
- **Dashboard Application**: Next.js application for interactive firm analytics
- **Onboarding Application**: Next.js application for user registration and setup

## Service Interaction Diagram

```
┌─────────────┐    ┌─────────────┐                 ┌───────────────┐
│ Dashboard   │    │ Onboarding  │                 │               │
│ Application ├────┤ Application ├─────────────────┤  API Gateway  │
│             │    │             │                 │  (Redis Cache)│
└─────────────┘    └─────────────┘                 └───────┬───────┘
        │                                                  │
        │                                                  │
        └─────────────── ┌─────────────┐ ─────────────────┘
                         │             │
                         │ UI Service  │
                         │             │
                         └─────────────┘
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
                 │                             │
        ┌────────┴───────┐           ┌────────┴────────┐
        │                │           │                 │
        │  Auth Service  │           │ Clio Service    │
        │  (Redis)       │           │ (Redis+Bull)    │
        └────────────────┘           └─────────────────┘
                │                             │
                │                             │
                └─────────────┬───────────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
                    │  Data Service      │
                    │  (PostgreSQL)      │
                    └────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
     ┌──────────┴───────┐          ┌───────┴──────────┐
     │                  │          │                  │
     │ Account &        │          │ Notifications    │
     │ Billing Service  │          │ Service          │
     └──────────────────┘          └──────────────────┘
```

## Implementation Status

| Service | Status | Key Features |
|---------|--------|-------------|
| Common-Models | ✅ Complete | - Shared TypeScript interfaces<br>- Zod validation schemas<br>- BigInt support for Clio IDs |
| Auth Service | ✅ Complete | - JWT authentication with refresh tokens<br>- Role-based authorization<br>- Password reset flow |
| API Gateway | ✅ Complete | - Service routing<br>- Redis caching<br>- Service registry<br>- Rate limiting |
| Clio Integration | ✅ Complete | - OAuth 2.0 flow<br>- Webhook processing<br>- Bull queue for synchronization<br>- Metrics collection |
| UI Service | 🔄 In Progress | - Authentication components<br>- Dashboard layout<br>- Client detail views |
| Data Service | ⏳ Planned | - Analytics processing<br>- Report generation |
| Notifications Service | ⏳ Planned | - Email<br>- In-app notifications |
| Account & Billing | ⏳ Planned | - Stripe integration<br>- Subscription management |
| Dashboard Application | ⏳ Planned | - Interactive reports<br>- Data visualization |
| Onboarding Application | ⏳ Planned | - Registration flow<br>- Clio connection wizard |

## Clio Integration Service Architecture

The Clio Integration Service uses Redis-backed queues for efficient and reliable data synchronization:

```
┌─────────────────┐     ┌─────────────┐     ┌───────────────┐
│                 │     │             │     │               │
│  API Endpoints  ├─────┤  Bull Queue ├─────┤  Worker       │
│  (Express)      │     │  (Redis)    │     │  Processors   │
└─────────────────┘     └─────────────┘     └───────┬───────┘
        │                                           │
        │                                           │
        └────────────┐                ┌─────────────┘
                     │                │
                     ▼                ▼
          ┌────────────────┐  ┌────────────────┐
          │                │  │                │
          │  Clio API      │  │  PostgreSQL    │
          │  (External)    │  │  (Data Storage)│
          │                │  │                │
          └────────────────┘  └────────────────┘
                     ▲                ▲
                     │                │
                     │                │
          ┌──────────┴───────┐       │
          │                  │       │
          │  Webhook         ├───────┘
          │  Receiver        │
          │                  │
          └──────────────────┘
```

### Clio Integration Components

1. **API Endpoints (Express)**: 
   - Handles OAuth authentication flow with Clio
   - Provides endpoints for manual sync triggering
   - Offers sync status reporting
   - Registers webhooks with Clio

2. **Bull Queue (Redis-backed)**:
   - Manages sync job requests
   - Ensures reliable job processing
   - Handles retry logic
   - Provides concurrency control
   - Tracks job history and metrics

3. **Worker Processors**:
   - Process jobs from the queue
   - Fetch data from Clio API
   - Transform and store data in PostgreSQL
   - Handle pagination for large data sets
   - Implement rate limiting and backoff strategies

4. **Webhook Receiver**:
   - Receives real-time updates from Clio
   - Validates webhook authenticity
   - Triggers targeted synchronization jobs
   - Collects metrics on webhook processing

5. **Metrics Collection**:
   - Redis-backed metrics storage
   - Processing time measurements
   - Success/failure rate tracking
   - Volume statistics for capacity planning
   - Webhook processing performance

## Data Flow

### Authentication Flow
1. User initiates login from Dashboard or Onboarding Application
2. Request is routed through API Gateway to Auth Service
3. Auth Service validates credentials and issues JWT tokens
4. Frontend stores tokens and includes them in subsequent requests
5. API Gateway validates tokens for all protected routes
6. Refresh token flow handles token expiration transparently

### Clio Integration Flow
1. User initiates Clio connection from Onboarding Application
2. Request is routed through API Gateway to Clio Integration Service
3. Clio Integration Service redirects to Clio OAuth authorization page
4. User authorizes the application in Clio
5. Clio redirects back to Clio Integration Service with authorization code
6. Clio Integration Service exchanges code for access/refresh tokens
7. Clio Integration Service stores tokens and registers webhooks with Clio
8. Initial synchronization jobs are queued in Bull
9. Worker processors fetch and transform Clio data into PostgreSQL
10. Frontend polls sync status endpoints to show progress to users

### Clio Incremental Sync Process
1. Scheduled jobs trigger incremental sync for each entity type
2. Workers process each entity type with pagination and rate limiting
3. Workers track last sync timestamp to fetch only new/modified data
4. Webhook endpoints receive real-time updates from Clio when data changes
5. Webhook processor validates and processes updates
6. Redis metrics track performance and volume statistics

### Billing Flow
1. User initiates subscription or payment from Onboarding Application
2. Request is routed through API Gateway to Account & Billing Service
3. Account & Billing Service processes payment through Stripe
4. Account & Billing Service updates subscription status
5. Notifications Service sends confirmation email

## Service Boundaries and Responsibilities

### API Gateway
- **Responsibilities**: Request routing, authentication verification, rate limiting, request logging, caching
- **Interacts with**: All services
- **Data owned**: Service registry, Redis cache
- **Technologies**: Express, Redis, circuit-breaker pattern

### Auth Service
- **Responsibilities**: User authentication, authorization, user profile management
- **Interacts with**: API Gateway
- **Data owned**: User profiles, authentication tokens, roles, permissions
- **Technologies**: Express, Prisma, PostgreSQL, Redis, JWT

### Clio Integration Service
- **Responsibilities**: Clio OAuth flow, data synchronization, API mapping, webhook processing
- **Interacts with**: API Gateway, Data Service, Clio API
- **Data owned**: Clio integration settings, OAuth tokens, sync status, metrics
- **Technologies**: Express, Bull, Redis, Prisma, PostgreSQL

### Account & Billing Service
- **Responsibilities**: Firm account management, subscription handling, payment processing
- **Interacts with**: API Gateway, Auth Service, Notifications Service
- **Data owned**: Firm accounts, subscription plans, payment records, invoices
- **Technologies**: Express, Prisma, PostgreSQL, Stripe

### Data Service
- **Responsibilities**: Data storage, processing, analytics, document management
- **Interacts with**: API Gateway, all other services
- **Data owned**: Firm data, client records, documents, analytics data
- **Technologies**: Express, Prisma, PostgreSQL, Redis

### Notifications Service
- **Responsibilities**: Email, SMS, and push notification delivery
- **Interacts with**: API Gateway, all other services
- **Data owned**: Notification templates, delivery status, notification preferences
- **Technologies**: Express, Prisma, PostgreSQL, AWS SES/SNS

### UI Service
- **Responsibilities**: Reusable component library, client-side services, integration layers
- **Interacts with**: Dashboard and Onboarding Applications
- **Data owned**: None
- **Technologies**: React, TailwindCSS, Storybook, React Query

### Dashboard Application
- **Responsibilities**: Interactive visualization, reporting, user interface
- **Interacts with**: API Gateway, UI Service
- **Data owned**: None (client-side state only)
- **Technologies**: Next.js, React, TailwindCSS

### Onboarding Application
- **Responsibilities**: User registration, Clio connection, firm setup
- **Interacts with**: API Gateway, UI Service
- **Data owned**: None (client-side state only)
- **Technologies**: Next.js, React, TailwindCSS

## Database Architecture

Each service maintains its own database to ensure service isolation:

- **Auth Service**: PostgreSQL - user profiles, credentials, sessions
  - Redis - token blacklist, rate limiting
- **Clio Integration Service**: PostgreSQL - integration settings, connection status, entity data
  - Redis - job queues, metrics, synchronization state
- **Account & Billing Service**: PostgreSQL - accounts, subscriptions, payment history
- **Data Service**: PostgreSQL - structured data, analytics results
  - S3 for document storage
- **Notifications Service**: PostgreSQL - notification history, templates, preferences
- **API Gateway**: Redis - cache, rate limiting, service registry

## Security Architecture

- All service-to-service communication is authenticated using JWT tokens
- All external APIs are secured with HTTPS
- Authentication is centralized in the Auth Service
- The API Gateway validates tokens before routing requests
- Sensitive data is encrypted at rest
- Rate limiting is implemented at the API Gateway level
- Environment variables are used for secret management
- Clio OAuth tokens are encrypted in storage

## Deployment Architecture

The services are designed to be deployed as containerized applications using Docker and AWS ECS:

- Each service has its own Docker configuration
- Services scale independently based on load
- Health checks monitor service availability
- Automated CI/CD pipelines handle building and deployment
- Redis and PostgreSQL hosted on AWS managed services
- S3 for document and asset storage
- CloudWatch for logging and monitoring 