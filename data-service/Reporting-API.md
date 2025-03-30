# Reporting API Documentation

## Overview

The Reporting API provides access to pre-built reports and custom report generation capabilities for the Smarter Firms platform. Reports combine data from multiple sources, apply business logic and calculations, and deliver structured insights into law firm performance.

## API Endpoints

### Financial Summary Report

```
GET /api/v1/reports/financial-summary
```

Retrieves a comprehensive financial summary report for the firm.

**Query Parameters:**
- `startDate`: (Optional) Start date for the report period (YYYY-MM-DD)
- `endDate`: (Optional) End date for the report period (YYYY-MM-DD)
- `timeframe`: (Optional) Predefined timeframe - `last_30_days`, `last_90_days`, `last_12_months`, `year_to_date`
- `practiceAreaId`: (Optional) Filter by practice area
- `format`: (Optional) Response format - `json` (default), `csv`, `excel`

**Response:**
```json
{
  "success": true,
  "data": {
    "title": "Financial Summary Report",
    "period": "2023-01-01 to 2023-12-31",
    "summary": {
      "revenue": 1250000,
      "expenses": 750000,
      "profit": 500000,
      "margin": 0.4,
      "realization": 0.85,
      "collectionRate": 0.92
    },
    "trending": {
      "revenues": [...],
      "collections": [...],
      "expenses": [...]
    },
    "practiceAreas": [
      {
        "name": "Corporate",
        "revenue": 450000,
        "expenses": 270000,
        "profit": 180000,
        "margin": 0.4
      },
      ...
    ],
    "topClients": [...],
    "topMatters": [...]
  }
}
```

### Timekeeper Performance Report

```
GET /api/v1/reports/timekeeper-performance
```

Retrieves performance metrics for timekeepers.

**Query Parameters:**
- `startDate`: (Optional) Start date for the report period (YYYY-MM-DD)
- `endDate`: (Optional) End date for the report period (YYYY-MM-DD)
- `timeframe`: (Optional) Predefined timeframe - `last_30_days`, `last_90_days`, `last_12_months`, `year_to_date`
- `timekeeperId`: (Optional) Filter by specific timekeeper
- `practiceAreaId`: (Optional) Filter by practice area
- `role`: (Optional) Filter by timekeeper role
- `metricType`: (Optional) Focus on specific metrics - `utilization`, `realization`, `profitability`, `all`
- `format`: (Optional) Response format - `json` (default), `csv`, `excel`

**Response:**
```json
{
  "success": true,
  "data": {
    "title": "Timekeeper Performance Report",
    "period": "Last 90 days",
    "summary": {
      "averageUtilization": 0.78,
      "averageBillableHours": 145,
      "averageRealization": 0.85,
      "targetUtilization": 0.80
    },
    "timekeepers": [
      {
        "id": "tk-1",
        "name": "John Smith",
        "role": "Partner",
        "billableHours": 165,
        "utilization": 0.83,
        "billedAmount": 82500,
        "collectedAmount": 74250,
        "realization": 0.90,
        "variance": {
          "utilizationVsTarget": 0.03,
          "realizationVsAverage": 0.05
        }
      },
      ...
    ],
    "trends": {
      "utilization": [...],
      "billableHours": [...],
      "collections": [...]
    }
  }
}
```

### Client Billing Report

```
GET /api/v1/reports/client-billing
```

Retrieves billing information for clients.

**Query Parameters:**
- `startDate`: (Optional) Start date for the report period (YYYY-MM-DD)
- `endDate`: (Optional) End date for the report period (YYYY-MM-DD)
- `timeframe`: (Optional) Predefined timeframe - `last_30_days`, `last_90_days`, `last_12_months`, `year_to_date`
- `clientId`: (Optional) Filter by specific client
- `status`: (Optional) Filter by invoice status - `paid`, `unpaid`, `partial`, `all`
- `agingBucket`: (Optional) Filter by aging bucket - `current`, `30_days`, `60_days`, `90_days`, `over_90_days`
- `format`: (Optional) Response format - `json` (default), `csv`, `excel`

**Response:**
```json
{
  "success": true,
  "data": {
    "title": "Client Billing Report",
    "period": "2023-01-01 to 2023-06-30",
    "summary": {
      "totalBilled": 850000,
      "totalCollected": 735000,
      "outstandingBalance": 115000,
      "averageDaysToCollect": 42
    },
    "agingBuckets": [
      {
        "name": "Current",
        "amount": 45000,
        "percentage": 39.1
      },
      {
        "name": "1-30 Days",
        "amount": 32000,
        "percentage": 27.8
      },
      ...
    ],
    "clients": [
      {
        "id": "client-1",
        "name": "Acme Corporation",
        "billed": 125000,
        "collected": 105000,
        "outstanding": 20000,
        "aging": {
          "current": 8000,
          "30_days": 7000,
          "60_days": 5000,
          "90_days": 0,
          "over_90_days": 0
        },
        "invoices": [...]
      },
      ...
    ]
  }
}
```

### Matter Status Report

