# Token Reuse Detection

## Overview

Token reuse detection is a security measure implemented in the API Gateway to identify potential token theft and unauthorized access. This document describes the implementation of token reuse detection, its configuration, and best practices.

## Why Token Reuse Detection Matters

Token theft is a common security threat where an attacker steals a user's authentication token and uses it to gain unauthorized access. By detecting unusual token usage patterns, the API Gateway can identify and mitigate potential token theft incidents.

## Implementation Details

The API Gateway implements suspicious token reuse detection with these key features:

### 1. Tracking Token Usage Patterns

The API Gateway tracks token usage patterns across different contexts:

```javascript
const trackTokenUsage = (req, tokenData) => {
  if (!tokenData || !tokenData.jti) {
    return;
  }
  
  const tokenId = tokenData.jti;
  const userId = tokenData.sub;
  const clientIp = req.ip;
  const userAgent = req.headers['user-agent'] || 'unknown';
  
  // Get existing token usage data
  const existingUsage = tokenUsageCache.get(tokenId) || {
    ips: new Set(),
    userAgents: new Set(),
    lastSeen: Date.now()
  };
  
  // Record this usage
  existingUsage.ips.add(clientIp);
  existingUsage.userAgents.add(userAgent);
  existingUsage.lastSeen = Date.now();
  
  // Update cache
  tokenUsageCache.set(tokenId, existingUsage, TOKEN_USAGE_TTL);
  
  // Check for suspicious usage
  if (existingUsage.ips.size > TOKEN_MAX_IPS || 
      existingUsage.userAgents.size > TOKEN_MAX_USER_AGENTS) {
    
    // Log the suspicious activity
    logger.warn('Suspicious token usage detected', {
      tokenId,
      userId,
      distinctIps: Array.from(existingUsage.ips),
      distinctUserAgents: Array.from(existingUsage.userAgents)
    });
    
    // Track security metrics
    metrics.increment('security.suspicious_token_usage', 1, {
      userId
    });
    
    // Add to suspicious tokens set for additional monitoring
    suspiciousTokensSet.add(tokenId);
    
    // Optional: Immediately revoke the token if configured
    if (config.security.autoRevokeReusedTokens) {
      revokeToken(tokenId);
    }
  }
};
```

### 2. IP Address and User Agent Tracking

The detection system identifies tokens used across different IP addresses and user agents:

```javascript
const TOKEN_MAX_IPS = 3; // Maximum number of different IPs allowed per token
const TOKEN_MAX_USER_AGENTS = 2; // Maximum number of different user agents allowed per token
const TOKEN_USAGE_TTL = 24 * 60 * 60 * 1000; // 24 hours

// Middleware to check for suspicious token usage
const detectTokenReuse = (req, res, next) => {
  const token = extractTokenFromRequest(req);
  
  if (!token) {
    return next();
  }
  
  try {
    // Get token data without full verification (just decode)
    const tokenData = jwt.decode(token, { complete: true });
    
    if (!tokenData || !tokenData.payload || !tokenData.payload.jti) {
      return next();
    }
    
    // Track token usage
    trackTokenUsage(req, tokenData.payload);
    
    // Apply additional scrutiny to suspicious tokens
    if (suspiciousTokensSet.has(tokenData.payload.jti)) {
      logger.info('Request with suspicious token', {
        tokenId: tokenData.payload.jti,
        path: req.path,
        method: req.method,
        ip: req.ip,
        userAgent: req.headers['user-agent']
      });
      
      // Apply additional verification if configured
      if (config.security.enhancedVerificationForSuspiciousTokens) {
        req.requiresEnhancedVerification = true;
      }
    }
    
    next();
  } catch (error) {
    // Don't block the request on tracking errors
    logger.error('Error in token reuse detection', {
      error: error.message,
      stack: error.stack
    });
    next();
  }
};
```

### 3. Integration with Security Monitoring

Suspicious token reuse incidents are reported to the security monitoring system:

```javascript
// Report suspicious token usage to security monitoring
const reportSuspiciousTokenUsage = (tokenData, usageData) => {
  const securityEvent = {
    eventType: 'SUSPICIOUS_TOKEN_USAGE',
    severity: 'HIGH',
    timestamp: Date.now(),
    userId: tokenData.sub,
    tokenId: tokenData.jti,
    tokenIssuedAt: tokenData.iat * 1000, // Convert to milliseconds
    distinctIps: Array.from(usageData.ips),
    distinctUserAgents: Array.from(usageData.userAgents),
    tokenClaims: tokenData
  };
  
  // Send to security monitoring system
  securityMonitoring.reportEvent(securityEvent)
    .catch(error => {
      logger.error('Failed to report security event', {
        error: error.message,
        securityEvent
      });
    });
  
  // Also emit websocket event for real-time monitoring dashboard
  if (securityWebsocket.connected) {
    securityWebsocket.emit('security-event', {
      type: 'SUSPICIOUS_TOKEN_USAGE',
      data: securityEvent
    });
  }
};
```

### 4. Enhanced Verification for Suspicious Tokens

Tokens flagged as suspicious undergo additional verification:

