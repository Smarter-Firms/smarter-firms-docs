# Data Service API Contract

## Overview

The Data Service API provides access to all data, analytics, and export functionality within the Smarter Firms platform. This document serves as a formal contract between the Data Service and its consumers.

## Base URL

```
https://api.smarterfirms.com/data-service/v1
```

## Authentication and Authorization

All API requests must include a valid Bearer token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

The token must include a valid `tenantId` claim for multi-tenant isolation. API endpoints will validate this token and ensure appropriate access control.

## Rate Limiting

- Standard rate limit: 100 requests per minute per API key
- Bulk operations: 20 requests per minute per API key

## Common Response Formats

### Success Response

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 157
  }
}
```

### Error Response

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid filter parameters provided",
    "details": { ... }
  }
}
```

## Pagination

All list endpoints support pagination with the following query parameters:

- `page`: Page number (defaults to 1)
- `limit`: Results per page (defaults to 20, max 100)

## API Endpoints

### Health Check

#### GET /health

Health check endpoint for monitoring and load balancers.

**Response:**

```json
{
  "status": "healthy",
  "version": "1.5.3",
  "timestamp": "2023-10-15T14:22:45Z"
}
```

### Analytics

#### GET /analytics/billable-hours

Retrieve billable hours utilization analytics.

**Parameters:**

- `startDate`: ISO 8601 date string (optional)
- `endDate`: ISO 8601 date string (optional)
- `timekeeperId`: Filter by timekeeper (optional)
- `practiceAreaId`: Filter by practice area (optional)

**Response:**

```json
{
  "success": true,
  "data": {
    "totalBillableHours": 3256.4,
    "totalNonBillableHours": 1243.2,
    "utilizationRate": 0.72,
    "targetUtilization": 0.75,
    "utilizationPercentage": 0.96,
    "utilizationByTimekeeper": [
      {
        "timekeeperId": "uuid",
        "timekeeperName": "Jane Smith",
        "billableHours": 156.3,
        "totalHours": 184.7,
        "utilization": 0.85,
        "percentageOfTarget": 1.13
      }
    ],
    "utilizationByPracticeArea": [
      {
        "practiceAreaId": "uuid",
        "practiceAreaName": "Corporate",
        "billableHours": 856.4,
        "totalHours": 1043.7,
        "utilization": 0.82
      }
    ],
    "timeEntryTrend": [
      {
        "date": "2023-09-15",
        "billableHours": 156.3,
        "nonBillableHours": 42.4,
        "utilization": 0.79
      }
    ]
  }
}
```

#### GET /analytics/collection-rates

Retrieve collection rate analytics.

**Parameters:**

- `startDate`: ISO 8601 date string (optional)
- `endDate`: ISO 8601 date string (optional)
- `clientId`: Filter by client (optional)

**Response:**

```json
{
  "success": true,
  "data": {
    "totalInvoicedAmount": 684250.75,
    "totalCollectedAmount": 623489.25,
    "overallCollectionRate": 0.91,
    "targetCollectionRate": 0.90,
    "collectionPercentage": 1.01,
    "averageDaysToPayment": 32.4,
    "collectionsByClient": [
      {
        "clientId": "uuid",
        "clientName": "Acme Inc",
        "invoicedAmount": 125400.50,
        "collectedAmount": 118750.25,
        "collectionRate": 0.95,
        "averageDaysToPayment": 28.3
      }
    ],
    "agingBuckets": [
      {
        "name": "Current",
        "amount": 125600.50,
        "percentage": 0.56
      },
      {
        "name": "1-30",
        "amount": 65480.25,
        "percentage": 0.28
      },
      {
        "name": "31-60",
        "amount": 23450.75,
        "percentage": 0.10
      },
      {
        "name": "61-90",
        "amount": 8540.50,
        "percentage": 0.04
      },
      {
        "name": "91+",
        "amount": 4680.25,
        "percentage": 0.02
      }
    ],
    "collectionTrend": [
      {
        "month": "2023-08",
        "invoicedAmount": 124500.75,
        "collectedAmount": 115680.50,
        "collectionRate": 0.93
      }
    ]
  }
}
```

#### GET /analytics/matter-profitability

Retrieve matter profitability analytics.

**Parameters:**

- `startDate`: ISO 8601 date string (optional)
- `endDate`: ISO 8601 date string (optional)
- `clientId`: Filter by client (optional)
- `practiceAreaId`: Filter by practice area (optional)

**Response:**