```
GET /api/v1/reports/matter-status
```

Retrieves status information for matters.

**Query Parameters:**
- `clientId`: (Optional) Filter by specific client
- `practiceAreaId`: (Optional) Filter by practice area
- `status`: (Optional) Filter by matter status - `active`, `inactive`, `pending`, `closed`, `all`
- `responsibleAttorneyId`: (Optional) Filter by responsible attorney
- `openedAfter`: (Optional) Filter matters opened after date (YYYY-MM-DD)
- `openedBefore`: (Optional) Filter matters opened before date (YYYY-MM-DD)
- `format`: (Optional) Response format - `json` (default), `csv`, `excel`

**Response:**
```json
{
  "success": true,
  "data": {
    "title": "Matter Status Report",
    "asOf": "2023-07-01",
    "summary": {
      "totalMatters": 85,
      "activeMatters": 62,
      "inactiveMatters": 8,
      "closedMatters": 15,
      "newMattersLast30Days": 5
    },
    "byPracticeArea": [
      {
        "name": "Litigation",
        "total": 32,
        "active": 24,
        "inactive": 3,
        "closed": 5
      },
      ...
    ],
    "byResponsibleAttorney": [...],
    "matters": [
      {
        "id": "matter-1",
        "name": "Smith v. Johnson",
        "client": "Acme Corporation",
        "status": "active",
        "openDate": "2023-01-15",
        "practiceArea": "Litigation",
        "responsibleAttorney": "Jane Doe",
        "lastActivityDate": "2023-06-28",
        "billedToDate": 75000,
        "unbilledWork": 12500
      },
      ...
    ]
  }
}
```

## Custom Report Generation

```
POST /api/v1/reports/custom
```

Generates a custom report based on specified parameters.

**Request Body:**
```json
{
  "title": "Custom Practice Area Performance",
  "metrics": [
    "billable_hours",
    "collection_rate",
    "profit_margin"
  ],
  "dimensions": [
    "practice_area",
    "month"
  ],
  "filters": {
    "startDate": "2023-01-01",
    "endDate": "2023-06-30",
    "practiceAreaIds": ["pa-1", "pa-2"]
  },
  "sortBy": "profit_margin",
  "sortOrder": "desc",
  "format": "json"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "title": "Custom Practice Area Performance",
    "period": "2023-01-01 to 2023-06-30",
    "dimensions": ["practice_area", "month"],
    "results": [
      {
        "practice_area": "Corporate",
        "month": "January",
        "billable_hours": 1250,
        "collection_rate": 0.92,
        "profit_margin": 0.45
      },
      ...
    ]
  }
}
```

## Report Scheduling

```
POST /api/v1/reports/schedule
```

Schedules a report to be generated and delivered on a recurring basis.

**Request Body:**
```json
{
  "reportType": "financial-summary",
  "parameters": {
    "timeframe": "last_30_days",
    "format": "excel"
  },
  "schedule": {
    "frequency": "monthly",
    "dayOfMonth": 1,
    "time": "08:00"
  },
  "delivery": {
    "method": "email",
    "recipients": ["user@example.com"],
    "subject": "Monthly Financial Summary"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "scheduleId": "sched-123",
    "reportType": "financial-summary",
    "nextDelivery": "2023-08-01T08:00:00Z",
    "message": "Report scheduled successfully"
  }
}
```

## Implementation Details

### Report Engine

The reporting system is built on a modular report engine that:

1. **Validates requests** against defined schemas
2. **Fetches data** from repositories with proper tenant isolation
3. **Processes data** through specialized calculators and transformers
4. **Formats output** according to requested format
5. **Caches results** for improved performance

### Report Templates

Each standard report is defined by a template that specifies:

- Required and optional parameters
- Data sources and repositories to query
- Calculations and transformations to apply
- Output format and structure

### Custom Report Builder

The custom report builder allows flexible report creation by:

- Combining multiple metrics and dimensions
- Applying filters across different entities
- Supporting complex sorting and grouping
- Enabling pivoting and cross-tabulation

### Performance Optimization

To ensure responsive report generation, the system employs:

- **Query optimization** to minimize database load
- **Parallel processing** for independent data retrieval
- **Incremental calculations** for time-based metrics
- **Result caching** with appropriate invalidation strategies
- **Background processing** for large reports

### Security Considerations

All reports enforce proper access controls:

- **Tenant isolation** ensures data is scoped to the user's tenant
- **Permission checking** verifies access to requested data
- **Field-level security** filters sensitive information
- **Output sanitization** prevents data exposure
- **Rate limiting** prevents abuse of the reporting API

## Error Handling

The API provides clear error messages for common issues:

- **Validation errors** for invalid parameters
- **Permission errors** for unauthorized access
- **Resource not found** errors for non-existent entities
- **Processing errors** for calculation failures
- **Timeout errors** for expensive reports

## Data Retention

Report data is subject to the following retention policies:

- Generated reports are retained for 30 days
- Report schedules are retained until explicitly deleted
- Report delivery logs are retained for 90 days 