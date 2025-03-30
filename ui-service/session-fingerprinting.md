# Session Fingerprinting

## Overview

Session fingerprinting is an essential security feature implemented in the UI Service to detect and prevent session hijacking. This document describes the implementation of session fingerprinting, its integration with the authentication flow, and best practices.

## Implementation Details

The UI Service implements comprehensive session fingerprinting with these key features:

### 1. Multiple Fingerprinting Factors

The session fingerprinting system collects and analyzes multiple device characteristics:

```javascript
const generateDeviceFingerprint = () => {
  // Basic device information
  const basicInfo = {
    userAgent: navigator.userAgent,
    language: navigator.language,
    platform: navigator.platform,
    screenResolution: `${window.screen.width}x${window.screen.height}`,
    colorDepth: window.screen.colorDepth,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    timezoneOffset: new Date().getTimezoneOffset(),
    deviceMemory: navigator.deviceMemory || 'unknown',
    hardwareConcurrency: navigator.hardwareConcurrency || 'unknown',
    doNotTrack: navigator.doNotTrack || 'unknown',
  };

  // Advanced canvas fingerprinting
  const canvasFingerprint = getCanvasFingerprint();
  
  // Audio fingerprinting
  const audioFingerprint = getAudioFingerprint();
  
  // WebGL fingerprinting
  const webglFingerprint = getWebGLFingerprint();
  
  // Combine all fingerprints
  const combinedFingerprint = {
    ...basicInfo,
    canvas: canvasFingerprint,
    audio: audioFingerprint,
    webgl: webglFingerprint
  };
  
  // Generate hash of the combined fingerprint
  return sha256(JSON.stringify(combinedFingerprint));
};
```

#### Canvas Fingerprinting Implementation

```javascript
const getCanvasFingerprint = () => {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  
  // Set canvas dimensions
  canvas.width = 200;
  canvas.height = 50;
  
  // Text with different styles
  ctx.textBaseline = 'top';
  ctx.font = '16px Arial';
  ctx.fillStyle = '#F0A';
  ctx.fillRect(125, 1, 62, 20);
  
  // Add text with emoji (good for OS/font differences)
  ctx.fillStyle = '#069';
  ctx.fillText('SmartFirms 🔒', 2, 15);
  
  // More styling for better differentiation
  ctx.fillStyle = 'rgba(102, 204, 0, 0.7)';
  ctx.fillText('canvas fingerprint', 4, 45);
  
  return canvas.toDataURL().replace('data:image/png;base64,', '');
};
```

### 2. Risk Level Assessment

The system evaluates the risk of potential session hijacking:

```javascript
const calculateRiskLevel = (currentFingerprint, storedFingerprint) => {
  // If fingerprints are identical, risk is minimal
  if (currentFingerprint === storedFingerprint) {
    return {
      riskLevel: 'minimal',
      score: 0.0,
      action: 'proceed'
    };
  }
  
  // Decode and compare individual factors
  const current = JSON.parse(atob(currentFingerprint));
  const stored = JSON.parse(atob(storedFingerprint));
  
  // Calculate match percentage for each factor group
  const basicInfoMatch = compareBasicInfo(current, stored);
  const canvasMatch = compareCanvas(current.canvas, stored.canvas);
  const audioMatch = compareAudio(current.audio, stored.audio);
  const webglMatch = compareWebGL(current.webgl, stored.webgl);
  
  // Weight each factor (weights should sum to 1.0)
  const weightedScore = (
    basicInfoMatch * 0.4 + 
    canvasMatch * 0.3 + 
    audioMatch * 0.1 + 
    webglMatch * 0.2
  );
  
  // Determine risk level and action
  if (weightedScore > 0.85) {
    return {
      riskLevel: 'low',
      score: weightedScore,
      action: 'proceed'
    };
  } else if (weightedScore > 0.6) {
    return {
      riskLevel: 'medium',
      score: weightedScore,
      action: 'verify'
    };
  } else {
    return {
      riskLevel: 'high',
      score: weightedScore,
      action: 'reauthenticate'
    };
  }
};
```

### 3. Integration with Token Refresh Flow

The fingerprinting system is integrated with the token refresh process:

```javascript
// During token refresh
const refreshToken = async () => {
  // Generate current fingerprint
  const currentFingerprint = generateDeviceFingerprint();
  
  // Get stored fingerprint from session storage
  const storedFingerprint = sessionStorage.getItem('device_fingerprint');
  
  // If this is the first session, store the fingerprint
  if (!storedFingerprint) {
    sessionStorage.setItem('device_fingerprint', currentFingerprint);
    
    // Proceed with normal token refresh
    return performTokenRefresh();
  }
  
  // Assess risk level
  const riskAssessment = calculateRiskLevel(currentFingerprint, storedFingerprint);
  
  // Handle based on risk assessment
  switch(riskAssessment.action) {
    case 'proceed':
      // Normal token refresh
      return performTokenRefresh();
      
    case 'verify':
      // Require additional verification
      return performTokenRefreshWithVerification();
      
    case 'reauthenticate':
      // Force full re-authentication
      logout();
      navigate('/login', { 
        state: { 
          message: 'Your session expired for security reasons. Please log in again.'
        }
      });
      
      throw new Error('Session invalidated due to security concerns');
  }
};
```

