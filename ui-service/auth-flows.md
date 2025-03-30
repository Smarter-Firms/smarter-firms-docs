# Authentication Flows

This document describes the authentication flows from the UI perspective, detailing how the frontend components interact with the Auth Service.

## Login Flow

![Login Flow Diagram](./assets/login-flow-diagram.png)

### Steps:

1. **User Enters Credentials**
   - UI collects email and password
   - Client-side validation occurs

2. **Device Fingerprinting**
   - Browser fingerprint is generated asynchronously
   - Fingerprint includes hardware, software, and canvas data
   - Fingerprint is attached to login request

3. **Login Request**
   ```tsx
   const handleLogin = async (formData) => {
     try {
       await login(formData.email, formData.password);
       // Redirect handled internally by AuthContext
     } catch (err) {
       setError(err.message);
     }
   };
   ```
   
4. **Server Authentication**
   - Auth Service validates credentials
   - HTTP-only cookies set for tokens
   - CSRF token provided
   
5. **Session Initialization**
   - User data retrieved
   - Session security evaluated
   - Permissions loaded

6. **Redirection**
   - User redirected to dashboard or original destination
   - Security status displayed

## Token Refresh Flow

![Token Refresh Flow Diagram](./assets/token-refresh-diagram.png)

### Automatic Refresh:

1. **401 Unauthorized Response**
   - API request returns 401
   - Request interceptor catches error
   
2. **Check Retry Status**
   - If already retried, force logout
   - If not, mark for retry

3. **Queue Pending Requests**
   - Original request is queued if refresh already in progress
   - Queue waits for refresh completion

4. **Refresh Token**
   - Refresh endpoint called with HTTP-only cookies
   - New tokens set via cookies

5. **Retry Original Requests**
   - All queued requests retried with new tokens
   - Failed requests rejected with consistent error

### Manual Refresh:

```tsx
// Proactively refresh the session
const extendSession = async () => {
  const success = await refreshSession();
  if (success) {
    showNotification('Session extended successfully.');
  } else {
    showNotification('Could not extend session. Please login again.');
  }
};
```

## Logout Flow

### Steps:

1. **Logout Initiated**
   ```tsx
   const handleLogout = async () => {
     await logout();
     // Redirect handled by AuthContext
   };
   ```

2. **Cleanup**
   - Pending API requests canceled
   - User state cleared

3. **Logout Request**
   - Request sent to Auth Service
   - HTTP-only cookies cleared

4. **Redirection**
   - User redirected to login page

## Security Validation Flow

![Security Validation Flow](./assets/security-validation-flow.png)

### Steps:

1. **Regular Security Checks**
   - Session security evaluated periodically
   - Fingerprint validation performed

2. **Security Score Calculation**
   ```tsx
   const { score, factors } = await evaluateSessionSecurity();
   ```

3. **Risk Level Response**
   - High risk (score < 40): Force re-authentication
   - Medium risk (score < 60): Display warnings
   - Low risk: Normal operation

4. **Security Indicators**
   - Visual security status in UI
   - Failed security factors listed

## Fingerprint Validation Flow

### Steps:

1. **Server Detects Mismatch**
   - API response includes `x-fingerprint-mismatch: true`
   - Response interceptor catches header

2. **Client-Side Validation**
   ```tsx
   const { isValid, riskLevel, currentFingerprint } = 
     await validateFingerprint(lastValidFingerprint);
   ```

3. **Risk Assessment**
   - Compare stored vs current fingerprint
   - Calculate similarity score
   - Determine risk level (low/medium/high)

4. **Response Based on Risk**
   - High risk: Force re-authentication
   - Medium risk: Allow with warnings
   - Low risk: Update fingerprint

## Protected Routes

### Implementation:

```tsx
// Protected route using HOC pattern
const ProtectedPage = withAuth(Dashboard, { 
  requiredRoles: ['ADMIN', 'CONSULTANT'],
  redirectTo: '/auth/login'
});

// Or with direct component usage
function ProtectedContent() {
  const { isAuthenticated, isLoading } = useAuth();
  
  if (isLoading) return <LoadingSpinner />;
  if (!isAuthenticated) return <Redirect to="/auth/login" />;
  
  return <YourComponent />;
}
```

### Features:

- Automatic session refresh attempt
- Loading state during authentication check
- Role-based access control
- Custom redirect paths
- Return URL preservation

## Error Handling

Error handling follows a consistent pattern:

```tsx
try {
  // Authentication operation
} catch (err) {
  const processedError = processApiError(err);
  
  // User-friendly message
  showError(processedError.message);
  
  // Suggestions based on error category
  if (processedError.suggestions?.length) {
    showSuggestions(processedError.suggestions);
  }
  
  // Retryable errors
  if (processedError.retry) {
    showRetryButton();
  }
}
```

### Error Categories:

- Authentication
- Validation
- Server
- Network
- Permission
- Input
- NotFound
- Timeout
- Unknown

Each category has specific handling strategies and user guidance.

## Integration Testing With Auth Service

For testing the integration with the Auth Service:

1. **Mock Auth Service Endpoints**
   - Use MSW (Mock Service Worker) for testing
   - Simulate various response scenarios

2. **Test Token Flows**
   - Success flows
   - Expiration handling
   - Refresh scenarios
   - Concurrent request handling

3. **Security Testing**
   - Fingerprint mismatch scenarios
   - CSRF token validation
   - Session security evaluation 