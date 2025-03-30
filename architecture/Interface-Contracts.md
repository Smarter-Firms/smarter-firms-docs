# Interface Contracts

This document defines the API contracts between services, ensuring that each service exposes a well-defined interface that other services can rely on.

## Auth Service API

### Authentication Endpoints

#### POST /api/auth/register
Creates a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response (201 Created):**
```json
{
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "USER",
    "accessLevel": "USER_ONLY",
    "createdAt": "2023-05-15T10:30:00Z"
  },
  "meta": {}
}
```

#### POST /api/auth/login
Authenticates a user and returns tokens.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "accessToken": "jwt-token",
    "refreshToken": "refresh-token",
    "expiresIn": 3600,
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "USER"
    }
  },
  "meta": {}
}
```

#### POST /api/auth/refresh
Refreshes an expired access token.

**Request:**
```json
{
  "refreshToken": "refresh-token"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "accessToken": "new-jwt-token",
    "expiresIn": 3600
  },
  "meta": {}
}
```

#### POST /api/auth/logout
Invalidates refresh tokens.

**Request:**
```json
{
  "refreshToken": "refresh-token"
}
```

**Response (204 No Content)**

### User Management Endpoints

#### GET /api/users/me
Gets the current user's profile.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "USER",
    "accessLevel": "USER_ONLY",
    "firmId": "firm-uuid",
    "lastLogin": "2023-05-15T12:30:00Z",
    "createdAt": "2023-05-01T10:30:00Z"
  },
  "meta": {}
}
```

#### PUT /api/users/me
Updates the current user's profile.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "firstName": "Johnny",
  "lastName": "Doe"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "firstName": "Johnny",
    "lastName": "Doe",
    "role": "USER",
    "accessLevel": "USER_ONLY"
  },
  "meta": {}
}
```

#### GET /api/users/{userId}
Gets a user by ID (admin only or if has access).

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "USER",
    "accessLevel": "USER_ONLY",
    "firmId": "firm-uuid",
    "lastLogin": "2023-05-15T12:30:00Z",
    "createdAt": "2023-05-01T10:30:00Z"
  },
  "meta": {}
}
```

### Role and Permission Endpoints

#### GET /api/roles
Gets all available roles (admin only).

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "name": "SUPER_ADMIN",
      "description": "Platform administrator"
    },
    {
      "name": "ADMIN",
      "description": "Firm administrator"
    },
    {
      "name": "USER",
      "description": "Standard user"
    },
    {
      "name": "CONSULTANT",
      "description": "External consultant"
    }
  ],
  "meta": {}
}
```

#### PUT /api/users/{userId}/role
Updates a user's role (admin only).

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "role": "ADMIN"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "ADMIN",
    "accessLevel": "WHOLE_FIRM"
  },
  "meta": {}
}
```

## Clio Integration Service API

### Connection Endpoints

#### POST /api/clio/connect
Initiates OAuth connection with Clio.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "redirectUrl": "https://app.smarterfirms.com/auth/callback"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "authorizationUrl": "https://app.clio.com/oauth/authorize?client_id=..."
  },
  "meta": {}
}
```

#### POST /api/clio/callback
Handles OAuth callback from Clio.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "code": "oauth-code",
  "state": "state-token"
}
```

**Response (201 Created):**
```json
{
  "data": {
    "connected": true,
    "clioUserName": "John Doe",
    "clioUserId": "clio-user-id",
    "expiresAt": "2023-05-16T10:30:00Z"
  },
  "meta": {}
}
```

#### GET /api/clio/connection
Gets current connection status.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "connected": true,
    "clioUserName": "John Doe",
    "clioUserId": "clio-user-id",
    "lastSyncAt": "2023-05-15T10:30:00Z",
    "expiresAt": "2023-05-16T10:30:00Z",
    "syncStatuses": [
      {
        "entityType": "ACTIVITIES",
        "lastSyncAt": "2023-05-15T10:30:00Z",
        "status": "COMPLETED",
        "recordCount": 1250
      },
      {
        "entityType": "TASKS",
        "lastSyncAt": "2023-05-15T10:30:00Z",
        "status": "COMPLETED",
        "recordCount": 350
      }
    ]
  },
  "meta": {}
}
```

#### DELETE /api/clio/connection
Disconnects from Clio API.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (204 No Content)**

### Synchronization Endpoints

#### POST /api/clio/sync
Triggers a data synchronization.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "entities": ["ACTIVITIES", "TASKS", "MATTERS"],
  "fullSync": false
}
```

