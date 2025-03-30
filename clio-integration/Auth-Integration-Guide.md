# Auth Service Integration Guide

This guide documents the authentication flow between the Auth Service, API Gateway, and Clio Integration Service, including integration testing procedures.

## Authentication Flow

```
┌───────────┐      ┌───────────┐      ┌───────────┐      ┌───────────┐
│           │      │           │      │           │      │           │
│   User    │      │ Auth Svc  │      │ API       │      │ Clio Svc  │
│           │      │           │      │ Gateway   │      │           │
│           │      │           │      │           │      │           │
└─────┬─────┘      └─────┬─────┘      └─────┬─────┘      └─────┬─────┘
      │                  │                  │                  │
      │  Login Request   │                  │                  │
      │─────────────────>│                  │                  │
      │                  │                  │                  │
      │  JWT Token       │                  │                  │
      │<─────────────────│                  │                  │
      │                  │                  │                  │
      │                                     │                  │
      │       API Request + JWT Token       │                  │
      │────────────────────────────────────>│                  │
      │                                     │                  │
      │                                     │ Validate Token   │
      │                                     │───────────┐      │
      │                                     │           │      │
      │                                     │<──────────┘      │
      │                                     │                  │
      │                                     │ Forward Request  │
      │                                     │─────────────────>│
      │                                     │                  │
      │                                     │                  │
      │                                     │    Response      │
      │                                     │<─────────────────│
      │                                     │                  │
      │          API Response               │                  │
      │<────────────────────────────────────│                  │
      │                                     │                  │
```

## Components Overview

### 1. Auth Service

Provides user authentication and authorization for the Smarter Firms platform.

- **Responsibilities**:
  - User authentication
  - JWT token issuance and validation
  - User management and permissions

- **Integration Points**:
  - Issues JWT tokens for authenticated users
  - Provides token validation endpoint for API Gateway

### 2. API Gateway

Acts as the central entry point for all API requests.

- **Responsibilities**:
  - Route requests to appropriate microservices
  - Validate authentication tokens
  - Apply rate limiting and other cross-cutting concerns

- **Integration Points**:
  - Validates JWT tokens with Auth Service
  - Routes authenticated requests to Clio Integration Service

### 3. Clio Integration Service

Integrates with Clio's API to sync legal practice management data.

- **Responsibilities**:
  - Manage OAuth connections to Clio
  - Process webhook events from Clio
  - Provide API endpoints for Clio data

- **Integration Points**:
  - Receives authenticated requests from API Gateway
  - Uses user identity from JWT for authorization

## JWT Token Structure

The JWT tokens used across the platform have the following structure:

```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user-id-123",
    "name": "John Doe",
    "email": "john@example.com",
    "roles": ["user", "admin"],
    "firmId": "firm-id-456",
    "iat": 1625097600,
    "exp": 1625184000,
    "iss": "smarter-firms-auth",
    "aud": "smarter-firms-platform"
  }
}
```

## Authentication Flow Details

### 1. User Authentication

1. User submits credentials to Auth Service
2. Auth Service validates credentials
3. Auth Service generates and returns a JWT token
4. Frontend stores token for subsequent requests

### 2. API Request Authentication

1. Frontend makes API request with JWT token in Authorization header
2. API Gateway extracts token from header
3. API Gateway validates token signature, expiration, and claims
4. If valid, API Gateway extracts user identity and attaches to request
5. API Gateway forwards request to appropriate service

### 3. Service Authorization

1. Clio Integration Service receives request with user identity
2. Service checks if the user has permissions for the requested operation
3. Service performs the requested operation
4. Service returns the result through API Gateway to client

## Integration Testing

### Prerequisites

- Running instances of:
  - Auth Service
  - API Gateway
  - Clio Integration Service
  - PostgreSQL database
  - Redis instance
- Test user accounts in Auth Service
- Test Clio credentials

### Test Environment Setup

1. Create a `.env.test.integration` file:

```
# Auth Service
AUTH_SERVICE_URL=http://localhost:3000

# API Gateway
API_GATEWAY_URL=http://localhost:8000

# Clio Integration Service
CLIO_SERVICE_URL=http://localhost:3001

# Test Credentials
TEST_USER_EMAIL=test@example.com
TEST_USER_PASSWORD=Test123!
TEST_FIRM_ID=test-firm-id

# Database (separate test database)
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/clio_integration_test

# Redis (separate test database)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=1
```

2. Set up test database:

```bash
# Setup test database
NODE_ENV=test npm run db:migrate
```

### Integration Tests

Create the following test files:

#### `tests/integration/auth-flow.test.ts`

```typescript
import axios from 'axios';
import { describe, it, expect, beforeAll, afterAll } from 'jest';
import { getTestUserToken } from '../helpers/auth';

describe('Auth Service Integration Flow', () => {
  let userToken: string;
  
  beforeAll(async () => {
    // Get a token for the test user
    userToken = await getTestUserToken(
      process.env.TEST_USER_EMAIL!,
      process.env.TEST_USER_PASSWORD!
    );
    expect(userToken).toBeTruthy();
  });
  
  it('should access protected Clio endpoint through API Gateway', async () => {
    // Attempt to access Clio connections endpoint with the auth token
    const response = await axios.get(
      `${process.env.API_GATEWAY_URL}/api/clio/connections`,
      {
        headers: {
          Authorization: `Bearer ${userToken}`
        }
      }
    );
    
    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('connections');
  });
  
  it('should reject requests with invalid auth token', async () => {
    // Try with an invalid token
    await expect(
      axios.get(
        `${process.env.API_GATEWAY_URL}/api/clio/connections`,
        {
          headers: {
            Authorization: 'Bearer invalid-token'
          }
        }
      )
    ).rejects.toThrow();
  });
  
  it('should reject requests with missing auth token', async () => {
    // Try with no token
    await expect(
      axios.get(`${process.env.API_GATEWAY_URL}/api/clio/connections`)
    ).rejects.toThrow();
  });
});
```

