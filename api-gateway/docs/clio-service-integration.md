# Clio Integration Service Integration Guide

## Overview

This document outlines the integration between the API Gateway and the Clio Integration Service. The Clio Integration Service provides interaction with the Clio Practice Management platform, handling OAuth authentication, data retrieval/modification, and webhook processing. The API Gateway acts as the entry point for all client requests, routing them to the appropriate services.

## Integration Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│             │     │             │     │             │     │             │
│   Clients   │────▶│ API Gateway │────▶│ Clio Service│────▶│  Clio API   │
│             │     │             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │
                           │
                           ▼
                    ┌─────────────┐
                    │  Auth       │
                    │  Service    │
                    └─────────────┘
```

### Data Flow

1. Clients send requests to the API Gateway
2. The Gateway authenticates the user via Auth Service
3. The Gateway forwards Clio-related requests to the Clio Integration Service
4. The Clio Integration Service communicates with the Clio API
5. The Gateway returns data to the client

## Configuration

The Clio Integration Service is configured in `src/config/clio-service.js`, which contains:

- Service endpoints and base URL
- Public paths (not requiring authentication)
- Role-protected endpoints
- Proxy configuration
- Health check configuration
- OAuth settings
- Webhook configuration
- Cache configuration
- Rate limiting settings

## Implementation Components

### 1. Enhanced Routes and Middleware (`src/routes/clio.js`)

The Clio routes implementation provides:

- Authentication verification through Auth Service
- Intelligent caching for different Clio endpoints
- Cache invalidation through webhook events
- Circuit breaker pattern for resilience

### 2. Clio Routes Exposed

#### OAuth Endpoints
- `/api/v1/clio/oauth/authorize` - Initialize Clio OAuth flow
- `/api/v1/clio/oauth/token` - Exchange authorization code for tokens
- `/api/v1/clio/oauth/callback` - OAuth callback endpoint
- `/api/v1/clio/oauth/disconnect` - Disconnect Clio integration

#### Webhook Endpoints
- `/api/v1/clio/webhooks` - Receive events from Clio

#### Data Endpoints
- `/api/v1/clio/matters` - Matter listing and creation
- `/api/v1/clio/matters/:id` - Specific matter operations
- `/api/v1/clio/contacts` - Contact listing and creation
- `/api/v1/clio/contacts/:id` - Specific contact operations
- `/api/v1/clio/user/connections` - User connection management

#### Admin Endpoints
- `/api/v1/clio/admin/users` - Manage users with Clio access
- `/api/v1/clio/admin/settings` - Configure Clio integration settings
- `/api/v1/clio/admin/connections/:id` - Manage specific connections

### 3. Caching Strategy

The Clio integration implements a sophisticated caching strategy:

- **Read-heavy resources**: Matters and contacts are cached for 5 minutes
- **Rarely-changing resources**: Health checks are cached for 30 seconds
- **Write operations**: POST/PUT requests bypass cache and invalidate related cache entries
- **Webhook-based invalidation**: Data changes from Clio trigger cache invalidation

### 4. Rate Limiting

To avoid hitting Clio API rate limits, the Gateway implements:

- Per-client rate limiting (100 requests/minute)
- Separate limits for authenticated vs. unauthenticated requests
- Admin routes with higher limits for administrative functions

## Testing the Integration

### Integration Tests

Run the Clio Service integration tests with:

```bash
npm run test:integration:clio
```

This will:
1. Start a mock Clio Service
2. Test the authentication flow
3. Verify OAuth token handling
4. Test Clio data access
5. Verify webhook processing
6. Test cache invalidation

### End-to-End Tests

Run the end-to-end integration tests to verify the complete flow:

```bash
npm run test:integration:e2e
```

This will:
1. Start mock Auth and Clio services
2. Test the complete user journey from registration to data access
3. Verify authentication persists across service boundaries
4. Test caching and performance

### Manual Testing

You can manually test the Clio integration using the following steps:

1. Start the OAuth flow:
   ```bash
   curl -X GET "http://localhost:3000/api/v1/clio/oauth/authorize" \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
   ```

2. Exchange the code for tokens:
   ```bash
   curl -X POST http://localhost:3000/api/v1/clio/oauth/token \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     -d '{"grant_type":"authorization_code","code":"RECEIVED_CODE","redirect_uri":"YOUR_CALLBACK_URL"}'
   ```

3. Access Clio data:
   ```bash
   curl -X GET http://localhost:3000/api/v1/clio/matters \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
   ```

## Security Considerations

### Authentication Chain

- User authentication is handled by the Auth Service
- Clio API authentication uses OAuth 2.0
- All requests to Clio API include valid access tokens
- Webhook requests are verified using HMAC signatures

### Token Management

- User JWT tokens from Auth Service are verified at the Gateway
- Clio OAuth tokens are stored securely in the Clio Integration Service
- Token refreshing is handled automatically by the Clio Service
- All communication uses HTTPS

## Performance Considerations

### Caching Strategy

- Caching reduces load on both the Gateway and Clio API
- TTL values are calibrated based on data change frequency
- Webhook events ensure cache is invalidated promptly when data changes
- Cache-Control headers optimize browser caching

### Circuit Breaking

- Circuit breaker prevents cascade failures if Clio API is down
- Automatic recovery when Clio API becomes available again
- Retry strategies provide resilience for transient errors

## Troubleshooting

### Common Issues

1. **OAuth Flow Failures**
   - Verify Clio API credentials are correctly configured
   - Check redirect URI matches exactly what's registered with Clio
   - Ensure user has granted appropriate permissions

2. **Webhook Processing Issues**
   - Verify the webhook signature verification is working
   - Check that the Gateway is reachable from Clio servers
   - Confirm correct event types are being subscribed to

3. **Rate Limiting Problems**
   - Adjust rate limits in the configuration
   - Implement backoff strategies for busy periods
   - Consider caching more aggressively

## Conclusion

The Clio Integration Service integration with the API Gateway provides a secure, efficient way to interact with the Clio Practice Management platform. The implementation prioritizes security, performance, and resilience while maintaining a clean separation of concerns between services. 