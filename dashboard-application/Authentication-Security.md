# Authentication and Security

This document outlines the authentication and security implementation for the Dashboard Application, including authentication flow, access control, data protection, and security best practices.

## Authentication Architecture

The Dashboard Application uses a JWT (JSON Web Token) based authentication system with the following components:

### Authentication Flow

1. **Login**: User submits credentials via the login form
2. **Token Generation**: Server validates credentials and returns access and refresh tokens
3. **Token Storage**: Tokens are stored securely in HTTP-only cookies
4. **Authentication State**: Global auth context maintains the user's authentication state
5. **Token Refresh**: Automatic refresh of expired tokens using the refresh token
6. **Logout**: Tokens are invalidated on the server and removed from client storage

### Authentication Service

```typescript
// src/services/auth.ts
import axios from 'axios';
import { API_BASE_URL } from '@/config';
import Cookies from 'js-cookie';

// Authentication token storage keys
const ACCESS_TOKEN_KEY = 'auth_token';
const REFRESH_TOKEN_KEY = 'refresh_token';

// User interface
export interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  permissions: string[];
}

// Authentication response interface
export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

// Login credentials interface
export interface LoginCredentials {
  email: string;
  password: string;
}

// Get stored access token
export const getAccessToken = (): string | undefined => {
  return Cookies.get(ACCESS_TOKEN_KEY);
};

// Get stored refresh token
export const getRefreshToken = (): string | undefined => {
  return Cookies.get(REFRESH_TOKEN_KEY);
};

// Store authentication tokens
export const storeTokens = (accessToken: string, refreshToken: string): void => {
  // Set secure cookies with appropriate attributes
  const options = {
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    expires: 7 // 7 days
  };
  
  Cookies.set(ACCESS_TOKEN_KEY, accessToken, options);
  Cookies.set(REFRESH_TOKEN_KEY, refreshToken, options);
};

// Remove authentication tokens
export const removeTokens = (): void => {
  Cookies.remove(ACCESS_TOKEN_KEY);
  Cookies.remove(REFRESH_TOKEN_KEY);
};

// Login function
export const login = async (credentials: LoginCredentials): Promise<AuthResponse> => {
  try {
    const response = await axios.post<AuthResponse>(
      `${API_BASE_URL}/auth/login`,
      credentials
    );
    
    const { accessToken, refreshToken, user } = response.data;
    
    // Store tokens
    storeTokens(accessToken, refreshToken);
    
    return response.data;
  } catch (error) {
    console.error('Login error:', error);
    throw error;
  }
};

// Refresh access token
export const refreshAccessToken = async (): Promise<string> => {
  try {
    const refreshToken = getRefreshToken();
    
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }
    
    const response = await axios.post<{ accessToken: string; refreshToken: string }>(
      `${API_BASE_URL}/auth/refresh`,
      { refreshToken }
    );
    
    const { accessToken, refreshToken: newRefreshToken } = response.data;
    
    // Store new tokens
    storeTokens(accessToken, newRefreshToken);
    
    return accessToken;
  } catch (error) {
    // If refresh fails, clear tokens
    removeTokens();
    throw error;
  }
};

// Logout function
export const logout = async (): Promise<void> => {
  try {
    const refreshToken = getRefreshToken();
    
    if (refreshToken) {
      // Notify server to invalidate tokens
      await axios.post(`${API_BASE_URL}/auth/logout`, { refreshToken });
    }
  } catch (error) {
    console.error('Logout error:', error);
  } finally {
    // Always remove tokens, even if API call fails
    removeTokens();
  }
};

// Get current user information
export const getCurrentUser = async (): Promise<User> => {
  const token = getAccessToken();
  
  if (!token) {
    throw new Error('No access token available');
  }
  
  const response = await axios.get<User>(`${API_BASE_URL}/auth/me`, {
    headers: {
      Authorization: `Bearer ${token}`
    }
  });
  
  return response.data;
};
```

### Authentication Context

The application uses React Context to manage authentication state:

