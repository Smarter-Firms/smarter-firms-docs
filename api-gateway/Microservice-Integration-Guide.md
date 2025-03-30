# Microservice Integration Guide

This guide explains how to properly integrate with the Common-Models package and Auth-Service in the Smarter Firms platform without breaking separation of concerns between microservices.

## Repository Access Strategy

### Maintaining Service Boundaries

Each team should focus primarily on their assigned microservice repository. To maintain proper separation:

1. **Use packages rather than direct code access** - Consume other services via published packages and API contracts
2. **Respect service boundaries** - Never directly access another service's database or internal components
3. **Follow the API contract** - All inter-service communication must happen through defined API endpoints

### Access Recommendations

- **Common-Models**: Read-only access for all teams (consumption only)
- **Auth-Service**: Read-only access for API contract reference (no direct code coupling)
- **Own Service**: Full write access for assigned service only

## Common-Models Package Integration

### Installation

The Common-Models package provides shared types, interfaces, and validation schemas. Install it as a dependency:

```bash
# Install from GitHub Package Registry
npm install @smarter-firms/common-models

# OR using the local path during development
npm install ../Common-Models
```

Add to your `package.json`:

```json
"dependencies": {
  "@smarter-firms/common-models": "^1.0.0"
}
```

### Using TypeScript Interfaces

Import and use the shared interfaces in your service:

```typescript
// Example: Using user interface
import { User, UserRole } from '@smarter-firms/common-models';

// Type-safe function
function processUser(user: User) {
  if (user.role === UserRole.ADMIN) {
    // Admin-specific logic
  }
}
```

### Using Validation Schemas

The Common-Models package includes Zod schemas for validation:

```typescript
// Example: Validating user input
import { UserSchema } from '@smarter-firms/common-models/schemas/auth';

function validateUserInput(input: unknown) {
  try {
    // Returns validated data with proper types
    const validatedUser = UserSchema.parse(input);
    return { success: true, data: validatedUser };
  } catch (error) {
    return { success: false, errors: error.errors };
  }
}
```

### Working with BigInt

Common-Models includes utilities for handling BigInt serialization:

```typescript
import { serializeBigInt, deserializeBigInt } from '@smarter-firms/common-models/utils';

// When sending data with BigInt to client
const serializedData = serializeBigInt(entityWithBigInt);

// When receiving serialized data
const deserializedData = deserializeBigInt(receivedData);
```

## Auth-Service Integration

### User Authentication

To authenticate users and get tokens:

```typescript
// Example authentication client
import axios from 'axios';

const authClient = axios.create({
  baseURL: process.env.AUTH_SERVICE_URL || 'http://localhost:3001/api/v1',
});

async function loginUser(email: string, password: string) {
  try {
    const response = await authClient.post('/auth/login', { email, password });
    return response.data; // Contains accessToken and refreshToken
  } catch (error) {
    // Handle authentication errors
    throw new Error(`Authentication failed: ${error.message}`);
  }
}
```

### Token Verification

For protected endpoints, verify the JWT token:

```typescript
// middleware/auth.ts
import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { UserRole } from '@smarter-firms/common-models';

interface JwtPayload {
  userId: string;
  email: string;
  role: UserRole;
}

export function authenticate(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Authentication required' });
  }
  
  const token = authHeader.split(' ')[1];
  
  try {
    // Verify token using the public key from Auth Service
    const payload = jwt.verify(
      token, 
      process.env.JWT_PUBLIC_KEY as string
    ) as JwtPayload;
    
    // Add user info to request object
    req.user = payload;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

// Role-based authorization
export function authorize(roles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }
    
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Insufficient permissions' });
    }
    
    next();
  };
}
```

### Using in Express Routes

```typescript
// routes/protectedRoutes.ts
import express from 'express';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '@smarter-firms/common-models';

const router = express.Router();

// Protected route requiring authentication
router.get('/profile', 
  authenticate,
  (req, res) => {
    res.json({ user: req.user });
  }
);

// Protected route requiring specific role
router.get('/admin/users', 
  authenticate,
  authorize([UserRole.ADMIN]),
  (req, res) => {
    // Admin-only endpoint logic
  }
);

export default router;
```

## API Gateway Integration

When working with the API Gateway, be aware that:

1. All service endpoints should be registered with the Gateway
2. Authentication is often handled at the Gateway level
3. Your service should expect authenticated requests with user context

Register your service endpoints with the Gateway:

```typescript
// Example service registration
const serviceInfo = {
  name: 'your-service-name',
  version: '1.0',
  baseUrl: 'http://localhost:YOUR_PORT',
  healthCheck: '/health',
  routes: [
    {
      path: '/your-endpoint',
      methods: ['GET', 'POST'],
      public: false, // Requires authentication
      roles: ['USER', 'ADMIN'] // Allowed roles
    }
  ]
};

// POST this information to the Gateway's service registry endpoint
```

## Best Practices

1. **Don't modify Common-Models directly** - Request changes through PRs to the Common-Models team
2. **Don't couple to Auth-Service implementation** - Only depend on its public API
3. **Use environment variables for service URLs** - Never hardcode service locations
4. **Implement circuit breakers** - Handle failures gracefully when dependent services are down
5. **Add comprehensive logging** - Log all cross-service calls for debugging
6. **Include correlation IDs** - Pass request IDs across service boundaries for tracing
7. **Handle version compatibility** - Be aware of package and API versions
8. **Write integration tests** - Test your service against mocked versions of other services

## Troubleshooting Common Issues

### Invalid Token Errors
- Check if the JWT_PUBLIC_KEY environment variable is correctly set
- Ensure tokens aren't expired
- Verify the token signature algorithm matches Auth-Service's

### Type Mismatch Errors
- Ensure you're using the latest version of Common-Models
- Check if you need to update your package dependency

### Authorization Failures
- Confirm the user has the required role for the operation
- Check if the token payload contains the correct role information

### BigInt Serialization Issues
- Remember JSON doesn't support BigInt natively
- Always use the serialization utilities when sending/receiving data with BigInt

## Getting Help

If you encounter integration issues:
1. Check the service's README and API documentation
2. Review the API-Contracts.md in the Project-Management repository
3. Check the #integration-help channel in Slack
4. Create an issue in the specific service repository if appropriate 