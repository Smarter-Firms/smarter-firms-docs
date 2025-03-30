# Error Handling Strategy

## Overview

The Data Service implements a comprehensive error handling strategy to provide consistent, informative error responses across all endpoints. This document outlines the approach to error management, including error categorization, error response structure, logging, and client-facing error messages.

## Error Categories

Errors are categorized into the following types:

### 1. Validation Errors
- **HTTP Status**: 400 Bad Request
- **Description**: Errors that occur when input data fails validation rules
- **Examples**: Missing required fields, invalid data types, format errors

### 2. Authentication Errors
- **HTTP Status**: 401 Unauthorized
- **Description**: Errors related to authentication failures
- **Examples**: Invalid JWT, expired token, missing token

### 3. Authorization Errors
- **HTTP Status**: 403 Forbidden
- **Description**: Errors related to permission restrictions
- **Examples**: Insufficient privileges, tenant isolation violations, role-based access control failures

### 4. Resource Not Found Errors
- **HTTP Status**: 404 Not Found
- **Description**: Errors when requested resources don't exist
- **Examples**: Invalid ID, deleted resource, non-existent endpoint

### 5. Conflict Errors
- **HTTP Status**: 409 Conflict
- **Description**: Errors due to conflicting operations
- **Examples**: Duplicate records, concurrent modification, version conflicts

### 6. Rate Limiting Errors
- **HTTP Status**: 429 Too Many Requests
- **Description**: Errors due to exceeding rate limits
- **Examples**: Too many API calls in a time period

### 7. Server Errors
- **HTTP Status**: 500 Internal Server Error
- **Description**: Unexpected errors in server processing
- **Examples**: Database failures, unhandled exceptions, external service failures

### 8. Service Unavailable Errors
- **HTTP Status**: 503 Service Unavailable
- **Description**: Temporary service unavailability
- **Examples**: Maintenance mode, overloaded system, dependent service failure

## Error Response Structure

All API errors follow a consistent JSON structure:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": [
      {
        "field": "fieldName",
        "message": "Field-specific error message"
      }
    ],
    "requestId": "unique-request-identifier",
    "timestamp": "2023-04-01T12:00:00Z"
  }
}
```

### Fields Description

- **code**: A unique error code identifier (string)
- **message**: A human-readable error message suitable for display to end users
- **details**: An array of field-specific errors (for validation errors)
- **requestId**: A unique identifier for the request (used for error tracing)
- **timestamp**: When the error occurred

## Implementation

### Central Error Handler

The service uses a central error handling middleware for Express that:

1. Captures all errors thrown by route handlers
2. Determines the appropriate error category and status code
3. Formats the error response according to the standard structure
4. Logs the error details (with appropriate sensitive data filtering)
5. Returns the formatted response to the client

### Error Classes

The service defines a hierarchy of custom error classes:

```typescript
// Base application error
class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 500,
    public code: string = 'INTERNAL_ERROR',
    public details?: any[]
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

// Validation error
class ValidationError extends AppError {
  constructor(message: string, details?: any[]) {
    super(message, 400, 'VALIDATION_ERROR', details);
  }
}

// Authentication error
class AuthenticationError extends AppError {
  constructor(message: string = 'Authentication failed') {
    super(message, 401, 'AUTHENTICATION_ERROR');
  }
}

// Authorization error
class AuthorizationError extends AppError {
  constructor(message: string = 'You do not have permission to perform this action') {
    super(message, 403, 'AUTHORIZATION_ERROR');
  }
}

// Resource not found error
class NotFoundError extends AppError {
  constructor(resource: string = 'Resource') {
    super(`${resource} not found`, 404, 'RESOURCE_NOT_FOUND');
  }
}
```

### Usage Example

```typescript
// In a service or controller
import { ValidationError, NotFoundError } from '../errors';

