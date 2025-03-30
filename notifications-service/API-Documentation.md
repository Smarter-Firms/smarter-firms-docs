# Notifications Service API Documentation

This document provides comprehensive documentation for the Notifications Service API.

## Base URL

```
https://api.smarter-firms.com/notifications/v1
```

## Authentication

All API endpoints require authentication using JWT tokens. Include the token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

## Error Handling

All API errors follow a consistent format:

```json
{
  "status": "error",
  "message": "Error message description",
  "code": "ERROR_CODE",
  "details": [ 
    {
      "field": "fieldName",
      "message": "Specific error for this field"
    }
  ],
  "requestId": "unique-request-id"
}
```

Common error codes:

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Request validation failed |
| `AUTHENTICATION_ERROR` | Authentication failed |
| `AUTHORIZATION_ERROR` | User lacks required permissions |
| `RESOURCE_NOT_FOUND` | Requested resource not found |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `INTERNAL_ERROR` | Unexpected server error |

## Content Types

All requests must use:
```
Content-Type: application/json
```

## API Endpoints

### Notifications

#### Send Notification

Creates and sends a new notification.

```
POST /notifications
```

**Request Body**:

```json
{
  "userId": "user123",
  "notificationTypeId": "welcome-email",
  "templateData": {
    "firstName": "John",
    "companyName": "Acme Inc"
  },
  "priority": "high",
  "metadata": {
    "source": "user-service",
    "correlationId": "signup-flow-123"
  }
}
```

**Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `userId` | string | Yes | ID of the recipient user |
| `notificationTypeId` | string | Yes | ID of the notification type |
| `templateData` | object | Yes | Data to populate the notification template |
| `priority` | string | No | Priority level: "low", "medium", "high", "critical". Default: "medium" |
| `metadata` | object | No | Additional metadata for tracking/analytics |

**Response (200 OK)**:

```json
{
  "status": "success",
  "data": {
    "notificationId": "notif-123456",
    "status": "queued",
    "estimatedDelivery": "2023-05-22T12:00:00Z"
  }
}
```

#### Get Notification Status

Retrieves the status of a notification.

```
GET /notifications/{notificationId}
```

**Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `notificationId` | string | Yes | ID of the notification |

**Response (200 OK)**:

```json
{
  "status": "success",
  "data": {
    "notificationId": "notif-123456",
    "userId": "user123",
    "notificationTypeId": "welcome-email",
    "status": "delivered",
    "sentAt": "2023-05-22T11:00:00Z",
    "deliveredAt": "2023-05-22T11:01:23Z",
    "channel": "email",
    "events": [
      {
        "type": "queued",
        "timestamp": "2023-05-22T11:00:00Z"
      },
      {
        "type": "sent",
        "timestamp": "2023-05-22T11:00:05Z"
      },
      {
        "type": "delivered",
        "timestamp": "2023-05-22T11:01:23Z"
      }
    ]
  }
}
```

#### Cancel Notification

Cancels a pending notification.

```
DELETE /notifications/{notificationId}
```

**Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `notificationId` | string | Yes | ID of the notification |

**Response (200 OK)**:

```json
{
  "status": "success",
  "data": {
    "notificationId": "notif-123456",
    "status": "cancelled"
  }
}
```

#### List User Notifications

Retrieves a user's notifications.

```
GET /users/{userId}/notifications
```

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `status` | string | No | Filter by status: "queued", "sent", "delivered", "failed", "cancelled" |
| `type` | string | No | Filter by notification type |
| `from` | string | No | Start date (ISO-8601) |
| `to` | string | No | End date (ISO-8601) |
| `limit` | integer | No | Maximum number of results (default: 20, max: 100) |
| `offset` | integer | No | Pagination offset (default: 0) |

**Response (200 OK)**:

```json
{
  "status": "success",
  "data": {
    "notifications": [
      {
        "notificationId": "notif-123456",
        "notificationTypeId": "welcome-email",
        "status": "delivered",
        "sentAt": "2023-05-22T11:00:00Z",
        "deliveredAt": "2023-05-22T11:01:23Z",
        "channel": "email"
      },
      {
        "notificationId": "notif-123457",
        "notificationTypeId": "password-reset",
        "status": "sent",
        "sentAt": "2023-05-23T14:30:00Z",
        "channel": "sms"
      }
    ],
    "pagination": {
      "total": 27,
      "limit": 20,
      "offset": 0,
      "nextOffset": 20
    }
  }
}
```

### Templates

#### List Templates

Retrieves available notification templates.

```
GET /templates
```

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `channel` | string | No | Filter by channel: "email", "sms", "push", "in-app" |
| `limit` | integer | No | Maximum number of results (default: 20, max: 100) |
| `offset` | integer | No | Pagination offset (default: 0) |

**Response (200 OK)**:

```json
{
  "status": "success",
  "data": {
    "templates": [
      {
        "id": "welcome-email",
        "name": "Welcome Email",
        "description": "Sent to new users upon registration",
        "channel": "email",
        "variables": ["firstName", "companyName"],
        "version": 2,
        "createdAt": "2023-04-15T10:00:00Z",
        "updatedAt": "2023-05-10T15:30:00Z"
      },
      {
        "id": "password-reset",
        "name": "Password Reset",
        "description": "Sent when a password reset is requested",
        "channel": "email",
        "variables": ["firstName", "resetLink"],
        "version": 1,
        "createdAt": "2023-04-20T14:00:00Z",
        "updatedAt": "2023-04-20T14:00:00Z"
      }
    ],
    "pagination": {
      "total": 12,
      "limit": 20,
      "offset": 0
    }
  }
}
```

