# API Versioning Strategy

## Overview

The Smarter Firms API Gateway implements a comprehensive API versioning strategy to ensure backward compatibility while allowing for evolution of the APIs. This document outlines our approach to API versioning, including implementation details, client integration, and best practices.

## Versioning Principles

### 1. Semantic Versioning

The API Gateway follows semantic versioning principles with the format `vX.Y`, where:

- **X (Major version)**: Incremented for breaking changes that require client updates.
- **Y (Minor version)**: Incremented for backward-compatible feature additions or improvements.

Minor versions within the same major version are guaranteed to be backward compatible.

### 2. URL-Based Versioning

The primary versioning mechanism is URL-based, with the major version included in the path:

```
https://api.smarterfirms.com/v1/resources
https://api.smarterfirms.com/v2/resources
```

This approach provides clear visibility of the API version being used and simplifies routing in the API Gateway.

### 3. Backwards Compatibility

Existing clients continue to work with their designated API version until explicitly migrated. New features and improvements may be backported to older versions when feasible, but breaking changes are only introduced in new major versions.

## Implementation Details

### Version Routing

The API Gateway implements version routing using the following approach:

```javascript
// Version routing in Express-based API Gateway
const express = require('express');
const app = express();

// Version 1 router
const v1Router = express.Router();
v1Router.use('/auth', require('./v1/auth'));
v1Router.use('/users', require('./v1/users'));
v1Router.use('/firms', require('./v1/firms'));
// ... other v1 routes

// Version 2 router
const v2Router = express.Router();
v2Router.use('/auth', require('./v2/auth'));
v2Router.use('/users', require('./v2/users'));
v2Router.use('/firms', require('./v2/firms'));
// ... other v2 routes

// Mount version routers
app.use('/v1', v1Router);
app.use('/v2', v2Router);

// Default version redirect
app.get('/', (req, res) => {
  res.redirect('/v1');
});

// Version deprecation middleware
app.use('/v1', (req, res, next) => {
  // Add deprecation warning header for v1 if it's scheduled for deprecation
  if (isVersionDeprecated('v1')) {
    res.setHeader(
      'Warning', 
      '299 smarterfirms.com "This API version is deprecated and will be discontinued on YYYY-MM-DD. Please migrate to /v2/"'
    );
  }
  next();
});
```

### API Specification Versioning

Each API version has its own OpenAPI specification document:

```javascript
// Swagger/OpenAPI setup
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

// V1 Swagger specs
const v1Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Smarter Firms API',
      version: '1.0.0',
      description: 'Smarter Firms REST API documentation',
    },
    servers: [
      {
        url: '/v1',
        description: 'Version 1',
      },
    ],
  },
  apis: ['./src/v1/**/*.js'],
};

// V2 Swagger specs
const v2Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Smarter Firms API',
      version: '2.0.0',
      description: 'Smarter Firms REST API documentation',
    },
    servers: [
      {
        url: '/v2',
        description: 'Version 2',
      },
    ],
  },
  apis: ['./src/v2/**/*.js'],
};

const v1Specs = swaggerJsdoc(v1Options);
const v2Specs = swaggerJsdoc(v2Options);

// Mount documentation
app.use('/docs/v1', swaggerUi.serve, swaggerUi.setup(v1Specs));
app.use('/docs/v2', swaggerUi.serve, swaggerUi.setup(v2Specs));
```

### Version Compatibility Layer

The API Gateway includes a compatibility layer to handle version differences:

```javascript
// Version compatibility layer
class VersionCompatibilityService {
  constructor() {
    this.transformers = {
      'v1_to_v2': {
        'UserResponse': this.transformUserV1ToV2,
        'FirmResponse': this.transformFirmV1ToV2,
        // ... other transformers
      },
      'v2_to_v1': {
        'UserResponse': this.transformUserV2ToV1,
        'FirmResponse': this.transformFirmV2ToV1,
        // ... other transformers
      }
    };
  }

  // Transform v1 user response to v2 format
  transformUserV1ToV2(userV1) {
    return {
      id: userV1.id,
      email: userV1.email,
      name: {
        first: userV1.firstName,
        last: userV1.lastName
      },
      role: userV1.role,
      status: userV1.active ? 'ACTIVE' : 'INACTIVE',
      createdAt: userV1.createdAt,
      updatedAt: userV1.updatedAt,
      preferences: userV1.settings || {},
      firms: userV1.firms || []
    };
  }

  // Transform v2 user response to v1 format
  transformUserV2ToV1(userV2) {
    return {
      id: userV2.id,
      email: userV2.email,
      firstName: userV2.name?.first || '',
      lastName: userV2.name?.last || '',
      role: userV2.role,
      active: userV2.status === 'ACTIVE',
      createdAt: userV2.createdAt,
      updatedAt: userV2.updatedAt,
      settings: userV2.preferences || {},
      firms: userV2.firms || []
    };
  }

  // Apply transformation based on model type and version
  transform(data, modelType, fromVersion, toVersion) {
    const transformKey = `${fromVersion}_to_${toVersion}`;
    const transformer = this.transformers[transformKey]?.[modelType];
    
    if (!transformer) {
      throw new Error(`No transformer found for ${modelType} from ${fromVersion} to ${toVersion}`);
    }
    
    if (Array.isArray(data)) {
      return data.map(item => transformer(item));
    }
    
    return transformer(data);
  }
}
```