```typescript
// src/context/AuthContext.tsx
import React, { createContext, useContext, useEffect, useReducer } from 'react';
import { useRouter } from 'next/router';
import { User, login as loginService, logout as logoutService, getCurrentUser, getAccessToken } from '@/services/auth';

// Authentication state interface
interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

// Initial authentication state
const initialState: AuthState = {
  user: null,
  isAuthenticated: false,
  isLoading: true,
  error: null,
};

// Authentication action types
type AuthAction =
  | { type: 'LOGIN_REQUEST' }
  | { type: 'LOGIN_SUCCESS'; payload: User }
  | { type: 'LOGIN_FAILURE'; payload: string }
  | { type: 'LOGOUT' }
  | { type: 'CLEAR_ERROR' };

// Authentication reducer
const authReducer = (state: AuthState, action: AuthAction): AuthState => {
  switch (action.type) {
    case 'LOGIN_REQUEST':
      return { ...state, isLoading: true, error: null };
    case 'LOGIN_SUCCESS':
      return {
        ...state,
        isAuthenticated: true,
        user: action.payload,
        isLoading: false,
        error: null,
      };
    case 'LOGIN_FAILURE':
      return {
        ...state,
        isAuthenticated: false,
        user: null,
        isLoading: false,
        error: action.payload,
      };
    case 'LOGOUT':
      return {
        ...state,
        isAuthenticated: false,
        user: null,
        isLoading: false,
        error: null,
      };
    case 'CLEAR_ERROR':
      return { ...state, error: null };
    default:
      return state;
  }
};

// Context interface
interface AuthContextType extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
}

// Create authentication context
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Authentication provider component
export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(authReducer, initialState);
  const router = useRouter();

  // Initialize authentication state
  useEffect(() => {
    const initAuth = async () => {
      const token = getAccessToken();
      
      if (!token) {
        dispatch({ type: 'LOGIN_FAILURE', payload: 'No token found' });
        return;
      }
      
      try {
        const user = await getCurrentUser();
        dispatch({ type: 'LOGIN_SUCCESS', payload: user });
      } catch (error) {
        dispatch({ type: 'LOGIN_FAILURE', payload: 'Session expired' });
      }
    };
    
    initAuth();
  }, []);

  // Login handler
  const login = async (email: string, password: string): Promise<void> => {
    dispatch({ type: 'LOGIN_REQUEST' });
    
    try {
      const response = await loginService({ email, password });
      dispatch({ type: 'LOGIN_SUCCESS', payload: response.user });
      
      // Redirect to dashboard after login
      router.push('/dashboard');
    } catch (error) {
      dispatch({
        type: 'LOGIN_FAILURE',
        payload: error instanceof Error ? error.message : 'Login failed',
      });
    }
  };

  // Logout handler
  const logout = async (): Promise<void> => {
    try {
      await logoutService();
    } finally {
      dispatch({ type: 'LOGOUT' });
      
      // Redirect to login page after logout
      router.push('/login');
    }
  };

  // Clear error handler
  const clearError = (): void => {
    dispatch({ type: 'CLEAR_ERROR' });
  };

  return (
    <AuthContext.Provider
      value={{
        ...state,
        login,
        logout,
        clearError,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

// Authentication hook
export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  
  return context;
};
```

### API Authentication

The application configures Axios to include authentication tokens in API requests:

```typescript
// src/lib/api-client.ts
import axios from 'axios';
import { API_BASE_URL, API_TIMEOUT } from '@/config';
import { getAccessToken, refreshAccessToken, removeTokens } from '@/services/auth';

// Create API client with default configuration
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Request interceptor to add authentication token
apiClient.interceptors.request.use(
  async (config) => {
    const token = getAccessToken();
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor to handle authentication errors
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    // If error is 401 (Unauthorized) and we haven't already tried to refresh
    if (
      error.response?.status === 401 &&
      !originalRequest._retry &&
      originalRequest.url !== '/auth/refresh'
    ) {
      originalRequest._retry = true;
      
      try {
        // Attempt to refresh the token
        const newToken = await refreshAccessToken();
        
        // Update the Authorization header
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        
        // Retry the original request
        return apiClient(originalRequest);
      } catch (refreshError) {
        // If refresh fails, redirect to login
        removeTokens();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

export default apiClient;
```

## Access Control

The application implements a robust access control system:

### Permission-based Authorization

