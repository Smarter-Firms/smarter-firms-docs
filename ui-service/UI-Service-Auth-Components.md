# UI Service - Authentication Components

## Overview
This document outlines the initial authentication-related UI components that need to be implemented in the UI Service. These components will provide the user interface for registration, login, and password management.

## Component Architecture
We'll use React components with TypeScript and follow a modular approach with:
- Container components (managing state and logic)
- Presentational components (handling UI rendering)
- Custom hooks (for reusable logic)
- Context providers (for shared state)

## Authentication Components

### 1. Login Form Component

#### Features
- Email/username input field
- Password input field with show/hide toggle
- "Remember me" checkbox
- Login button
- Links to registration and forgot password
- Validation with error messaging
- Loading state indication

#### Technical Specification
```tsx
// LoginForm.tsx
interface LoginFormProps {
  onLogin: (credentials: { email: string; password: string; remember: boolean }) => Promise<void>;
  isLoading?: boolean;
  error?: string;
}

// LoginContainer.tsx
const LoginContainer: React.FC = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | undefined>();
  const { login } = useAuth();
  
  const handleLogin = async (credentials) => {
    setIsLoading(true);
    setError(undefined);
    try {
      await login(credentials);
      // Redirect or handle success
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };
  
  return <LoginForm onLogin={handleLogin} isLoading={isLoading} error={error} />;
};
```

### 2. Registration Form Component

#### Features
- Name input fields (first, last)
- Email input field
- Password input field with strength indicator
- Password confirmation field
- Terms and conditions checkbox
- Registration button
- Link to login
- Comprehensive validation
- Loading state indication

#### Technical Specification
```tsx
// RegistrationForm.tsx
interface RegistrationFormProps {
  onRegister: (userData: {
    firstName: string;
    lastName: string;
    email: string;
    password: string;
    agreeToTerms: boolean;
  }) => Promise<void>;
  isLoading?: boolean;
  error?: string;
}

// RegistrationContainer.tsx
const RegistrationContainer: React.FC = () => {
  // Similar to LoginContainer with appropriate state and handlers
};
```

### 3. Forgot Password Flow

#### 3.1 Request Reset Component
- Email input field
- Submit button
- Link back to login
- Success state with instructions
- Loading state indication

#### 3.2 Reset Password Component
- Token validation (from URL)
- New password input with strength indicator
- Confirm password input
- Submit button
- Success state with login link
- Error state for invalid/expired tokens

#### Technical Specification
```tsx
// ForgotPasswordForm.tsx
interface ForgotPasswordFormProps {
  onSubmit: (email: string) => Promise<void>;
  isLoading?: boolean;
  isSuccess?: boolean;
  error?: string;
}

// ResetPasswordForm.tsx
interface ResetPasswordFormProps {
  token: string;
  onSubmit: (data: { password: string; confirmPassword: string }) => Promise<void>;
  isLoading?: boolean;
  isSuccess?: boolean;
  error?: string;
  isTokenValid: boolean;
}
```

### 4. Email Verification Component

#### Features
- Token validation (from URL)
- Success state with redirect to login
- Error state for invalid/expired tokens
- Resend verification email option
- Loading state indication

#### Technical Specification
```tsx
// EmailVerification.tsx
interface EmailVerificationProps {
  token: string;
  onResendVerification: (email: string) => Promise<void>;
  isLoading?: boolean;
  isSuccess?: boolean;
  error?: string;
  email?: string;
}
```

### 5. Authentication Context Provider

#### Features
- User state management
- Login/logout functionality
- Token management
- Persistence with localStorage/sessionStorage
- Protected route functionality

#### Technical Specification
```tsx
// AuthContext.tsx
interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => Promise<void>;
  register: (userData: RegistrationData) => Promise<void>;
  forgotPassword: (email: string) => Promise<void>;
  resetPassword: (token: string, password: string) => Promise<void>;
  verifyEmail: (token: string) => Promise<void>;
}

// AuthProvider.tsx
const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Implementation with state and API calls
};

// useAuth.tsx
const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// ProtectedRoute.tsx
const ProtectedRoute: React.FC<{ 
  children: React.ReactNode;
  requiredRoles?: string[];
}> = ({ children, requiredRoles }) => {
  // Implementation with auth checks and role validation
};
```

## API Integration

### Authentication Service Hooks
```tsx
// useAuthService.ts
export const useAuthService = () => {
  const apiClient = useApiClient();
  
  const login = async (credentials: LoginCredentials) => {
    const response = await apiClient.post('/auth/login', credentials);
    return response.data;
  };
  
  const register = async (userData: RegistrationData) => {
    const response = await apiClient.post('/auth/register', userData);
    return response.data;
  };
  
  // Additional methods for other auth operations
  
  return {
    login,
    register,
    // Other methods
  };
};
```

### API Client
```tsx
// apiClient.ts
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for adding auth token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for token refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    // Token refresh logic
  }
);

export default apiClient;
```

## Design & Style Considerations
- Use TailwindCSS for styling
- Follow mobile-first approach
- Ensure accessibility compliance
- Implement consistent error messaging
- Use loading skeletons for better UX
- Apply consistent form validation patterns

## Testing Strategy
- Unit tests for form validation
- Integration tests for API interactions
- Test user flows through authentication process
- Test error cases and edge conditions
- Test form accessibility

## Implementation Phases
1. **Phase 1**: Basic login/register components
2. **Phase 2**: Forgot password flow
3. **Phase 3**: Email verification
4. **Phase 4**: Auth context and protected routes
5. **Phase 5**: Polish and optimizations

## Dependencies
- React 18+
- TypeScript 5+
- TailwindCSS
- React Hook Form for form management
- Zod for validation
- Axios for API requests
- JWT decode for token handling 