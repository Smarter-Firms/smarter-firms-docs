# Auth Service Integration Guide

## Overview

This document outlines the integration between the API Gateway and the Auth Service. The Auth Service provides authentication and authorization capabilities for the entire Smarter Firms platform, and the API Gateway acts as the entry point for all client requests, routing them to the appropriate services.

## Integration Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│             │     │             │     │             │
│   Clients   │────▶│ API Gateway │────▶│ Auth Service│
│             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           │
                           ▼
                    ┌─────────────┐
                    │  Other      │
                    │ Microservices│
                    └─────────────┘
```

### Authentication Flow

1. Clients send authentication requests to the API Gateway
2. The Gateway forwards these requests to the Auth Service
3. The Auth Service validates credentials and issues JWT tokens
4. The Gateway returns tokens to the client
5. For subsequent requests, the Gateway validates tokens before proxying to services

## Configuration

The Auth Service integration is configured in `src/config/auth-service.js`, which contains:

- Service endpoints and base URL
- Public paths (not requiring authentication)
- Role-protected endpoints
- Proxy configuration
- Health check configuration
- Authentication settings
- Cache configuration

## Implementation Components

### 1. Enhanced Auth Middleware (`src/middleware/authServiceMiddleware.js`)

The authentication middleware provides:

- Token extraction from headers
- JWT verification using Auth Service public key
- Role-based access control
- Detailed error handling for authentication failures

### 2. Auth Routes (`src/routes/auth.js`)

Routes exposed through the Gateway:

- `/api/v1/auth/register` - User registration
- `/api/v1/auth/login` - User login
- `/api/v1/auth/refresh` - Token refresh
- `/api/v1/auth/logout` - User logout
- `/api/v1/auth/verify` - Token verification
- `/api/v1/auth/me` - Get current user info

### 3. Monitoring Integration

Auth Service metrics are collected and displayed in the monitoring dashboard:

- Request counts
- Success/failure rates
- Response times
- Active user sessions

## Testing the Integration

### Integration Tests

Run the Auth Service integration tests with:

```bash
npm run test:integration:auth
```

This will:
1. Start a mock Auth Service
2. Test the complete authentication flow
3. Verify token validation
4. Test role-based access control
5. Verify cache integration
6. Test circuit breaker functionality

### Manual Testing

You can manually test the Auth integration using the following steps:

1. Register a new user:
   ```bash
   curl -X POST http://localhost:3000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123","name":"Test User"}'
   ```

2. Login with the user:
   ```bash
   curl -X POST http://localhost:3000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123"}'
   ```

3. Use the returned token to access protected resources:
   ```bash
   curl -X GET http://localhost:3000/api/v1/protected-resource \
     -H "Authorization: Bearer YOUR_TOKEN_HERE"
   ```

## Deployment Considerations

### Scalability

- The Auth Service is stateless and can be horizontally scaled
- JWT verification happens at the Gateway, reducing load on the Auth Service
- Redis cache speeds up token validation

### Security

- All communication between Gateway and Auth Service should use HTTPS
- JWT tokens are signed with RS256 (asymmetric) algorithm
- Private key for signing is only stored in Auth Service
- Public key for verification is stored in Gateway
- Token expiration is enforced

### Monitoring

- Failed authentication attempts are logged and monitored
- Sudden increases in failed authentication trigger alerts
- Auth Service health checks are performed regularly

## Troubleshooting

### Common Issues

1. **JWT Verification Failures**
   - Check that the public key in Gateway matches private key in Auth Service
   - Verify token hasn't expired
   - Ensure clock sync between services

2. **Role-Based Access Control Issues**
   - Confirm user has required roles in token payload
   - Check that role mapping is correctly configured

3. **Performance Issues**
   - Consider adjusting cache TTL for token verification
   - Monitor Auth Service response times
   - Check circuit breaker thresholds

## Conclusion

The Auth Service integration with the API Gateway provides a secure, scalable authentication and authorization system for the entire platform. By centralizing these functions, we ensure consistent security policies across all services while maintaining the flexibility of a microservices architecture. 