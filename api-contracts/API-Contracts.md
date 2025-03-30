# Smarter Firms API Contracts

This document defines the API contracts between services in the Smarter Firms system. Each service exposes a set of endpoints that follow REST principles and consistent response formats.

## Common API Standards

All APIs in the Smarter Firms system adhere to the following standards:

- **Base URL Format**: `http://{service-host}:{port}/api/v1`
- **Authentication**: Bearer token in Authorization header
- **Content Type**: application/json
- **Error Response Format**:
  ```json
  {
    "status": "error",
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {} // Optional additional error details
  }
  ```
- **Success Response Format**:
  ```json
  {
    "status": "success",
    "data": {} // Response data
  }
  ```
- **Pagination Format** (for list endpoints):
  ```json
  {
    "status": "success",
    "data": [], // Array of items
    "pagination": {
      "page": 1,
      "limit": 20,
      "totalItems": 100,
      "totalPages": 5
    }
  }
  ```

## Auth Service API

Base URL: `/api/v1`

### Authentication Endpoints

#### POST /auth/register
- **Description**: Register a new user
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "securePassword123",
    "firstName": "John",
    "lastName": "Doe"
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "user": {
        "id": "user_id",
        "email": "user@example.com",
        "firstName": "John",
        "lastName": "Doe",
        "createdAt": "2023-06-01T00:00:00Z"
      },
      "tokens": {
        "accessToken": "jwt_access_token",
        "refreshToken": "jwt_refresh_token"
      }
    }
  }
  ```

#### POST /auth/login
- **Description**: Authenticate a user
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "securePassword123"
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "user": {
        "id": "user_id",
        "email": "user@example.com",
        "firstName": "John",
        "lastName": "Doe"
      },
      "tokens": {
        "accessToken": "jwt_access_token",
        "refreshToken": "jwt_refresh_token"
      }
    }
  }
  ```

#### POST /auth/refresh
- **Description**: Refresh access token
- **Request Body**:
  ```json
  {
    "refreshToken": "jwt_refresh_token"
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "accessToken": "new_jwt_access_token",
      "refreshToken": "new_jwt_refresh_token"
    }
  }
  ```

#### POST /auth/logout
- **Description**: Logout a user (invalidate tokens)
- **Request**: No body required (uses Authorization header)
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "message": "Logged out successfully"
    }
  }
  ```

### User Management Endpoints

#### GET /users/me
- **Description**: Get current user profile
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "user_id",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "admin",
      "createdAt": "2023-06-01T00:00:00Z",
      "updatedAt": "2023-06-01T00:00:00Z"
    }
  }
  ```

#### PUT /users/me
- **Description**: Update current user profile
- **Request Body**:
  ```json
  {
    "firstName": "Updated",
    "lastName": "Name",
    "phone": "1234567890"
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "user_id",
      "email": "user@example.com",
      "firstName": "Updated",
      "lastName": "Name",
      "phone": "1234567890",
      "updatedAt": "2023-06-02T00:00:00Z"
    }
  }
  ```

#### POST /users/password/change
- **Description**: Change user password
- **Request Body**:
  ```json
  {
    "currentPassword": "oldPassword123",
    "newPassword": "newPassword123"
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "message": "Password changed successfully"
    }
  }
  ```

## Clio Integration Service API

Base URL: `/api/v1`

### Integration Endpoints

#### GET /clio/auth/url
- **Description**: Get Clio OAuth authorization URL
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "authUrl": "https://app.clio.com/oauth/authorize?response_type=code&client_id=client_id&redirect_uri=http://localhost:3002/api/v1/auth/callback"
    }
  }
  ```

#### GET /clio/auth/callback
- **Description**: OAuth callback endpoint (redirected from Clio)
- **Query Parameters**: `code` (authorization code)
- **Response**: Redirects to UI with success/error status

#### GET /clio/connection/status
- **Description**: Check if user has connected to Clio
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "connected": true,
      "connectedAt": "2023-06-01T00:00:00Z",
      "lastSyncAt": "2023-06-01T01:00:00Z"
    }
  }
  ```

#### POST /clio/connection/disconnect
- **Description**: Disconnect from Clio
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "message": "Disconnected from Clio successfully"
    }
  }
  ```

### Data Sync Endpoints

#### POST /clio/sync/start
- **Description**: Manually initiate data synchronization
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "syncId": "sync_job_id",
      "status": "started",
      "startedAt": "2023-06-01T00:00:00Z"
    }
  }
  ```