#### Get Template Details

Retrieves details of a specific template.

```
GET /templates/{templateId}
```

**Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `templateId` | string | Yes | ID of the template |

**Response (200 OK)**:

```json
{
  "status": "success",
  "data": {
    "id": "welcome-email",
    "name": "Welcome Email",
    "description": "Sent to new users upon registration",
    "channel": "email",
    "subject": "Welcome to {{ companyName }}!",
    "body": "Hello {{ firstName }},\n\nWelcome to {{ companyName }}! We're excited to have you on board.",
    "variables": ["firstName", "companyName"],
    "version": 2,
    "createdAt": "2023-04-15T10:00:00Z",
    "updatedAt": "2023-05-10T15:30:00Z",
    "preview": {
      "subject": "Welcome to Acme Inc!",
      "body": "Hello John,\n\nWelcome to Acme Inc! We're excited to have you on board."
    }
  }
}
```

### User Preferences

#### Get User Preferences

Retrieves notification preferences for a user.

```
GET /users/{userId}/preferences
```

**Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `userId` | string | Yes | ID of the user |

**Response (200 OK)**:

```json
{
  "status": "success",
  "data": {
    "userId": "user123",
    "channels": {
      "email": {
        "enabled": true,
        "address": "user@example.com"
      },
      "sms": {
        "enabled": true,
        "phoneNumber": "+15551234567"
      },
      "push": {
        "enabled": false
      },
      "in-app": {
        "enabled": true
      }
    },
    "categories": {
      "marketing": {
        "enabled": false,
        "channels": {
          "email": false,
          "sms": false,
          "push": false,
          "in-app": true
        }
      },
      "transactional": {
        "enabled": true,
        "channels": {
          "email": true,
          "sms": true,
          "push": false,
          "in-app": true
        }
      },
      "security": {
        "enabled": true,
        "channels": {
          "email": true,
          "sms": true,
          "push": false,
          "in-app": true
        }
      }
    }
  }
}
```

#### Update User Preferences

Updates notification preferences for a user.

```
PATCH /users/{userId}/preferences
```

**Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `userId` | string | Yes | ID of the user |

**Request Body**:

```json
{
  "channels": {
    "sms": {
      "enabled": false
    },
    "push": {
      "enabled": true
    }
  },
  "categories": {
    "marketing": {
      "enabled": true,
      "channels": {
        "email": true
      }
    }
  }
}
```

**Response (200 OK)**:

```json
{
  "status": "success",
  "data": {
    "userId": "user123",
    "updated": ["channels.sms", "channels.push", "categories.marketing"]
  }
}
```

### Health Check

#### Get Service Health

Returns the current health status of the service.

```
GET /health
```

**Response (200 OK)**:

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2023-05-24T12:34:56Z",
  "components": {
    "database": "healthy",
    "messageQueue": "healthy",
    "emailProvider": "healthy",
    "smsProvider": "healthy"
  },
  "metrics": {
    "uptime": 1209600,
    "requestsPerMinute": 125,
    "averageResponseTime": 45
  }
}
```

## Webhooks

The Notifications Service can send webhooks to notify your service about notification status changes.

### Notification Status Webhook

```
POST {your-webhook-url}
```

**Request Headers**:

```
X-Notification-Signature: sha256-HMAC-signature
Content-Type: application/json
```

**Request Body**:

```json
{
  "event": "notification.status_change",
  "timestamp": "2023-05-22T11:01:23Z",
  "data": {
    "notificationId": "notif-123456",
    "userId": "user123",
    "notificationTypeId": "welcome-email",
    "previousStatus": "sent",
    "status": "delivered",
    "channel": "email",
    "timestamp": "2023-05-22T11:01:23Z",
    "metadata": {
      "source": "user-service",
      "correlationId": "signup-flow-123"
    }
  }
}
```

To verify webhook authenticity, compute the HMAC signature of the payload using your webhook secret and compare it to the `X-Notification-Signature` header value.

## Appendix

### Notification Statuses

| Status | Description |
|--------|-------------|
| `queued` | Notification is queued for delivery |
| `sent` | Notification has been sent to delivery provider |
| `delivered` | Notification has been delivered to recipient |
| `failed` | Notification delivery failed |
| `cancelled` | Notification was cancelled before delivery |
| `read` | Notification has been read by recipient (when trackable) |
| `clicked` | Recipient clicked a link in the notification (when trackable) |

### Priority Levels

| Priority | Description | Delivery Guarantees |
|----------|-------------|---------------------|
| `low` | Non-urgent, bulk notifications | Best-effort delivery, may be delayed during high load |
| `medium` | Standard notifications | Standard delivery, may be briefly delayed during extreme load |
| `high` | Important notifications | Prioritized delivery, minimal delays |
| `critical` | Time-sensitive, critical notifications | Highest priority delivery, guaranteed delivery attempts |

### Rate Limits

See [Rate Limiting Documentation](./Rate-Limiting.md) for details on API rate limits.

### Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2023-05-24 | 1.0.0 | Initial API release | 