# Token Refresh Edge Cases

## Overview

Token refresh is a critical part of the authentication system, but it can encounter various edge cases that need careful handling. This document describes the implementation of sophisticated token refresh handling in the UI Service, focusing on edge cases and their solutions.

## Token Refresh Implementation

### Core Token Refresh Logic

The UI Service implements a robust token refresh mechanism:

```javascript
class TokenManager {
  constructor() {
    this.accessToken = null;
    this.refreshToken = null;
    this.accessTokenExpiry = null;
    this.refreshInProgress = false;
    this.refreshPromise = null;
    this.pendingRequests = [];
    this.refreshThreshold = 0.75; // Refresh when 75% of token lifetime has passed
  }
  
  // Initialize tokens from storage
  initialize() {
    const tokens = getTokensFromSecureStorage();
    if (tokens) {
      this.setTokens(tokens.accessToken, tokens.refreshToken, tokens.expiresAt);
    }
  }
  
  // Set tokens and expiry
  setTokens(accessToken, refreshToken, expiresAt) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.accessTokenExpiry = expiresAt;
    
    // Store tokens securely
    saveTokensToSecureStorage(accessToken, refreshToken, expiresAt);
  }
  
  // Get access token (refreshing if needed)
  async getAccessToken() {
    // If no refresh token, we can't refresh
    if (!this.refreshToken) {
      return null;
    }
    
    // If token is valid and not near expiry, return it
    if (this.isTokenValid() && !this.isTokenNearExpiry()) {
      return this.accessToken;
    }
    
    // Refresh token if expired or near expiry
    return this.refreshTokenIfNeeded();
  }
  
  // Check if token is valid
  isTokenValid() {
    if (!this.accessToken || !this.accessTokenExpiry) {
      return false;
    }
    
    return Date.now() < this.accessTokenExpiry;
  }
  
  // Check if token is near expiry
  isTokenNearExpiry() {
    if (!this.accessTokenExpiry) {
      return true;
    }
    
    const timeToExpiry = this.accessTokenExpiry - Date.now();
    const tokenLifetime = this.accessTokenExpiry - this.lastRefreshTime;
    
    return timeToExpiry < tokenLifetime * (1 - this.refreshThreshold);
  }
  
  // Refresh token if needed
  async refreshTokenIfNeeded() {
    // If token is valid and not near expiry, return it
    if (this.isTokenValid() && !this.isTokenNearExpiry()) {
      return this.accessToken;
    }
    
    // Handle refresh process (including edge cases)
    return this.handleTokenRefresh();
  }
}
```

## Edge Cases and Solutions

### 1. Concurrent API Requests During Refresh

When multiple API requests occur simultaneously while a token refresh is in progress, the system needs to queue and resolve them after the refresh:

```javascript
async handleTokenRefresh() {
  // If refresh is already in progress, wait for it to complete
  if (this.refreshInProgress) {
    return new Promise((resolve, reject) => {
      this.pendingRequests.push({ resolve, reject });
    });
  }
  
  // Set refresh in progress flag
  this.refreshInProgress = true;
  
  try {
    // Create refresh promise
    this.refreshPromise = this.performTokenRefresh();
    
    // Wait for refresh to complete
    const newTokens = await this.refreshPromise;
    
    // Update tokens
    this.setTokens(
      newTokens.accessToken,
      newTokens.refreshToken,
      newTokens.expiresAt
    );
    
    // Resolve all pending requests
    this.resolvePendingRequests(this.accessToken);
    
    // Return new access token
    return this.accessToken;
  } catch (error) {
    // Reject all pending requests
    this.rejectPendingRequests(error);
    
    // Handle refresh failure
    return this.handleRefreshFailure(error);
  } finally {
    // Reset refresh state
    this.refreshInProgress = false;
    this.refreshPromise = null;
  }
}

// Resolve all pending requests with new token
resolvePendingRequests(accessToken) {
  this.pendingRequests.forEach(({ resolve }) => {
    resolve(accessToken);
  });
  this.pendingRequests = [];
}

// Reject all pending requests with error
rejectPendingRequests(error) {
  this.pendingRequests.forEach(({ reject }) => {
    reject(error);
  });
  this.pendingRequests = [];
}
```