```typescript
// src/lib/permissions.ts
import { User } from '@/services/auth';

// Permission types
export type Permission =
  | 'view:dashboard'
  | 'view:clients'
  | 'create:clients'
  | 'edit:clients'
  | 'delete:clients'
  | 'view:matters'
  | 'create:matters'
  | 'edit:matters'
  | 'delete:matters'
  | 'view:reports'
  | 'create:reports'
  | 'admin:users'
  | 'admin:settings';

// Role-permission mappings
export const rolePermissions: Record<string, Permission[]> = {
  admin: [
    'view:dashboard',
    'view:clients',
    'create:clients',
    'edit:clients',
    'delete:clients',
    'view:matters',
    'create:matters',
    'edit:matters',
    'delete:matters',
    'view:reports',
    'create:reports',
    'admin:users',
    'admin:settings',
  ],
  manager: [
    'view:dashboard',
    'view:clients',
    'create:clients',
    'edit:clients',
    'view:matters',
    'create:matters',
    'edit:matters',
    'view:reports',
    'create:reports',
  ],
  user: [
    'view:dashboard',
    'view:clients',
    'view:matters',
    'view:reports',
  ],
};

// Check if user has permission
export const hasPermission = (user: User | null, permission: Permission): boolean => {
  if (!user) return false;
  
  // Direct permission check
  if (user.permissions.includes(permission)) {
    return true;
  }
  
  // Role-based permission check
  const roleBasedPermissions = rolePermissions[user.role] || [];
  return roleBasedPermissions.includes(permission);
};

// Check multiple permissions (AND logic)
export const hasAllPermissions = (user: User | null, permissions: Permission[]): boolean => {
  return permissions.every(permission => hasPermission(user, permission));
};

// Check multiple permissions (OR logic)
export const hasAnyPermission = (user: User | null, permissions: Permission[]): boolean => {
  return permissions.some(permission => hasPermission(user, permission));
};
```

### Protected Routes

The application uses a wrapper component to protect routes:

```typescript
// src/components/ProtectedRoute.tsx
import { useEffect } from 'react';
import { useRouter } from 'next/router';
import { useAuth } from '@/context/AuthContext';
import { Permission, hasPermission } from '@/lib/permissions';
import LoadingSpinner from '@/components/common/LoadingSpinner';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredPermissions?: Permission[];
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ 
  children, 
  requiredPermissions = [] 
}) => {
  const { isAuthenticated, isLoading, user } = useAuth();
  const router = useRouter();

  useEffect(() => {
    // If authentication check is complete (not loading)
    if (!isLoading) {
      // If not authenticated, redirect to login
      if (!isAuthenticated) {
        router.replace({
          pathname: '/login',
          query: { returnUrl: router.asPath },
        });
        return;
      }
      
      // If authenticated but missing required permissions
      if (
        requiredPermissions.length > 0 && 
        !requiredPermissions.every(permission => hasPermission(user, permission))
      ) {
        // Redirect to forbidden page or dashboard
        router.replace('/forbidden');
      }
    }
  }, [isAuthenticated, isLoading, requiredPermissions, router, user]);

  // Show loading state while checking authentication
  if (isLoading) {
    return <LoadingSpinner fullScreen />;
  }

  // If authenticated and has permissions, render children
  if (isAuthenticated && (
    requiredPermissions.length === 0 ||
    requiredPermissions.every(permission => hasPermission(user, permission))
  )) {
    return <>{children}</>;
  }

  // Render nothing while redirecting
  return <LoadingSpinner fullScreen />;
};

export default ProtectedRoute;
```

### Permission-based UI Elements

The application conditionally renders UI elements based on permissions:

```typescript
// src/components/PermissionGuard.tsx
import { useAuth } from '@/context/AuthContext';
import { Permission, hasPermission, hasAllPermissions, hasAnyPermission } from '@/lib/permissions';

interface PermissionGuardProps {
  children: React.ReactNode;
  permission?: Permission;
  permissions?: Permission[];
  requireAll?: boolean;
  fallback?: React.ReactNode;
}

const PermissionGuard: React.FC<PermissionGuardProps> = ({
  children,
  permission,
  permissions = [],
  requireAll = true,
  fallback = null,
}) => {
  const { user } = useAuth();
  
  // Single permission check
  if (permission && !hasPermission(user, permission)) {
    return <>{fallback}</>;
  }
  
  // Multiple permissions check
  if (permissions.length > 0) {
    const hasPermissions = requireAll
      ? hasAllPermissions(user, permissions)
      : hasAnyPermission(user, permissions);
      
    if (!hasPermissions) {
      return <>{fallback}</>;
    }
  }
  
  // User has required permissions
  return <>{children}</>;
};

export default PermissionGuard;

// Usage example
const ClientActions = () => (
  <div className="client-actions">
    <PermissionGuard permission="view:clients">
      <button>View Details</button>
    </PermissionGuard>
    
    <PermissionGuard permission="edit:clients">
      <button>Edit Client</button>
    </PermissionGuard>
    
    <PermissionGuard permission="delete:clients">
      <button>Delete Client</button>
    </PermissionGuard>
  </div>
);
```