**Response (202 Accepted):**
```json
{
  "data": {
    "syncId": "sync-uuid",
    "status": "PENDING",
    "entities": ["ACTIVITIES", "TASKS", "MATTERS"]
  },
  "meta": {}
}
```

#### GET /api/clio/sync/{syncId}
Gets the status of a synchronization.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "syncId": "sync-uuid",
    "status": "IN_PROGRESS",
    "startedAt": "2023-05-15T10:30:00Z",
    "progress": {
      "ACTIVITIES": {
        "status": "COMPLETED",
        "recordCount": 1250,
        "completedAt": "2023-05-15T10:31:00Z"
      },
      "TASKS": {
        "status": "IN_PROGRESS",
        "recordCount": 150
      },
      "MATTERS": {
        "status": "PENDING"
      }
    }
  },
  "meta": {}
}
```

### Data Retrieval Endpoints

#### GET /api/data/matters
Gets matters from the database.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Parameters:**
- `page`: Page number (default: 1)
- `perPage`: Items per page (default: 20)
- `status`: Filter by status
- `q`: Search query
- `sortBy`: Field to sort by
- `sortOrder`: asc or desc

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "matter-uuid",
      "clioId": "clio-matter-id",
      "clientName": "Acme Inc.",
      "description": "Corporate restructuring",
      "matterNumber": "ACM-2023-001",
      "status": "Open",
      "openDate": "2023-01-15T00:00:00Z",
      "closeDate": null,
      "practiceArea": "Corporate",
      "lastActivityDate": "2023-05-10T14:30:00Z",
      "clioCreatedAt": "2023-01-15T10:30:00Z",
      "clioUpdatedAt": "2023-05-10T14:30:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "perPage": 20,
    "totalPages": 5,
    "totalCount": 98
  },
  "links": {
    "self": "/api/data/matters?page=1&perPage=20",
    "next": "/api/data/matters?page=2&perPage=20",
    "prev": null
  }
}
```

#### GET /api/data/activities
Gets activities from the database.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Parameters:**
- `page`: Page number (default: 1)
- `perPage`: Items per page (default: 20)
- `type`: Filter by activity type
- `startDate`: Filter by date range start
- `endDate`: Filter by date range end
- `billable`: Filter by billable status
- `q`: Search query
- `sortBy`: Field to sort by
- `sortOrder`: asc or desc

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "activity-uuid",
      "clioId": "clio-activity-id",
      "type": "TIME",
      "date": "2023-05-10T14:30:00Z",
      "quantity": 1.5,
      "price": 250.0,
      "total": 375.0,
      "note": "Client call",
      "description": "Phone call to discuss contract terms",
      "billable": true,
      "contingent": false,
      "onBill": true,
      "billed": false,
      "matter": {
        "clioId": "clio-matter-id",
        "clientName": "Acme Inc.",
        "matterNumber": "ACM-2023-001"
      },
      "user": {
        "clioId": "clio-user-id",
        "name": "John Doe"
      },
      "clioCreatedAt": "2023-05-10T14:35:00Z",
      "clioUpdatedAt": "2023-05-10T14:35:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "perPage": 20,
    "totalPages": 50,
    "totalCount": 985
  },
  "links": {
    "self": "/api/data/activities?page=1&perPage=20",
    "next": "/api/data/activities?page=2&perPage=20",
    "prev": null
  }
}
```

#### GET /api/data/tasks
Gets tasks from the database.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Parameters:**
- `page`: Page number (default: 1)
- `perPage`: Items per page (default: 20)
- `status`: Filter by status
- `assignee`: Filter by assignee ID
- `dueStart`: Filter by due date range start
- `dueEnd`: Filter by due date range end
- `q`: Search query
- `sortBy`: Field to sort by
- `sortOrder`: asc or desc

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "task-uuid",
      "clioId": "clio-task-id",
      "name": "Prepare contract draft",
      "description": "Draft initial contract for client review",
      "dueAt": "2023-05-20T23:59:59Z",
      "completeAt": null,
      "priority": "High",
      "status": "Pending",
      "matter": {
        "clioId": "clio-matter-id",
        "clientName": "Acme Inc.",
        "matterNumber": "ACM-2023-001"
      },
      "assignee": {
        "clioId": "clio-user-id",
        "name": "John Doe"
      },
      "clioCreatedAt": "2023-05-10T14:35:00Z",
      "clioUpdatedAt": "2023-05-10T14:35:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "perPage": 20,
    "totalPages": 15,
    "totalCount": 287
  },
  "links": {
    "self": "/api/data/tasks?page=1&perPage=20",
    "next": "/api/data/tasks?page=2&perPage=20",
    "prev": null
  }
}
```

