# API Gateway Security Middleware

This document outlines the security middleware implemented in the API Gateway for the Smarter Firms platform.

## JWT Validation

### Audience Validation

The gateway implements strict JWT audience validation to prevent token reuse across services:

```javascript
// Example implementation of audience validation
const validateAudience = (token, expectedAudience) => {
  if (!token.aud || !token.aud.includes(expectedAudience)) {
    throw new JwtAudienceError('Invalid token audience');
  }
};
```

- Explicit audience claim validation with detailed error handling
- Double-checking of cached tokens to prevent audience claim issues
- Dedicated logging for audience validation failures
- Specific error responses for different validation failures

### Token Reuse Detection

The gateway implements a token usage monitoring system to detect potential token theft:

- Tracks token usage patterns across different IP addresses and user agents
- Maintains a history of access patterns for each token family
- Triggers alerts when suspicious patterns are detected
- Can automatically revoke tokens with suspicious activity

## Rate Limiting

The gateway implements a tiered rate limiting strategy to protect API endpoints:

| Tier | User Type | Requests/Min | Burst | Notes |
|------|-----------|--------------|-------|-------|
| 1 | Unauthenticated | 30 | 10 | Most restrictive |
| 2 | Authenticated Users | 100 | 30 | Standard access |
| 3 | Consultant Users | 300 | 60 | Higher for multi-firm access |
| 4 | Internal Services | 600 | 120 | Most permissive |

Additional rate limiting features:
- IP-based rate limiting to prevent DDoS attacks
- Route-specific limiting for sensitive operations (login, password reset)
- Redis-backed distributed rate limiting for cluster deployments
- Configurable options in `auth-service.js` for all tiers

## HTTP Security Headers

The gateway adds comprehensive HTTP security headers to all responses:

```javascript
// Example header configuration
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "trusted-cdn.com"],
      styleSrc: ["'self'", "'unsafe-inline'", "trusted-cdn.com"],
      imgSrc: ["'self'", "data:", "trusted-cdn.com"],
      connectSrc: ["'self'", "api.smarter-firms.com"],
      fontSrc: ["'self'", "trusted-cdn.com"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    }
  },
  hsts: {
    maxAge: 15552000,
    includeSubDomains: true,
    preload: true
  }
}));
```

Implemented headers include:
- Content-Security-Policy with restrictive settings
- Strict-Transport-Security with long max-age
- X-Content-Type-Options: nosniff
- Referrer-Policy: strict-origin-when-cross-origin
- Permissions-Policy with detailed browser feature restrictions

Additional security features:
- Backup headers in case Helmet middleware fails
- Metrics tracking for security headers
- Regular security header auditing

## Security Monitoring

The gateway includes comprehensive security monitoring:

- Detailed logging of authentication events
- Metrics collection for security-related operations
- Integration with monitoring systems for real-time alerting
- Regular security report generation

## Implementation Notes

- All security middleware is initialized in the application bootstrap process
- Configuration values are externalized to environment variables
- Circuit breakers are implemented for critical security services
- Regular security audits review the middleware implementation 