# API Gateway Security Measures

> **Note**: This is a work-in-progress document. When finalized, it should be moved to `smarter-firms-docs/api-gateway/security-measures.md`.

## Overview

This document outlines the security measures implemented in the Smarter Firms API Gateway. The gateway serves as the primary entry point for all client requests and implements multiple layers of security to protect our services and user data.

## Authentication Security

### Enhanced JWT Authentication

The API Gateway implements a robust JWT-based authentication system with the following security features:

#### JWT Verification with JWKS Support

- **JWKS Integration**: Fetches and caches public keys from the authentication service's JWKS endpoint
- **Key Rotation**: Supports automatic key rotation with configurable refresh intervals
- **Circuit Breaker Pattern**: Prevents cascading failures when JWKS service is unavailable
- **Caching**: Keys are cached both in Redis and in-memory for optimal performance

#### Audience Validation

- **Strict Audience Checking**: Validates the `aud` claim in JWTs to ensure tokens are only used with their intended service
- **Pre-Verification Check**: Performs audience validation before full token verification to fail fast
- **Double-Checking**: Re-checks audience for cached tokens as an additional security measure
- **Customizable Configuration**: Audience values can be configured per environment

#### Token Security Features

- **Token Blacklisting**: Revoked tokens are blacklisted to prevent reuse after logout
- **Token Fingerprinting**: Creates unique fingerprints for tokens to track usage
- **Verification Caching**: Successful verifications are cached to improve performance
- **Source Tracking**: Tokens are tracked across IP addresses and user agents

#### Suspicious Activity Detection

- **Token Reuse Detection**: Identifies potential token theft by monitoring usage across IPs
- **Concurrent Usage Alerting**: Alerts when the same token is used from different locations
- **Security Event Logging**: Records authentication failures and suspicious events
- **Integration with Security Monitoring**: Feeds data to the security monitoring service

### Security Implementation Details

#### Token Extraction Methods

The middleware supports multiple token extraction methods in the following order of preference:

1. Authorization Header (`Bearer` token)
2. Cookies (configurable cookie name)
3. Query parameters (configurable parameter name)

```javascript
const extractToken = (req) => {
  const methods = authConfig.auth.tokenExtraction || ['header', 'cookie', 'query'];
  let token = null;
  
  for (const method of methods) {
    if (method === 'header' && req.headers.authorization) {
      const parts = req.headers.authorization.split(' ');
      if (parts.length === 2 && parts[0] === 'Bearer') {
        token = parts[1];
        break;
      }
    } else if (method === 'cookie' && req.cookies && req.cookies[authConfig.auth.cookieName]) {
      token = req.cookies[authConfig.auth.cookieName];
      break;
    } else if (method === 'query' && req.query && req.query[authConfig.auth.queryParamName]) {
      token = req.query[authConfig.auth.queryParamName];
      break;
    }
  }
  
  return token;
};
```

#### Token Verification Process

The middleware follows a detailed verification process:

1. Check if the requested path is public (no auth required)
2. Extract token using configured methods
3. Create a token fingerprint for cache/blacklist checks
4. Check if token is blacklisted (revoked)
5. Check if verification result is cached
6. If not cached, verify token using JWKS or public key
7. Cache verification result for future requests
8. Attach user info to the request object

#### Error Handling

Specific error responses are provided for different types of authentication failures:

- `TOKEN_EXPIRED`: When the token's expiration time has passed
- `TOKEN_REVOKED`: When a token appears on the blacklist
- `INVALID_AUDIENCE`: When the token's audience claim doesn't match the expected value
- `INVALID_TOKEN`: When the token signature verification fails
- `TOKEN_NOT_ACTIVE`: When the token's not-before time hasn't been reached

## Best Practices for Developers

### Authentication Integration

When developing services that integrate with the API Gateway:

1. **Always check authentication**: The gateway adds user information to `req.user`, but services should validate this exists
2. **Use role checking**: Leverage the `hasRole` middleware for role-specific endpoints
3. **Don't implement your own JWT verification**: Rely on the gateway for token verification
4. **Include proper headers**: When making service-to-service calls, include `x-service-name` and API key headers

### Security Headers

All responses from the API Gateway include security headers. Frontend developers should:

1. Comply with the Content Security Policy directives
2. Implement proper CORS behavior for cross-origin requests
3. Never embed resources from untrusted domains
4. Report any CSP violations to the security team

## Configuration Reference

See the following documents for detailed configuration references:

- [Rate Limiting Configuration](./rate-limiting-configuration.md)
- [Security Headers Configuration](./security-headers-configuration.md)
- [Auth Service Integration](./auth-service-integration.md)

## Monitoring and Metrics

Security metrics are available through the metrics endpoint (`/metrics/security`) and include:

- Authentication success/failure rates
- Token cache hit/miss ratios
- Rate limiting events
- Blacklisted token attempts
- Security header applications

## References

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [JWT Best Practices (RFC 8725)](https://datatracker.ietf.org/doc/html/rfc8725)
- [Smarter Firms Security Standards](https://github.com/Smarter-Firms/smarter-firms-docs/security/standards.md) 