#### GET /clio/sync/status/:syncId
- **Description**: Check status of a sync job
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "syncId": "sync_job_id",
      "status": "completed", // started, processing, completed, failed
      "progress": 100,
      "startedAt": "2023-06-01T00:00:00Z",
      "completedAt": "2023-06-01T00:05:00Z",
      "itemsProcessed": 250,
      "errors": []
    }
  }
  ```

## Account & Billing Service API

Base URL: `/api/v1`

### Account Management Endpoints

#### POST /accounts
- **Description**: Create a new firm account
- **Request Body**:
  ```json
  {
    "name": "Example Law Firm",
    "address": {
      "street": "123 Main St",
      "city": "New York",
      "state": "NY", 
      "zipCode": "10001",
      "country": "USA"
    },
    "phone": "1234567890",
    "website": "https://examplelawfirm.com"
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "account_id",
      "name": "Example Law Firm",
      "address": {
        "street": "123 Main St",
        "city": "New York",
        "state": "NY", 
        "zipCode": "10001",
        "country": "USA"
      },
      "phone": "1234567890",
      "website": "https://examplelawfirm.com",
      "createdAt": "2023-06-01T00:00:00Z",
      "status": "active"
    }
  }
  ```

#### GET /accounts/current
- **Description**: Get current account details
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "account_id",
      "name": "Example Law Firm",
      "address": {
        "street": "123 Main St",
        "city": "New York",
        "state": "NY", 
        "zipCode": "10001",
        "country": "USA"
      },
      "phone": "1234567890",
      "website": "https://examplelawfirm.com",
      "createdAt": "2023-06-01T00:00:00Z",
      "subscription": {
        "plan": "premium",
        "status": "active",
        "currentPeriodEnd": "2024-06-01T00:00:00Z"
      }
    }
  }
  ```

#### PUT /accounts/current
- **Description**: Update current account details
- **Request Body**:
  ```json
  {
    "name": "Updated Law Firm",
    "address": {
      "street": "456 New St",
      "city": "Los Angeles",
      "state": "CA", 
      "zipCode": "90001",
      "country": "USA"
    },
    "phone": "9876543210"
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "account_id",
      "name": "Updated Law Firm",
      "address": {
        "street": "456 New St",
        "city": "Los Angeles",
        "state": "CA", 
        "zipCode": "90001",
        "country": "USA"
      },
      "phone": "9876543210",
      "updatedAt": "2023-06-02T00:00:00Z"
    }
  }
  ```

### Subscription Management Endpoints

#### GET /subscriptions/plans
- **Description**: Get available subscription plans
- **Response**: 
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": "basic",
        "name": "Basic Plan",
        "description": "For small law firms",
        "price": 29.99,
        "billingPeriod": "monthly",
        "features": [
          "Feature 1",
          "Feature 2"
        ]
      },
      {
        "id": "premium",
        "name": "Premium Plan",
        "description": "For medium-sized law firms",
        "price": 99.99,
        "billingPeriod": "monthly",
        "features": [
          "Feature 1",
          "Feature 2",
          "Feature 3",
          "Feature 4"
        ]
      }
    ]
  }
  ```

#### POST /subscriptions
- **Description**: Subscribe to a plan
- **Request Body**:
  ```json
  {
    "planId": "premium",
    "paymentMethodId": "pm_card_visa"
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "subscriptionId": "sub_123456",
      "plan": "premium",
      "status": "active",
      "currentPeriodStart": "2023-06-01T00:00:00Z",
      "currentPeriodEnd": "2023-07-01T00:00:00Z"
    }
  }
  ```

#### GET /subscriptions/current
- **Description**: Get current subscription details
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "subscriptionId": "sub_123456",
      "plan": "premium",
      "status": "active",
      "currentPeriodStart": "2023-06-01T00:00:00Z",
      "currentPeriodEnd": "2023-07-01T00:00:00Z",
      "cancelAtPeriodEnd": false
    }
  }
  ```