### 2. API Request Queueing

The system queues API requests that occur during token refresh and resolves them once the refresh is complete:

```javascript
// API client with token refresh handling
class ApiClient {
  constructor(tokenManager) {
    this.tokenManager = tokenManager;
    this.axios = axios.create({
      baseURL: API_BASE_URL,
      timeout: 30000
    });
    
    // Add request interceptor for token handling
    this.axios.interceptors.request.use(
      async (config) => {
        // Skip token for auth endpoints
        if (this.isAuthEndpoint(config.url)) {
          return config;
        }
        
        try {
          // Get access token (triggers refresh if needed)
          const token = await this.tokenManager.getAccessToken();
          
          if (!token) {
            throw new Error('No access token available');
          }
          
          // Add token to request
          config.headers.Authorization = `Bearer ${token}`;
          
          return config;
        } catch (error) {
          // Handle token error
          return this.handleTokenError(error, config);
        }
      },
      (error) => Promise.reject(error)
    );
    
    // Add response interceptor for 401 handling
    this.axios.interceptors.response.use(
      (response) => response,
      async (error) => {
        // If response status is 401 and we haven't already retried
        if (error.response?.status === 401 && !error.config.__isRetry) {
          try {
            // Force token refresh
            await this.tokenManager.forceRefresh();
            
            // Retry request once
            error.config.__isRetry = true;
            return this.axios(error.config);
          } catch (refreshError) {
            // If refresh fails, reject with original error
            return Promise.reject(error);
          }
        }
        
        return Promise.reject(error);
      }
    );
  }
  
  // Check if URL is an auth endpoint
  isAuthEndpoint(url) {
    return url.includes('/auth/') && 
           !url.includes('/auth/validate') &&
           !url.includes('/auth/user');
  }
  
  // Handle token error
  handleTokenError(error, config) {
    // If unauthorized, redirect to login
    if (error.response?.status === 401) {
      this.tokenManager.clearTokens();
      redirectToLogin();
      return Promise.reject(error);
    }
    
    // Otherwise, reject with error
    return Promise.reject(error);
  }
}
```

### 3. Graceful Degradation on Refresh Failure

The system handles token refresh failures gracefully:

```javascript
async handleRefreshFailure(error) {
  // Log refresh failure
  console.error('Token refresh failed:', error);
  
  // Check if error is due to invalid refresh token
  if (error.response?.status === 401) {
    // Clear tokens
    this.clearTokens();
    
    // Emit authentication error event
    events.emit('auth:error', { 
      type: 'refresh_failed',
      message: 'Your session has expired. Please log in again.'
    });
    
    // Redirect to login
    redirectToLogin({
      reason: 'session_expired',
      message: 'Your session has expired. Please log in again.'
    });
    
    return null;
  }
  
  // Check if error is due to network issues
  if (error.isAxiosError && !error.response) {
    // Emit network error event
    events.emit('auth:error', {
      type: 'network_error',
      message: 'Network error during token refresh. Retry in progress...'
    });
    
    // Retry refresh after delay
    return this.retryRefreshWithBackoff(error);
  }
  
  // For other errors, clear tokens and force re-authentication
  this.clearTokens();
  events.emit('auth:error', {
    type: 'refresh_error',
    message: 'Authentication error. Please log in again.'
  });
  
  return null;
}

// Retry refresh with exponential backoff
async retryRefreshWithBackoff(error, attempt = 1) {
  // Maximum retry attempts
  const MAX_RETRY_ATTEMPTS = 3;
  
  // If max attempts reached, give up
  if (attempt > MAX_RETRY_ATTEMPTS) {
    this.clearTokens();
    events.emit('auth:error', {
      type: 'refresh_failed_after_retry',
      message: 'Could not refresh your session after multiple attempts. Please log in again.'
    });
    
    redirectToLogin({
      reason: 'refresh_failed',
      message: 'Your session could not be refreshed. Please log in again.'
    });
    
    return null;
  }
  
  // Calculate backoff delay (with jitter)
  const baseDelay = 1000; // 1 second
  const jitter = Math.random() * 500; // 0-500ms random jitter
  const delay = (Math.pow(2, attempt - 1) * baseDelay) + jitter;
  
  // Wait for delay
  await new Promise(resolve => setTimeout(resolve, delay));
  
  // Retry refresh
  try {
    const newTokens = await this.performTokenRefresh();
    
    this.setTokens(
      newTokens.accessToken,
      newTokens.refreshToken,
      newTokens.expiresAt
    );
    
    return this.accessToken;
  } catch (retryError) {
    // Recursively retry with increased attempt count
    return this.retryRefreshWithBackoff(retryError, attempt + 1);
  }
}
```