```json
{
  "success": true,
  "data": {
    "totalRevenue": 845625.50,
    "totalCost": 372865.25,
    "overallProfitMargin": 0.56,
    "mattersByProfitability": [
      {
        "matterId": "uuid",
        "matterName": "Smith Acquisition",
        "clientName": "Acme Inc",
        "revenue": 75250.50,
        "cost": 28450.25,
        "profit": 46800.25,
        "profitMargin": 0.62
      }
    ],
    "profitabilityByPracticeArea": [
      {
        "practiceAreaId": "uuid",
        "practiceAreaName": "Corporate",
        "revenue": 324560.75,
        "cost": 124589.25,
        "profit": 199971.50,
        "profitMargin": 0.62
      }
    ]
  }
}
```

#### GET /analytics/client-value

Retrieve client value analytics.

**Parameters:**

- `startDate`: ISO 8601 date string (optional)
- `endDate`: ISO 8601 date string (optional)
- `clientId`: Filter by client (optional)

**Response:**

```json
{
  "success": true,
  "data": {
    "totalClientRevenue": 1245680.50,
    "clientsByValue": [
      {
        "clientId": "uuid",
        "clientName": "Acme Inc",
        "revenue": 234569.75,
        "activeMatters": 12,
        "billableHours": 1245.5,
        "collectionRate": 0.94,
        "clientScore": 87
      }
    ],
    "clientsByLongevity": [
      {
        "clientId": "uuid",
        "clientName": "Johnson Corp",
        "relationshipDuration": 4.3,
        "totalRevenue": 856420.75,
        "averageAnnualRevenue": 198936.45
      }
    ],
    "clientAcquisitionTrend": [
      {
        "month": "2023-08",
        "newClients": 3,
        "churnedClients": 1,
        "netGrowth": 2
      }
    ]
  }
}
```

#### GET /analytics/overview

Retrieve overview of key metrics for dashboard.

**Parameters:**

- `startDate`: ISO 8601 date string (optional)
- `endDate`: ISO 8601 date string (optional)

**Response:**

```json
{
  "success": true,
  "data": {
    "period": {
      "startDate": "2023-09-01T00:00:00Z",
      "endDate": "2023-09-30T23:59:59Z"
    },
    "keyMetrics": {
      "utilizationRate": 0.73,
      "utilizationPercentage": 0.97,
      "collectionRate": 0.92,
      "collectionPercentage": 1.02,
      "averageDaysToPayment": 29.5,
      "totalBillableHours": 3256.4,
      "totalInvoicedAmount": 684250.75,
      "totalCollectedAmount": 623489.25,
      "profitMargin": 0.56,
      "totalRevenue": 845625.50,
      "totalCost": 372865.25,
      "totalClientRevenue": 1245680.50
    },
    "topTimekeepers": [...],
    "topClients": [...],
    "topMattersByProfitability": [...],
    "topClientsByValue": [...],
    "timeEntryTrend": [...],
    "collectionTrend": [...],
    "agingReceivables": [...],
    "clientAcquisitionTrend": [...],
    "profitabilityByPracticeArea": [...]
  }
}
```

### Data Access

#### GET /matters

Retrieve matters with optional filtering.

**Parameters:**

- `clientId`: Filter by client (optional)
- `practiceAreaId`: Filter by practice area (optional)
- `responsibleAttorneyId`: Filter by attorney (optional)
- `status`: Filter by status (optional)
- `startDate`: Filter by open date (optional)
- `endDate`: Filter by open date (optional)
- `searchTerm`: Search in name, number, or description (optional)
- `page`: Page number (defaults to 1)
- `limit`: Results per page (defaults to 20)

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Smith Acquisition",
      "matterNumber": "CORP-1234",
      "clientId": "uuid",
      "clientName": "Acme Inc",
      "practiceAreaId": "uuid",
      "practiceAreaName": "Corporate",
      "responsibleAttorneyId": "uuid",
      "responsibleAttorneyName": "Jane Smith",
      "status": "active",
      "billingType": "hourly",
      "openDate": "2023-05-15T00:00:00Z",
      "closeDate": null,
      "isConfidential": false
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 157
  }
}
```

#### GET /clients

Retrieve clients with optional filtering.

**Parameters:**

- `status`: Filter by status (optional)
- `primaryAttorneyId`: Filter by primary attorney (optional)
- `startDate`: Filter by onboarding date (optional)
- `endDate`: Filter by onboarding date (optional)
- `searchTerm`: Search in name, email, or contact person (optional)
- `page`: Page number (defaults to 1)
- `limit`: Results per page (defaults to 20)

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Acme Inc",
      "email": "billing@acme.com",
      "contactPersonName": "John Smith",
      "primaryAttorneyId": "uuid",
      "primaryAttorneyName": "Jane Smith",
      "status": "active",
      "onboardingDate": "2021-03-10T00:00:00Z",
      "activeMatters": 12,
      "totalRevenue": 234569.75
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 63
  }
}
```