async function getMatter(matterId: string, tenantId: string) {
  // Validate input
  if (!isValidUuid(matterId)) {
    throw new ValidationError('Invalid matter ID format', [
      { field: 'matterId', message: 'Must be a valid UUID' }
    ]);
  }
  
  // Get data from repository
  const matter = await matterRepository.findById(matterId, tenantId);
  
  // Check if resource exists
  if (!matter) {
    throw new NotFoundError('Matter');
  }
  
  return matter;
}
```

## Error Handling in Async Operations

For asynchronous operations, including Express route handlers, errors are properly propagated using:

1. Async/await with try/catch blocks
2. Express's error-handling middleware
3. Promise rejection handlers

Example:

```typescript
// Route handler with proper error handling
router.get('/matters/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { tenantId } = req.user;
    
    const matter = await matterService.getMatterById(id, tenantId);
    
    return res.json(matter);
  } catch (error) {
    next(error); // Pass to central error handler
  }
});
```

## Validation Implementation

The service uses Zod for input validation with custom error mapping:

```typescript
import { z } from 'zod';
import { ValidationError } from '../errors';

// Define schema
const createMatterSchema = z.object({
  clientId: z.string().uuid(),
  name: z.string().min(3).max(200),
  // Other fields
});

// Validation function
function validateCreateMatter(data: unknown) {
  const result = createMatterSchema.safeParse(data);
  
  if (!result.success) {
    // Transform Zod errors to our format
    const details = result.error.errors.map(err => ({
      field: err.path.join('.'),
      message: err.message
    }));
    
    throw new ValidationError('Invalid matter data', details);
  }
  
  return result.data;
}
```

## Logging Strategy

Errors are logged with different severity levels:

1. **400-level errors**: Logged at INFO or WARNING level (client errors)
2. **500-level errors**: Logged at ERROR level (server errors)

For server errors, detailed information is logged including:
- Full error stack trace
- Request details (URL, method, headers (filtered), body (filtered))
- User information (tenant ID, user ID)
- Timestamp

Example log entry:

```
[2023-04-01T12:00:00.000Z] ERROR [requestId: abc-123] - Internal server error processing GET /matters/123
User: userId=user-456, tenantId=tenant-789
Error: Database query failed
    at MatterRepository.findById (.../repositories/matterRepository.ts:45:7)
    at MatterService.getMatterById (.../services/matterService.ts:28:29)
    at processTicksAndRejections (node:internal/process/task_queues:95:5)
Cause: Error: Connection timeout
```

## Security Considerations

The error handling system implements these security best practices:

1. **Production vs Development**: Different verbosity levels based on environment
2. **Sensitive Data**: No exposure of internal details or sensitive data in client responses
3. **Generic Messages**: Use of generic messages for security-related errors
4. **Request IDs**: Unique identifiers for all requests to facilitate investigation without exposing internal information

## Client Communication

For client-facing applications, error messages are designed to be:

1. **Clear**: Explaining what went wrong in simple language
2. **Actionable**: Providing guidance on how to resolve the issue when applicable
3. **Consistent**: Following the same structure and terminology across the API

## Error Monitoring

The service implements error monitoring using:

1. Structured logging with severity levels and context
2. Error aggregation and alerting for critical errors
3. Regular error report analysis to identify patterns
4. Performance metrics for error rates and types

## Integration with Frontend

Frontend applications should:

1. Check for the presence of an `error` object in responses
2. Display appropriate user-friendly messages based on the error code
3. Implement appropriate retry logic for 5xx errors or network failures
4. Log client-side errors with context for debugging

## Rate Limiting and Retry Strategy

For handling rate limits:

1. Clients receive 429 responses with a `Retry-After` header
2. Documentation recommends exponential backoff for retries
3. Critical endpoints have higher rate limits than non-critical ones

## Conclusion

This error handling strategy ensures that:

1. All errors are consistently formatted
2. Developers can quickly debug issues using detailed logs
3. End-users receive appropriate and actionable error messages
4. Security is maintained by not exposing sensitive information
5. Errors can be properly monitored and analyzed 