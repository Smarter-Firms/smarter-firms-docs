# Developer Guide: Integrating with the API Gateway

This guide provides instructions for service teams on how to integrate their microservices with the Smarter Firms API Gateway.

## Table of Contents

1. [Integration Overview](#integration-overview)
2. [Service Registration](#service-registration)
3. [Health Check Implementation](#health-check-implementation)
4. [Authentication](#authentication)
5. [Error Handling](#error-handling)
6. [Response Formats](#response-formats)
7. [Testing Your Integration](#testing-your-integration)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## Integration Overview

The API Gateway serves as the central entry point for all client requests to Smarter Firms services. Benefits of integrating with the gateway include:

- Centralized authentication and authorization
- Service discovery and health monitoring
- Caching and request rate limiting
- Consistent error handling
- Traffic management with circuit breaking
- Unified documentation

The integration process consists of three main steps:

1. Implementing a health check endpoint
2. Registering your service with the gateway
3. Ensuring your API follows the required standards

## Service Registration

### Manual Registration

Services can be registered manually using the Gateway API:

```bash
curl -X POST http://api-gateway:3000/api/v1/discovery/services \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "my-service",
    "url": "http://my-service:8080/api/v1",
    "healthUrl": "http://my-service:8080/health",
    "version": "1.0.0",
    "metadata": {
      "description": "My awesome service",
      "owner": "my-team@example.com",
      "docsUrl": "http://my-service:8080/docs"
    }
  }'
```

### Automated Registration

For production use, implement automated registration in your service:

```javascript
// service-registration.js
const axios = require('axios');
const logger = require('./logger');

// Configuration from environment variables
const config = {
  gatewayUrl: process.env.API_GATEWAY_URL || 'http://api-gateway:3000',
  serviceName: process.env.SERVICE_NAME || 'my-service',
  serviceUrl: process.env.SERVICE_URL || 'http://my-service:8080/api/v1',
  healthUrl: process.env.HEALTH_URL || 'http://my-service:8080/health',
  version: require('../package.json').version,
  registrationInterval: parseInt(process.env.REGISTRATION_INTERVAL_MS || '300000', 10),
  adminToken: process.env.ADMIN_TOKEN
};

// Registration function
async function registerWithGateway() {
  try {
    const response = await axios.post(
      `${config.gatewayUrl}/api/v1/discovery/services`,
      {
        name: config.serviceName,
        url: config.serviceUrl,
        healthUrl: config.healthUrl,
        version: config.version,
        metadata: {
          description: 'My awesome service',
          owner: 'my-team@example.com',
          docsUrl: `${config.serviceUrl}/docs`
        }
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${config.adminToken}`
        },
        timeout: 5000
      }
    );

    logger.info('Successfully registered with API Gateway', { 
      serviceId: response.data.data.id
    });
    
    return response.data.data.id;
  } catch (error) {
    logger.error('Failed to register with API Gateway', {
      error: error.message,
      status: error.response?.status
    });
    return null;
  }
}

// Deregistration function
async function deregisterFromGateway(serviceId) {
  if (!serviceId) return false;
  
  try {
    await axios.delete(
      `${config.gatewayUrl}/api/v1/discovery/services/${serviceId}`,
      {
        headers: {
          'Authorization': `Bearer ${config.adminToken}`
        },
        timeout: 5000
      }
    );
    
    logger.info('Successfully deregistered from API Gateway');
    return true;
  } catch (error) {
    logger.error('Failed to deregister from API Gateway', {
      error: error.message
    });
    return false;
  }
}

// Setup functions
function setupRegistration() {
  // Register immediately
  registerWithGateway().then(serviceId => {
    // Store service ID for deregistration
    if (serviceId) {
      global.serviceId = serviceId;
    }
    
    // Set up periodic re-registration
    setInterval(() => {
      registerWithGateway().then(newServiceId => {
        if (newServiceId) {
          global.serviceId = newServiceId;
        }
      });
    }, config.registrationInterval);
  });
  
  // Handle graceful shutdown
  process.on('SIGTERM', async () => {
    logger.info('Received SIGTERM, deregistering from API Gateway');
    
    if (global.serviceId) {
      await deregisterFromGateway(global.serviceId);
    }
    
    // Then continue with other shutdown tasks
    process.exit(0);
  });
}

module.exports = {
  registerWithGateway,
  deregisterFromGateway,
  setupRegistration
};
```

Include this in your service startup:

```javascript
const serviceRegistration = require('./service-registration');

// Start your Express/Fastify/etc app

// Register with the gateway after app is ready
serviceRegistration.setupRegistration();
```

## Health Check Implementation

Every service must implement a health check endpoint that meets gateway requirements.

### Basic Health Check Example

```javascript
app.get('/health', (req, res) => {
  res.json({
    status: 'UP',  // Required: UP or DOWN
    version: require('../package.json').version,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    dependencies: {
      // Add checks for critical dependencies
      database: isDatabaseConnected() ? 'UP' : 'DOWN',
      redis: isRedisConnected() ? 'UP' : 'DOWN',
      // External APIs
      externalApi: isExternalApiResponding() ? 'UP' : 'DOWN'
    }
  });
});
```

### Health Check Best Practices

1. **Fast Response**: Health checks should respond within 500ms
2. **Minimal Processing**: Avoid heavy operations that could impact service performance
3. **Dependency Checks**: Include critical dependencies but use caching to avoid repeated checks
4. **Detailed Status**: Provide component-level health information for better diagnostics
5. **Cache Results**: Cache health check results for a few seconds to avoid hammering dependencies

## Authentication

Services behind the gateway should rely on the gateway for authentication verification.

### JWT Authentication

The API Gateway uses JWT authentication and passes validated claims to services:

1. **User Information**: The Gateway adds `X-User-Id` and `X-User-Roles` headers
2. **Token Verification**: The Gateway handles token signature verification
3. **Optional Verification**: Services can optionally verify tokens themselves

### Authentication Example

```javascript
// middleware/auth.js
function requireAuth(req, res, next) {
  // Check headers from gateway
  const userId = req.headers['x-user-id'];
  const userRoles = req.headers['x-user-roles'] ? 
    req.headers['x-user-roles'].split(',') : [];
  
  if (!userId) {
    return res.status(401).json({
      status: 'error',
      code: 'UNAUTHORIZED',
      message: 'Authentication required'
    });
  }
  
  // Add user info to request
  req.user = {
    id: userId,
    roles: userRoles
  };
  
  next();
}

function requireRole(roles) {
  return (req, res, next) => {
    // Ensure auth middleware has run
    if (!req.user) {
      return res.status(401).json({
        status: 'error',
        code: 'UNAUTHORIZED',
        message: 'Authentication required'
      });
    }
    
    // Check if user has required role
    const hasRequiredRole = Array.isArray(roles) ? 
      roles.some(role => req.user.roles.includes(role)) : 
      req.user.roles.includes(roles);
    
    if (!hasRequiredRole) {
      return res.status(403).json({
        status: 'error',
        code: 'FORBIDDEN',
        message: 'Insufficient permissions'
      });
    }
    
    next();
  };
}

module.exports = {
  requireAuth,
  requireRole
};
```

## Error Handling

Standardized error handling ensures consistent responses across services:

### Error Format

All service errors should follow this format:

```json
{
  "status": "error",
  "code": "ERROR_CODE",
  "message": "Human-readable error message",
  "details": {
    "field": "More specific information"
  }
}
```

### Error Handling Middleware

```javascript
// middleware/errorHandler.js
function errorHandler(err, req, res, next) {
  // Default error values
  let statusCode = err.statusCode || 500;
  let errorCode = err.code || 'INTERNAL_SERVER_ERROR';
  let message = err.message || 'An unexpected error occurred';
  let details = err.details || null;
  
  // Don't leak error details in production
  if (process.env.NODE_ENV === 'production' && statusCode === 500) {
    message = 'An unexpected error occurred';
    details = null;
  }
  
  // Log the error (with stack in non-production)
  console.error(`[ERROR] ${errorCode}: ${message}`, 
    process.env.NODE_ENV !== 'production' ? err.stack : '');
  
  // Send standardized response
  res.status(statusCode).json({
    status: 'error',
    code: errorCode,
    message,
    details
  });
}

module.exports = errorHandler;
```

## Response Formats

All service responses should follow consistent formats to ensure Gateway compatibility:

### Success Response Format

```json
{
  "status": "success",
  "data": {
    // Response data here
  },
  "meta": {
    // Optional metadata (pagination, etc.)
    "page": 1,
    "limit": 10,
    "total": 100
  }
}
```

### Response Transformation

To ensure consistency, implement a response transformer:

```javascript
// middleware/responseFormatter.js
function responseFormatter(req, res, next) {
  // Store original send function
  const originalSend = res.send;
  
  // Override send
  res.send = function(body) {
    // Skip if already formatted or non-object response
    if (res.headersSent || typeof body !== 'object' || body === null) {
      return originalSend.call(this, body);
    }
    
    // Skip if error response
    if (body.status === 'error') {
      return originalSend.call(this, body);
    }
    
    // Format successful response
    const formattedBody = {
      status: 'success',
      data: body.data || body,  // Use data property if exists, otherwise whole body
      meta: body.meta || {}
    };
    
    // Send formatted response
    return originalSend.call(this, formattedBody);
  };
  
  next();
}

module.exports = responseFormatter;
```

## Testing Your Integration

Follow these steps to test your service integration with the API Gateway:

### Local Testing Checklist

1. **Health Check**: Verify your health endpoint works and returns proper format
2. **Registration**: Test manual registration with the Gateway
3. **Authentication**: Verify your endpoints handle authentication headers correctly
4. **Error Cases**: Test error responses for correct format
5. **Performance**: Verify service response times are within acceptable limits

### Integration Testing Script

```javascript
// test-integration.js
const axios = require('axios');

const gatewayUrl = process.env.API_GATEWAY_URL || 'http://localhost:3000';
const adminToken = process.env.ADMIN_TOKEN;
const serviceName = process.env.SERVICE_NAME || 'test-service';

async function testIntegration() {
  console.log('Testing API Gateway integration...');
  
  try {
    // Step 1: Register service
    console.log('Registering service...');
    const registerResponse = await axios.post(
      `${gatewayUrl}/api/v1/discovery/services`,
      {
        name: serviceName,
        url: `http://${serviceName}:8080/api/v1`,
        healthUrl: `http://${serviceName}:8080/health`,
        version: '1.0.0'
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        }
      }
    );
    
    const serviceId = registerResponse.data.data.id;
    console.log(`Service registered with ID: ${serviceId}`);
    
    // Step 2: Test health check
    console.log('Testing health check...');
    const healthResponse = await axios.get(
      `${gatewayUrl}/api/v1/discovery/services/${serviceId}/health`,
      {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      }
    );
    
    console.log(`Health check status: ${healthResponse.data.data.status}`);
    
    // Step 3: Test request through gateway
    console.log('Testing request through gateway...');
    const apiResponse = await axios.get(
      `${gatewayUrl}/api/v1/${serviceName}/example-endpoint`,
      {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      }
    );
    
    console.log('Request through gateway successful');
    console.log(apiResponse.data);
    
    // Step 4: Deregister service
    console.log('Deregistering service...');
    await axios.delete(
      `${gatewayUrl}/api/v1/discovery/services/${serviceId}`,
      {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      }
    );
    
    console.log('Service deregistered');
    console.log('Integration test complete: SUCCESS');
  } catch (error) {
    console.error('Integration test failed:');
    if (error.response) {
      console.error(`Status: ${error.response.status}`);
      console.error(error.response.data);
    } else {
      console.error(error.message);
    }
    process.exit(1);
  }
}

testIntegration();
```

## Best Practices

### Service Health Checks

1. **Comprehensive Checks**: Include all critical dependencies in health checks
2. **Fast Response**: Optimize for quick responses (<500ms)
3. **Caching**: Cache dependency check results to avoid repeated checks
4. **Circuit Breaking**: Implement timeouts in dependency checks
5. **Detailed Status**: Return component-level status information

### Service Registration

1. **Automation**: Automate registration on service startup
2. **Deregistration**: Deregister on graceful shutdown
3. **Periodic Re-registration**: Re-register periodically to keep information fresh
4. **Metadata**: Include useful metadata like team contacts and documentation URLs
5. **Version Information**: Always include accurate version information

### API Design

1. **Consistent Routes**: Follow RESTful conventions
2. **Versioning**: Include version in URL path (e.g., `/api/v1/resource`)
3. **Response Format**: Adhere to the standard response format
4. **Error Handling**: Use consistent error codes and formats
5. **Input Validation**: Validate all inputs and return descriptive errors

### Performance Optimization

1. **Response Size**: Minimize response payload size
2. **Request Validation**: Fail fast on invalid requests
3. **Caching Headers**: Set appropriate caching headers
4. **Compression**: Enable response compression
5. **Connection Pooling**: Use connection pools for database and external services

## Troubleshooting

### Common Registration Issues

1. **Service not accessible from Gateway**
   - Ensure the service URL is accessible from the Gateway network
   - Check firewall rules and network configuration
   - Verify the service is listening on the specified port

2. **Authentication failures**
   - Verify the admin token used for registration is valid
   - Check JWT expiration and issuer configuration

3. **Health check failures**
   - Ensure health endpoint returns correct format
   - Verify dependencies (database, Redis, etc.) are properly connected
   - Check for timeout issues in health check implementation

### Gateway Communication Issues

1. **Gateway not routing requests**
   - Check if service is registered and marked as UP
   - Verify the service URL format is correct
   - Check for circuit breaker trips

2. **Authentication header problems**
   - Ensure the service is reading the correct headers
   - Check for case sensitivity in header names
   - Verify required headers are being passed through

3. **Response issues**
   - Verify response format matches the expected standard
   - Check for content type and encoding issues
   - Look for missing CORS headers if applicable

### Debugging Tools

1. Use the Gateway dashboard to check service status
2. Examine Gateway logs for routing issues
3. Test direct service access to isolate Gateway issues
4. Use tools like Postman or curl with debug headers
5. Check service registry with Gateway API to verify registration 