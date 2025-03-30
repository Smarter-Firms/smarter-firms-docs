# API Gateway Rate Limiting

This document details the rate limiting strategy implemented in the API Gateway for the Smarter Firms platform.

## Rate Limiting Architecture

The Smarter Firms platform uses a multi-tiered, distributed rate limiting approach to protect APIs from abuse while allowing legitimate traffic to flow with appropriate limits.

### Key Features

- **Redis-backed Storage**: Distributed rate limiting using Redis for shared state across instances
- **Sliding Window Algorithm**: More accurate rate tracking compared to fixed windows
- **IP-based Limiting**: Protection against DDoS attacks from individual IPs
- **User-based Limiting**: Separate limits for different user types and permissions
- **Route-specific Configuration**: Different limits for different endpoints based on sensitivity

## Rate Limiting Tiers

The gateway applies different rate limits based on authentication status and user type:

| Tier | User Type | Requests/Min | Burst | Notes |
|------|-----------|--------------|-------|-------|
| 1 | Unauthenticated | 30 | 10 | Most restrictive, applies to public endpoints |
| 2 | Authenticated Users | 100 | 30 | Standard limit for regular authenticated users |
| 3 | Consultant Users | 300 | 60 | Higher limits to support multi-firm access patterns |
| 4 | Internal Services | 600 | 120 | Most permissive, for service-to-service communication |

## Sensitive Endpoint Protection

Special rate limiting rules apply to sensitive operations:

| Endpoint | Rate Limit | Window | Notes |
|----------|------------|--------|-------|
| `/auth/login` | 5 requests | 5 minutes | Per IP address and username combination |
| `/auth/password-reset` | 3 requests | 60 minutes | Per email address |
| `/auth/register` | 3 requests | 24 hours | Per IP address |
| `/auth/verify` | 10 requests | 10 minutes | Per verification token |

## Implementation Details

### Rate Limit Headers

The API Gateway includes rate limit information in response headers:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1614556800
```

### Limiting Algorithm

We use a sliding window algorithm to track request rates:

```javascript
// Pseudocode for sliding window implementation
const slidingWindowRateLimit = async (key, limit, window) => {
  const now = Date.now();
  const windowStart = now - window;
  
  // Remove old entries
  await redis.zremrangebyscore(key, 0, windowStart);
  
  // Count current requests in window
  const currentCount = await redis.zcard(key);
  
  if (currentCount >= limit) {
    return false; // Rate limit exceeded
  }
  
  // Add current request
  await redis.zadd(key, now, uuidv4());
  await redis.expire(key, window / 1000);
  
  return true; // Request allowed
};
```

### Composite Keys

For certain endpoints, we use composite keys to enforce more specific limits:

- Login: `rate:login:${ip}:${username}`
- API calls: `rate:api:${userId}:${endpoint}`
- Consultant access: `rate:consultant:${consultantId}:${firmId}:${endpoint}`

## Graceful Degradation

When Redis is unavailable, the system falls back to in-memory rate limiting:

- Less accurate but provides continued protection
- Gradually restores shared state when Redis becomes available again
- Logs degraded operations for monitoring

## Configuration

Rate limiting is configured in `auth-service.js`:

```javascript
// Example configuration snippet
const rateLimitConfig = {
  tiers: {
    unauthenticated: {
      limit: 30,
      window: 60000, // 1 minute
      burst: 10
    },
    authenticated: {
      limit: 100,
      window: 60000,
      burst: 30
    },
    consultant: {
      limit: 300,
      window: 60000,
      burst: 60
    },
    internal: {
      limit: 600,
      window: 60000,
      burst: 120
    }
  },
  endpoints: {
    '/auth/login': {
      limit: 5,
      window: 300000, // 5 minutes
      keyGenerator: (req) => `rate:login:${req.ip}:${req.body.username}`
    },
    // Additional endpoint-specific configurations
  }
};
```

## Monitoring and Alerting

The rate limiting system includes comprehensive monitoring:

- Metrics collection for rate limit hits and near-misses
- Alerts for suspicious patterns (e.g., sustained limit reaching)
- Dashboards showing rate limit status by endpoint and user type

## References

- [OWASP API Security - API4:2023 Unrestricted Resource Consumption](https://owasp.org/API-Security/editions/2023/en/0xa4-unrestricted-resource-consumption/)
- [Rate Limiting Best Practices](https://cloud.google.com/architecture/rate-limiting-strategies-techniques) 