#### GET /time-entries

Retrieve time entries with optional filtering.

**Parameters:**

- `timekeeperId`: Filter by timekeeper (optional)
- `matterId`: Filter by matter (optional)
- `clientId`: Filter by client (optional)
- `startDate`: Filter by date (optional)
- `endDate`: Filter by date (optional)
- `billableStatus`: Filter by billable status (optional)
- `searchTerm`: Search in description (optional)
- `page`: Page number (defaults to 1)
- `limit`: Results per page (defaults to 20)

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "timekeeperId": "uuid",
      "timekeeperName": "Jane Smith",
      "matterId": "uuid",
      "matterName": "Smith Acquisition",
      "clientId": "uuid",
      "clientName": "Acme Inc",
      "date": "2023-09-15T00:00:00Z",
      "duration": 120,
      "description": "Contract review and markup",
      "billableStatus": "billable",
      "rate": 350.00,
      "amount": 700.00
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 4325
  }
}
```

#### GET /invoices

Retrieve invoices with optional filtering.

**Parameters:**

- `clientId`: Filter by client (optional)
- `status`: Filter by status (optional)
- `startDate`: Filter by issue date (optional)
- `endDate`: Filter by issue date (optional)
- `minAmount`: Filter by minimum amount (optional)
- `maxAmount`: Filter by maximum amount (optional)
- `isOverdue`: Filter for overdue invoices (optional)
- `searchTerm`: Search in invoice number or notes (optional)
- `page`: Page number (defaults to 1)
- `limit`: Results per page (defaults to 20)

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "invoiceNumber": "INV-2023-1234",
      "clientId": "uuid",
      "clientName": "Acme Inc",
      "issueDate": "2023-09-01T00:00:00Z",
      "dueDate": "2023-10-01T00:00:00Z",
      "total": 12450.75,
      "balance": 4250.25,
      "status": "partial",
      "paidDate": null,
      "payments": [
        {
          "id": "uuid",
          "date": "2023-09-15T00:00:00Z",
          "amount": 8200.50,
          "method": "bankTransfer"
        }
      ]
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 358
  }
}
```

### Export

#### POST /exports

Create a new data export job.

**Request Body:**

```json
{
  "format": "csv",
  "dataSource": "matters",
  "filters": {
    "clientId": "uuid",
    "status": "active",
    "startDate": "2023-01-01T00:00:00Z",
    "endDate": "2023-09-30T23:59:59Z"
  },
  "columns": ["id", "name", "matterNumber", "clientName", "status", "openDate"]
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "exportId": "uuid",
    "status": "pending",
    "progress": 0,
    "createdAt": "2023-10-15T14:30:45Z",
    "expiresAt": "2023-10-16T14:30:45Z"
  }
}
```

#### GET /exports/{exportId}

Get export job status.

**Response:**

```json
{
  "success": true,
  "data": {
    "exportId": "uuid",
    "status": "processing",
    "progress": 45,
    "createdAt": "2023-10-15T14:30:45Z",
    "expiresAt": "2023-10-16T14:30:45Z",
    "format": "csv",
    "dataSource": "matters",
    "downloadUrl": null
  }
}
```

#### GET /exports/{exportId}/download

Download the export file. Will redirect to a signed URL for the file if it's ready.

**Response Headers:**
```
Content-Type: text/csv
Content-Disposition: attachment; filename="matters_export_2023-10-15.csv"
```

## Changes and Versioning

This API follows semantic versioning. Breaking changes will result in a new major version number in the URL path.

## Error Codes

- `AUTHENTICATION_ERROR`: Missing or invalid authentication token
- `AUTHORIZATION_ERROR`: Not authorized to access the requested resource
- `VALIDATION_ERROR`: Invalid request parameters
- `NOT_FOUND`: Requested resource doesn't exist
- `RATE_LIMIT_EXCEEDED`: Too many requests in a given time period
- `INTERNAL_ERROR`: Server-side error
- `EXPORT_ERROR`: Error during export generation

## API Integrations

The Data Service API should be used by:

1. Dashboard Service - For displaying analytics and reporting data
2. Web UI - For direct data access when needed
3. Mobile App - For data visualization and export capabilities
4. Business Intelligence Tools - For connecting to reporting endpoints

## Support

API support is available at api-support@smarterfirms.com 