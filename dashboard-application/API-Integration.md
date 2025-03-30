# API Integration

This document outlines the API integration approach for the Dashboard Application, including service architecture, authentication, error handling, and performance optimization strategies.

## Service Architecture

The Dashboard Application uses a service-based architecture for API integration:

### Service Layer

The application implements service modules to encapsulate API communication:

```
src/
  services/
    analytics.ts      // Analytics data services
    auth.ts           // Authentication services
    clients.ts        // Client management services
    matters.ts        // Matter management services
    notifications.ts  // Notification services
    reports.ts        // Reporting services
    user.ts           // User profile services
```

Each service module follows a consistent pattern:

```typescript
// Example service pattern
import axios from 'axios';
import { API_BASE_URL } from '@/config';

// Type definitions
export interface ClientData {
  id: string;
  name: string;
  // Other properties
}

// Service class or functions
export const clientsService = {
  // Get all clients
  async getClients(): Promise<ClientData[]> {
    try {
      const response = await axios.get(`${API_BASE_URL}/clients`);
      return response.data;
    } catch (error) {
      handleApiError(error);
      throw error;
    }
  },
  
  // Get single client
  async getClient(id: string): Promise<ClientData> {
    try {
      const response = await axios.get(`${API_BASE_URL}/clients/${id}`);
      return response.data;
    } catch (error) {
      handleApiError(error);
      throw error;
    }
  },
  
  // Create new client
  async createClient(data: Omit<ClientData, 'id'>): Promise<ClientData> {
    try {
      const response = await axios.post(`${API_BASE_URL}/clients`, data);
      return response.data;
    } catch (error) {
      handleApiError(error);
      throw error;
    }
  },
  
  // Update client
  async updateClient(id: string, data: Partial<ClientData>): Promise<ClientData> {
    try {
      const response = await axios.put(`${API_BASE_URL}/clients/${id}`, data);
      return response.data;
    } catch (error) {
      handleApiError(error);
      throw error;
    }
  },
  
  // Delete client
  async deleteClient(id: string): Promise<void> {
    try {
      await axios.delete(`${API_BASE_URL}/clients/${id}`);
    } catch (error) {
      handleApiError(error);
      throw error;
    }
  }
};
```

## API Client Configuration

The application uses Axios as the HTTP client with custom configuration:

```typescript
// src/lib/api-client.ts
import axios from 'axios';
import { getAuthToken, refreshToken } from '@/services/auth';
import { API_BASE_URL, API_TIMEOUT } from '@/config';

// Create axios instance with default config
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Request interceptor for adding auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = getAuthToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for token refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    // If error is 401 and we haven't tried refreshing token yet
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        // Attempt to refresh token
        await refreshToken();
        
        // Retry the original request with new token
        const token = getAuthToken();
        originalRequest.headers.Authorization = `Bearer ${token}`;
        return apiClient(originalRequest);
      } catch (refreshError) {
        // If refresh fails, redirect to login
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

export default apiClient;
```

## Authentication Flow

The authentication flow involves:

1. **Login**: User credentials are sent to the auth API endpoint
2. **Token Storage**: JWT tokens are stored in secure HTTP-only cookies
3. **Token Refresh**: Refresh tokens are used to obtain new access tokens
4. **Logout**: Tokens are invalidated on the server and removed from cookies

