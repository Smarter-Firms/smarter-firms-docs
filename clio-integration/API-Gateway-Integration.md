# API Gateway Integration Guide

This document explains how the Clio Integration Service integrates with the Smarter Firms API Gateway and how to manage this integration.

## Overview

The Clio Integration Service exposes its APIs through the centralized Smarter Firms API Gateway. This provides several benefits:

- **Unified entry point** for all Smarter Firms platform services
- **Centralized authentication and authorization**
- **Consistent rate limiting and monitoring**
- **API documentation consolidation**
- **Service discovery**

## Service Registration

The Clio Integration Service automatically registers itself with the API Gateway during deployment using the `register-service` script. This script:

1. Collects information about the service and its endpoints
2. Sends this information to the API Gateway's registration endpoint
3. Updates the registration if the service is already registered

### Running the Registration Script Manually

You can manually register or update the service registration using:

```bash
npm run register-service
```

This requires the following environment variables to be set:

- `API_GATEWAY_URL`: URL of the API Gateway (default: http://api-gateway:3000)
- `API_GATEWAY_KEY`: API key for the Gateway's admin API
- `SERVICE_URL`: URL where this service is deployed (default: http://localhost:3001)
- `SERVICE_VERSION`: Version of this service (default: 1.0.0)

## Health Checks

The API Gateway periodically checks the health of the Clio Integration Service using the `/api/health` endpoint. The health check:

1. Verifies connectivity to the database
2. Checks Redis connection status
3. Returns service metrics and status information

The health check response format is:

```json
{
  "status": "ok",
  "timestamp": "2023-07-10T15:32:45.123Z",
  "responseTime": "42ms",
  "info": {
    "service": "clio-integration-service",
    "version": "1.0.0",
    "nodeVersion": "v18.16.0",
    "hostname": "clio-integration-1",
    "uptime": 3600,
    "memory": {
      "total": 8192,
      "free": 4096,
      "used": 4096
    }
  },
  "dependencies": {
    "database": {
      "status": "ok",
      "error": null
    },
    "redis": {
      "status": "ok",
      "error": null
    }
  },
  "metrics": {
    "webhooks": {
      "total": 1250,
      "success": 1215,
      "failure": 35,
      "successRate": "97.20"
    }
  }
}
```

If any critical dependency fails, the service returns a 500 status code with the `status` field set to "error".

## Exposed Endpoints

The Clio Integration Service exposes the following endpoints through the API Gateway:

### Authentication Endpoints

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/clio/oauth/authorize` | GET | No | Initiates the OAuth flow with Clio |
| `/api/clio/oauth/callback` | GET | No | OAuth callback endpoint for Clio authentication |

### Clio Data Endpoints

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/clio/connections` | GET | Yes | Get all Clio connections for the authenticated user |
| `/api/clio/connections/:id` | GET | Yes | Get a specific Clio connection by ID |
| `/api/clio/matters` | GET | Yes | Get matters from Clio |
| `/api/clio/contacts` | GET | Yes | Get contacts from Clio |

### Webhook Endpoints

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/webhooks/clio` | POST | No | Webhook endpoint for Clio events |
| `/api/webhooks/register/:userId` | POST | Yes | Register webhooks with Clio |

### Metrics Endpoints

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/metrics/webhooks/dashboard` | GET | Yes | Get webhook metrics dashboard data |
| `/api/metrics/webhooks/daily/:date?` | GET | Yes | Get daily webhook metrics |
| `/api/metrics/webhooks/events` | GET | Yes | Get webhook metrics by event type |
| `/api/metrics/webhooks/errors` | GET | Yes | Get webhook error metrics |
| `/api/metrics/webhooks/success-rate/:date?` | GET | Yes | Get webhook success rate metrics |
| `/api/metrics/webhooks/processing-time/:date?` | GET | Yes | Get webhook processing time metrics |

## Authentication Flow

Authentication with the Clio Integration Service through the API Gateway works as follows:

1. **User Authentication**: Users authenticate with the Auth Service to obtain a JWT token
2. **Gateway Authentication**: This JWT token is included in requests to the API Gateway
3. **Service Authentication**: The Gateway validates the token and forwards it to the Clio Integration Service
4. **Clio API Authentication**: The Clio Integration Service uses stored OAuth tokens to authenticate with the Clio API

## Gateway-to-Service Communication

The API Gateway communicates with the Clio Integration Service using:

1. **Direct HTTP requests** for synchronous API calls
2. **Redis pub/sub** for asynchronous events and notifications
3. **Health check polling** for service health monitoring

## Troubleshooting Gateway Integration

### Service Not Found in Gateway

If the service is not appearing in the API Gateway:

1. Verify the service is running: `curl http://localhost:3001/api/health`
2. Check Gateway connection: `curl http://api-gateway:3000/admin/services`
3. Manually register the service: `npm run register-service`
4. Check logs for registration errors: `docker logs clio-integration-service`

### Authentication Issues

If authentication is failing:

1. Verify JWT token is valid using the Auth Service's token validation endpoint
2. Check that the token has the necessary scopes for the Clio Integration Service
3. Verify that the Gateway's public key for JWT validation is correctly configured

### Endpoint Not Accessible

If an endpoint is not accessible through the Gateway:

1. Verify the endpoint is registered: `curl http://api-gateway:3000/admin/services/clio-integration-service`
2. Check that the endpoint is correctly defined in `src/scripts/register-with-gateway.ts`
3. Update the service registration: `npm run register-service`

## Monitoring the Gateway Integration

Monitor the API Gateway integration using:

1. **Gateway Metrics**: The API Gateway exposes metrics on service usage
2. **Service Logs**: Check the service logs for Gateway-related events
3. **Health Check Responses**: Monitor the health check response times and status

## Security Considerations

1. **API Gateway Key**: The API Gateway key used for registration should be kept secure and rotated regularly
2. **HTTPS**: All communication between the Gateway and the service should use HTTPS in production
3. **JWT Validation**: Ensure the Gateway's JWT validation is correctly configured
4. **Webhook Validation**: The Gateway should validate webhook requests properly
5. **Rate Limiting**: Use appropriate rate limits to prevent abuse

## Updating the API Gateway Integration

When adding new endpoints to the Clio Integration Service:

1. Add the endpoint to the `SERVICE_ENDPOINTS` array in `src/scripts/register-with-gateway.ts`
2. Run `npm run register-service` to update the Gateway registration
3. Update this documentation to reflect the new endpoint 