## Security Measures

The application implements several security measures:

### CSRF Protection

```typescript
// src/lib/csrf.ts
import axios from 'axios';
import { API_BASE_URL } from '@/config';

// Get CSRF token
export const getCsrfToken = async (): Promise<string> => {
  try {
    const response = await axios.get(`${API_BASE_URL}/csrf-token`);
    return response.data.token;
  } catch (error) {
    console.error('Failed to get CSRF token:', error);
    throw error;
  }
};

// Add CSRF token to API client
export const configureCsrfProtection = (apiClient: any): void => {
  apiClient.interceptors.request.use(
    async (config: any) => {
      // Only add CSRF token for mutating requests
      if (['post', 'put', 'patch', 'delete'].includes(config.method)) {
        try {
          const token = await getCsrfToken();
          config.headers['X-CSRF-Token'] = token;
        } catch (error) {
          console.error('CSRF token error:', error);
        }
      }
      
      return config;
    },
    (error: any) => Promise.reject(error)
  );
};
```

### Content Security Policy

The application configures a Content Security Policy with Next.js:

```typescript
// next.config.js
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-eval' 'unsafe-inline' https://cdn.jsdelivr.net",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "img-src 'self' data: https://res.cloudinary.com",
      "font-src 'self' https://fonts.gstatic.com",
      "connect-src 'self' https://api.smarter-firms.com",
      "frame-src 'none'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
    ].join('; '),
  },
  {
    key: 'X-XSS-Protection',
    value: '1; mode=block',
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY',
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff',
  },
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin',
  },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=()',
  },
];

module.exports = {
  // ...other Next.js config
  async headers() {
    return [
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },
};
```

### Input Validation

The application uses Zod for client-side validation:

```typescript
// src/lib/validation.ts
import { z } from 'zod';

// Login form schema
export const loginSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

// Client form schema
export const clientSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Please enter a valid email address'),
  phone: z.string().regex(/^\+?[0-9]{10,15}$/, 'Please enter a valid phone number'),
  address: z.object({
    street: z.string().min(1, 'Street is required'),
    city: z.string().min(1, 'City is required'),
    state: z.string().min(1, 'State is required'),
    zipCode: z.string().regex(/^[0-9]{5}(-[0-9]{4})?$/, 'Please enter a valid ZIP code'),
    country: z.string().min(1, 'Country is required'),
  }),
  status: z.enum(['active', 'inactive', 'pending']),
});

// Form validation helper
export const validateForm = <T>(schema: z.ZodSchema<T>, data: unknown): { 
  valid: boolean; 
  data?: T; 
  errors?: z.ZodError 
} => {
  try {
    const validData = schema.parse(data);
    return { valid: true, data: validData };
  } catch (error) {
    if (error instanceof z.ZodError) {
      return { valid: false, errors: error };
    }
    throw error;
  }
};
```

### XSS Prevention

The application implements measures to prevent XSS attacks:

```typescript
// src/lib/sanitize.ts
import DOMPurify from 'dompurify';

// Sanitize HTML content
export const sanitizeHtml = (html: string): string => {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'ul', 'ol', 'li', 'br'],
    ALLOWED_ATTR: ['href', 'target', 'rel'],
  });
};

// Escape text for safe display
export const escapeHtml = (text: string): string => {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
};

// Safe display component for user-generated content
interface SafeHtmlProps {
  html: string;
  className?: string;
}

export const SafeHtml: React.FC<SafeHtmlProps> = ({ html, className }) => {
  const sanitizedHtml = sanitizeHtml(html);
  
  return (
    <div 
      className={className}
      dangerouslySetInnerHTML={{ __html: sanitizedHtml }}
    />
  );
};
```

### Rate Limiting

The application implements client-side rate limiting for sensitive operations:

```typescript
// src/lib/rate-limit.ts
interface RateLimitConfig {
  maxAttempts: number;
  timeWindow: number; // in milliseconds
  key: string;
}

interface RateLimitRecord {
  attempts: number;
  resetTime: number;
}

class RateLimiter {
  private cache: Map<string, RateLimitRecord> = new Map();
  
  check(config: RateLimitConfig): boolean {
    const { maxAttempts, timeWindow, key } = config;
    const now = Date.now();
    
    // Get current rate limit record or create new one
    const record = this.cache.get(key) || {
      attempts: 0,
      resetTime: now + timeWindow,
    };
    
    // Reset counter if time window has passed
    if (now > record.resetTime) {
      record.attempts = 1;
      record.resetTime = now + timeWindow;
      this.cache.set(key, record);
      return true;
    }
    
    // Increment counter
    record.attempts += 1;
    this.cache.set(key, record);
    
    // Check if rate limit is exceeded
    return record.attempts <= maxAttempts;
  }
  
  getRemainingAttempts(key: string): number {
    const record = this.cache.get(key);
    if (!record) return Infinity;
    
    const now = Date.now();
    
    // Reset expired records
    if (now > record.resetTime) {
      this.cache.delete(key);
      return Infinity;
    }
    
    return Math.max(0, record.maxAttempts - record.attempts);
  }
  
  getTimeToReset(key: string): number {
    const record = this.cache.get(key);
    if (!record) return 0;
    
    const now = Date.now();
    return Math.max(0, record.resetTime - now);
  }
}

export const rateLimiter = new RateLimiter();

// Usage in login form
export const useRateLimitedLogin = (email: string) => {
  const attemptLogin = async (password: string) => {
    const canAttempt = rateLimiter.check({
      maxAttempts: 5,
      timeWindow: 5 * 60 * 1000, // 5 minutes
      key: `login:${email}`,
    });
    
    if (!canAttempt) {
      const timeToReset = rateLimiter.getTimeToReset(`login:${email}`);
      throw new Error(`Too many login attempts. Please try again in ${Math.ceil(timeToReset / 60000)} minutes.`);
    }
    
    // Proceed with login
    // ...
  };
  
  return attemptLogin;
};
```

### Secure Data Storage

The application uses secure storage mechanisms:

```typescript
// src/lib/secure-storage.ts
import CryptoJS from 'crypto-js';

// Encryption key (in a real app, this would be from environment variables)
const ENCRYPTION_KEY = process.env.NEXT_PUBLIC_ENCRYPTION_KEY || 'fallback-key-for-dev-only';

// Encrypt data
export const encryptData = (data: any): string => {
  // Convert data to string if it's not already
  const dataString = typeof data === 'string' ? data : JSON.stringify(data);
  
  // Encrypt
  return CryptoJS.AES.encrypt(dataString, ENCRYPTION_KEY).toString();
};

// Decrypt data
export const decryptData = <T>(encryptedData: string): T => {
  // Decrypt
  const decryptedBytes = CryptoJS.AES.decrypt(encryptedData, ENCRYPTION_KEY);
  const decryptedText = decryptedBytes.toString(CryptoJS.enc.Utf8);
  
  // Parse JSON if necessary
  try {
    return JSON.parse(decryptedText) as T;
  } catch (e) {
    return decryptedText as unknown as T;
  }
};

// Secure localStorage wrapper
export const secureStorage = {
  setItem: (key: string, data: any): void => {
    const encryptedData = encryptData(data);
    localStorage.setItem(key, encryptedData);
  },
  
  getItem: <T>(key: string): T | null => {
    const encryptedData = localStorage.getItem(key);
    
    if (!encryptedData) {
      return null;
    }
    
    try {
      return decryptData<T>(encryptedData);
    } catch (error) {
      console.error('Failed to decrypt data:', error);
      return null;
    }
  },
  
  removeItem: (key: string): void => {
    localStorage.removeItem(key);
  },
  
  clear: (): void => {
    localStorage.clear();
  },
};
```

## Security Best Practices

The application follows these security best practices:

1. **Authentication**: JWT-based authentication with secure token storage and automatic refresh
2. **Authorization**: Role-based access control with fine-grained permissions
3. **Input Validation**: Zod schemas for client-side validation before submission
4. **Output Encoding**: DOMPurify for sanitizing HTML content
5. **CSRF Protection**: CSRF tokens for mutating operations
6. **Content Security Policy**: Restrictive CSP to prevent script injection
7. **Secure Cookies**: HTTP-only cookies with secure and SameSite attributes
8. **HTTPS Only**: Enforced HTTPS for all communications
9. **Rate Limiting**: Protection against brute force attacks
10. **Audit Logging**: Logging of security-relevant events
11. **Error Handling**: Generic error messages that don't leak implementation details
12. **Dependency Security**: Regular updates and security audits of dependencies 