```typescript
// src/services/auth.ts
import apiClient from '@/lib/api-client';
import Cookies from 'js-cookie';

const AUTH_TOKEN_KEY = 'auth_token';
const REFRESH_TOKEN_KEY = 'refresh_token';

interface AuthResponse {
  token: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    name: string;
    role: string;
  };
}

export const getAuthToken = (): string | undefined => {
  return Cookies.get(AUTH_TOKEN_KEY);
};

export const getRefreshToken = (): string | undefined => {
  return Cookies.get(REFRESH_TOKEN_KEY);
};

export const setAuthTokens = (token: string, refreshToken: string): void => {
  // Set cookies with secure flag in production
  const options = {
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    expires: 7 // 7 days
  };
  
  Cookies.set(AUTH_TOKEN_KEY, token, options);
  Cookies.set(REFRESH_TOKEN_KEY, refreshToken, options);
};

export const removeAuthTokens = (): void => {
  Cookies.remove(AUTH_TOKEN_KEY);
  Cookies.remove(REFRESH_TOKEN_KEY);
};

export const login = async (email: string, password: string): Promise<AuthResponse> => {
  try {
    const response = await apiClient.post<AuthResponse>('/auth/login', { email, password });
    const { token, refreshToken, user } = response.data;
    
    setAuthTokens(token, refreshToken);
    
    return response.data;
  } catch (error) {
    handleAuthError(error);
    throw error;
  }
};

export const refreshToken = async (): Promise<string> => {
  try {
    const refreshToken = getRefreshToken();
    
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }
    
    const response = await apiClient.post<{ token: string; refreshToken: string }>('/auth/refresh', {
      refreshToken,
    });
    
    const { token, refreshToken: newRefreshToken } = response.data;
    setAuthTokens(token, newRefreshToken);
    
    return token;
  } catch (error) {
    removeAuthTokens();
    throw error;
  }
};

export const logout = async (): Promise<void> => {
  try {
    const refreshToken = getRefreshToken();
    
    if (refreshToken) {
      // Notify server to invalidate the token
      await apiClient.post('/auth/logout', { refreshToken });
    }
  } catch (error) {
    console.error('Logout error:', error);
  } finally {
    removeAuthTokens();
  }
};
```

## Error Handling

The application implements a comprehensive error handling strategy:

```typescript
// src/lib/error-handler.ts
import { AxiosError } from 'axios';
import { toast } from 'react-toastify';

export interface ApiError {
  status: number;
  message: string;
  code?: string;
  details?: Record<string, any>;
}

export const handleApiError = (error: unknown): ApiError => {
  // Default error response
  const defaultError: ApiError = {
    status: 500,
    message: 'An unexpected error occurred. Please try again later.',
  };

  // Handle Axios errors
  if (error && typeof error === 'object' && 'isAxiosError' in error) {
    const axiosError = error as AxiosError<any>;
    
    // Get response data if available
    const responseData = axiosError.response?.data;
    const status = axiosError.response?.status || 500;
    
    // Format error based on status code
    switch (status) {
      case 400:
        return {
          status,
          message: responseData?.message || 'Invalid request data',
          code: responseData?.code,
          details: responseData?.details,
        };
        
      case 401:
        return {
          status,
          message: 'You are not authenticated. Please log in again.',
          code: 'UNAUTHENTICATED',
        };
        
      case 403:
        return {
          status,
          message: 'You do not have permission to perform this action.',
          code: 'FORBIDDEN',
        };
        
      case 404:
        return {
          status,
          message: responseData?.message || 'The requested resource was not found.',
          code: 'NOT_FOUND',
        };
        
      case 422:
        return {
          status,
          message: responseData?.message || 'Validation error',
          code: 'VALIDATION_ERROR',
          details: responseData?.errors,
        };
        
      case 429:
        return {
          status,
          message: 'Too many requests. Please try again later.',
          code: 'RATE_LIMITED',
        };
        
      case 500:
      case 502:
      case 503:
      case 504:
        return {
          status,
          message: 'Server error. Please try again later.',
          code: 'SERVER_ERROR',
        };
        
      default:
        return {
          status,
          message: responseData?.message || defaultError.message,
          code: responseData?.code,
        };
    }
  }
  
  // Handle other types of errors
  return defaultError;
};

export const displayApiError = (error: unknown): void => {
  const apiError = handleApiError(error);
  
  // Log the error
  console.error('API Error:', apiError);
  
  // Display user-friendly error message
  toast.error(apiError.message);
  
  // For validation errors, display field-specific errors
  if (apiError.code === 'VALIDATION_ERROR' && apiError.details) {
    Object.values(apiError.details).forEach((message) => {
      if (typeof message === 'string') {
        toast.error(message);
      }
    });
  }
};
```