#### PUT /subscriptions/current/cancel
- **Description**: Cancel current subscription (at period end)
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "subscriptionId": "sub_123456",
      "plan": "premium",
      "status": "active",
      "currentPeriodEnd": "2023-07-01T00:00:00Z",
      "cancelAtPeriodEnd": true
    }
  }
  ```

### Payment Management Endpoints

#### POST /payment-methods
- **Description**: Add a new payment method
- **Request Body**:
  ```json
  {
    "paymentMethodId": "pm_card_visa" // Stripe payment method ID
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "payment_method_id",
      "type": "card",
      "card": {
        "brand": "visa",
        "last4": "4242",
        "expMonth": 12,
        "expYear": 2025
      },
      "isDefault": true
    }
  }
  ```

#### GET /payment-methods
- **Description**: Get saved payment methods
- **Response**: 
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": "payment_method_id_1",
        "type": "card",
        "card": {
          "brand": "visa",
          "last4": "4242",
          "expMonth": 12,
          "expYear": 2025
        },
        "isDefault": true
      },
      {
        "id": "payment_method_id_2",
        "type": "card",
        "card": {
          "brand": "mastercard",
          "last4": "8888",
          "expMonth": 6,
          "expYear": 2026
        },
        "isDefault": false
      }
    ]
  }
  ```

#### DELETE /payment-methods/:id
- **Description**: Delete a payment method
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "message": "Payment method deleted successfully"
    }
  }
  ```

## Data Service API

Base URL: `/api/v1`

### Document Management Endpoints

#### POST /documents
- **Description**: Upload a new document
- **Request**: Multipart form data with file and metadata
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "document_id",
      "name": "contract.pdf",
      "size": 1024567,
      "mimeType": "application/pdf",
      "uploadedAt": "2023-06-01T00:00:00Z",
      "tags": ["contract", "client"]
    }
  }
  ```

#### GET /documents
- **Description**: List documents with optional filtering
- **Query Parameters**: 
  - `page`: Page number (default: 1)
  - `limit`: Items per page (default: 20)
  - `search`: Search term
  - `tags`: Comma-separated tags
  - `dateFrom`: Filter by date
  - `dateTo`: Filter by date
- **Response**: 
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": "document_id_1",
        "name": "contract.pdf",
        "size": 1024567,
        "mimeType": "application/pdf",
        "uploadedAt": "2023-06-01T00:00:00Z",
        "tags": ["contract", "client"]
      },
      {
        "id": "document_id_2",
        "name": "letter.docx",
        "size": 45678,
        "mimeType": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "uploadedAt": "2023-06-02T00:00:00Z",
        "tags": ["letter"]
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "totalItems": 45,
      "totalPages": 3
    }
  }
  ```

#### GET /documents/:id
- **Description**: Get document details
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "document_id",
      "name": "contract.pdf",
      "size": 1024567,
      "mimeType": "application/pdf",
      "uploadedAt": "2023-06-01T00:00:00Z",
      "modifiedAt": "2023-06-01T00:00:00Z",
      "tags": ["contract", "client"],
      "metadata": {
        "author": "John Doe",
        "createdAt": "2023-05-28T00:00:00Z"
      }
    }
  }
  ```

#### GET /documents/:id/download
- **Description**: Download a document
- **Response**: Binary file stream

#### PUT /documents/:id
- **Description**: Update document metadata
- **Request Body**:
  ```json
  {
    "name": "updated-name.pdf",
    "tags": ["contract", "client", "updated"]
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "document_id",
      "name": "updated-name.pdf",
      "tags": ["contract", "client", "updated"],
      "modifiedAt": "2023-06-02T00:00:00Z"
    }
  }
  ```

#### DELETE /documents/:id
- **Description**: Delete a document
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "message": "Document deleted successfully"
    }
  }
  ```

### Analytics Endpoints

#### GET /analytics/cases
- **Description**: Get case analytics
- **Query Parameters**: 
  - `startDate`: Analysis start date
  - `endDate`: Analysis end date
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "totalCases": 45,
      "newCases": 12,
      "closedCases": 8,
      "byPracticeArea": [
        {
          "name": "Family Law",
          "count": 20
        },
        {
          "name": "Corporate",
          "count": 15
        },
        {
          "name": "Real Estate",
          "count": 10
        }
      ],
      "byStatus": [
        {
          "status": "Open",
          "count": 30
        },
        {
          "status": "Closed",
          "count": 15
        }
      ]
    }
  }
  ```

