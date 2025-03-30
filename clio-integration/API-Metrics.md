# Webhook Metrics API Documentation

This document details the API endpoints available for accessing webhook metrics in the Clio Integration Service.

## Base URL

All API endpoints are prefixed with: `/api/v1/metrics/webhooks`

## Authentication

All endpoints require authentication using an API key or JWT token, which should be included in the request header:

```
Authorization: Bearer <your-token>
```

## Available Endpoints

### Dashboard Metrics

Get a summary of the most important webhook metrics for dashboard display.

**Endpoint:** `GET /dashboard`

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "data": {
    "totalWebhooks": 1250,
    "successRate": 97.2,
    "averageProcessingTime": 124,
    "topEvents": [
      { "type": "Matter.created", "count": 320 },
      { "type": "Contact.updated", "count": 285 },
      { "type": "Matter.updated", "count": 210 }
    ],
    "topErrors": [
      { "type": "database_connection", "count": 15 },
      { "type": "validation_error", "count": 10 },
      { "type": "timeout", "count": 5 }
    ],
    "recentTrend": {
      "timestamps": ["2023-06-10T10:00:00Z", "2023-06-10T11:00:00Z", "2023-06-10T12:00:00Z"],
      "counts": [42, 55, 38],
      "successRates": [96.5, 98.2, 97.4]
    }
  }
}
```

### Daily Metrics

Get webhook metrics for a specific date.

**Endpoint:** `GET /daily/:date?`

**Parameters:**
- `date` (optional): Date in YYYY-MM-DD format. Defaults to current day if not provided.

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2023-06-10",
    "total": 1250,
    "successful": 1215,
    "failed": 35,
    "successRate": 97.2,
    "averageProcessingTime": 124,
    "hourlyBreakdown": [
      { "hour": 0, "count": 12, "successRate": 100 },
      { "hour": 1, "count": 8, "successRate": 100 },
      // ... more hours
      { "hour": 23, "count": 15, "successRate": 93.3 }
    ]
  }
}
```

### Event Type Metrics

Get metrics broken down by webhook event type.

**Endpoint:** `GET /events`

**Parameters:**
- `date` (optional): Date in YYYY-MM-DD format. Defaults to current day if not provided.
- `limit` (optional): Maximum number of event types to return. Defaults to 10.

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2023-06-10",
    "events": [
      {
        "type": "Matter.created",
        "count": 320,
        "successful": 315,
        "failed": 5,
        "successRate": 98.4,
        "averageProcessingTime": 118
      },
      {
        "type": "Contact.updated",
        "count": 285,
        "successful": 280,
        "failed": 5,
        "successRate": 98.2,
        "averageProcessingTime": 132
      },
      // ... more event types
    ]
  }
}
```

### Error Metrics

Get metrics for webhook processing errors.

**Endpoint:** `GET /errors`

**Parameters:**
- `date` (optional): Date in YYYY-MM-DD format. Defaults to current day if not provided.
- `limit` (optional): Maximum number of error types to return. Defaults to 10.

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2023-06-10",
    "totalErrors": 35,
    "errorRate": 2.8,
    "errors": [
      {
        "type": "database_connection",
        "count": 15,
        "percentage": 42.9,
        "affectedEvents": ["Matter.created", "Contact.updated"]
      },
      {
        "type": "validation_error",
        "count": 10,
        "percentage": 28.6,
        "affectedEvents": ["Matter.updated", "Contact.created"]
      },
      // ... more error types
    ]
  }
}
```

### Success Rate

Get webhook success rate over time.

**Endpoint:** `GET /success-rate/:date?`

**Parameters:**
- `date` (optional): Date in YYYY-MM-DD format. Defaults to current day if not provided.
- `interval` (optional): Time interval for data points. Options: "hourly" or "daily". Defaults to "hourly".
- `period` (optional): Number of intervals to return. Defaults to 24 for hourly, 7 for daily.

**Response:**
```json
{
  "success": true,
  "data": {
    "interval": "hourly",
    "dataPoints": [
      {
        "timestamp": "2023-06-10T00:00:00Z",
        "successRate": 100,
        "total": 12,
        "successful": 12,
        "failed": 0
      },
      {
        "timestamp": "2023-06-10T01:00:00Z",
        "successRate": 100,
        "total": 8,
        "successful": 8,
        "failed": 0
      },
      // ... more data points
    ]
  }
}
```

### Processing Time

Get webhook processing time metrics.

**Endpoint:** `GET /processing-time/:date?`

**Parameters:**
- `date` (optional): Date in YYYY-MM-DD format. Defaults to current day if not provided.
- `interval` (optional): Time interval for data points. Options: "hourly" or "daily". Defaults to "hourly".
- `period` (optional): Number of intervals to return. Defaults to 24 for hourly, 7 for daily.

**Response:**
```json
{
  "success": true,
  "data": {
    "interval": "hourly",
    "dataPoints": [
      {
        "timestamp": "2023-06-10T00:00:00Z",
        "average": 115,
        "min": 82,
        "max": 243,
        "p90": 180,
        "p95": 210,
        "count": 12
      },
      {
        "timestamp": "2023-06-10T01:00:00Z",
        "average": 124,
        "min": 90,
        "max": 210,
        "p90": 175,
        "p95": 195,
        "count": 8
      },
      // ... more data points
    ]
  }
}
```

## Error Responses

### Authentication Error

**Status Code:** 401 Unauthorized

```json
{
  "success": false,
  "error": {
    "code": "unauthorized",
    "message": "Authentication required"
  }
}
```

### Not Found Error

**Status Code:** 404 Not Found

```json
{
  "success": false,
  "error": {
    "code": "not_found",
    "message": "No metrics found for the specified date"
  }
}
```

### Server Error

**Status Code:** 500 Internal Server Error

```json
{
  "success": false,
  "error": {
    "code": "server_error",
    "message": "An error occurred while retrieving metrics"
  }
}
```

## Rate Limiting

API endpoints are rate limited to 100 requests per minute per API key. If you exceed this limit, you will receive:

**Status Code:** 429 Too Many Requests

```json
{
  "success": false,
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Try again in 35 seconds.",
    "retryAfter": 35
  }
}
```

## SDK Example

```javascript
import { ClioMetricsClient } from '@smarter-firms/clio-sdk';

const client = new ClioMetricsClient({
  apiKey: 'your-api-key',
  baseUrl: 'https://your-api-url.com'
});

async function getDashboardMetrics() {
  try {
    const dashboard = await client.webhooks.getDashboard();
    console.log(`Total webhooks: ${dashboard.totalWebhooks}`);
    console.log(`Success rate: ${dashboard.successRate}%`);
  } catch (error) {
    console.error('Error fetching dashboard metrics:', error);
  }
}
``` 