### Headers-Based Version Fallback

In addition to URL-based versioning, the API Gateway supports request header-based version selection:

```javascript
// Headers-based version selection middleware
app.use((req, res, next) => {
  const urlVersion = req.path.split('/')[1]; // e.g., 'v1', 'v2'
  const headerVersion = req.headers['x-api-version'];
  
  // If no version in URL but specified in header
  if (!urlVersion.match(/^v\d+$/) && headerVersion?.match(/^v\d+$/)) {
    // Rewrite URL with version from header
    req.url = `/${headerVersion}${req.url}`;
  }
  
  next();
});
```

## Version Lifecycle Management

### 1. Version Sunset Policy

API versions have a defined lifecycle:

1. **Active**: Fully supported, receives bug fixes and non-breaking improvements
2. **Deprecated**: Still functional but scheduled for removal, receives only critical bug fixes
3. **Sunset**: No longer available

Major versions are supported for at least 12 months after deprecation notice before sunset.

### 2. Deprecation Notifications

Deprecated endpoints include warning headers:

```javascript
// Deprecated endpoint middleware
const deprecatedEndpoint = (sunsetDate, alternativeEndpoint) => {
  return (req, res, next) => {
    res.setHeader('Deprecation', 'true');
    res.setHeader('Sunset', sunsetDate); // ISO 8601 format
    
    if (alternativeEndpoint) {
      res.setHeader('Link', `<${alternativeEndpoint}>; rel="successor-version"`);
    }
    
    next();
  };
};

// Example usage
v1Router.get(
  '/users/:id/profile', 
  deprecatedEndpoint('2023-12-31', '/v2/users/:id'), 
  userController.getUserProfile
);
```

### 3. Version Metrics

The API Gateway tracks version usage metrics:

```javascript
// Version usage tracking middleware
app.use((req, res, next) => {
  const version = req.path.split('/')[1];
  
  // Skip for non-versioned paths
  if (!version.match(/^v\d+$/)) {
    return next();
  }
  
  // Track request start time
  req.startTime = Date.now();
  
  // Capture original status
  const originalSend = res.send;
  res.send = function(...args) {
    // Calculate request duration
    const duration = Date.now() - req.startTime;
    
    // Log metrics
    metrics.increment('api.requests', 1, {
      version,
      path: req.route?.path || 'unknown',
      method: req.method,
      status: res.statusCode
    });
    
    metrics.histogram('api.response_time', duration, {
      version,
      path: req.route?.path || 'unknown',
      method: req.method
    });
    
    originalSend.apply(res, args);
  };
  
  next();
});
```

## Client Integration

### 1. SDK Versioning

The official client SDKs follow the same versioning scheme as the API:

```javascript
// Example JavaScript SDK with version support
class SmarterFirmsClient {
  constructor(config) {
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl || 'https://api.smarterfirms.com';
    this.version = config.version || 'v1';
    this.axios = axios.create({
      baseURL: `${this.baseUrl}/${this.version}`,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      }
    });
  }
  
  // Example method working across versions
  async getUser(userId) {
    try {
      const response = await this.axios.get(`/users/${userId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }
  
  // SDK version-specific method
  async getFirmMembers(firmId) {
    if (this.version === 'v1') {
      // v1 endpoint
      const response = await this.axios.get(`/firms/${firmId}/members`);
      return response.data;
    } else {
      // v2 endpoint with enhanced data
      const response = await this.axios.get(`/firms/${firmId}/users`);
      return response.data;
    }
  }
}
```

### 2. Version Discovery

Clients can discover supported API versions:

```javascript
// API information endpoint
app.get('/api-info', (req, res) => {
  res.json({
    versions: [
      {
        version: 'v1',
        status: 'deprecated',
        sunset: '2023-12-31'
      },
      {
        version: 'v2',
        status: 'active'
      }
    ],
    currentVersion: 'v2',
    recommendedVersion: 'v2'
  });
});
```

## Breaking vs. Non-Breaking Changes

### Examples of Non-Breaking Changes

These changes don't require a major version increment:

1. **Adding new endpoints**: New API endpoints don't affect existing clients.
2. **Adding optional parameters**: New optional parameters with defaults don't break existing calls.
3. **Adding response fields**: Extending responses with new fields doesn't break existing clients.
4. **Relaxing constraints**: Accepting broader input ranges or formats doesn't break existing clients.

### Examples of Breaking Changes

These changes require a major version increment:

1. **Removing or renaming fields**: Changing field names or removing them breaks existing clients.
2. **Changing field types**: Altering data types of fields breaks existing serialization.
3. **Adding required parameters**: New required parameters break existing calls.
4. **Changing status codes or error formats**: Altering the error response structure breaks existing error handling.
5. **Changing authentication mechanisms**: New authentication requirements break existing clients.

## Migration Guides

### V1 to V2 Migration

The API Gateway provides comprehensive migration guides for clients:

```markdown
# V1 to V2 Migration Guide

