# Security Headers Configuration

> **Note**: This is a work-in-progress document. When finalized, it should be moved to `smarter-firms-docs/api-gateway/security-headers-configuration.md`.

## Overview

The API Gateway implements a comprehensive set of HTTP security headers to protect against common web vulnerabilities. This document describes the security headers used, their configuration options, and best practices for developers working with the API Gateway.

## Security Headers Implementation

The API Gateway adds the following security headers to all responses:

### Critical Security Headers

| Header | Value | Description |
|--------|-------|-------------|
| `Content-Security-Policy` | Configured per environment | Controls resources the browser is allowed to load |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | Enforces HTTPS connections |
| `X-Content-Type-Options` | `nosniff` | Prevents MIME type sniffing |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Controls referrer information |
| `Permissions-Policy` | Restricted configuration | Controls browser feature permissions |

### Additional Security Headers

| Header | Value | Description |
|--------|-------|-------------|
| `X-XSS-Protection` | `1; mode=block` | Legacy XSS protection for older browsers |
| `X-Frame-Options` | `DENY` | Prevents clickjacking attacks |
| `Cross-Origin-Opener-Policy` | `same-origin` | Isolates cross-origin windows |
| `Cross-Origin-Resource-Policy` | `same-origin` | Prevents cross-origin resource loading |
| `Cross-Origin-Embedder-Policy` | `require-corp` | Ensures all resources are properly CORS-configured |
| `Cache-Control` | `no-store` (for auth endpoints) | Prevents sensitive data caching |

## Content Security Policy

The Content Security Policy (CSP) is configured in `src/config/auth-service.js`:

```javascript
csp: {
  defaultSrc: ["'self'"],
  scriptSrc: ["'self'", "'unsafe-inline'", 'https://cdn.jsdelivr.net'],
  styleSrc: ["'self'", "'unsafe-inline'", 'https://cdn.jsdelivr.net'],
  imgSrc: ["'self'", 'data:', 'https://cdn.jsdelivr.net'],
  connectSrc: ["'self'", 'https://api.smarter-firms.com'],
  fontSrc: ["'self'", 'https://cdn.jsdelivr.net'],
  objectSrc: ["'none'"],
  mediaSrc: ["'self'"],
  frameSrc: ["'none'"],
  reportUri: '/csp-report'
}
```

### CSP Report Collection

The API Gateway includes a CSP reporting endpoint (`/csp-report`) that:

1. Collects CSP violation reports from browsers
2. Logs violations for investigation
3. Enables real-time monitoring of potential attacks

## Permissions Policy

The Permissions Policy header restricts which browser features a page can use. The API Gateway implements a restrictive policy:

```javascript
const permissionsPolicyMap = {
  camera: "none",
  microphone: "none",
  geolocation: "none",
  "interest-cohort": "none",
  accelerometer: "none",
  autoplay: "none",
  battery: "none",
  gyroscope: "none",
  magnetometer: "none",
  payment: "none",
  usb: "none",
  // Allow these features from same origin only
  "display-capture": "self",
  "document-domain": "self",
  fullscreen: "self",
  "encrypted-media": "self",
  "publickey-credentials-get": "self",
  "screen-wake-lock": "self"
};
```

## HTTP Strict Transport Security (HSTS)

The HSTS header is configured with:

- One year max-age (31536000 seconds)
- Include subdomains directive
- Preload flag for browser integration

This configuration ensures that browsers will only connect to the API Gateway using secure HTTPS connections, even if a user tries to use HTTP.

## Implementation Details

### Security Headers Middleware

The security headers are implemented in `src/middleware/securityHeaders.js` using Helmet as a base:

```javascript
const addSecurityHeaders = (req, res, next) => {
  // Apply Helmet middleware first with our custom configuration
  helmet(baseSecurityConfig)(req, res, () => {
    // Add additional custom headers
    
    // X-Content-Type-Options - Already added by Helmet but we explicitly set it again
    res.setHeader('X-Content-Type-Options', 'nosniff');
    
    // Permissions-Policy
    const permissionsList = Object.entries(permissionsPolicyMap).map(
      ([feature, value]) => `${feature}=(${value === 'none' ? '' : value})`
    );
    res.setHeader('Permissions-Policy', permissionsList.join(', '));
    
    // Cache control for auth endpoints
    if (req.path.startsWith('/api/v1/auth')) {
      res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
      res.setHeader('Surrogate-Control', 'no-store');
    }
    
    next();
  });
};
```

## Environment-Specific Configuration

### Production Environment

In production, all security headers are enabled with strict settings:

- CSP with restrictive directives
- HSTS with long max-age and preload
- Cache control headers for sensitive endpoints

### Development Environment

In development, some headers are relaxed to improve developer experience:

- CSP is disabled by default for easier debugging
- HSTS is generally disabled to allow HTTP connections
- Cache settings are less restrictive

## Configuration Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENABLE_CSP` | Enable Content Security Policy | `true` in production |
| `CSP_REPORT_URI` | URI for CSP violation reports | `/api/v1/csp-report` |
| `HSTS_MAX_AGE` | Max age for HSTS in seconds | `31536000` (1 year) |
| `ENABLE_HSTS_PRELOAD` | Enable HSTS preload flag | `true` in production |

## Impact on Developers

### Frontend Developers

Frontend applications need to be compatible with the security headers:

1. All resources must be loaded from allowed domains in CSP
2. Inline scripts and styles need proper nonces or hashes if used
3. Third-party resources need to be explicitly allowed
4. All assets should be served over HTTPS

### API Developers

API developers should be aware of:

1. CORS headers must be properly configured for cross-origin requests
2. iFraming capabilities will be restricted
3. Cache control settings will be enforced for sensitive endpoints

## Testing Security Headers

The API Gateway provides a special endpoint for testing security headers:

```
GET /api/v1/security/headers-test
```

This endpoint returns the headers applied to the response, allowing developers to verify that security headers are correctly implemented.

## Security Header Analysis

You can analyze the security headers using:

1. The [Security Headers](https://securityheaders.com/) website
2. Chrome DevTools Security panel
3. Mozilla Observatory [https://observatory.mozilla.org/](https://observatory.mozilla.org/)

## Common Issues and Solutions

### CSP Blocking Resources

If resources are blocked by CSP:

1. Check the CSP configuration in `src/config/auth-service.js`
2. Add the required domain to the appropriate directive
3. Use CSP reporting to identify blocked resources

### CORS Issues

If experiencing CORS problems with security headers:

1. Ensure the client is using the allowed HTTP methods
2. Check that the origin is in the allowed origins list
3. Verify that credentials handling is consistent

## Best Practices

1. **Don't Disable Security Headers**: Never disable security headers in production
2. **Test with Headers Enabled**: Always test applications with security headers enabled
3. **Monitor CSP Reports**: Regularly review CSP violation reports
4. **Keep Allowed Lists Minimal**: Only allow resources from trusted domains
5. **Update Regularly**: Review and update security header configuration regularly

## References

- [OWASP Secure Headers Project](https://owasp.org/www-project-secure-headers/)
- [MDN: Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
- [MDN: HTTP Strict Transport Security](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security)
- [MDN: Permissions Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy)
- [Smarter Firms Security Standards](https://github.com/Smarter-Firms/smarter-firms-docs/security/standards.md) 