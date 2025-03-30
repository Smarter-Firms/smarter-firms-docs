# Service Discovery Documentation

## Overview

The API Gateway implements a service discovery mechanism that allows for dynamic registration and routing of services. This enables:

1. Automatic service registration and deregistration
2. Health monitoring of services
3. Circuit breaking for fault tolerance
4. Dynamic routing based on service health

## Service Registration

Services can register themselves with the API Gateway by making a POST request to the registration endpoint.

```
POST /api/v1/discovery/services
```

Example request:

```json
{
  "name": "auth-service",
  "url": "http://auth-service:3001/api/v1",
  "healthUrl": "http://auth-service:3001/health",
  "version": "1.0.0",
  "metadata": {
    "description": "Authentication Service",
    "owner": "auth-team"
  }
}
```

Required fields:
- `name`: Service name (used for routing)
- `url`: Base URL of the service

Optional fields:
- `healthUrl`: Health check URL (defaults to `${url}/health`)
- `version`: Service version (defaults to "default")
- `metadata`: Additional service metadata
- `ttl`: Time-to-live in seconds (defaults to 30)

### Service Registration in Code

Services can register themselves programmatically on startup. Here's an example in Node.js:

```javascript
const axios = require('axios');

async function registerWithGateway() {
  try {
    const response = await axios.post('http://api-gateway:3000/api/v1/discovery/services', {
      name: 'auth-service',
      url: process.env.SERVICE_URL || 'http://auth-service:3001/api/v1',
      healthUrl: process.env.HEALTH_URL || 'http://auth-service:3001/health',
      version: process.env.SERVICE_VERSION || '1.0.0',
      metadata: {
        description: 'Authentication Service',
        owner: 'auth-team'
      }
    }, {
      headers: {
        'Authorization': `Bearer ${adminToken}` // Admin token required
      }
    });
    
    console.log('Registered with API Gateway:', response.data);
    return response.data;
  } catch (error) {
    console.error('Failed to register with API Gateway:', error.message);
    // Implement retry logic here
    setTimeout(registerWithGateway, 5000);
  }
}

// Register on startup
registerWithGateway();

// Register signal handlers for graceful shutdown
process.on('SIGTERM', async () => {
  // Deregister service
  try {
    await axios.delete(`http://api-gateway:3000/api/v1/discovery/services/${serviceId}`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`
      }
    });
    console.log('Deregistered from API Gateway');
  } catch (error) {
    console.error('Failed to deregister from API Gateway:', error.message);
  }
  
  process.exit(0);
});
```

## Service Health Checking

The API Gateway periodically checks the health of registered services. Services must expose a health check endpoint that returns a 2xx status code and optionally a JSON response with a `status` field set to "UP" or "OK".

Example health endpoint response:

```json
{
  "status": "UP",
  "checks": [
    {
      "name": "database",
      "status": "UP"
    },
    {
      "name": "redis",
      "status": "UP"
    }
  ]
}
```

If a service fails health checks, it will be marked as DOWN in the registry, and the API Gateway will avoid routing requests to it.

## Circuit Breaking

The API Gateway implements a circuit breaker pattern for fault tolerance. If a service fails repeatedly, the circuit breaker will open, and requests to that service will be immediately rejected with a 503 Service Unavailable response.

The circuit breaker operates in three states:

1. **CLOSED**: Normal operation, requests pass through to the service
2. **OPEN**: The service is failing, requests are immediately rejected
3. **HALF-OPEN**: Testing if the service is back online by letting a single request through

The circuit breaker will automatically transition from OPEN to HALF-OPEN after the reset timeout (default: 30 seconds). If a request succeeds in the HALF-OPEN state, the circuit breaker will close again.

## API Endpoints

### Service Registry Management

- `POST /api/v1/discovery/services` - Register a service
- `DELETE /api/v1/discovery/services/:serviceId` - Deregister a service
- `GET /api/v1/discovery/services` - Get all registered services
- `GET /api/v1/discovery/services/:serviceId` - Get service by ID
- `GET /api/v1/discovery/services/:serviceId/health` - Check service health
- `GET /api/v1/discovery/services/status/:status` - Get services by status

### Health Check Scheduler Management

- `POST /api/v1/discovery/health-check/start` - Start health check scheduler
- `POST /api/v1/discovery/health-check/stop` - Stop health check scheduler

## Request Routing

The API Gateway uses the service registry to dynamically route requests to the appropriate service. Requests are routed based on the service name in the URL path:

```
/api/v1/{service-name}/{path}
```

For example, a request to `/api/v1/auth/users/me` will be routed to the `auth-service` if it's registered and healthy.

## Security

Service registration and deregistration are restricted to users with the `admin` or `gateway_admin` role. Service discovery endpoints are protected with JWT authentication. 