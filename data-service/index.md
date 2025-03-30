# Data Service Documentation

The Data Service is responsible for managing all data access and storage for the Smarter Firms platform, with a particular focus on multi-tenant data isolation and security.

## Overview

The Data Service implements a robust multi-tenant architecture that ensures complete data isolation between law firms while enabling consultants to access data across multiple firms with appropriate permissions and security controls.

## Documentation Structure

- **[Multi-Tenant Implementation Guide](multi-tenant-implementation-guide.md)** - Overall architecture for multi-tenant data isolation
- **[Row-Level Security](row-level-security.md)** - Implementation details for PostgreSQL row-level security policies
- **[Repository Pattern](repository-pattern.md)** - How repositories enforce tenant isolation at the application level
- **[Cache Invalidation](cache-invalidation.md)** - Implementation of tenant-aware cache invalidation
- **[Key Rotation](key-rotation.md)** - Process for rotating encryption keys without service disruption
- **[Resilience Testing](resilience-testing.md)** - Testing strategy for tenant isolation under edge cases
- **[Query Optimization](query-optimization.md)** - Strategies for optimizing database queries
- **[Security Implementation](security-implementation.md)** - Security features including encryption and access control
- **[Database Migration Plan](database-migration-plan.md)** - Plan for database schema evolution

## Getting Started

### Prerequisites

- PostgreSQL 14+
- Redis 6+
- Node.js 18+
- Prisma ORM

### Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/Smarter-Firms/data-service.git
   ```

2. Install dependencies:
   ```bash
   cd data-service
   npm install
   ```

3. Configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env file with your configuration
   ```

4. Set up the database:
   ```bash
   npm run prisma:migrate
   npm run prisma:seed
   ```

5. Start the service:
   ```bash
   npm run dev
   ```

## Integration with Other Services

The Data Service integrates with other Smarter Firms services:

- **Auth Service** - For JWT validation and tenant identification
- **API Gateway** - For routing and tenant context propagation
- **UI Service** - For data retrieval and cross-firm analytics

## Security Features

- PostgreSQL Row-Level Security (RLS) for tenant isolation
- Encryption at rest for sensitive data
- Audit logging for all data modifications
- Tenant-aware caching with automatic invalidation
- Parameterized queries to prevent SQL injection

## Monitoring and Observability

The Data Service exposes metrics and logs that can be used to monitor its health and performance:

- Prometheus metrics at `/metrics`
- Structured logging with tenant context
- Database query performance tracing
- Cache hit/miss ratios by tenant

## Contributing

See the [Development Workflow](../operations/Development-Workflow.md) document for information on how to contribute to the Data Service. 