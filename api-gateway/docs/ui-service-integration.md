# UI Service Integration Guide

## Overview

This document outlines the integration between the API Gateway and the UI Service. The UI Service provides the web interface for the Smarter Firms platform, while the API Gateway handles routing, authentication, and serves as the unified entry point for all client requests.

## Integration Architecture

```
┌─────────────┐     ┌─────────────┐
│             │     │             │
│   Browser   │────▶│ API Gateway │
│             │     │             │
└─────────────┘     └─────────────┘
                           │
                           ├───────────────┐
                           │               │
                           ▼               ▼
                    ┌─────────────┐ ┌─────────────┐
                    │  UI Service │ │  Backend    │
                    │  (Frontend) │ │  Services   │
                    └─────────────┘ └─────────────┘
```

### Request Flow

1. Browsers/clients send requests to the API Gateway
2. The Gateway handles authentication via Auth Service
3. For UI/frontend requests:
   - Static assets are served directly or proxied to UI Service
   - API requests are routed to appropriate backend services
4. The Gateway applies appropriate caching, compression, and security headers

## Configuration

The UI Service integration is configured in `src/config/ui-service.js`, which contains:

- Service endpoints and base URL
- CORS configuration specific to UI needs
- Static asset serving configuration
- Proxy configuration for UI backend
- Cache control settings
- Content Security Policy (CSP) configuration

## Implementation Components

### 1. CORS Configuration

CORS settings are specifically tailored for the UI Service:

- Allows requests from UI origins
- Supports credentials for authenticated requests
- Exposes headers needed by UI components
- Configures appropriate preflight caching

### 2. Static Asset Serving

When enabled, the Gateway can serve UI static assets directly:

- Configurable directory for UI assets
- Browser caching with appropriate Cache-Control headers
- Compression for text-based assets (JS, CSS, HTML)
- Content-Type and security headers

### 3. UI Routes

#### Static Asset Routes
- `/ui/*` - UI application files

#### API Routes
- `/api/ui/settings` - User interface settings
- `/api/ui/preferences` - User interface preferences
- `/api/ui/themes` - Theme configuration
- `/api/ui/layouts` - Layout configuration

#### Utility Routes
- `/ui/health` - UI service health check
- `/ui/csp-report` - CSP violation reporting endpoint

### 4. Content Security Policy

The Gateway implements a Content Security Policy to:

- Prevent XSS attacks
- Control which resources can be loaded
- Limit inline scripts and styles
- Report violations for monitoring and debugging

## Caching Strategy

The UI Service integration implements a tiered caching strategy:

### Browser Caching
- Static assets have long TTLs (24 hours)
- Versioned URLs for cache busting
- ETags and conditional requests support

### Server Caching
- API responses cached based on endpoint characteristics
- User-specific data has short or no cache TTL
- Common settings and configuration cached longer

## Security Considerations

### Content Security Policy

The Gateway enforces a strict Content Security Policy that:

- Limits script sources to known domains
- Controls where styles, fonts, and images can be loaded from
- Prevents inline scripts (with specific exceptions)
- Reports violations to a monitoring endpoint

### Authentication

- UI backend API endpoints require valid authentication
- Public routes are explicitly configured
- All requests include appropriate security headers

## Performance Optimizations

- Compression for text-based assets
- Cache-Control headers for browser caching
- Server-side caching for API responses
- Content-length and transfer encoding optimizations

## Testing the Integration

### Manual Testing

Test the UI integration manually:

1. Access the UI through the Gateway:
   ```
   http://localhost:3000/ui/
   ```

2. Check static asset loading and caching:
   ```bash
   curl -I http://localhost:3000/ui/static/js/main.js
   ```

3. Test UI API endpoints:
   ```bash
   curl -X GET http://localhost:3000/api/ui/settings \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
   ```

## Deployment Considerations

### Single-Page Application Support

For single-page applications, the Gateway:

- Serves `index.html` for all unmatched routes
- Preserves URL parameters and paths
- Handles client-side routing

### Multiple UI Applications

If multiple UI applications are deployed:

- Configure each under a different path
- Set up appropriate route mappings
- Apply different cache and security policies as needed

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Verify the UI domain is included in allowed origins
   - Check that all needed headers are in the exposedHeaders list
   - Ensure credentials are enabled if cookies are used

2. **CSP Violations**
   - Check the CSP report endpoint for violation details
   - Adjust CSP directives to allow legitimate resources
   - Use `reportOnly` mode during development

3. **Caching Issues**
   - Clear both browser and server cache during testing
   - Check Cache-Control headers
   - Verify cache key generation includes relevant factors

## Conclusion

The UI Service integration with the API Gateway provides a secure, performant foundation for delivering the Smarter Firms user interface. By centralizing authentication, security policies, and caching, the Gateway ensures consistent behavior while simplifying the UI Service implementation. 