```javascript
// Enhanced verification middleware for suspicious tokens
const enhancedTokenVerification = (req, res, next) => {
  if (!req.requiresEnhancedVerification) {
    return next();
  }
  
  try {
    // Get token and user data (already verified at this point)
    const { user, token } = req;
    
    if (!user || !token) {
      return next();
    }
    
    // Check if token was recently issued
    const tokenIssuedAt = new Date(token.iat * 1000);
    const tokenAge = Date.now() - tokenIssuedAt.getTime();
    
    // Tokens less than 5 minutes old are allowed more flexibility
    // since users might be logging in from a new device
    if (tokenAge < 5 * 60 * 1000) {
      return next();
    }
    
    // Geographical anomaly detection for suspicious tokens
    const geoResult = geoIpService.checkIpAgainstUserHistory(user.id, req.ip);
    
    if (geoResult.anomalyScore > 0.7) {
      logger.warn('Geo anomaly detected for suspicious token', {
        userId: user.id,
        tokenId: token.jti,
        ip: req.ip,
        anomalyScore: geoResult.anomalyScore,
        userLocation: geoResult.userLocation,
        historyLocations: geoResult.historyLocations
      });
      
      // Force re-authentication for high-risk requests
      if (isHighRiskOperation(req)) {
        return res.status(401).json({
          error: 'authentication_required',
          error_description: 'Please re-authenticate to proceed with this sensitive operation',
          error_code: 'REVERIFICATION_REQUIRED'
        });
      }
    }
    
    next();
  } catch (error) {
    logger.error('Error in enhanced verification', {
      error: error.message,
      stack: error.stack
    });
    
    // Don't block the request on verification errors, but log them
    next();
  }
};
```

## Configuration Options

Token reuse detection is configured in `src/config/auth-service.js`:

```javascript
security: {
  tokenReuse: {
    enabled: process.env.ENABLE_TOKEN_REUSE_DETECTION !== 'false',
    maxDistinctIps: parseInt(process.env.TOKEN_MAX_IPS) || 3,
    maxDistinctUserAgents: parseInt(process.env.TOKEN_MAX_USER_AGENTS) || 2,
    usageTrackingTtl: parseInt(process.env.TOKEN_USAGE_TTL) || 24 * 60 * 60 * 1000, // 24 hours
    autoRevokeReusedTokens: process.env.AUTO_REVOKE_REUSED_TOKENS === 'true',
    enhancedVerificationForSuspiciousTokens: process.env.ENHANCED_VERIFICATION_FOR_SUSPICIOUS_TOKENS !== 'false'
  }
}
```

## Real-Time Monitoring Dashboard

The API Gateway provides a real-time monitoring dashboard for security teams:

```javascript
// WebSocket connection for real-time security monitoring
const initializeSecurityMonitoring = (server) => {
  const io = new SocketIO(server, {
    path: '/security-monitoring',
    serveClient: false,
    // Only allow authorized connections
    allowRequest: (req, callback) => {
      const isAuthorized = validateMonitoringRequest(req);
      callback(null, isAuthorized);
    }
  });
  
  io.on('connection', (socket) => {
    logger.info('Security monitoring client connected', {
      id: socket.id,
      ip: socket.handshake.address
    });
    
    // Send current suspicious tokens list on connect
    socket.emit('suspicious-tokens', {
      count: suspiciousTokensSet.size,
      tokens: Array.from(suspiciousTokensSet).slice(0, 100) // Limit to 100 for performance
    });
    
    // Set up security event stream
    socket.join('security-events');
    
    socket.on('disconnect', () => {
      logger.info('Security monitoring client disconnected', {
        id: socket.id
      });
    });
  });
  
  // Store for later use
  securityWebsocket = io;
};
```

## Best Practices for Developers

### Token Handling in Client Applications

Client applications should follow these best practices to prevent token theft:

1. **Store tokens securely**: Use secure storage mechanisms like HTTP-only cookies or secure browser storage.

2. **Implement token refresh**: Use short-lived access tokens with refresh tokens to limit the impact of token theft.

3. **Include fingerprinting**: Incorporate device fingerprinting to help detect token reuse.

```javascript
// Example client-side implementation with fingerprinting
const getDeviceFingerprint = () => {
  // Generate a fingerprint based on device characteristics
  const fingerprint = {
    userAgent: navigator.userAgent,
    language: navigator.language,
    screenResolution: `${screen.width}x${screen.height}`,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    platform: navigator.platform
  };
  
  // Create a hash of the fingerprint
  return btoa(JSON.stringify(fingerprint));
};

// Include the fingerprint with authentication requests
const authenticate = async (credentials) => {
  const response = await fetch('/api/v1/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Device-Fingerprint': getDeviceFingerprint()
    },
    body: JSON.stringify({
      ...credentials,
      device_info: {
        type: navigator.platform,
        name: navigator.userAgent
      }
    })
  });
  
  return response.json();
};
```

### Handling Token Reuse Alerts

When a token reuse alert is triggered, follow these steps:

1. Verify if it's a false positive (user using multiple devices or behind a load balancer).
2. Contact the user to confirm if they initiated the activity.
3. If unauthorized, revoke all tokens for the user and force a password reset.

## Troubleshooting

### Common False Positives

1. **Users Behind NAT**: Multiple users behind a NAT gateway may appear to share the same IP.
   
   Solution: Adjust the `maxDistinctIps` setting or implement additional identification methods.

2. **Mobile Networks**: Mobile users may frequently change IP addresses as they move.
   
   Solution: Consider relaxing detection for mobile user agents or implementing additional context-aware checks.

3. **VPN Users**: Users who connect through VPNs may trigger alerts when switching servers.
   
   Solution: Track known VPN IP ranges or implement user education about consistent VPN usage.

## Security Considerations

1. **Balance Security and Usability**: Token reuse detection should be calibrated to minimize false positives while still catching legitimate threats.

2. **Privacy Concerns**: IP address tracking may have privacy implications in some jurisdictions.

3. **Graduated Response**: Rather than immediately blocking access, consider a graduated response based on the risk level.

## References

- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-jwt-bcp)
- [Smarter Firms Authentication Strategy](../Authentication-Strategy.md) 