### 4. Security Score System

The UI Service implements a security score to evaluate overall session security:

```javascript
const calculateSessionSecurityScore = () => {
  let score = 0;
  const maxScore = 100;
  
  // Check for secure connection
  if (window.location.protocol === 'https:') {
    score += 20;
  }
  
  // Check for HTTP-only cookies
  if (document.cookie.includes('HttpOnly')) {
    score += 15;
  }
  
  // Check fingerprint consistency
  const currentFingerprint = generateDeviceFingerprint();
  const storedFingerprint = sessionStorage.getItem('device_fingerprint');
  
  if (storedFingerprint && currentFingerprint === storedFingerprint) {
    score += 25;
  } else if (storedFingerprint) {
    const riskAssessment = calculateRiskLevel(currentFingerprint, storedFingerprint);
    score += Math.round(riskAssessment.score * 25);
  }
  
  // Check token age
  const tokenIssued = sessionStorage.getItem('token_issued_at');
  if (tokenIssued) {
    const tokenAge = Date.now() - parseInt(tokenIssued);
    const tokenMaxAge = 3600 * 1000; // 1 hour
    
    // Newer tokens are more secure
    score += Math.round(20 * (1 - Math.min(tokenAge / tokenMaxAge, 1)));
  }
  
  // Check for known vulnerabilities in browser
  const browserVulnerabilityScore = assessBrowserSecurity();
  score += browserVulnerabilityScore;
  
  // Rate limiting factor
  const rateLimitingStatus = getRateLimitingStatus();
  if (rateLimitingStatus === 'no_warnings') {
    score += 10;
  }
  
  return {
    score: Math.min(score, maxScore),
    maxScore,
    rating: getSecurityRating(score),
    recommendations: generateSecurityRecommendations(score)
  };
};
```

## Integration with Authentication System

### Authentication Flow with Fingerprinting

```javascript
const authenticateUser = async (credentials) => {
  try {
    // Generate device fingerprint
    const fingerprint = generateDeviceFingerprint();
    
    // Include fingerprint with authentication request
    const authResponse = await authService.login({
      ...credentials,
      device_fingerprint: fingerprint
    });
    
    // Store fingerprint for later verification
    sessionStorage.setItem('device_fingerprint', fingerprint);
    sessionStorage.setItem('token_issued_at', Date.now().toString());
    
    // Store tokens
    storeTokens(authResponse.tokens);
    
    return authResponse;
  } catch (error) {
    console.error('Authentication failed:', error);
    throw error;
  }
};
```

### Regular Security Status Checks

The UI Service performs regular security checks to ensure session integrity:

```javascript
// Security check interval (every 5 minutes)
const SECURITY_CHECK_INTERVAL = 5 * 60 * 1000;

// Setup security monitoring
const setupSecurityMonitoring = () => {
  // Perform initial check
  checkSessionSecurity();
  
  // Schedule regular checks
  const intervalId = setInterval(checkSessionSecurity, SECURITY_CHECK_INTERVAL);
  
  // Clean up on unmount
  return () => clearInterval(intervalId);
};

// Session security check
const checkSessionSecurity = () => {
  // Get current fingerprint
  const currentFingerprint = generateDeviceFingerprint();
  const storedFingerprint = sessionStorage.getItem('device_fingerprint');
  
  if (!storedFingerprint) {
    // First check, just store fingerprint
    sessionStorage.setItem('device_fingerprint', currentFingerprint);
    return;
  }
  
  // Assess risk
  const riskAssessment = calculateRiskLevel(currentFingerprint, storedFingerprint);
  
  // Log for monitoring
  securityLogger.log('Session security check', {
    riskLevel: riskAssessment.riskLevel,
    score: riskAssessment.score,
    action: riskAssessment.action,
    timestamp: new Date().toISOString()
  });
  
  // Take action for high risk
  if (riskAssessment.action === 'reauthenticate') {
    // Force logout
    authService.logout();
    
    // Show security alert
    showSecurityAlert('Your session has been ended due to suspicious activity.');
    
    // Redirect to login
    navigate('/login');
  } else if (riskAssessment.action === 'verify') {
    // Schedule verification at next interaction
    scheduleVerification();
  }
};
```

## Best Practices for Developers

### Working with Fingerprinting

- **Privacy Considerations**: Ensure users are informed about fingerprinting through appropriate privacy notices.
- **Fallback Mechanisms**: Provide alternative authentication methods if fingerprinting fails.
- **Calibration**: Regularly tune risk thresholds based on false positive/negative rates.

### Security Considerations

1. **Balance Security and User Experience**: Overly strict fingerprinting can lead to poor user experience.
2. **Graceful Degradation**: Provide fallback mechanisms for environments where fingerprinting is limited.
3. **Defense in Depth**: Use fingerprinting as one layer of a comprehensive security strategy.

## References

- [Browser Fingerprinting: What Is It and What Should You Do About It?](https://blog.mozilla.org/internetcitizen/2018/07/26/this-is-your-digital-fingerprint/)
- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [Smarter Firms Authentication Strategy](../auth-service/Authentication-Strategy.md) 