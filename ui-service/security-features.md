# Security Features

This document outlines the security features implemented in the UI authentication system for the Smarter Firms platform.

## Token Management

### HTTP-Only Cookies

The system uses HTTP-only cookies for token storage rather than localStorage or JavaScript-accessible cookies:

```tsx
// In apiGateway.ts
// Note: No manual token extraction; cookies are automatically sent
const createApiClient = (baseURL = API_BASE_URL) => {
  const apiClient = axios.create({
    baseURL,
    withCredentials: true, // Important for cookies
    timeout: 30000,
  });
  
  // Rest of configuration...
  
  return apiClient;
};
```

Benefits:
- Protection against XSS attacks
- Inaccessible to JavaScript/malicious scripts
- Automatic inclusion in requests to the same domain
- Server-controlled expiration and attributes

### CSRF Protection

The system implements Cross-Site Request Forgery protection through tokens:

```tsx
// In apiGateway.ts
apiClient.interceptors.request.use(
  (config) => {
    // Only add CSRF tokens to non-GET requests
    if (config.method && ['post', 'put', 'delete', 'patch'].includes(config.method)) {
      const csrfToken = getCsrfToken();
      if (csrfToken) {
        config.headers['X-CSRF-Token'] = csrfToken;
      }
    }
    
    return config;
  },
  (error) => Promise.reject(error)
);
```

Implementation details:
- CSRF token received at login/token refresh
- Stored in memory (not persisted storage)
- Added to all mutation request headers
- Refreshed during token refresh cycles

## Device Fingerprinting

The system uses device fingerprinting to validate session integrity:

```tsx
// In fingerprint.ts
export const generateFingerprint = async (): Promise<DeviceFingerprint> => {
  // Collection of multiple fingerprinting factors
  return {
    // Hardware factors
    screenResolution: `${window.screen.width}x${window.screen.height}`,
    colorDepth: window.screen.colorDepth,
    devicePixelRatio: window.devicePixelRatio,
    
    // Software factors
    userAgent: navigator.userAgent,
    language: navigator.language,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    
    // Canvas fingerprinting
    canvasFingerprint: await generateCanvasFingerprint(),
    
    // Browser features
    cookiesEnabled: navigator.cookieEnabled,
    doNotTrack: navigator.doNotTrack,
    
    // Enhanced data when available
    gpuInfo: await getGpuInfo(),
    fonts: await detectFonts(),
    
    // Network characteristics
    connectionType: getConnectionType(),
  };
};
```

Security mechanisms:
- Multiple factors for reliable identification
- Canvas fingerprinting for hardware signatures
- Robust similarity algorithm for risk assessment
- Gradual fingerprint updates for legitimate changes
- Detection of sudden changes as security threats

## Session Security Score

The system maintains a security score based on multiple factors:

```tsx
// In sessionSecurity.ts
export const evaluateSessionSecurity = async (): Promise<SecurityEvaluation> => {
  const currentFingerprint = await generateFingerprint();
  const storedFingerprint = getStoredFingerprint();
  
  const factors: SecurityFactor[] = [];
  let totalScore = 100;
  
  // Fingerprint verification (up to -40 points)
  const fingerprintScore = calculateFingerprintSimilarity(currentFingerprint, storedFingerprint);
  if (fingerprintScore < 95) {
    const deduction = Math.min(40, (95 - fingerprintScore) * 2);
    totalScore -= deduction;
    factors.push({
      name: 'device_fingerprint',
      status: 'warning',
      deduction,
      message: 'Device characteristics have changed'
    });
  }
  
  // Session duration check (up to -15 points)
  const sessionAge = calculateSessionAge();
  if (sessionAge > MAX_SESSION_AGE) {
    const deduction = Math.min(15, (sessionAge - MAX_SESSION_AGE) / 3600 * 5);
    totalScore -= deduction;
    factors.push({
      name: 'session_age',
      status: 'warning',
      deduction,
      message: 'Extended session without re-authentication'
    });
  }
  
  // IP change detection (up to -30 points)
  const ipChanged = await detectIpChange();
  if (ipChanged) {
    totalScore -= 30;
    factors.push({
      name: 'ip_change',
      status: 'critical',
      deduction: 30,
      message: 'IP address has changed significantly'
    });
  }
  
  // Additional security checks...
  
  return {
    score: totalScore,
    factors,
    riskLevel: getRiskLevel(totalScore),
    timestamp: new Date().toISOString()
  };
};
```

Implementation:
- Baseline 100-point scoring system
- Factors that reduce security score
- Risk level categorization (low/medium/high)
- Actionable security insights
- Periodic background evaluation

## Token Refresh Security

The system implements a secure token refresh mechanism:

```tsx
// In authService.ts
export const refreshSession = async (): Promise<boolean> => {
  try {
    // Get current fingerprint for validation
    const fingerprint = await generateFingerprint();
    
    // Uses HTTP-only cookies automatically
    const response = await apiClient.post('/auth/refresh', {
      fingerprint: serializeFingerprint(fingerprint)
    });
    
    // Update CSRF token
    if (response.data.csrfToken) {
      setCsrfToken(response.data.csrfToken);
    }
    
    // Update stored fingerprint when successful
    storeFingerprint(fingerprint);
    
    return true;
  } catch (error) {
    // Handle various error scenarios
    // Force logout on critical errors
    if (isAuthError(error) && error.status === 401) {
      logout();
    }
    
    return false;
  }
};
```