## Key Changes

1. **Authentication**: 
   - V1: Token-based authentication via `Authorization: Token <token>`
   - V2: JWT-based authentication via `Authorization: Bearer <token>`

2. **User Resource**:
   - V1: Flat user object with `firstName` and `lastName` fields
   - V2: Structured name object with `name.first` and `name.last` fields

3. **Pagination**:
   - V1: Simple offset/limit pagination
   - V2: Cursor-based pagination with `after` parameter

## Code Examples

### Authentication

```javascript
// V1 Authentication
const tokenV1 = await api.post('/v1/auth/login', credentials);
axios.defaults.headers.common['Authorization'] = `Token ${tokenV1}`;

// V2 Authentication
const authResponseV2 = await api.post('/v2/auth/login', credentials);
axios.defaults.headers.common['Authorization'] = `Bearer ${authResponseV2.accessToken}`;
```

### Fetch Users

```javascript
// V1 User Listing
const usersV1 = await api.get('/v1/users?offset=0&limit=10');
console.log(usersV1.data.map(u => `${u.firstName} ${u.lastName}`));

// V2 User Listing
const usersV2 = await api.get('/v2/users?limit=10');
console.log(usersV2.data.map(u => `${u.name.first} ${u.name.last}`));
```
```

## Best Practices for API Consumers

### 1. Version Specification

Always explicitly specify the API version you're using:

```javascript
// Good: Explicit version
const API_VERSION = 'v2';
const response = await fetch(`https://api.smarterfirms.com/${API_VERSION}/users`);

// Bad: Implicit version
const response = await fetch('https://api.smarterfirms.com/users');
```

### 2. Version Pinning in Dependencies

Pin your API version in package configurations:

```json
// package.json
{
  "dependencies": {
    "smarterfirms-sdk": "^2.0.0"  // Major version pinned to v2 API
  }
}
```

### 3. Regular Version Checks

Periodically check for version upgrades:

```javascript
// Version compatibility check
async function checkApiVersionStatus() {
  try {
    const apiInfo = await fetch('https://api.smarterfirms.com/api-info').then(r => r.json());
    
    const currentVersion = 'v1';
    const versionInfo = apiInfo.versions.find(v => v.version === currentVersion);
    
    if (versionInfo.status === 'deprecated') {
      console.warn(`API version ${currentVersion} is deprecated and will sunset on ${versionInfo.sunset}`);
      console.warn(`Please upgrade to ${apiInfo.recommendedVersion}`);
    }
  } catch (error) {
    console.error('Failed to check API version status', error);
  }
}
```

## Best Practices for API Developers

### 1. Version Compatibility Tests

Each API version has automated compatibility tests:

```javascript
// API compatibility test
describe('API Backward Compatibility', () => {
  it('v2 endpoints should handle v1 request format', async () => {
    // Create v1-formatted request
    const v1Request = {
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com'
    };
    
    // Send to v2 endpoint
    const response = await request(app)
      .post('/v2/users')
      .set('Content-Type', 'application/json')
      .send(v1Request);
      
    // Verify successful processing
    expect(response.status).toBe(201);
    expect(response.body.id).toBeDefined();
  });
});
```

### 2. Version Documentation

Each version has its own dedicated documentation:

```javascript
/**
 * @swagger
 * /v2/users:
 *   post:
 *     summary: Create a new user
 *     description: Creates a new user in the system. This endpoint replaces /v1/users with enhanced features.
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: object
 *                 properties:
 *                   first:
 *                     type: string
 *                   last:
 *                     type: string
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       201:
 *         description: User created successfully
 */
router.post('/users', usersController.createUser);
```

### 3. Change Review Process

All API changes undergo a version impact assessment:

```javascript
// Example version impact assessment
/**
 * Version Impact Assessment
 * 
 * Change: Add user preferences field to user response
 * Affected endpoints: GET /users, GET /users/:id
 * 
 * Breaking change: No
 * Rationale: Adding a new field to the response is backward compatible
 * 
 * Version impact:
 * - Add to v2 API: Yes
 * - Backport to v1 API: Yes (no compatibility issues)
 * 
 * Migration notice required: No
 */
```

## References

- [REST API Versioning - Industry Best Practices](https://www.mnot.net/blog/2012/12/04/api-evolution)
- [Semantic Versioning Specification](https://semver.org/)
- [API Deprecation RFC](https://tools.ietf.org/html/draft-dalal-deprecation-header-01)
- [Smarter Firms API Standards](../api-standards/README.md)
``` 