## Account and Billing Service API

### Subscription Endpoints

#### POST /api/subscriptions
Creates a new subscription.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "planType": "INDIVIDUAL",
  "paymentMethodId": "pm_card_visa"
}
```

**Response (201 Created):**
```json
{
  "data": {
    "id": "subscription-uuid",
    "stripeCustomerId": "cus_123456",
    "stripeSubscriptionId": "sub_123456",
    "status": "ACTIVE",
    "planType": "INDIVIDUAL",
    "currentPeriodStart": "2023-05-15T00:00:00Z",
    "currentPeriodEnd": "2023-06-15T00:00:00Z",
    "cancelAtPeriodEnd": false
  },
  "meta": {}
}
```

#### GET /api/subscriptions/current
Gets the current subscription.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "subscription-uuid",
    "stripeCustomerId": "cus_123456",
    "stripeSubscriptionId": "sub_123456",
    "status": "ACTIVE",
    "planType": "INDIVIDUAL",
    "currentPeriodStart": "2023-05-15T00:00:00Z",
    "currentPeriodEnd": "2023-06-15T00:00:00Z",
    "cancelAtPeriodEnd": false,
    "invoices": [
      {
        "id": "invoice-uuid",
        "stripeInvoiceId": "in_123456",
        "amount": 3500,
        "currency": "usd",
        "status": "PAID",
        "invoiceDate": "2023-05-15T00:00:00Z",
        "paidDate": "2023-05-15T00:05:00Z"
      }
    ]
  },
  "meta": {}
}
```

#### PUT /api/subscriptions/current
Updates the current subscription.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "planType": "FIRM",
  "cancelAtPeriodEnd": false
}
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "subscription-uuid",
    "status": "ACTIVE",
    "planType": "FIRM",
    "currentPeriodStart": "2023-05-15T00:00:00Z",
    "currentPeriodEnd": "2023-06-15T00:00:00Z",
    "cancelAtPeriodEnd": false
  },
  "meta": {}
}
```

#### DELETE /api/subscriptions/current
Cancels the current subscription at period end.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "subscription-uuid",
    "status": "ACTIVE",
    "planType": "INDIVIDUAL",
    "currentPeriodStart": "2023-05-15T00:00:00Z",
    "currentPeriodEnd": "2023-06-15T00:00:00Z",
    "cancelAtPeriodEnd": true
  },
  "meta": {}
}
```

### Firm Management Endpoints

#### POST /api/firms
Creates a new firm.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "name": "Smith & Associates",
  "clioFirmId": "clio-firm-id",
  "planType": "FIRM"
}
```

**Response (201 Created):**
```json
{
  "data": {
    "id": "firm-uuid",
    "name": "Smith & Associates",
    "clioFirmId": "clio-firm-id",
    "planType": "FIRM",
    "createdAt": "2023-05-15T10:30:00Z",
    "isActive": true
  },
  "meta": {}
}
```

#### GET /api/firms/{firmId}
Gets a firm by ID.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "firm-uuid",
    "name": "Smith & Associates",
    "clioFirmId": "clio-firm-id",
    "planType": "FIRM",
    "createdAt": "2023-05-15T10:30:00Z",
    "isActive": true,
    "users": [
      {
        "id": "user-uuid",
        "email": "admin@smith.com",
        "firstName": "John",
        "lastName": "Smith",
        "role": "ADMIN"
      }
    ]
  },
  "meta": {}
}
```

