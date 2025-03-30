# Smarter Firms Project Overview

## Project Mission
Provide law firms using Clio with enhanced reporting capabilities through a SaaS platform that offers actionable insights derived from their practice management data.

## Architecture Overview

```
                                   ┌───────────────────┐
                                   │                   │
                                   │  API Gateway      │
                                   │  (Node.js/Express)│
                                   │                   │
                                   └─────────┬─────────┘
                                             │
                          ┌──────────────────┼──────────────────┐
                          │                  │                  │
                          ▼                  ▼                  ▼
┌─────────────────────┐  ┌────────────────────┐  ┌───────────────────┐
│                     │  │                    │  │                   │
│  Onboarding App     │◄►│   Auth Service     │◄►│  Dashboard App    │
│  (Next.js)          │  │   (Node.js/Express)│  │  (Next.js)        │
│                     │  │                    │  │                   │
└─────────────────────┘  └────────────────────┘  └───────────────────┘
          │                        │                      │
          │                        │                      │
          │                        │                      │
          ▼                        ▼                      ▼
┌─────────────────────┐  ┌────────────────────┐  ┌───────────────────┐
│                     │  │                    │  │                   │
│ Account & Billing   │  │ Clio Integration   │  │  Data Service     │
│ Service             │  │ Service            │  │  (Node.js/Express)│
│                     │  │                    │  │                   │
└─────────────────────┘  └────────────────────┘  └───────────────────┘
          │                        │                      │
          │                        │                      │
          └──────────┬─────────────┴──────────┬───────────┘
                     │                        │
                     ▼                        ▼
         ┌────────────────────┐    ┌────────────────────┐
         │                    │    │                    │
         │ Notifications      │    │ UI Service         │
         │ Service            │    │ (Node.js/Next.js)  │
         │                    │    │                    │
         └────────────────────┘    └────────────────────┘
                     │                        │
                     │                        │
                     └──────────┬─────────────┘
                                │
                                ▼
                     ┌────────────────────┐
                     │                    │
                     │ PostgreSQL + Redis │
                     │                    │
                     └────────────────────┘
```

## Implementation Status

| Service | Status | Description |
|---------|--------|-------------|
| Common-Models | ✅ Complete | Shared types, interfaces, validation schemas, BigInt support |
| Auth Service | ✅ Complete | User authentication, authorization, password reset, email verification |
| API Gateway | 🔄 In Progress | Service routing, authentication, caching, documentation |
| Clio Integration | 🔄 In Progress | OAuth flow, data synchronization, webhooks, metrics |
| UI Service | 🔄 In Progress | Authentication components, dashboard layouts, client views |
| Data Service | ⏳ Planned | Analytics calculations, report generation, data warehouse |
| Notifications Service | ⏳ Planned | Email, SMS, in-app notifications, alert management |
| Account & Billing | ⏳ Planned | Subscription management, invoicing, payment processing |
| Onboarding App | ⏳ Planned | User registration, Clio connection setup, initial configuration |
| Dashboard App | ⏳ Planned | Interactive dashboards, reporting, visualization |

## Service Communication Patterns

- **API Gateway**: Central entry point for all client requests, handles routing, authentication verification, rate limiting
- **Service-to-Service**: Direct API calls with JWT authentication for internal communication
- **Event-Based**: Webhooks for real-time updates from Clio
- **Shared Models**: Common-Models package for consistent data types across services

## Key Technical Decisions

- **Architecture**: Microservices with dedicated repositories for each component
- **Frontend**: Next.js, React, TypeScript, TailwindCSS
- **Backend**: Node.js, Express, Prisma ORM
- **Database**: PostgreSQL (primary data store), Redis (caching, queues, metrics)
- **Infrastructure**: AWS (ECS, RDS, ElastiCache, S3)
- **CI/CD**: GitHub Actions
- **Authentication**: JWT with refresh tokens
- **API Documentation**: OpenAPI/Swagger
- **Package Management**: Private npm registry for shared packages

## User Types

1. **Super Admin**: Smarter Firms platform administrators
2. **Admin**: Law firm administrators with full firm access
3. **User**: Standard users with configurable access levels
4. **Consultant**: External advisors with firm-level access

## Access Levels

1. **Whole Firm**: Access to all firm data
2. **Specific Users/Practice Areas**: Limited to designated subsets
3. **User Only**: Access to individual user data only

## Pricing Model

1. **Individual Plan**: $35/month per user
   - Single user access
   - Individual dashboard
   - Personal reporting

2. **Firm Plan**: $25/month per active Clio user
   - Whole firm access management
   - Configurable user access
   - Comprehensive reporting

## Project Objectives

1. Create a secure integration with Clio API
2. Build flexible reporting dashboards
3. Implement role-based access control
4. Deploy a scalable and cost-effective architecture
5. Ensure seamless onboarding experience
6. Create a subscription-based billing system 