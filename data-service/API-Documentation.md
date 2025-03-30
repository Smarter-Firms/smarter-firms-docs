# API Documentation

## Base URL

```
https://api.smarterfirms.com/data-service/v1
```

## Authentication

All API requests require authentication using a Bearer token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

The token must include a valid `tenantId` claim for multi-tenant data isolation.

## Endpoints

### Health Check

#### Get Service Status

```
GET /health
```

Returns the health status of the service.

**Response:**

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2023-04-01T12:00:00Z",
  "services": {
    "database": "connected",
    "cache": "connected"
  }
}
```

### Analytics

#### Get Billable Hours Metrics

```
GET /analytics/billable-hours
```

Retrieves billable hours and utilization metrics across the firm.

**Query Parameters:**

| Parameter        | Type     | Required | Description                                |
|------------------|----------|----------|--------------------------------------------|
| startDate        | ISO Date | No       | Start date for filtering (default: 30 days ago) |
| endDate          | ISO Date | No       | End date for filtering (default: today)    |
| timekeeperId     | UUID     | No       | Filter by specific timekeeper              |
| practiceAreaId   | UUID     | No       | Filter by practice area                    |
| clientId         | UUID     | No       | Filter by client                           |

**Response:**

```json
{
  "totalBillableHours": 1250.5,
  "totalNonBillableHours": 420.25,
  "utilizationRate": 0.748,
  "targetUtilization": 0.75,
  "utilizationPercentage": 0.997,
  "utilizationByTimekeeper": [
    {
      "timekeeperId": "timekeeper-123",
      "timekeeperName": "Jane Smith",
      "billableHours": 165.5,
      "totalHours": 180.0,
      "utilization": 0.92,
      "percentageOfTarget": 1.23
    }
  ],
  "utilizationByPracticeArea": [
    {
      "practiceAreaId": "practice-123",
      "practiceAreaName": "Corporate",
      "billableHours": 725.0,
      "totalHours": 950.0,
      "utilization": 0.76
    }
  ],
  "timeEntryTrend": [
    {
      "date": "2023-01-01",
      "billableHours": 45.5,
      "nonBillableHours": 12.0,
      "utilization": 0.79
    }
  ]
}
```

#### Get Collection Rate Metrics

```
GET /analytics/collection-rates
```

Retrieves collection rate metrics for firm invoices.

**Query Parameters:**

| Parameter | Type     | Required | Description                                |
|-----------|----------|----------|--------------------------------------------|
| startDate | ISO Date | No       | Start date for filtering (default: 30 days ago) |
| endDate   | ISO Date | No       | End date for filtering (default: today)    |
| clientId  | UUID     | No       | Filter by specific client                  |
| status    | String   | No       | Filter by invoice status                   |

**Response:**

```json
{
  "totalInvoicedAmount": 450000.00,
  "totalCollectedAmount": 405000.00,
  "overallCollectionRate": 0.90,
  "targetCollectionRate": 0.90,
  "collectionPercentage": 1.0,
  "averageDaysToPayment": 32.5,
  "collectionsByClient": [
    {
      "clientId": "client-123",
      "clientName": "Acme Corporation",
      "invoicedAmount": 125000.00,
      "collectedAmount": 118750.00,
      "collectionRate": 0.95,
      "averageDaysToPayment": 28.3
    }
  ],
  "agingBuckets": [
    {
      "name": "Current",
      "amount": 150000.00,
      "percentage": 0.33
    },
    {
      "name": "1-30 days",
      "amount": 125000.00,
      "percentage": 0.28
    }
  ],
  "collectionTrend": [
    {
      "month": "2023-01",
      "invoicedAmount": 75000.00,
      "collectedAmount": 67500.00,
      "collectionRate": 0.90
    }
  ]
}
```

#### Get Matter Profitability Metrics

```
GET /analytics/matter-profitability
```

Retrieves profitability metrics for legal matters.

**Query Parameters:**

| Parameter        | Type     | Required | Description                                |
|------------------|----------|----------|--------------------------------------------|
| startDate        | ISO Date | No       | Start date for filtering (default: 30 days ago) |
| endDate          | ISO Date | No       | End date for filtering (default: today)    |
| clientId         | UUID     | No       | Filter by specific client                  |
| practiceAreaId   | UUID     | No       | Filter by practice area                    |
| matterId         | UUID     | No       | Filter by specific matter                  |

**Response:**

```json
{
  "totalRevenue": 100000,
  "totalCost": 60000,
  "overallProfitMargin": 0.4,
  "mattersByProfitability": [
    {
      "matterId": "matter-1",
      "matterName": "Corporate Restructuring",
      "clientName": "Acme Inc",
      "revenue": 25000,
      "cost": 12500,
      "profit": 12500,
      "profitMargin": 0.5
    }
  ],
  "profitabilityByPracticeArea": [
    {
      "practiceAreaId": "practice-1",
      "practiceAreaName": "Corporate",
      "revenue": 50000,
      "cost": 30000,
      "profit": 20000,
      "profitMargin": 0.4
    }
  ]
}
```

#### Get Client Value Metrics

```
GET /analytics/client-value
```

Retrieves value metrics for clients.

**Query Parameters:**

| Parameter      | Type     | Required | Description                                |
|----------------|----------|----------|--------------------------------------------|
| startDate      | ISO Date | No       | Start date for filtering (default: 30 days ago) |
| endDate        | ISO Date | No       | End date for filtering (default: today)    |
| clientId       | UUID     | No       | Filter by specific client                  |
| type           | String   | No       | Filter by client type                      |

**Response:**

```json
{
  "totalClientRevenue": 500000,
  "clientsByValue": [
    {
      "clientId": "client-1",
      "clientName": "Acme Inc",
      "revenue": 150000,
      "activeMatters": 3,
      "billableHours": 500,
      "collectionRate": 0.95,
      "clientScore": 95
    }
  ],
  "clientsByLongevity": [
    {
      "clientId": "client-1",
      "clientName": "Acme Inc",
      "relationshipDuration": 5,
      "totalRevenue": 750000,
      "averageAnnualRevenue": 150000
    }
  ],
  "clientAcquisitionTrend": [
    {
      "month": "2023-01",
      "newClients": 2,
      "churnedClients": 0,
      "netGrowth": 2
    }
  ]
}
```

#### Get Analytics Overview

```
GET /analytics/overview
```

Retrieves a comprehensive overview of key metrics for dashboard display.

**Query Parameters:**

| Parameter | Type     | Required | Description                                |
|-----------|----------|----------|--------------------------------------------|
| startDate | ISO Date | No       | Start date for filtering (default: 30 days ago) |
| endDate   | ISO Date | No       | End date for filtering (default: today)    |

**Response:**

```json
{
  "period": {
    "startDate": "2023-03-01T00:00:00Z",
    "endDate": "2023-03-31T23:59:59Z"
  },
  "keyMetrics": {
    "utilizationRate": 0.748,
    "utilizationPercentage": 0.997,
    "collectionRate": 0.90,
    "collectionPercentage": 1.0,
    "averageDaysToPayment": 32.5,
    "totalBillableHours": 1250.5,
    "totalInvoicedAmount": 450000.00,
    "totalCollectedAmount": 405000.00
  },
  "topTimekeepers": [
    {
      "timekeeperId": "timekeeper-123",
      "timekeeperName": "Jane Smith",
      "billableHours": 165.5,
      "utilization": 0.92
    }
  ],
  "topClients": [
    {
      "clientId": "client-123",
      "clientName": "Acme Corporation",
      "invoicedAmount": 125000.00,
      "collectionRate": 0.95
    }
  ],
  "timeEntryTrend": [
    {
      "date": "2023-03-01",
      "billableHours": 45.5,
      "utilization": 0.79
    }
  ],
  "collectionTrend": [
    {
      "month": "2023-03",
      "invoicedAmount": 75000.00,
      "collectionRate": 0.90
    }
  ],
  "agingReceivables": [
    {
      "name": "Current",
      "amount": 150000.00,
      "percentage": 0.33
    }
  ]
}
```

### Data Access

#### Get Matters

```
GET /matters
```

Retrieves a list of legal matters.

**Query Parameters:**

| Parameter           | Type     | Required | Description                                |
|---------------------|----------|----------|--------------------------------------------|
| clientId            | UUID     | No       | Filter by client                           |
| practiceAreaId      | UUID     | No       | Filter by practice area                    |
| responsibleAttorneyId | UUID   | No       | Filter by responsible attorney             |
| status              | String   | No       | Filter by status (active, inactive, closed) |
| billingType         | String   | No       | Filter by billing type                     |
| startDate           | ISO Date | No       | Filter by open date range start            |
| endDate             | ISO Date | No       | Filter by open date range end              |
| isConfidential      | Boolean  | No       | Filter by confidentiality                  |
| searchTerm          | String   | No       | Search in name, number, and description    |
| page                | Integer  | No       | Page number (default: 1)                   |
| limit               | Integer  | No       | Items per page (default: 20, max: 100)     |

**Response:**

```json
{
  "data": [
    {
      "id": "matter-1",
      "tenantId": "tenant-1",
      "clientId": "client-1",
      "practiceAreaId": "practice-1",
      "responsibleAttorneyId": "attorney-1",
      "name": "Corporate Restructuring",
      "description": "Major restructuring of corporate entities",
      "matterNumber": "M-2023-001",
      "status": "active",
      "billingType": "hourly",
      "hourlyRate": 350.00,
      "isConfidential": false,
      "openDate": "2023-01-15T00:00:00Z",
      "client": {
        "id": "client-1",
        "name": "Acme Inc"
      },
      "practiceArea": {
        "id": "practice-1",
        "name": "Corporate"
      },
      "responsibleAttorney": {
        "id": "attorney-1",
        "name": "John Smith"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "pages": 1
  }
}
```

#### Get Clients

```
GET /clients
```

Retrieves a list of clients.

**Query Parameters:**

| Parameter         | Type     | Required | Description                                |
|-------------------|----------|----------|--------------------------------------------|
| status            | String   | No       | Filter by status (active, inactive, lead, former) |
| type              | String   | No       | Filter by type (individual, company, etc.) |
| primaryAttorneyId | UUID     | No       | Filter by primary attorney                 |
| startDate         | ISO Date | No       | Filter by onboarding date range start      |
| endDate           | ISO Date | No       | Filter by onboarding date range end        |
| searchTerm        | String   | No       | Search in name, email, contact person      |
| page              | Integer  | No       | Page number (default: 1)                   |
| limit             | Integer  | No       | Items per page (default: 20, max: 100)     |

**Response:**

```json
{
  "data": [
    {
      "id": "client-1",
      "tenantId": "tenant-1",
      "name": "Acme Inc",
      "type": "company",
      "status": "active",
      "contactPersonName": "Jane Smith",
      "email": "jane@acme.com",
      "phone": "555-123-4567",
      "address": "123 Main St",
      "city": "Metropolis",
      "state": "NY",
      "zipCode": "10001",
      "country": "USA",
      "primaryAttorneyId": "attorney-1",
      "onboardingDate": "2022-01-15T00:00:00Z",
      "primaryAttorney": {
        "id": "attorney-1",
        "name": "John Smith"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "pages": 1
  }
}
```

#### Get Time Entries

```
GET /time-entries
```

Retrieves a list of time entries.

**Query Parameters:**

| Parameter     | Type     | Required | Description                                |
|---------------|----------|----------|--------------------------------------------|
| timekeeperId  | UUID     | No       | Filter by timekeeper                       |
| matterId      | UUID     | No       | Filter by matter                           |
| clientId      | UUID     | No       | Filter by client associated with matters   |
| startDate     | ISO Date | No       | Filter by date range start                 |
| endDate       | ISO Date | No       | Filter by date range end                   |
| status        | String   | No       | Filter by status                           |
| billableStatus| String   | No       | Filter by billable status                  |
| invoiceId     | UUID     | No       | Filter by invoice                          |
| activityCode  | String   | No       | Filter by activity code                    |
| searchTerm    | String   | No       | Search in description                      |
| page          | Integer  | No       | Page number (default: 1)                   |
| limit         | Integer  | No       | Items per page (default: 20, max: 100)     |

**Response:**

```json
{
  "data": [
    {
      "id": "timeentry-1",
      "tenantId": "tenant-1",
      "timekeeperId": "timekeeper-1",
      "matterId": "matter-1",
      "date": "2023-03-15T00:00:00Z",
      "duration": 120,
      "description": "Drafted contract review memo",
      "status": "approved",
      "billableStatus": "billable",
      "activityCode": "DRAFT",
      "rate": 350.00,
      "timekeeper": {
        "id": "timekeeper-1",
        "name": "Jane Smith"
      },
      "matter": {
        "id": "matter-1",
        "name": "Corporate Restructuring",
        "client": {
          "id": "client-1",
          "name": "Acme Inc"
        }
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "pages": 1
  }
}
```

#### Get Invoices

```
GET /invoices
```

Retrieves a list of invoices.

**Query Parameters:**

| Parameter  | Type     | Required | Description                                |
|------------|----------|----------|--------------------------------------------|
| clientId   | UUID     | No       | Filter by client                           |
| status     | String   | No       | Filter by status                           |
| startDate  | ISO Date | No       | Filter by issue date range start           |
| endDate    | ISO Date | No       | Filter by issue date range end             |
| minAmount  | Number   | No       | Filter by minimum amount                   |
| maxAmount  | Number   | No       | Filter by maximum amount                   |
| isOverdue  | Boolean  | No       | Filter to only show overdue invoices       |
| searchTerm | String   | No       | Search in invoice number or notes          |
| page       | Integer  | No       | Page number (default: 1)                   |
| limit      | Integer  | No       | Items per page (default: 20, max: 100)     |

**Response:**

```json
{
  "data": [
    {
      "id": "invoice-1",
      "tenantId": "tenant-1",
      "clientId": "client-1",
      "invoiceNumber": "INV-2023-001",
      "status": "sent",
      "issueDate": "2023-03-01T00:00:00Z",
      "dueDate": "2023-04-01T00:00:00Z",
      "subtotal": 10000.00,
      "taxAmount": 0.00,
      "discount": 0.00,
      "total": 10000.00,
      "balance": 10000.00,
      "sentDate": "2023-03-01T12:30:00Z",
      "client": {
        "id": "client-1",
        "name": "Acme Inc"
      },
      "payments": [
        {
          "id": "payment-1",
          "amount": 5000.00,
          "paymentDate": "2023-03-15T00:00:00Z",
          "paymentMethod": "bank transfer"
        }
      ]
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "pages": 1
  }
}
```

### Export

#### Create CSV Export

```
POST /export/csv
```

Initiates a CSV export job.

**Request Body:**

```json
{
  "dataSource": "matters",
  "parameters": {
    "clientId": "client-1",
    "status": "active"
  }
}
```

**Response:**

```json
{
  "id": "export-1",
  "format": "csv",
  "status": "pending",
  "dataSource": "matters",
  "parameters": {
    "clientId": "client-1",
    "status": "active"
  },
  "createdAt": "2023-04-01T12:00:00Z",
  "expiresAt": "2023-04-02T12:00:00Z"
}
```

#### Create Excel Export

```
POST /export/excel
```

Initiates an Excel export job.

**Request Body:**

```json
{
  "dataSource": "time-entries",
  "parameters": {
    "matterId": "matter-1",
    "startDate": "2023-01-01T00:00:00Z",
    "endDate": "2023-03-31T23:59:59Z"
  }
}
```

**Response:**

```json
{
  "id": "export-2",
  "format": "excel",
  "status": "pending",
  "dataSource": "time-entries",
  "parameters": {
    "matterId": "matter-1",
    "startDate": "2023-01-01T00:00:00Z",
    "endDate": "2023-03-31T23:59:59Z"
  },
  "createdAt": "2023-04-01T12:05:00Z",
  "expiresAt": "2023-04-02T12:05:00Z"
}
```

#### Create PDF Export

```
POST /export/pdf
```

Initiates a PDF export job.

**Request Body:**

```json
{
  "dataSource": "invoices",
  "parameters": {
    "clientId": "client-1",
    "status": "sent"
  }
}
```

**Response:**

```json
{
  "id": "export-3",
  "format": "pdf",
  "status": "pending",
  "dataSource": "invoices",
  "parameters": {
    "clientId": "client-1",
    "status": "sent"
  },
  "createdAt": "2023-04-01T12:10:00Z",
  "expiresAt": "2023-04-02T12:10:00Z"
}
```

#### Get Export Status

```
GET /export/status/:exportId
```

Checks the status of an export job.

**Path Parameters:**

| Parameter | Type   | Required | Description        |
|-----------|--------|----------|--------------------|
| exportId  | UUID   | Yes      | ID of export job   |

**Response:**

```json
{
  "id": "export-1",
  "format": "csv",
  "status": "completed",
  "dataSource": "matters",
  "parameters": {
    "clientId": "client-1",
    "status": "active"
  },
  "progress": 100,
  "createdAt": "2023-04-01T12:00:00Z",
  "completedAt": "2023-04-01T12:01:30Z",
  "expiresAt": "2023-04-02T12:00:00Z"
}
```

#### Download Export

```
GET /export/download/:exportId
```

Downloads the exported file.

**Path Parameters:**

| Parameter | Type   | Required | Description        |
|-----------|--------|----------|--------------------|
| exportId  | UUID   | Yes      | ID of export job   |

**Response:**

The file is returned with appropriate Content-Type and Content-Disposition headers.

## Error Responses

The API uses standard HTTP status codes to indicate the success or failure of requests:

- 200 OK: Request succeeded
- 201 Created: Resource was successfully created
- 400 Bad Request: Invalid request parameters
- 401 Unauthorized: Authentication failure
- 403 Forbidden: Permission denied
- 404 Not Found: Resource not found
- 429 Too Many Requests: Rate limit exceeded
- 500 Internal Server Error: Server error

Error responses follow this format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid parameter value",
    "details": [
      {
        "field": "startDate",
        "message": "Must be a valid ISO date string"
      }
    ]
  }
}
``` 