#### POST /api/firms/{firmId}/invite
Invites a user to join a firm.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "email": "lawyer@smith.com",
  "firstName": "Jane",
  "lastName": "Doe",
  "role": "USER",
  "accessLevel": "USER_ONLY"
}
```

**Response (201 Created):**
```json
{
  "data": {
    "id": "invite-uuid",
    "email": "lawyer@smith.com",
    "firstName": "Jane",
    "lastName": "Doe",
    "role": "USER",
    "accessLevel": "USER_ONLY",
    "expiresAt": "2023-05-22T10:30:00Z",
    "status": "PENDING"
  },
  "meta": {}
}
```

## Dashboard Application API

### Dashboard Endpoints

#### POST /api/dashboards
Creates a new dashboard.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "name": "Billing Overview",
  "description": "Track billable hours and revenue"
}
```

**Response (201 Created):**
```json
{
  "data": {
    "id": "dashboard-uuid",
    "name": "Billing Overview",
    "description": "Track billable hours and revenue",
    "isDefault": false,
    "createdAt": "2023-05-15T10:30:00Z",
    "widgets": []
  },
  "meta": {}
}
```

#### GET /api/dashboards
Gets all dashboards for the current user.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "dashboard-uuid",
      "name": "Billing Overview",
      "description": "Track billable hours and revenue",
      "isDefault": true,
      "createdAt": "2023-05-15T10:30:00Z",
      "widgetCount": 5
    },
    {
      "id": "dashboard-uuid-2",
      "name": "Task Management",
      "description": "Monitor task completion and deadlines",
      "isDefault": false,
      "createdAt": "2023-05-16T14:20:00Z",
      "widgetCount": 3
    }
  ],
  "meta": {
    "totalCount": 2
  }
}
```

#### GET /api/dashboards/{dashboardId}
Gets a dashboard by ID with widgets.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "dashboard-uuid",
    "name": "Billing Overview",
    "description": "Track billable hours and revenue",
    "isDefault": true,
    "createdAt": "2023-05-15T10:30:00Z",
    "widgets": [
      {
        "id": "widget-uuid",
        "name": "Monthly Billable Hours",
        "type": "BAR_CHART",
        "config": {
          "dataSource": "activities",
          "metrics": ["sum:quantity"],
          "dimensions": ["date:month"],
          "filters": [
            {"field": "billable", "operator": "equals", "value": true}
          ]
        },
        "position": {"x": 0, "y": 0, "width": 6, "height": 4}
      }
    ]
  },
  "meta": {}
}
```

### Widget Endpoints

#### POST /api/dashboards/{dashboardId}/widgets
Adds a widget to a dashboard.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "name": "Monthly Billable Hours",
  "type": "BAR_CHART",
  "config": {
    "dataSource": "activities",
    "metrics": ["sum:quantity"],
    "dimensions": ["date:month"],
    "filters": [
      {"field": "billable", "operator": "equals", "value": true}
    ]
  },
  "position": {"x": 0, "y": 0, "width": 6, "height": 4}
}
```

**Response (201 Created):**
```json
{
  "data": {
    "id": "widget-uuid",
    "name": "Monthly Billable Hours",
    "type": "BAR_CHART",
    "config": {
      "dataSource": "activities",
      "metrics": ["sum:quantity"],
      "dimensions": ["date:month"],
      "filters": [
        {"field": "billable", "operator": "equals", "value": true}
      ]
    },
    "position": {"x": 0, "y": 0, "width": 6, "height": 4}
  },
  "meta": {}
}
```

#### PUT /api/widgets/{widgetId}
Updates a widget.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "name": "Updated Widget Name",
  "position": {"x": 0, "y": 0, "width": 12, "height": 4}
}
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "widget-uuid",
    "name": "Updated Widget Name",
    "type": "BAR_CHART",
    "config": {
      "dataSource": "activities",
      "metrics": ["sum:quantity"],
      "dimensions": ["date:month"],
      "filters": [
        {"field": "billable", "operator": "equals", "value": true}
      ]
    },
    "position": {"x": 0, "y": 0, "width": 12, "height": 4}
  },
  "meta": {}
}
```

