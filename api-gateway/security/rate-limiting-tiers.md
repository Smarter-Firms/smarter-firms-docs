# Rate Limiting Tiers

## Overview

The API Gateway implements a comprehensive rate limiting strategy with different tiers for various types of users and endpoints. This document describes the rate limiting tiers, their implementation, and configuration options.

## Rate Limiting Tiers Implementation

The API Gateway implements different rate limiting tiers based on the type of request and user:

### 1. Unauthenticated Requests (Most Restrictive)

Unauthenticated requests are subject to the strictest rate limits to prevent abuse:

```javascript
const unauthenticatedLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // 30 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.ip; // Rate limit by IP address
  },
  handler: (req, res) => {
    logger.warn('Rate limit exceeded for unauthenticated request', {
      ip: req.ip,
      path: req.path,
      method: req.method,
      userAgent: req.headers['user-agent']
    });
    
    res.status(429).json({
      error: 'rate_limit_exceeded',
      error_description: 'Too many requests, please try again later',
      retry_after: Math.ceil(req.rateLimit.resetTime / 1000 - Date.now() / 1000)
    });
  }
});
```

### 2. Authenticated User Requests (Moderate Limits)

Authenticated users receive higher limits than unauthenticated requests:

```javascript
const authenticatedLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // 300 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Use user ID as the key if authenticated
    return req.user ? req.user.id : req.ip;
  },
  handler: (req, res) => {
    logger.warn('Rate limit exceeded for authenticated user', {
      userId: req.user?.id,
      ip: req.ip,
      path: req.path,
      method: req.method
    });
    
    res.status(429).json({
      error: 'rate_limit_exceeded',
      error_description: 'Too many requests, please try again later',
      retry_after: Math.ceil(req.rateLimit.resetTime / 1000 - Date.now() / 1000)
    });
  }
});
```

### 3. Consultant-Specific Endpoints (Higher Limits)

Consultant users accessing specific endpoints receive higher rate limits to support their workflow:

```javascript
const consultantLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 600, // 600 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Use consultant ID as the key
    return req.user.consultantId || req.user.id;
  },
  skip: (req) => {
    // Skip if not a consultant
    return !req.user || !req.user.roles.includes('consultant');
  },
  handler: (req, res) => {
    logger.warn('Rate limit exceeded for consultant', {
      consultantId: req.user.consultantId,
      userId: req.user.id,
      ip: req.ip,
      path: req.path
    });
    
    res.status(429).json({
      error: 'rate_limit_exceeded',
      error_description: 'Too many requests, please try again later',
      retry_after: Math.ceil(req.rateLimit.resetTime / 1000 - Date.now() / 1000)
    });
  }
});
```

### 4. Internal Service-to-Service Communication (Most Permissive)

Service-to-service communication has the highest rate limits to ensure smooth operation:

```javascript
const serviceLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 1000, // 1000 requests per minute
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.headers['x-service-id'] || req.ip;
  },
  skip: (req) => {
    // Skip if not a service-to-service request
    const serviceId = req.headers['x-service-id'];
    const serviceKey = req.headers['x-service-key'];
    
    if (!serviceId || !serviceKey) {
      return true;
    }
    
    return !validateServiceRequest(serviceId, serviceKey);
  },
  handler: (req, res) => {
    logger.warn('Rate limit exceeded for service request', {
      serviceId: req.headers['x-service-id'],
      ip: req.ip,
      path: req.path
    });
    
    res.status(429).json({
      error: 'rate_limit_exceeded',
      error_description: 'Service rate limit exceeded',
      retry_after: Math.ceil(req.rateLimit.resetTime / 1000 - Date.now() / 1000)
    });
  }
});
```

## IP-Based Rate Limiting for DDoS Prevention

In addition to user-based rate limits, the API Gateway implements IP-based rate limiting to prevent DDoS attacks:

```javascript
const ipLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 500, // 500 requests per 5 minutes
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.ip,
  skip: (req) => {
    // Skip for trusted networks
    return isTrustedNetwork(req.ip);
  },
  handler: (req, res) => {
    logger.warn('IP-based rate limit exceeded', {
      ip: req.ip,
      userAgent: req.headers['user-agent']
    });
    
    // Track potential DDoS attempts
    if (req.rateLimit.current > req.rateLimit.limit * 2) {
      metrics.increment('security.potential_ddos', 1, {
        ip: req.ip
      });
    }
    
    res.status(429).json({
      error: 'rate_limit_exceeded',
      error_description: 'Too many requests from this IP address',
      retry_after: Math.ceil(req.rateLimit.resetTime / 1000 - Date.now() / 1000)
    });
  }
});
```

## Route-Specific Rate Limiting for Sensitive Operations

Sensitive operations like login and password reset have specific rate limits:

```javascript
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 login attempts per 15 minutes
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Rate limit by email/username + IP address
    const username = req.body.email || req.body.username || 'unknown';
    return `${username}:${req.ip}`;
  },
  handler: (req, res) => {
    logger.warn('Login rate limit exceeded', {
      username: req.body.email || req.body.username,
      ip: req.ip
    });
    
    // Track failed login attempts for security monitoring
    metrics.increment('security.login_rate_limit_exceeded', 1, {
      ip: req.ip
    });
    
    res.status(429).json({
      error: 'rate_limit_exceeded',
      error_description: 'Too many login attempts, please try again later',
      retry_after: Math.ceil(req.rateLimit.resetTime / 1000 - Date.now() / 1000)
    });
  }
});

const passwordResetLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 reset attempts per hour
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Rate limit by email + IP address
    const email = req.body.email || 'unknown';
    return `${email}:${req.ip}`;
  },
  handler: (req, res) => {
    logger.warn('Password reset rate limit exceeded', {
      email: req.body.email,
      ip: req.ip
    });
    
    res.status(429).json({
      error: 'rate_limit_exceeded',
      error_description: 'Too many password reset attempts, please try again later',
      retry_after: Math.ceil(req.rateLimit.resetTime / 1000 - Date.now() / 1000)
    });
  }
});
```

