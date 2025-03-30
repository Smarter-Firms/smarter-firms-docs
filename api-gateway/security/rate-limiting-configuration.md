# Rate Limiting Configuration

> **Note**: This is a work-in-progress document. When finalized, it should be moved to `smarter-firms-docs/api-gateway/rate-limiting-configuration.md`.

## Overview

The API Gateway implements a tiered rate limiting strategy to prevent abuse while ensuring appropriate access levels for different types of users and services. This document describes the rate limiting implementation and configuration options.

## Rate Limiting Tiers

The API Gateway implements different rate limits based on the client type:

### 1. Unauthenticated Requests (Most Restrictive)

- Applied to all requests without valid authentication
- Lowest limits to prevent abuse and brute force attacks
- Default: 30 requests per minute

### 2. Authenticated User Requests (Standard Limits)

- Applied to requests with valid user authentication
- Higher limits than unauthenticated requests
- Default: 100 requests per minute

### 3. Consultant-Specific Endpoints (Higher Limits)

- Applied to consultant users with specific role
- Higher limits to accommodate consulting operations
- Default: 200 requests per minute

### 4. Internal Service-to-Service Communication (Most Permissive)

- Applied to requests from other microservices
- Very high limits for internal operations
- Default: 1000 requests per minute

## Implementation Details

### Sliding Window Algorithm

The rate limiter uses a sliding window algorithm to provide more accurate rate limiting:

- Counts requests within a moving time window
- Provides smoother throttling than fixed window approaches
- Prevents request spikes at window boundaries

```javascript
const slidingWindowRateLimiter = (options) => {
  const {
    windowMs = 60000, // 1 minute default
    maxRequests = 100,
    keyPrefix = 'ratelimit',
    keyGenerator = (req) => req.ip || 'unknown',
    skip = () => false,
    handler = defaultHandler
  } = options;
  
  return async (req, res, next) => {
    if (skip(req)) {
      return next();
    }
    
    const key = `${keyPrefix}:${keyGenerator(req)}`;
    const now = Date.now();
    const windowStart = now - windowMs;
    
    try {
      // Remove old entries outside the current window
      await redisClient.zremrangebyscore(key, 0, windowStart);
      
      // Add current request with current timestamp
      await redisClient.zadd(key, now, `${now}`);
      
      // Set expiration on the key for cleanup
      await redisClient.expire(key, Math.ceil(windowMs / 1000));
      
      // Count requests in the current window
      const requestCount = await redisClient.zcard(key);
      
      // Set headers for rate limit info
      res.setHeader('X-RateLimit-Limit', maxRequests);
      res.setHeader('X-RateLimit-Remaining', Math.max(0, maxRequests - requestCount));
      res.setHeader('X-RateLimit-Reset', Math.ceil((now + windowMs) / 1000));
      
      // Check if rate limit is exceeded
      if (requestCount > maxRequests) {
        return handler(req, res);
      }
      
      next();
    } catch (error) {
      // On Redis error, allow the request (fail open)
      next();
    }
  };
};
```

### Dynamic Rate Limiting

The middleware determines which rate limit to apply based on request properties:

1. First checks if the request is from an internal service
2. Then checks for IP-based rate limiting if enabled
3. For authenticated users, checks if the user is a consultant
4. Falls back to either authenticated or unauthenticated limits

```javascript
const dynamicRateLimiter = (req, res, next) => {
  // Check for internal service first (highest priority)
  const isInternalService = req.headers['x-service-name'] && 
    (apiKey === config.internalServices?.apiKey || 
     req.ip === '127.0.0.1');
  
  if (isInternalService) {
    // Apply internal service limits (most permissive)
    return internalServiceLimiter(req, res, next);
  }
  
  // For authenticated users, check if they're a consultant
  if (req.user) {
    const userRoles = req.user.roles || [];
    if (userRoles.includes('consultant')) {
      return consultantLimiter(req, res, next);
    } else {
      return authenticatedLimiter(req, res, next);
    }
  } else {
    // Apply unauthenticated limits (most restrictive)
    return unauthenticatedLimiter(req, res, next);
  }
};
```

### Route-Specific Rate Limiting

Some routes have special rate limiting rules:

- **Login**: More restrictive to prevent brute force attacks
- **Registration**: Limited to prevent spam account creation
- **Password Reset**: Limited to prevent abuse

## Configuration

### Main Configuration

Rate limiting is configured in `src/config/auth-service.js`:

```javascript
rateLimiting: {
  // Rate limits for authenticated users (requests per minute)
  authenticated: {
    default: 100,
    login: 5,
    register: 3,
    passwordReset: 3
  },
  
  // Rate limits for unauthenticated users (requests per minute)
  unauthenticated: {
    default: 30,
    login: 3,
    register: 2,
    passwordReset: 2
  },
  
  // Rate limits for consultant users (requests per minute)
  consultant: {
    default: 200,
    apiCalls: 250,
    firmData: 300,
    login: 10,
    register: 5
  },
  
  // Rate limits for internal service-to-service communication
  internalService: {
    default: 1000,
    critical: 5000
  },
  
  // IP-based rate limiting settings
  ipBased: {
    enabled: true,
    windowSizeInSeconds: 60,
    maxRequests: 100
  }
}
```

### Environment Variables

Rate limiting can be configured using environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `RATE_LIMIT_AUTHENTICATED_DEFAULT` | Default limit for authenticated users | `100` |
| `RATE_LIMIT_UNAUTHENTICATED_DEFAULT` | Default limit for unauthenticated users | `30` |
| `RATE_LIMIT_CONSULTANT_DEFAULT` | Default limit for consultant users | `200` |
| `RATE_LIMIT_INTERNAL_DEFAULT` | Default limit for internal services | `1000` |
| `RATE_LIMIT_IP_ENABLED` | Enable IP-based rate limiting | `true` |
| `RATE_LIMIT_IP_MAX` | Max requests per window for IP-based limiting | `100` |

## Headers and Response

### Rate Limit Headers

The API Gateway includes rate limit information in the response headers:

- `X-RateLimit-Limit`: Maximum number of requests allowed
- `X-RateLimit-Remaining`: Number of requests remaining in the current window
- `X-RateLimit-Reset`: Time when the rate limit window resets (Unix timestamp)

### Rate Limit Exceeded Response

When a rate limit is exceeded, the API returns:

- HTTP Status: `429 Too Many Requests`
- Response Body:
  ```json
  {
    "status": "error",
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Please try again later.",
    "retryAfter": 60
  }
  ```
- Header: `Retry-After: 60` (seconds until retry is allowed)

## Monitoring and Metrics

Rate limiting metrics are available at the `/metrics/rate-limiting` endpoint:

- **Total rate limited requests**: Count of requests that exceeded limits
- **Rate limits by tier**: Breakdown by user type
- **Rate limits by endpoint**: Breakdown by API endpoint
- **Rate limit distribution**: Distribution of remaining limits

## Best Practices

### For Frontend Developers

1. Implement exponential backoff for retries
2. Respect the `Retry-After` header
3. Cache responses when appropriate
4. Batch requests where possible

### For Internal Services

1. Always include the `x-service-name` header
2. Use the internal service API key for authentication
3. Implement circuit breakers for service protection
4. Monitor rate limit headers to detect issues

## References

- [IETF Rate Limiting Header Fields](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/)
- [OWASP API Security - Lack of Resources & Rate Limiting](https://owasp.org/API-Security/editions/2023/en/0xa4-unrestricted-resource-consumption/)
- [Smarter Firms API Standards](https://github.com/Smarter-Firms/smarter-firms-docs/api/standards.md) 