### Report Data Endpoints

#### POST /api/reports/data
Gets report data based on query parameters.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "dataSource": "activities",
  "metrics": ["sum:quantity", "sum:total"],
  "dimensions": ["date:month", "user.name"],
  "filters": [
    {"field": "billable", "operator": "equals", "value": true},
    {"field": "date", "operator": "between", "value": ["2023-01-01", "2023-05-31"]}
  ],
  "sort": [
    {"field": "date:month", "direction": "asc"}
  ],
  "limit": 100
}
```

**Response (200 OK):**
```json
{
  "data": {
    "rows": [
      {
        "date:month": "2023-01",
        "user.name": "John Doe",
        "sum:quantity": 160.5,
        "sum:total": 40125.0
      },
      {
        "date:month": "2023-02",
        "user.name": "John Doe",
        "sum:quantity": 145.0,
        "sum:total": 36250.0
      }
    ],
    "totals": {
      "sum:quantity": 305.5,
      "sum:total": 76375.0
    }
  },
  "meta": {
    "dimensions": ["date:month", "user.name"],
    "metrics": ["sum:quantity", "sum:total"]
  }
}
```

## Onboarding Application API

### Onboarding Endpoints

#### GET /api/onboarding/status
Gets the onboarding status for the current user.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Response (200 OK):**
```json
{
  "data": {
    "steps": [
      {"id": "account-creation", "completed": true, "completedAt": "2023-05-15T10:30:00Z"},
      {"id": "plan-selection", "completed": true, "completedAt": "2023-05-15T10:35:00Z"},
      {"id": "clio-connection", "completed": false, "completedAt": null},
      {"id": "initial-sync", "completed": false, "completedAt": null},
      {"id": "dashboard-setup", "completed": false, "completedAt": null}
    ],
    "currentStep": "clio-connection",
    "percentComplete": 40
  },
  "meta": {}
}
```

#### PUT /api/onboarding/steps/{stepId}
Updates an onboarding step.

**Headers:**
```
Authorization: Bearer jwt-token
```

**Request:**
```json
{
  "completed": true
}
```

**Response (200 OK):**
```json
{
  "data": {
    "id": "clio-connection",
    "completed": true,
    "completedAt": "2023-05-15T11:00:00Z"
  },
  "meta": {}
}
```

## Webhook Endpoints

### Clio Webhooks

#### POST /api/webhooks/clio
Receives webhook notifications from Clio.

**Headers:**
```
X-Clio-Signature: signature-hash
```

**Request:**
```json
{
  "event": "matter.update",
  "data": {
    "id": "clio-matter-id",
    "updated_at": "2023-05-15T10:30:00Z"
  }
}
```

**Response (202 Accepted)**

### Stripe Webhooks

#### POST /api/webhooks/stripe
Receives webhook notifications from Stripe.

**Headers:**
```
Stripe-Signature: signature-hash
```

**Request:**
```json
{
  "id": "evt_123456",
  "type": "invoice.payment_succeeded",
  "data": {
    "object": {
      "id": "in_123456",
      "customer": "cus_123456",
      "subscription": "sub_123456",
      "amount_paid": 3500
    }
  }
}
```

**Response (202 Accepted)**

## Error Handling

All APIs should use consistent error formats:

### 400 Bad Request
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

### 401 Unauthorized
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

### 403 Forbidden
```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "Insufficient permissions"
  }
}
```

### 404 Not Found
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "The requested resource was not found"
  }
}
```

### 500 Internal Server Error
```json
{
  "error": {
    "code": "INTERNAL_SERVER_ERROR",
    "message": "An unexpected error occurred"
  }
}
``` 