### 4. Uninterrupted User Experience During Refresh

The UI Service ensures that users can continue to interact with the application during token refresh:

```javascript
// React hook for API calls with token refresh handling
const useApi = (endpoint, options = {}) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [retryCount, setRetryCount] = useState(0);
  
  // Get API client from context
  const apiClient = useApiClient();
  
  // Fetch data with token refresh handling
  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Make API request
      const response = await apiClient.request({
        url: endpoint,
        ...options
      });
      
      setData(response.data);
      setLoading(false);
    } catch (err) {
      // If retry on token refresh issue
      if (err.isRefreshError && retryCount < 3) {
        // Increment retry count
        setRetryCount(prev => prev + 1);
        
        // Wait for a short delay before retrying
        setTimeout(() => {
          fetchData();
        }, 1000);
      } else {
        // Set error state
        setError(err);
        setLoading(false);
      }
    }
  }, [endpoint, options, apiClient, retryCount]);
  
  // Fetch data on mount and when dependencies change
  useEffect(() => {
    fetchData();
  }, [fetchData]);
  
  return { data, loading, error, refetch: fetchData };
};
```

## Integration with User Interface

The UI Service provides visual feedback during token refresh:

```jsx
// TokenRefreshIndicator component
const TokenRefreshIndicator = () => {
  // Get token manager from context
  const tokenManager = useTokenManager();
  
  // State for refresh status
  const [isRefreshing, setIsRefreshing] = useState(false);
  
  // Subscribe to token refresh events
  useEffect(() => {
    const handleRefreshStart = () => setIsRefreshing(true);
    const handleRefreshEnd = () => setIsRefreshing(false);
    
    // Subscribe to events
    tokenManager.on('refresh:start', handleRefreshStart);
    tokenManager.on('refresh:end', handleRefreshEnd);
    tokenManager.on('refresh:error', handleRefreshEnd);
    
    // Unsubscribe on cleanup
    return () => {
      tokenManager.off('refresh:start', handleRefreshStart);
      tokenManager.off('refresh:end', handleRefreshEnd);
      tokenManager.off('refresh:error', handleRefreshEnd);
    };
  }, [tokenManager]);
  
  // Don't render anything if not refreshing
  if (!isRefreshing) {
    return null;
  }
  
  // Render subtle refresh indicator
  return (
    <div className="token-refresh-indicator">
      <div className="refresh-spinner" />
      <span className="refresh-text">Refreshing session...</span>
    </div>
  );
};
```

## Best Practices for Developers

### Working with Token Refresh

1. **Never Block UI**: Always handle token refresh in the background without blocking the user interface.
2. **Retry Strategies**: Implement appropriate retry strategies with exponential backoff.
3. **Clear Error Messages**: Provide clear error messages when token refresh fails.
4. **Security Considerations**: Always validate tokens server-side, even after refresh.

### Edge Case Handling Tips

1. **Request Queueing**: Queue requests that occur during token refresh rather than rejecting them.
2. **Network Issues**: Implement proper fallbacks for network issues during refresh.
3. **Session Monitoring**: Regularly check session health to avoid unexpected expiration.
4. **Refresh Threshold**: Set an appropriate refresh threshold to prevent token expiry.

## References

- [OAuth 2.0 Token Refresh Best Practices](https://auth0.com/docs/tokens/refresh-tokens/refresh-token-rotation)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [Smarter Firms Authentication Strategy](../auth-service/Authentication-Strategy.md) 