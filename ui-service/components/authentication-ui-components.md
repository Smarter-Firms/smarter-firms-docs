# Authentication UI Components

This document describes the authentication components and flows implemented in the UI Service.

## Overview

The authentication system features:

- HTTP-only cookie-based token storage
- Device fingerprinting for session validation
- CSRF protection
- Intelligent token refresh handling
- Multi-firm context switching with safeguards
- Detailed loading states for cross-firm data access

## Key Components

### Authentication Context

The `AuthContext` component provides authentication state management throughout the application:

```tsx
// Usage example
import { useAuth } from '../contexts/auth/AuthContext';

function MyComponent() {
  const { user, isLoading, isAuthenticated, error } = useAuth();
  
  // Use authentication state
}
```

Key features:
- Session security evaluation
- Automatic token refresh
- Token refresh that handles concurrent requests
- Regular security status checks

### Firm Context Management

For consultants working with multiple firms, we provide a comprehensive firm context system:

```tsx
// Usage example
import { useFirmContext } from '../hooks/useFirmContext';

function MyConsultantComponent() {
  const { 
    firms, 
    currentFirm, 
    loadingState, 
    switchFirm, 
    fetchCrossFirmData 
  } = useFirmContext();
  
  // Access or change firm context
}
```

### Component Library

#### FirmSelector

Dropdown component allowing consultants to switch between firms:

```tsx
<FirmSelector
  firms={firms}
  currentFirmId={currentFirm?.id || null}
  loadingState={loadingState}
  onFirmSelect={switchFirm}
  hasUnsavedChanges={hasUnsavedChanges}
  activeFirmOperations={activeFirmOperations}
/>
```

Features:
- Displays access level badges
- Confirms switching when unsaved changes exist
- Shows loading indicators during switching
- Prevents switching during active operations

#### FirmContextBanner

Banner that clearly indicates the current firm context:

```tsx
<FirmContextBanner firm={currentFirm} className="sticky top-0 z-20" />
```

Features:
- Color-coded by access level
- Always visible, sticky positioning
- Clear indication of access permissions

#### CrossFirmData

Component for fetching and displaying data from other firms without switching contexts:

```tsx
<CrossFirmData
  firmId="firm-123"
  endpoint="/api/some-data"
  renderData={(data) => (
    <div>{/* Render your data here */}</div>
  )}
  loadingLabel="Loading client data..."
/>
```

Features:
- Clear loading states
- Visual indication of cross-firm data
- Error handling
- Custom rendering

#### ConsultantLayout

Layout wrapper providing firm context UI for consultant users:

```tsx
<ConsultantLayout hasUnsavedChanges={formIsDirty} preventNavigation={true}>
  {/* Your page content */}
</ConsultantLayout>
```

Features:
- Firm context banner
- Security status indicator
- Unsaved changes warnings
- Navigation prevention

## Integration with Auth Service

### API Integration Points

1. **Login**: `/auth/login` endpoint with device fingerprinting
2. **Logout**: `/auth/logout` endpoint with pending request cleanup
3. **Token Refresh**: `/auth/refresh` endpoint with concurrent request handling
4. **Current User**: `/auth/me` endpoint to fetch user data
5. **Firm Switching**: `/firms/{firmId}/switch` endpoint

### Security Features

#### Session Fingerprinting

The fingerprinting system balances security and privacy:

```tsx
// Device fingerprint generation
const fingerprint = await getDeviceFingerprint();

// Fingerprint validation
const { isValid, riskLevel } = await validateFingerprint(storedFingerprint);
```

Fingerprinting includes:
- Core stable components (user agent, screen size, timezone)
- Semi-variable components (canvas fingerprint, plugins count)
- Security scoring

#### Token Refresh Strategy

The token refresh system handles these edge cases:
- Refreshing during active use without disruption
- Handling multiple concurrent requests during refresh
- Graceful degradation when refresh fails

```tsx
// Manual refresh can be triggered
await apiGateway.refreshToken();

// Automatic refresh happens on 401 responses via interceptors
```

## UI Flows

### Authentication Flow

1. User enters credentials
2. Device fingerprint is generated and sent with login request
3. HTTP-only cookies store authentication tokens
4. Session security is evaluated
5. Regular token refresh maintains session
6. Security score displayed to user

### Firm Switching Flow

1. Consultant selects firm from dropdown
2. System checks for unsaved changes
3. If changes exist, confirmation dialog appears
4. If confirmed or no changes, firm switch request is sent
5. Loading states indicate switch in progress
6. When complete, UI updates to show new firm context

### Cross-Firm Data Access Flow

1. Component requests data from different firm
2. Loading indicator shows cross-firm data access
3. Special header indicates temporary firm context to API
4. Data is fetched without changing user's current context
5. Visual indicator shows data is from a different firm

## Security Best Practices

- HTTP-only cookies for token storage
- CSRF token protection for all non-GET requests
- Device fingerprinting for session validation
- Regular security checks with scoring system
- Graceful handling of security compromises

## Future Enhancements

- Integration with 2FA flow
- Enhanced anomaly detection
- More granular permissions display
- Improved cross-firm data visualization 