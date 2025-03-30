# Database Schema

## Overview

The Data Service uses PostgreSQL with Prisma ORM to manage the data layer. This document outlines the database schema, relationships between entities, and key design decisions.

## Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    Client    │       │    Matter    │       │  TimeEntry   │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id           │       │ id           │       │ id           │
│ tenantId     │◄──┐   │ tenantId     │◄──┐   │ tenantId     │
│ name         │   │   │ clientId     │───┘   │ timekeeperId │───┐
│ type         │   │   │ practiceAreaId│      │ matterId     │───┘
│ status       │   │   │ name         │       │ date         │
│ email        │   │   │ description  │       │ duration     │
│ phone        │   │   │ matterNumber │       │ description  │
│ address      │   │   │ status       │       │ status       │
│ onboardingDate│  │   │ openDate     │       │ billableStatus│
│ primaryAttorneyId│  │   │ closeDate    │       │ rate         │
└──────────────┘   │   └──────────────┘       └──────────────┘
                  │                                  ▲
┌──────────────┐  │    ┌──────────────┐             │
│   Invoice    │  │    │  Timekeeper  │             │
├──────────────┤  │    ├──────────────┤             │
│ id           │  │    │ id           │             │
│ tenantId     │◄─┘    │ tenantId     │◄────────────┘
│ clientId     │───┘   │ name         │
│ invoiceNumber│       │ email        │
│ status       │       │ role         │
│ issueDate    │       │ rate         │
│ dueDate      │       │ title        │
│ subtotal     │       │ practiceAreaId│
│ total        │       │ status       │
└──────────────┘       └──────────────┘
       │
       │
       ▼