#### GET /analytics/revenue
- **Description**: Get revenue analytics
- **Query Parameters**: 
  - `startDate`: Analysis start date
  - `endDate`: Analysis end date
  - `groupBy`: Group by parameter (daily, weekly, monthly)
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "totalRevenue": 125000.50,
      "totalBilled": 150000.75,
      "outstandingAmount": 25000.25,
      "revenueByPeriod": [
        {
          "period": "2023-05",
          "amount": 45000.25
        },
        {
          "period": "2023-06",
          "amount": 80000.25
        }
      ],
      "revenueByPracticeArea": [
        {
          "name": "Family Law",
          "amount": 50000.20
        },
        {
          "name": "Corporate",
          "amount": 45000.15
        },
        {
          "name": "Real Estate",
          "amount": 30000.15
        }
      ]
    }
  }
  ```

## Notifications Service API

Base URL: `/api/v1`

### Notification Management Endpoints

#### POST /notifications
- **Description**: Send a notification
- **Request Body**:
  ```json
  {
    "type": "email", // email, sms, push
    "recipient": {
      "userId": "user_id", // or
      "email": "user@example.com",
      "phone": "+1234567890"
    },
    "template": "welcome_email", // predefined template
    "data": {
      "firstName": "John",
      "activationLink": "https://example.com/activate"
    }
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "notification_id",
      "type": "email",
      "status": "queued",
      "createdAt": "2023-06-01T00:00:00Z"
    }
  }
  ```

#### GET /notifications
- **Description**: Get user notifications
- **Query Parameters**: 
  - `page`: Page number (default: 1)
  - `limit`: Items per page (default: 20)
  - `type`: Filter by type (email, sms, push)
  - `status`: Filter by status (sent, delivered, failed)
- **Response**: 
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": "notification_id_1",
        "type": "email",
        "subject": "Welcome to Smarter Firms",
        "preview": "Welcome to Smarter Firms! We're excited to...",
        "status": "delivered",
        "sentAt": "2023-06-01T00:00:00Z",
        "deliveredAt": "2023-06-01T00:00:05Z",
        "read": true
      },
      {
        "id": "notification_id_2",
        "type": "sms",
        "preview": "Your verification code is 123456",
        "status": "delivered",
        "sentAt": "2023-06-02T00:00:00Z",
        "deliveredAt": "2023-06-02T00:00:01Z",
        "read": false
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "totalItems": 35,
      "totalPages": 2
    }
  }
  ```

#### GET /notifications/:id
- **Description**: Get notification details
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "notification_id",
      "type": "email",
      "recipient": "user@example.com",
      "subject": "Welcome to Smarter Firms",
      "content": "Full content of the email...",
      "status": "delivered",
      "sentAt": "2023-06-01T00:00:00Z",
      "deliveredAt": "2023-06-01T00:00:05Z",
      "readAt": "2023-06-01T01:00:00Z"
    }
  }
  ```

#### PUT /notifications/:id/read
- **Description**: Mark notification as read
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "id": "notification_id",
      "read": true,
      "readAt": "2023-06-02T00:00:00Z"
    }
  }
  ```

### Notification Preferences Endpoints

#### GET /notification-preferences
- **Description**: Get user notification preferences
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "email": {
        "enabled": true,
        "categories": {
          "marketing": false,
          "billing": true,
          "system": true
        }
      },
      "sms": {
        "enabled": true,
        "categories": {
          "security": true,
          "billing": false,
          "system": false
        }
      },
      "push": {
        "enabled": true,
        "categories": {
          "system": true,
          "billing": true
        }
      }
    }
  }
  ```

#### PUT /notification-preferences
- **Description**: Update notification preferences
- **Request Body**:
  ```json
  {
    "email": {
      "enabled": true,
      "categories": {
        "marketing": true
      }
    },
    "sms": {
      "enabled": false
    }
  }
  ```
- **Response**: 
  ```json
  {
    "status": "success",
    "data": {
      "email": {
        "enabled": true,
        "categories": {
          "marketing": true,
          "billing": true,
          "system": true
        }
      },
      "sms": {
        "enabled": false,
        "categories": {
          "security": true,
          "billing": false,
          "system": false
        }
      },
      "push": {
        "enabled": true,
        "categories": {
          "system": true,
          "billing": true
        }
      }
    }
  }
  ``` 