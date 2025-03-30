# Service Integration Plan

This document outlines the plan for integrating existing and upcoming services with the API Gateway.

## Overview

The integration approach follows these key principles:
- Seamless authentication and authorization
- Consistent API interface
- Resilient communication
- Centralized monitoring
- Performance optimization

## Services Integration

### Auth Service (Current)

The Authentication Service is already integrated with the Gateway and provides core authentication functionality.

#### Integration Points

| Function | Integration Method | Status |
|----------|-------------------|--------|
| User Registration | Direct Proxy | Complete |
| Login/Token Generation | Direct Proxy | Complete |
| Token Refresh | Direct Proxy | Complete |
| User Management | Direct Proxy | Complete |

#### Environment Variables Required

Auth Service needs these environment variables to communicate with the Gateway:

```
# Auth Service .env
API_GATEWAY_URL=http://api-gateway:3000
SERVICE_NAME=auth
SERVICE_URL=http://auth-service:3001/api/v1
HEALTH_CHECK_PATH=/health
REGISTRATION_INTERVAL_MS=300000  # Re-register every 5 minutes
SERVICE_SECRET=your-service-shared-secret
```

#### Configuration Changes

Auth Service requires these changes:

1. Add Gateway registration on service startup:
   ```javascript
   // On service startup
   async function registerWithGateway() {
     try {
       const response = await axios.post(`${process.env.API_GATEWAY_URL}/api/v1/discovery/services`, {
         name: process.env.SERVICE_NAME,
         url: process.env.SERVICE_URL,
         healthUrl: `${process.env.SERVICE_URL}${process.env.HEALTH_CHECK_PATH}`,
         metadata: {
           version: require('../package.json').version
         }
       }, {
         headers: {
           'Authorization': `Bearer ${adminToken}`,
           'X-Service-Secret': process.env.SERVICE_SECRET
         }
       });
       logger.info('Registered with API Gateway', response.data);
       return true;
     } catch (error) {
       logger.error('Failed to register with API Gateway', error);
       return false;
     }
   }
   ```

2. Add re-registration on interval and graceful shutdown:
   ```javascript
   // Set up registration interval
   const registrationInterval = setInterval(registerWithGateway, 
     parseInt(process.env.REGISTRATION_INTERVAL_MS, 10));
     
   // Graceful shutdown
   process.on('SIGTERM', async () => {
     clearInterval(registrationInterval);
     try {
       await axios.delete(`${process.env.API_GATEWAY_URL}/api/v1/discovery/services/${process.env.SERVICE_NAME}`, {
         headers: {
           'Authorization': `Bearer ${adminToken}`,
           'X-Service-Secret': process.env.SERVICE_SECRET
         }
       });
       logger.info('Deregistered from API Gateway');
     } catch (error) {
       logger.error('Failed to deregister from API Gateway', error);
     }
     // Continue with shutdown...
   });
   ```

### Clio Integration Service (Coming Soon)

The Clio Integration Service will connect the platform with Clio's legal practice management software API.

#### Integration Points

| Function | Integration Method | Status |
|----------|-------------------|--------|
| Clio Authentication | Direct Proxy | Pending |
| Matter Management | Direct Proxy | Pending |
| Contact Sync | Direct Proxy | Pending |
| Document Integration | Direct Proxy | Pending |

#### Environment Variables Required

Clio Integration Service will need:

```
# Clio Integration Service .env
API_GATEWAY_URL=http://api-gateway:3000
SERVICE_NAME=clio
SERVICE_URL=http://clio-service:3002/api/v1
HEALTH_CHECK_PATH=/health
REGISTRATION_INTERVAL_MS=300000
SERVICE_SECRET=your-service-shared-secret
JWT_PUBLIC_KEY=same-as-gateway-key
```

#### Configuration Changes

1. Add JWT verification using the same public key as the Gateway
2. Implement service registration logic (as shown in Auth Service example)
3. Update all endpoint responses to match the standard envelope format:
   ```javascript
   {
     "status": "success",
     "data": { /* response data */ },
     "meta": { /* pagination, etc */ }
   }
   ```
4. Implement a `/health` endpoint with detailed health status:
   ```javascript
   app.get('/health', (req, res) => {
     const status = {
       status: 'UP',
       version: require('../package.json').version,
       timestamp: new Date().toISOString(),
       dependencies: {
         clioApi: clioApiStatus,
         database: databaseStatus
       },
       uptime: process.uptime()
     };
     res.json(status);
   });
   ```

### UI Service (Needs Connection)

The UI Service serves the frontend application and needs to connect through the Gateway.

#### Integration Points

| Function | Integration Method | Status |
|----------|-------------------|--------|
| Static Assets | Direct (no proxy) | Pending |
| API Requests | Via API Gateway | Pending |
| WebSocket Connections | Via API Gateway | Pending |

#### Environment Variables Required

UI Service will need:

```
# UI Service .env
API_GATEWAY_URL=http://api-gateway:3000
NEXT_PUBLIC_API_URL=http://api-gateway:3000/api/v1
NEXT_PUBLIC_AUTH_SERVICE_URL=http://api-gateway:3000/api/v1/auth
NEXT_PUBLIC_CLIO_SERVICE_URL=http://api-gateway:3000/api/v1/clio
CORS_ORIGIN=http://localhost:3000,http://api-gateway:3000
```

#### Configuration Changes

1. Update all API client requests to go through the Gateway:
   ```javascript
   // Old approach - direct to services
   const response = await axios.get('http://auth-service:3001/api/v1/users/me');
   
   // New approach - through Gateway
   const response = await axios.get('http://api-gateway:3000/api/v1/auth/users/me');
   ```

2. Configure CORS for Gateway communication:
   ```javascript
   app.use(cors({
     origin: process.env.CORS_ORIGIN.split(','),
     credentials: true
   }));
   ```

3. Update WebSocket connections to use the Gateway:
   ```javascript
   const socket = io(`${process.env.API_GATEWAY_URL}/notifications`, {
     extraHeaders: {
       Authorization: `Bearer ${token}`
     }
   });
   ```

## Integration Timeline

| Phase | Services | Timeline | Dependencies |
|-------|----------|----------|--------------|
| 1 | Auth Service | Complete | None |
| 2 | UI Service | Week 1 | Update to use Gateway endpoints |
| 3 | Clio Integration | Week 2-3 | Clio API Credentials, JWT integration |

## Testing Integration

Each service integration should be tested:

1. Authentication flow through the Gateway
2. Service registration and discovery
3. Health check functionality
4. Performance impact
5. Error handling and circuit breaking

## Rollback Plan

If issues are encountered during integration:

1. Maintain direct service URLs in configuration
2. Create feature flags to toggle Gateway vs. direct communication
3. Document process for reverting to direct service communication

## Post-Integration Monitoring

After integration, monitor:

1. Gateway request latency
2. Service health status
3. Cache hit rates
4. Authentication failures
5. Circuit breaker status 