## React Query Integration

The application uses React Query for data fetching, caching, and state management:

```typescript
// src/hooks/useClients.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { clientsService } from '@/services/clients';
import { displayApiError } from '@/lib/error-handler';

// Query keys
export const clientsKeys = {
  all: ['clients'] as const,
  lists: () => [...clientsKeys.all, 'list'] as const,
  list: (filters: Record<string, any>) => [...clientsKeys.lists(), filters] as const,
  details: () => [...clientsKeys.all, 'detail'] as const,
  detail: (id: string) => [...clientsKeys.details(), id] as const,
};

// Hook for fetching all clients
export const useClients = (filters: Record<string, any> = {}) => {
  return useQuery({
    queryKey: clientsKeys.list(filters),
    queryFn: () => clientsService.getClients(filters),
    onError: displayApiError,
  });
};

// Hook for fetching a single client
export const useClient = (id: string) => {
  return useQuery({
    queryKey: clientsKeys.detail(id),
    queryFn: () => clientsService.getClient(id),
    onError: displayApiError,
    enabled: !!id, // Only run if ID is provided
  });
};

// Hook for creating a client
export const useCreateClient = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: clientsService.createClient,
    onSuccess: () => {
      // Invalidate the clients list query
      queryClient.invalidateQueries({ queryKey: clientsKeys.lists() });
    },
    onError: displayApiError,
  });
};

// Hook for updating a client
export const useUpdateClient = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => clientsService.updateClient(id, data),
    onSuccess: (data) => {
      // Update the cache for this specific client
      queryClient.setQueryData(clientsKeys.detail(data.id), data);
      // Invalidate the clients list query
      queryClient.invalidateQueries({ queryKey: clientsKeys.lists() });
    },
    onError: displayApiError,
  });
};

// Hook for deleting a client
export const useDeleteClient = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: clientsService.deleteClient,
    onSuccess: (_, id) => {
      // Remove the client from the cache
      queryClient.removeQueries({ queryKey: clientsKeys.detail(id) });
      // Invalidate the clients list query
      queryClient.invalidateQueries({ queryKey: clientsKeys.lists() });
    },
    onError: displayApiError,
  });
};
```

## API Query Provider

The application implements a QueryClientProvider to configure React Query:

```tsx
// src/providers/QueryProvider.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
      retry: 1,
      refetchOnWindowFocus: false,
      refetchOnMount: true,
    },
  },
});

interface QueryProviderProps {
  children: React.ReactNode;
}

export const QueryProvider: React.FC<QueryProviderProps> = ({ children }) => {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      {process.env.NODE_ENV === 'development' && <ReactQueryDevtools />}
    </QueryClientProvider>
  );
};
```

## WebSocket Integration

The application integrates WebSockets for real-time updates:

```typescript
// src/lib/websocket.ts
import { io, Socket } from 'socket.io-client';
import { getAuthToken } from '@/services/auth';
import { WEBSOCKET_URL } from '@/config';

class WebSocketService {
  private socket: Socket | null = null;
  private reconnectAttempts: number = 0;
  private maxReconnectAttempts: number = 5;
  private listeners: Record<string, Array<(data: any) => void>> = {};

  // Initialize socket connection
  connect(): void {
    if (this.socket) return;

    const token = getAuthToken();
    
    if (!token) {
      console.error('Cannot connect to WebSocket: No auth token available');
      return;
    }

    this.socket = io(WEBSOCKET_URL, {
      auth: {
        token,
      },
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
      reconnectionAttempts: this.maxReconnectAttempts,
    });

    this.setupEventListeners();
  }

  // Setup socket event listeners
  private setupEventListeners(): void {
    if (!this.socket) return;

    this.socket.on('connect', () => {
      console.log('WebSocket connected');
      this.reconnectAttempts = 0;
    });

    this.socket.on('disconnect', (reason) => {
      console.log(`WebSocket disconnected: ${reason}`);
    });

    this.socket.on('connect_error', (error) => {
      console.error('WebSocket connection error:', error);
      this.reconnectAttempts++;
      
      if (this.reconnectAttempts >= this.maxReconnectAttempts) {
        console.error('Max reconnection attempts reached');
        this.disconnect();
      }
    });

    // Register all existing listeners
    Object.entries(this.listeners).forEach(([event, callbacks]) => {
      callbacks.forEach(callback => {
        this.socket?.on(event, callback);
      });
    });
  }

  // Disconnect the socket
  disconnect(): void {
    if (!this.socket) return;
    
    this.socket.disconnect();
    this.socket = null;
  }

  // Subscribe to an event
  subscribe<T>(event: string, callback: (data: T) => void): () => void {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    
    this.listeners[event].push(callback);
    
    // Register with socket if connected
    if (this.socket) {
      this.socket.on(event, callback);
    }

    // Return unsubscribe function
    return () => this.unsubscribe(event, callback);
  }

  // Unsubscribe from an event
  unsubscribe(event: string, callback: (data: any) => void): void {
    if (!this.listeners[event]) return;
    
    // Remove from internal listeners
    this.listeners[event] = this.listeners[event].filter(cb => cb !== callback);
    
    // Remove from socket
    if (this.socket) {
      this.socket.off(event, callback);
    }
  }

  // Emit an event
  emit<T>(event: string, data: T): void {
    if (!this.socket) {
      console.error('Cannot emit event: WebSocket not connected');
      return;
    }
    
    this.socket.emit(event, data);
  }
}

// Create singleton instance
export const webSocketService = new WebSocketService();

// React hook for WebSocket events
export const useWebSocket = <T>(event: string, callback: (data: T) => void) => {
  React.useEffect(() => {
    // Ensure connection is established
    webSocketService.connect();
    
    // Subscribe to event
    const unsubscribe = webSocketService.subscribe<T>(event, callback);
    
    // Cleanup on unmount
    return () => {
      unsubscribe();
    };
  }, [event, callback]);
};
```

## API Performance Optimization

The application implements several strategies for optimizing API performance:

### Request Batching

For multiple related resources, the application batches requests:

```typescript
// src/services/batch.ts
import apiClient from '@/lib/api-client';

interface BatchRequest {
  id: string;
  path: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  body?: any;
}

interface BatchResponse {
  id: string;
  status: number;
  data: any;
}

export const executeBatchRequest = async (requests: BatchRequest[]): Promise<Record<string, BatchResponse>> => {
  try {
    const response = await apiClient.post<BatchResponse[]>('/batch', { requests });
    
    // Convert array response to record keyed by request id
    return response.data.reduce((acc, item) => {
      acc[item.id] = item;
      return acc;
    }, {} as Record<string, BatchResponse>);
  } catch (error) {
    handleApiError(error);
    throw error;
  }
};
```

### Prefetching

The application prefetches data that is likely to be needed:

```typescript
// src/components/ClientsList.tsx
import { useClients, clientsKeys } from '@/hooks/useClients';
import { useQueryClient } from '@tanstack/react-query';

const ClientsList: React.FC = () => {
  const { data: clients, isLoading } = useClients();
  const queryClient = useQueryClient();
  
  // Prefetch client details when hovering over a client row
  const prefetchClient = (id: string) => {
    queryClient.prefetchQuery({
      queryKey: clientsKeys.detail(id),
      queryFn: () => clientsService.getClient(id),
    });
  };
  
  return (
    <div className="clients-list">
      {isLoading ? (
        <LoadingSpinner />
      ) : (
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {clients?.map((client) => (
              <tr 
                key={client.id}
                onMouseEnter={() => prefetchClient(client.id)}
              >
                <td>{client.name}</td>
                <td>{client.email}</td>
                <td>{client.status}</td>
                <td>
                  <Link href={`/clients/${client.id}`}>View</Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};
```