Security considerations:
- Includes fingerprint verification
- Protects against session hijacking
- Critical errors force re-authentication
- Comprehensive error handling
- Rate limiting against brute force attempts

## Request Security Headers

The API client automatically adds security headers to requests:

```tsx
// In apiGateway.ts
apiClient.interceptors.request.use(
  (config) => {
    // Add security headers
    config.headers = {
      ...config.headers,
      'X-Requested-With': 'XMLHttpRequest',
      'X-Device-Id': getDeviceId(),
      'X-Client-Version': APP_VERSION,
    };
    
    // Fingerprint header when available
    const fingerprint = getFingerprintHash();
    if (fingerprint) {
      config.headers['X-Fingerprint-Hash'] = fingerprint;
    }
    
    return config;
  },
  (error) => Promise.reject(error)
);
```

Header purposes:
- `X-Requested-With`: Helps prevent CSRF
- `X-Device-Id`: Consistent device identifier
- `X-Client-Version`: Ensures compatibility
- `X-Fingerprint-Hash`: Session integrity validation

## Unauthorized Request Handling

The system handles unauthorized requests securely:

```tsx
// In apiGateway.ts
let isRefreshing = false;
let failedQueue: Array<{
  resolve: (value: any) => void;
  reject: (reason?: any) => void;
  config: AxiosRequestConfig;
}> = [];

apiClient.interceptors.response.use(
  response => response,
  async (error) => {
    const originalRequest = error.config;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // Queue this request while refresh is in progress
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject, config: originalRequest });
        });
      }
      
      originalRequest._retry = true;
      isRefreshing = true;
      
      try {
        const refreshed = await refreshSession();
        
        if (refreshed) {
          // Process queue and retry original request
          processQueue(null, originalRequest);
          return apiClient(originalRequest);
        } else {
          // Handle failed refresh
          processQueue(new Error('Session refresh failed'), null);
          return Promise.reject(error);
        }
      } catch (refreshError) {
        processQueue(refreshError, null);
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }
    
    return Promise.reject(error);
  }
);
```

Security aspects:
- Single refresh attempt per request
- Queuing system to prevent refresh storms
- Smart retry with new tokens
- Forced logout on critical failures
- No infinite retry loops

## Client-Side Validation

The system implements comprehensive client-side validation:

```tsx
// In login component
const loginSchema = z.object({
  email: z.string().email({ message: 'Valid email required' }),
  password: z.string().min(8, { message: 'Password must be at least 8 characters' }),
});

const { register, handleSubmit, formState: { errors } } = useForm({
  resolver: zodResolver(loginSchema)
});

const onSubmit = async (data) => {
  try {
    await login(data.email, data.password);
  } catch (error) {
    // Process error using standardized error handling
    const appError = processApiError(error);
    setError('form', { message: appError.message });
  }
};
```

Implementation:
- Zod schema validation for all inputs
- Standardized error processing
- Context-specific error messages
- Input sanitization before submission
- Protection against common attack vectors

## Security Monitoring

The system implements client-side security monitoring:

```tsx
// In securityMonitor.ts
export const monitorSecurityStatus = (
  callback: (status: SecurityStatus) => void
) => {
  // Initial assessment
  evaluateSessionSecurity().then(evaluation => {
    callback({
      status: evaluation.riskLevel,
      factors: evaluation.factors,
      lastChecked: new Date()
    });
  });
  
  // Setup interval checks
  const intervalId = setInterval(async () => {
    const evaluation = await evaluateSessionSecurity();
    
    // Trigger callback with updated status
    callback({
      status: evaluation.riskLevel,
      factors: evaluation.factors,
      lastChecked: new Date()
    });
    
    // Force reauthentication for high risk
    if (evaluation.riskLevel === 'high') {
      forceReauthentication('Security status check failed');
    }
  }, SECURITY_CHECK_INTERVAL);
  
  // Return cleanup function
  return () => clearInterval(intervalId);
};
```

Features:
- Regular security status assessments
- Real-time risk level updates
- Automated response to security threats
- Visual security indicators
- Configurable check frequency

## User Trust Features

The system implements features to build user trust:

```tsx
// Example login notification component
const LastLoginNotification = () => {
  const { user } = useAuth();
  
  if (!user?.lastLogin) return null;
  
  return (
    <div className="last-login-notification">
      <Icon name="info-circle" />
      <div>
        <p>Last successful login: {formatDateTime(user.lastLogin.timestamp)}</p>
        <p>From: {user.lastLogin.location}</p>
        <p>Device: {user.lastLogin.device}</p>
      </div>
    </div>
  );
};
```

Trust features:
- Last login information
- Session activity timeline
- Browser/location notifications
- Active sessions management
- Visual security status indicators 