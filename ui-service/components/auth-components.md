# Authentication Components

This document provides an overview of the authentication components implemented for the Smarter Firms platform.

## Component Architecture

The authentication system consists of the following components:

```
Auth Service
├── Components
│   ├── LoginForm
│   ├── RegistrationForm
│   ├── ConsultantRegistrationForm
│   ├── ForgotPasswordForm
│   ├── ResetPasswordForm
│   ├── TwoFactorSetup
│   ├── ClioSSOButton
│   └── SessionTimeoutModal
├── Context
│   └── AuthContext
├── Hooks
│   └── useSessionTimeout
├── Utils
│   └── CSRF Protection
└── Validations
    └── Zod Schemas
```

## Form Components

### `LoginForm`

A component that handles user login with both traditional email/password and Clio SSO options.

**Features:**
- Email/password validation
- "Remember me" functionality
- Clio SSO integration
- Error state handling
- Loading states for both authentication methods

**Props:**
```typescript
interface LoginFormProps {
  onLogin: (data: LoginFormValues) => Promise<void>;
  onClioLogin: () => Promise<void>;
  isLoading?: boolean;
  isClioLoading?: boolean;
  error?: string;
}
```

### `RegistrationForm`

A component for new user registration with comprehensive validation.

**Features:**
- Validated input fields
- Password strength requirements
- Terms and conditions agreement
- Real-time validation feedback

**Props:**
```typescript
interface RegistrationFormProps {
  onRegister: (data: RegistrationFormValues) => Promise<void>;
  isLoading?: boolean;
  error?: string;
}
```

### `ConsultantRegistrationForm`

A specialized registration form for consultants with additional fields.

**Features:**
- All standard registration fields
- Organization and specialty fields
- Optional referral code
- Robust validation

**Props:**
```typescript
interface ConsultantRegistrationFormProps {
  onRegister: (data: ConsultantRegistrationFormValues) => Promise<void>;
  isLoading?: boolean;
  error?: string;
  specialties?: { value: string; label: string }[];
}
```

### `ForgotPasswordForm`

A form for requesting a password reset link.

**Features:**
- Email validation
- Success/error state handling
- Clear user feedback

**Props:**
```typescript
interface ForgotPasswordFormProps {
  onForgotPassword: (data: ForgotPasswordFormValues) => Promise<void>;
  isLoading?: boolean;
  error?: string;
}
```

### `ResetPasswordForm`

A form for setting a new password after receiving a reset link.

**Features:**
- Password strength requirements
- Password confirmation
- Clear validation feedback

**Props:**
```typescript
interface ResetPasswordFormProps {
  onSubmit: (data: ResetPasswordFormValues) => Promise<void>;
  isLoading?: boolean;
  error?: string;
}
```

## Security Components

### `TwoFactorSetup`

A multi-step wizard for setting up two-factor authentication.

**Features:**
- Support for app-based, SMS, and email 2FA methods
- QR code display for authentication apps
- Verification code validation
- Backup codes generation and display

**Props:**
```typescript
interface TwoFactorSetupProps {
  onGenerateQR: () => Promise<{qrCode: string, secret: string}>;
  onVerifyCode: (code: string, secret: string) => Promise<boolean>;
  onGenerateBackupCodes: () => Promise<string[]>;
  onComplete: (method: TwoFactorMethod) => Promise<void>;
  onCancel: () => void;
}
```

### `SessionTimeoutModal`

A modal that appears when a user's session is about to expire.

**Features:**
- Countdown timer
- Options to continue session or logout
- Accessible design

**Props:**
```typescript
interface SessionTimeoutModalProps {
  isVisible: boolean;
  timeRemaining: number;
  onContinue: () => void;
  onLogout: () => void;
}
```

## Utility Components

### `ClioSSOButton`

A button component for initiating Clio SSO login.

**Features:**
- Loading state
- Clio branding
- Accessible design

**Props:**
```typescript
interface ClioSSOButtonProps {
  onClick: () => void;
  isLoading?: boolean;
  className?: string;
}
```

## Hooks

### `useSessionTimeout`

A custom hook for managing session timeouts.

**Features:**
- Configurable timeout duration
- Warning period before session expiry
- User activity monitoring
- Automatic logout

**Usage:**
```typescript
const { showWarning, timeRemaining, continueSession, handleLogout } = useSessionTimeout({
  expiryTime: 15 * 60 * 1000, // 15 minutes
  warningTime: 60 * 1000, // 1 minute warning
});
```

## Security Utilities

### CSRF Protection

Utilities for protecting against Cross-Site Request Forgery attacks.

**Features:**
- Automatic CSRF token inclusion in fetch requests
- Form data protection
- React component for CSRF token input fields

**Usage:**
```typescript
// Initialize protection
setupCSRFProtection();

// Get current token
const token = getCSRFToken();

// Add token to form data
const formDataWithToken = addCSRFToFormData(formData);

// Include token in forms
<form>
  <CSRFTokenInput />
  {/* other form fields */}
</form>
```

## State Management

Authentication state is managed through React Context, providing:

- User authentication status
- Login/logout functionality
- Registration process
- Password management
- Session handling

**Usage:**
```typescript
const { user, isLoading, isAuthenticated, login, logout } = useAuth();
```

## Validation

Form validation is implemented using Zod schemas:

- `loginSchema` - For login form validation
- `registrationSchema` - For user registration
- `consultantRegistrationSchema` - For consultant registration
- `forgotPasswordSchema` - For password reset requests
- `resetPasswordSchema` - For password reset confirmation

## Accessibility

All components meet WCAG AA compliance:

- Proper use of ARIA attributes
- Keyboard navigation support
- Screen reader compatibility
- Sufficient color contrast
- Clear focus indicators

## Responsive Design

Components are built with a mobile-first approach:

- Flexible layouts
- Touch-friendly targets
- Responsive form elements
- Appropriate spacing for all device sizes 