## Configuration Options

The rate limiting tiers are configured in `src/config/auth-service.js`:

```javascript
rateLimiting: {
  // Unauthenticated requests
  unauthenticated: {
    windowMs: parseInt(process.env.RATE_LIMIT_UNAUTH_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_UNAUTH_MAX) || 30
  },
  
  // Authenticated user requests
  authenticated: {
    windowMs: parseInt(process.env.RATE_LIMIT_AUTH_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_AUTH_MAX) || 300
  },
  
  // Consultant-specific endpoints
  consultant: {
    windowMs: parseInt(process.env.RATE_LIMIT_CONSULTANT_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_CONSULTANT_MAX) || 600
  },
  
  // Service-to-service communication
  service: {
    windowMs: parseInt(process.env.RATE_LIMIT_SERVICE_WINDOW_MS) || 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_SERVICE_MAX) || 1000
  },
  
  // IP-based rate limiting
  ip: {
    windowMs: parseInt(process.env.RATE_LIMIT_IP_WINDOW_MS) || 5 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_IP_MAX) || 500
  },
  
  // Sensitive operations
  login: {
    windowMs: parseInt(process.env.RATE_LIMIT_LOGIN_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_LOGIN_MAX) || 10
  },
  
  passwordReset: {
    windowMs: parseInt(process.env.RATE_LIMIT_PASSWORD_RESET_WINDOW_MS) || 60 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_PASSWORD_RESET_MAX) || 3
  }
}
```

## Applying Rate Limiters to Routes

The API Gateway applies rate limiters to routes based on the request type:

```javascript
// Apply IP-based limiter first to prevent DDoS
app.use(ipLimiter);

// Apply route-specific rate limiters
app.use('/api/v1/auth/login', loginLimiter);
app.use('/api/v1/auth/password-reset', passwordResetLimiter);

// Apply tiered rate limiters based on authentication status
app.use((req, res, next) => {
  if (isServiceRequest(req)) {
    return serviceLimiter(req, res, next);
  }
  
  if (req.user) {
    if (req.user.roles.includes('consultant')) {
      return consultantLimiter(req, res, next);
    }
    return authenticatedLimiter(req, res, next);
  }
  
  return unauthenticatedLimiter(req, res, next);
});
```

## Monitoring and Alerting

The API Gateway tracks rate limiting metrics for monitoring and alerting:

```javascript
// Rate limit middleware that tracks metrics
const trackRateLimitMetrics = (req, res, next) => {
  const originalSend = res.send;
  
  res.send = function (body) {
    if (res.statusCode === 429) {
      // Track rate limit exceeded
      metrics.increment('rate_limit.exceeded', 1, {
        path: req.path,
        method: req.method,
        authenticated: !!req.user,
        ip: req.ip
      });
      
      // Alert on suspicious patterns
      if (req.rateLimit && req.rateLimit.current > req.rateLimit.limit * 3) {
        logger.error('Potential abuse detected', {
          ip: req.ip,
          path: req.path,
          method: req.method,
          user: req.user?.id,
          rateLimitCurrent: req.rateLimit.current,
          rateLimitLimit: req.rateLimit.limit
        });
      }
    }
    
    return originalSend.apply(this, arguments);
  };
  
  next();
};

app.use(trackRateLimitMetrics);
```

## Best Practices for Developers

### Client-Side Rate Limit Handling

Clients should properly handle rate limit responses:

```javascript
// Example client-side handling
const apiRequest = async (url, options) => {
  try {
    const response = await fetch(url, options);
    
    if (response.status === 429) {
      const data = await response.json();
      const retryAfter = data.retry_after || 60;
      
      // Implement exponential backoff
      await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
      
      // Retry the request
      return apiRequest(url, options);
    }
    
    return response;
  } catch (error) {
    // Handle other errors
    console.error('API request failed', error);
    throw error;
  }
};
```

### Batch Operations for High-Volume Clients

For clients that need to make many requests, batch operations should be used where possible:

```javascript
// Instead of:
for (const item of items) {
  await api.updateItem(item);
}

// Use batch operations:
await api.updateItems(items);
```

## Troubleshooting

### Common Rate Limiting Issues

1. **Unexpected Rate Limiting**: Client is being rate limited unexpectedly.
   
   Solution: Check if the client is properly authenticated and using the correct tier.

2. **Shared IP Address Rate Limiting**: Multiple users behind a NAT or proxy are sharing rate limits.
   
   Solution: Consider implementing client-specific tokens or additional identification methods.

3. **Service Rate Limiting**: Service-to-service communication is being rate limited.
   
   Solution: Verify service identification headers and authentication.

## Security Considerations

1. **Balance Security and Usability**: Rate limits should be set high enough to allow legitimate usage but low enough to prevent abuse.

2. **Monitor and Adjust**: Regularly review rate limit metrics and adjust limits based on actual usage patterns.

3. **Consider Geographic Factors**: Different regions may have different legitimate usage patterns.

## References

- [OWASP API Security Top 10: API4:2019 - Lack of Resources & Rate Limiting](https://owasp.org/www-project-api-security/)
- [Rate Limiting Best Practices](https://cloud.google.com/architecture/rate-limiting-strategies-techniques)
- [Smarter Firms API Security Standards](https://github.com/Smarter-Firms/smarter-firms-docs/security/api-security.md) 