┌──────────────┐
│   Payment    │
├──────────────┤
│ id           │
│ tenantId     │
│ invoiceId    │
│ amount       │
│ paymentDate  │
│ paymentMethod│
└──────────────┘
```

## Multi-Tenant Architecture

Every table includes a `tenantId` column to ensure data isolation between different law firms using the platform. The `tenantId` is a non-nullable string field that is part of the composite primary key in most tables.

## Tables

### Tenant

Represents a law firm using the platform.

| Column       | Type      | Constraints       | Description                |
|--------------|-----------|-------------------|----------------------------|
| id           | String    | PK               | Unique identifier          |
| name         | String    | Not null         | Firm name                  |
| subdomain    | String    | Unique, not null | Firm's subdomain           |
| plan         | String    | Not null         | Subscription plan          |
| status       | String    | Not null         | active, inactive, trial    |
| createdAt    | DateTime  | Not null         | Creation timestamp         |
| updatedAt    | DateTime  | Not null         | Last update timestamp      |

### Client

Represents a client of a law firm.

| Column           | Type      | Constraints       | Description                |
|------------------|-----------|-------------------|----------------------------|
| id               | String    | PK               | Unique identifier          |
| tenantId         | String    | PK, FK           | Reference to Tenant        |
| name             | String    | Not null         | Client name                |
| type             | String    | Not null         | individual, company, etc.  |
| status           | String    | Not null         | active, inactive, lead     |
| contactPersonName| String    |                  | Primary contact person     |
| email            | String    |                  | Primary email              |
| phone            | String    |                  | Primary phone              |
| address          | String    |                  | Street address             |
| city             | String    |                  | City                       |
| state            | String    |                  | State/Province             |
| zipCode          | String    |                  | Postal/ZIP code            |
| country          | String    |                  | Country                    |
| primaryAttorneyId| String    | FK               | Primary attorney reference |
| onboardingDate   | DateTime  |                  | Client onboarding date     |
| createdAt        | DateTime  | Not null         | Creation timestamp         |
| updatedAt        | DateTime  | Not null         | Last update timestamp      |
| isDeleted        | Boolean   | Not null, default| Soft delete flag           |

### Matter

Represents a legal matter/case.

| Column              | Type      | Constraints       | Description                  |
|---------------------|-----------|-------------------|------------------------------|
| id                  | String    | PK               | Unique identifier            |
| tenantId            | String    | PK, FK           | Reference to Tenant          |
| clientId            | String    | FK, Not null     | Reference to Client          |
| practiceAreaId      | String    | FK               | Reference to PracticeArea    |
| responsibleAttorneyId| String   | FK               | Attorney managing the matter |
| name                | String    | Not null         | Matter name                  |
| description         | String    |                  | Matter description           |
| matterNumber        | String    | Not null         | Business reference number    |
| status              | String    | Not null         | active, inactive, closed     |
| billingType         | String    | Not null         | hourly, fixed, contingency   |
| hourlyRate          | Decimal   |                  | Default hourly rate          |
| fixedFeeAmount      | Decimal   |                  | Fixed fee amount if applicable|
| isConfidential      | Boolean   | Not null, default| Confidentiality flag         |
| openDate            | DateTime  | Not null         | Date matter was opened       |
| closeDate           | DateTime  |                  | Date matter was closed       |
| createdAt           | DateTime  | Not null         | Creation timestamp           |
| updatedAt           | DateTime  | Not null         | Last update timestamp        |
| isDeleted           | Boolean   | Not null, default| Soft delete flag             |

### Timekeeper

Represents attorneys and staff who record time.

| Column         | Type      | Constraints       | Description                |
|----------------|-----------|-------------------|----------------------------|
| id             | String    | PK               | Unique identifier          |
| tenantId       | String    | PK, FK           | Reference to Tenant        |
| userId         | String    | Unique           | Reference to user account  |
| name           | String    | Not null         | Timekeeper name            |
| email          | String    | Not null         | Email address              |
| role           | String    | Not null         | attorney, paralegal, etc.  |
| title          | String    |                  | Job title                  |
| rate           | Decimal   | Not null         | Default billing rate       |
| practiceAreaId | String    | FK               | Primary practice area      |
| status         | String    | Not null         | active, inactive           |
| createdAt      | DateTime  | Not null         | Creation timestamp         |
| updatedAt      | DateTime  | Not null         | Last update timestamp      |
| isDeleted      | Boolean   | Not null, default| Soft delete flag           |

### TimeEntry

Represents recorded time for billing purposes.

| Column         | Type      | Constraints       | Description                |
|----------------|-----------|-------------------|----------------------------|
| id             | String    | PK               | Unique identifier          |
| tenantId       | String    | PK, FK           | Reference to Tenant        |
| timekeeperId   | String    | FK, Not null     | Timekeeper reference       |
| matterId       | String    | FK, Not null     | Matter reference           |
| date           | DateTime  | Not null         | Date of work performed     |
| duration       | Integer   | Not null         | Duration in minutes        |
| description    | String    | Not null         | Description of work        |
| status         | String    | Not null         | draft, submitted, approved |
| billableStatus | String    | Not null         | billable, non-billable     |
| rate           | Decimal   | Not null         | Billing rate used          |
| activityCode   | String    |                  | Activity category code     |
| invoiceId      | String    | FK               | Invoice if billed          |
| createdAt      | DateTime  | Not null         | Creation timestamp         |
| updatedAt      | DateTime  | Not null         | Last update timestamp      |
| isDeleted      | Boolean   | Not null, default| Soft delete flag           |

### Invoice

Represents a bill sent to clients.

| Column        | Type      | Constraints       | Description                 |
|---------------|-----------|-------------------|-----------------------------|
| id            | String    | PK               | Unique identifier           |
| tenantId      | String    | PK, FK           | Reference to Tenant         |
| clientId      | String    | FK, Not null     | Client reference            |
| invoiceNumber | String    | Not null         | Business reference number   |
| status        | String    | Not null         | draft, sent, paid, void     |
| issueDate     | DateTime  | Not null         | Date invoice was issued     |
| dueDate       | DateTime  | Not null         | Payment due date            |
| subtotal      | Decimal   | Not null         | Sum before adjustments      |
| taxAmount     | Decimal   | Not null         | Tax amount                  |
| discount      | Decimal   | Not null         | Discount amount             |
| total         | Decimal   | Not null         | Final invoice amount        |
| balance       | Decimal   | Not null         | Remaining amount due        |
| notes         | String    |                  | Invoice notes               |
| sentDate      | DateTime  |                  | Date sent to client         |
| paidDate      | DateTime  |                  | Date fully paid             |
| createdAt     | DateTime  | Not null         | Creation timestamp          |
| updatedAt     | DateTime  | Not null         | Last update timestamp       |
| isDeleted     | Boolean   | Not null, default | Soft delete flag            |

### Payment

Represents payments received for invoices.

| Column        | Type      | Constraints       | Description                |
|---------------|-----------|-------------------|----------------------------|
| id            | String    | PK               | Unique identifier          |
| tenantId      | String    | PK, FK           | Reference to Tenant        |
| invoiceId     | String    | FK, Not null     | Invoice reference          |
| amount        | Decimal   | Not null         | Payment amount             |
| paymentDate   | DateTime  | Not null         | Date payment received      |
| paymentMethod | String    | Not null         | Method of payment          |
| referenceNumber| String   |                  | Payment reference number   |
| notes         | String    |                  | Payment notes              |
| createdAt     | DateTime  | Not null         | Creation timestamp         |
| updatedAt     | DateTime  | Not null         | Last update timestamp      |
| isDeleted     | Boolean   | Not null, default| Soft delete flag           |

### PracticeArea

Represents areas of legal practice.

| Column        | Type      | Constraints       | Description                |
|---------------|-----------|-------------------|----------------------------|
| id            | String    | PK               | Unique identifier          |
| tenantId      | String    | PK, FK           | Reference to Tenant        |
| name          | String    | Not null         | Practice area name         |
| description   | String    |                  | Practice area description  |
| createdAt     | DateTime  | Not null         | Creation timestamp         |
| updatedAt     | DateTime  | Not null         | Last update timestamp      |
| isDeleted     | Boolean   | Not null, default| Soft delete flag           |

### ExportJob

Represents data export jobs.

| Column        | Type      | Constraints       | Description                |
|---------------|-----------|-------------------|----------------------------|
| id            | String    | PK               | Unique identifier          |
| tenantId      | String    | PK, FK           | Reference to Tenant        |
| userId        | String    | Not null         | User who created the export|
| dataSource    | String    | Not null         | Data entity being exported |
| format        | String    | Not null         | csv, excel, pdf            |
| status        | String    | Not null         | pending, processing, completed, failed |
| parameters    | Json      | Not null         | Export parameters          |
| filePath      | String    |                  | Path to exported file      |
| progress      | Integer   | Not null         | Progress percentage        |
| error         | String    |                  | Error message if failed    |
| createdAt     | DateTime  | Not null         | Creation timestamp         |
| completedAt   | DateTime  |                  | Completion timestamp       |
| expiresAt     | DateTime  | Not null         | Expiration timestamp       |

## Indexes

### Performance Indexes

| Table      | Columns                           | Type     | Purpose                               |
|------------|-----------------------------------|----------|---------------------------------------|
| Client     | (tenantId, status)                | BTREE    | Filter clients by status              |
| Matter     | (tenantId, clientId, status)      | BTREE    | Filter matters by client and status   |
| Matter     | (tenantId, status, openDate)      | BTREE    | Filter matters by status and date     |
| TimeEntry  | (tenantId, matterId, date)        | BTREE    | Filter time entries by matter and date|
| TimeEntry  | (tenantId, timekeeperId, date)    | BTREE    | Filter entries by timekeeper and date |
| TimeEntry  | (tenantId, status)                | BTREE    | Filter entries by status              |
| Invoice    | (tenantId, clientId, status)      | BTREE    | Filter invoices by client and status  |
| Invoice    | (tenantId, status, issueDate)     | BTREE    | Filter invoices by status and date    |
| Payment    | (tenantId, invoiceId)             | BTREE    | Look up payments for an invoice       |

### Full-Text Search Indexes

| Table      | Columns                          | Type     | Purpose                               |
|------------|----------------------------------|----------|---------------------------------------|
| Client     | (tenantId, name, email)          | GIN      | Full-text search for clients          |
| Matter     | (tenantId, name, description)    | GIN      | Full-text search for matters          |
| TimeEntry  | (tenantId, description)          | GIN      | Full-text search for time entries     |

## Schema Design Decisions

### Primary Keys

- All tables use UUID as the primary key format stored as strings
- Most tables use composite primary keys (id, tenantId) to ensure tenant isolation

### Soft Deletes

Most entities implement soft delete patterns with:
- `isDeleted` boolean field
- Indexes include WHERE isDeleted = false conditions
- Prisma middleware automatically filters deleted records

### Date Fields

- All timestamp fields use UTC timezone
- `createdAt` and `updatedAt` fields are maintained automatically by Prisma

### Foreign Keys

- All foreign keys have appropriate indexes
- All foreign keys are constrained with CASCADE for updates and RESTRICT for deletes

### Multi-Tenancy

- All queries include tenantId to maintain strict data isolation
- Enforced in code via Prisma middleware

## Database Migrations

- All schema changes are managed through Prisma Migrate
- Migration strategy follows these principles:
  - Additive changes preferred over destructive ones
  - Column renaming done in multiple steps (add new, migrate data, drop old)
  - Backward compatibility maintained during phased deployments

## Data Security

- Sensitive data is encrypted at rest
- Column-level encryption implemented for fields like:
  - Client.email
  - Client.phone
  - Payment.referenceNumber

## Performance Considerations

- Partitioning strategy for TimeEntry table based on tenantId
- Materialized views for frequently accessed analytics queries
- Aggressive indexing for most common query patterns 