### Helper Functions

#### `tests/helpers/auth.ts`

```typescript
import axios from 'axios';

/**
 * Get an authentication token for test user
 */
export async function getTestUserToken(email: string, password: string): Promise<string> {
  try {
    const response = await axios.post(
      `${process.env.AUTH_SERVICE_URL}/api/auth/login`,
      { email, password }
    );
    
    return response.data.token;
  } catch (error) {
    console.error('Failed to get test user token:', error);
    throw error;
  }
}

/**
 * Get authorization headers with a valid token
 */
export async function getAuthHeaders(): Promise<Record<string, string>> {
  const token = await getTestUserToken(
    process.env.TEST_USER_EMAIL!,
    process.env.TEST_USER_PASSWORD!
  );
  
  return {
    Authorization: `Bearer ${token}`
  };
}
```

### End-to-End Flow Tests

#### `tests/integration/end-to-end-flow.test.ts`

```typescript
import axios from 'axios';
import { describe, it, expect, beforeAll } from 'jest';
import { getAuthHeaders } from '../helpers/auth';

describe('End-to-End Integration Flow', () => {
  let authHeaders: Record<string, string>;
  
  beforeAll(async () => {
    // Get authorization headers for all tests
    authHeaders = await getAuthHeaders();
  });
  
  it('should register Clio webhooks through authenticated API', async () => {
    // Register webhooks for the test user
    const response = await axios.post(
      `${process.env.API_GATEWAY_URL}/api/webhooks/register/${process.env.TEST_FIRM_ID}`,
      {},
      { headers: authHeaders }
    );
    
    expect(response.status).toBe(200);
    expect(response.data.success).toBe(true);
    expect(response.data.webhooksRegistered).toBeDefined();
  });
  
  it('should retrieve webhook metrics through authenticated API', async () => {
    // Get webhook metrics
    const response = await axios.get(
      `${process.env.API_GATEWAY_URL}/api/metrics/webhooks/dashboard`,
      { headers: authHeaders }
    );
    
    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('successRate');
    expect(response.data).toHaveProperty('processingTime');
  });
  
  it('should access Clio matters through authenticated API', async () => {
    // Get matters from Clio
    const response = await axios.get(
      `${process.env.API_GATEWAY_URL}/api/clio/matters`,
      { headers: authHeaders }
    );
    
    expect(response.status).toBe(200);
    expect(response.data).toHaveProperty('matters');
  });
});
```

### Running Integration Tests

Add the following to your `package.json`:

```json
{
  "scripts": {
    "test:auth-integration": "jest --config jest.auth-integration.config.js"
  }
}
```

Create `jest.auth-integration.config.js`:

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/tests/integration/*-flow.test.ts'],
  setupFiles: ['dotenv/config'],
  testTimeout: 30000
};
```

Run the tests:

```bash
npm run test:auth-integration
```

## Authentication Error Handling

### Common Error Scenarios

1. **Invalid Token**: Token signature verification fails
   - Gateway returns 401 Unauthorized
   - Error code: `invalid_token`

2. **Expired Token**: Token has expired
   - Gateway returns 401 Unauthorized
   - Error code: `token_expired`

3. **Insufficient Permissions**: Valid token but insufficient permissions
   - Gateway returns 403 Forbidden
   - Error code: `insufficient_permissions`

4. **Token Missing**: No token provided
   - Gateway returns 401 Unauthorized
   - Error code: `missing_token`

### Error Response Format

All authentication errors follow this format:

```json
{
  "error": {
    "code": "invalid_token",
    "message": "Authentication token is invalid",
    "details": "Token signature verification failed"
  }
}
```

## Debugging Authentication Issues

### Client-Side

1. Check token expiration
2. Verify Authorization header format: `Bearer <token>`
3. Check if user has the required permissions

### Server-Side

1. Check API Gateway logs for token validation errors
2. Verify Auth Service is accessible from API Gateway
3. Check user permissions in Auth Service

### Troubleshooting Commands

```bash
# Check API Gateway logs
docker logs api-gateway | grep "token"

# Verify Auth Service health
curl http://auth-service:3000/api/health

# Test token validation directly
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"token": "your-token"}' \
  http://auth-service:3000/api/auth/validate
```

## Development Guidelines

### Implementing New Protected Endpoints

1. Register the endpoint with API Gateway:
   ```typescript
   // In register-with-gateway.ts
   const SERVICE_ENDPOINTS = [
     // ...existing endpoints
     {
       path: '/api/clio/new-endpoint',
       method: 'GET',
       auth: true, // Requires authentication
       rateLimit: 100,
       description: 'New protected endpoint'
     }
   ];
   ```

2. Implement authorization checks in your controller:
   ```typescript
   public newEndpoint = (req: Request, res: Response): void => {
     // User ID is extracted from JWT and attached by API Gateway
     const userId = req.user.sub;
     
     // Firm ID from JWT
     const firmId = req.user.firmId;
     
     // Check permissions
     if (!hasPermission(req.user, 'clio:read')) {
       return res.status(403).json({
         error: {
           code: 'insufficient_permissions',
           message: 'User lacks required permissions'
         }
       });
     }
     
     // Proceed with authorized operation
     // ...
   };
   ```

### Security Best Practices

1. **Never** bypass API Gateway for authenticated requests
2. Always validate user permissions in service logic
3. Use user IDs from JWT, never from request parameters
4. Set appropriate token expiration times
5. Implement token refresh flow for long-lived sessions 