### Request Cancellation

The application cancels ongoing requests when components unmount:

```typescript
// src/hooks/useApi.ts
import { useState, useEffect, useRef } from 'react';
import axios, { AxiosRequestConfig, CancelTokenSource } from 'axios';
import apiClient from '@/lib/api-client';
import { handleApiError } from '@/lib/error-handler';

export function useApi<T>(config: AxiosRequestConfig): {
  data: T | null;
  loading: boolean;
  error: Error | null;
  execute: () => Promise<T>;
} {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<Error | null>(null);
  
  const cancelTokenRef = useRef<CancelTokenSource | null>(null);
  
  const execute = async (): Promise<T> => {
    setLoading(true);
    setError(null);
    
    // Cancel any ongoing request
    if (cancelTokenRef.current) {
      cancelTokenRef.current.cancel('Request superseded');
    }
    
    // Create new cancel token
    cancelTokenRef.current = axios.CancelToken.source();
    
    try {
      const response = await apiClient.request<T>({
        ...config,
        cancelToken: cancelTokenRef.current.token,
      });
      
      setData(response.data);
      setLoading(false);
      return response.data;
    } catch (err) {
      if (axios.isCancel(err)) {
        // Request was cancelled, ignore
        console.log('Request cancelled', err.message);
      } else {
        const apiError = handleApiError(err);
        setError(new Error(apiError.message));
      }
      setLoading(false);
      throw err;
    }
  };
  
  useEffect(() => {
    return () => {
      // Cancel request on component unmount
      if (cancelTokenRef.current) {
        cancelTokenRef.current.cancel('Component unmounted');
      }
    };
  }, []);
  
  return { data, loading, error, execute };
}
```

## API Response Caching

The application implements a custom caching layer for API responses:

```typescript
// src/lib/cache.ts
interface CacheItem<T> {
  data: T;
  timestamp: number;
  expiry: number;
}

class ApiCache {
  private cache: Map<string, CacheItem<any>> = new Map();
  private defaultExpiry: number = 5 * 60 * 1000; // 5 minutes
  
  // Get item from cache
  get<T>(key: string): T | null {
    const item = this.cache.get(key);
    
    if (!item) {
      return null;
    }
    
    // Check if item has expired
    if (Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }
    
    return item.data as T;
  }
  
  // Set item in cache
  set<T>(key: string, data: T, expiry?: number): void {
    const expiryTime = expiry || this.defaultExpiry;
    
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      expiry: Date.now() + expiryTime,
    });
  }
  
  // Remove item from cache
  remove(key: string): void {
    this.cache.delete(key);
  }
  
  // Clear all items from cache
  clear(): void {
    this.cache.clear();
  }
  
  // Clear items by key pattern
  clearByPattern(pattern: string): void {
    const regex = new RegExp(pattern);
    
    for (const key of this.cache.keys()) {
      if (regex.test(key)) {
        this.cache.delete(key);
      }
    }
  }
}

// Create singleton instance
export const apiCache = new ApiCache();
```

## API Best Practices

The application follows these API integration best practices:

1. **Consistent Error Handling**: All API errors are processed through the same error handling pipeline.
2. **Type Safety**: TypeScript interfaces are used for all API requests and responses.
3. **Service Abstraction**: API calls are encapsulated in service modules.
4. **Caching Strategy**: React Query provides automatic caching with configurable stale times.
5. **Token Management**: JWT tokens are handled securely with automatic refresh.
6. **Request Optimization**: Batching, prefetching, and cancellation to optimize performance.
7. **Real-time Updates**: WebSocket integration for instant data updates.
8. **Background Syncing**: Service worker integration for offline support and background syncing.
9. **Retry Logic**: Automatic retry of failed requests with exponential backoff.
10. **Rate Limiting**: Client-side throttling to prevent API rate limit issues. 