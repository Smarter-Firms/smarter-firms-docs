# JWT Audience Validation

## Overview

JWT audience validation is a critical security measure implemented in the API Gateway to ensure that tokens are only used with their intended services. This document describes the implementation of JWT audience validation, its configuration, and best practices.

## Why Audience Validation Matters

The `aud` (audience) claim in a JWT token specifies the intended recipient of the token. Without proper audience validation, tokens issued for one service could potentially be used with another service, creating a security vulnerability.

## Implementation Details

The API Gateway implements comprehensive audience validation with these key features:

### 1. Explicit Audience Claim Validation

The JWT verification middleware performs explicit audience validation:

```javascript
const verifyToken = (token, options) => {
  try {
    // Load public key from cache or fetch if not available
    const publicKey = getPublicKeyFromCache(options.keyId);
    
    // Verify token with explicit audience check
    const decoded = jwt.verify(token, publicKey, {
      algorithms: ['RS256'],
      audience: options.expectedAudience, // Explicit audience check
      issuer: config.auth.tokenIssuer,
      complete: true
    });
    
    // Additional audience validation check
    if (!decoded.payload.aud || 
        (Array.isArray(decoded.payload.aud) && 
         !decoded.payload.aud.includes(options.expectedAudience)) ||
        (typeof decoded.payload.aud === 'string' && 
         decoded.payload.aud !== options.expectedAudience)) {
      
      // Log audience validation failure
      logger.warn('JWT audience validation failed', {
        expectedAudience: options.expectedAudience,
        receivedAudience: decoded.payload.aud,
        tokenId: decoded.payload.jti
      });
      
      throw new Error('Token audience validation failed');
    }
    
    return decoded.payload;
  } catch (error) {
    // Enhanced error handling for audience failures
    if (error.message.includes('audience')) {
      metrics.increment('security.jwt.audience_validation_failure');
      throw new AuthError('Invalid token audience', 'INVALID_AUDIENCE');
    }
    throw error;
  }
};
```

### 2. Double-Checking for Cached Tokens

For performance reasons, the API Gateway caches valid tokens. When retrieving tokens from the cache, audience validation is verified again:

```javascript
const getTokenFromCache = (tokenId, expectedAudience) => {
  const cachedToken = tokenCache.get(tokenId);
  
  if (cachedToken) {
    // Double-check audience even for cached tokens
    if (!cachedToken.aud || 
        (Array.isArray(cachedToken.aud) && !cachedToken.aud.includes(expectedAudience)) ||
        (typeof cachedToken.aud === 'string' && cachedToken.aud !== expectedAudience)) {
      
      // Remove invalid token from cache
      tokenCache.delete(tokenId);
      
      // Log the cache audience mismatch
      logger.warn('Cached token audience mismatch', {
        expectedAudience,
        tokenAudience: cachedToken.aud,
        tokenId
      });
      
      return null;
    }
    
    return cachedToken;
  }
  
  return null;
};
```

### 3. Detailed Logging for Security Monitoring

The API Gateway includes comprehensive logging for audience validation failures:

```javascript
// Log audience validation failures with context
const logAudienceFailure = (req, expectedAudience, providedAudience) => {
  logger.warn('JWT audience validation failed', {
    path: req.path,
    method: req.method,
    ip: req.ip,
    expectedAudience,
    providedAudience,
    userAgent: req.headers['user-agent'],
    serviceId: req.headers['x-service-id']
  });
  
  // Track metrics for audience failures
  metrics.increment('security.jwt.audience_validation_failure', 1, {
    path: req.path
  });
};
```

### 4. Specific Error Responses

The API Gateway provides specific error responses for audience validation failures to help with debugging while not revealing sensitive information:

```javascript
// When audience validation fails
res.status(401).json({
  error: 'authentication_error',
  error_description: 'Invalid token audience',
  error_code: 'INVALID_AUDIENCE',
  request_id: req.id
});
```

## Configuration Options

### JWT Audience Settings

JWT audience validation is configured in `src/config/auth-service.js`:

```javascript
jwt: {
  audiences: {
    apiGateway: 'smarter-firms-api-gateway',
    dataService: 'smarter-firms-data-service',
    authService: 'smarter-firms-auth-service',
    uiService: 'smarter-firms-ui-service',
    // Other services...
  },
  // Audience validation can be temporarily disabled in development
  validateAudience: process.env.VALIDATE_JWT_AUDIENCE === 'false' ? false : true
}
```

## Best Practices for Developers

### Token Generation

When generating tokens, always specify the correct audience:

```javascript
// Example token generation in Auth Service
const generateToken = (user, audience) => {
  return jwt.sign(
    {
      sub: user.id,
      aud: audience, // Explicitly set the audience
      // Other claims...
    },
    privateKey,
    { algorithm: 'RS256', expiresIn: '1h' }
  );
};
```

### Service-to-Service Communication

For service-to-service communication, request tokens with the appropriate audience:

```javascript
// Example request for service-specific token
const getServiceToken = async (targetService) => {
  const response = await fetch(`${AUTH_SERVICE_URL}/api/v1/auth/service-token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${serviceApiKey}`
    },
    body: JSON.stringify({
      service_id: SERVICE_ID,
      target_audience: targetService
    })
  });
  
  const { token } = await response.json();
  return token;
};
```

## Troubleshooting

### Common Issues with Audience Validation

1. **Token Used with Wrong Service**: If a token intended for one service is used with another, audience validation will fail.
   
   Solution: Request a token with the correct audience for each service.

2. **Missing Audience Claim**: If tokens are generated without an audience claim, validation will fail.
   
   Solution: Ensure all token generation includes the appropriate audience claim.

3. **Audience Mismatch in Development**: Developers may encounter audience validation issues in local development.
   
   Solution: Use proper audience values in development or temporarily disable audience validation using the environment variable.

## Security Considerations

1. **Never Disable in Production**: Audience validation should never be disabled in production environments.

2. **Audit Audience Validation Failures**: Regular auditing of audience validation failures can help identify potential security issues or misconfigured services.

3. **Key Rotation Impact**: When rotating signing keys, ensure that audience claims are preserved and validated with the new keys.

## References

- [JWT RFC 7519 - Audience Claim](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.3)
- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [Smarter Firms Authentication Strategy](../Authentication-Strategy.md) 