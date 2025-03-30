# API Integration Documentation

This document details how the Smarter Firms Onboarding Application integrates with various backend services through their APIs. The application communicates with multiple services to create and configure user accounts.

## Service Integration Architecture

The Onboarding Application integrates with four primary backend services:

1. **Auth Service**: User registration and authentication
2. **Firm Service**: Firm creation and management
3. **Clio Integration Service**: OAuth connection to Clio
4. **Subscription Service**: Plan selection and billing setup

Each service integration is encapsulated in a dedicated service module that provides a clean API for the application components to use.

## Authentication Service

The Auth Service handles user registration, authentication, and account management.

### Implementation Details

**Service File:** `src/app/_lib/services/authService.ts`

```typescript
// Key functions
export const registerUser = async (userData: RegisterUserParams) => {
  try {
    const response = await axios.post(`${API_URL}/auth/register`, userData);
    return response.data;
  } catch (error) {
    console.error('Registration error:', error);
    throw error;
  }
};

export const loginUser = async (credentials: LoginParams) => {
  try {
    const response = await axios.post(`${API_URL}/auth/login`, credentials);
    return response.data;
  } catch (error) {
    console.error('Login error:', error);
    throw error;
  }
};
```

### Integration Points

- **Account Creation Step**: Uses `registerUser()` to create new user accounts
- Captures user registration details (name, email, password, role)
- API returns user details and authentication tokens
- Auth tokens are stored securely for subsequent API calls

### Error Handling

- Registration errors are caught and displayed to the user
- API-specific error messages are extracted and shown when available
- Network errors trigger fallback error messages

## Firm Service

The Firm Service manages law firm profiles and related data.

### Implementation Details

**Service File:** `src/app/_lib/services/firmService.ts`

```typescript
// Key functions
export const createFirm = async (firmData: FirmDetails) => {
  try {
    const response = await axios.post(`${API_URL}/firms`, firmData);
    return response.data;
  } catch (error) {
    console.error('Error creating firm:', error);
    throw error;
  }
};

export const getPracticeAreas = async () => {
  try {
    const response = await axios.get(`${API_URL}/practice-areas`);
    return response.data.practiceAreas;
  } catch (error) {
    console.error('Error fetching practice areas:', error);
    throw error;
  }
};

export const getFirmSizes = async () => {
  try {
    const response = await axios.get(`${API_URL}/firm-sizes`);
    return response.data.firmSizes;
  } catch (error) {
    console.error('Error fetching firm sizes:', error);
    throw error;
  }
};
```

### Integration Points

- **Firm Details Step**: Uses `createFirm()` to create the firm profile
- **Dropdown Data**: Uses `getPracticeAreas()` and `getFirmSizes()` to populate dropdowns
- Captures firm details (name, size, practice areas, address)
- API returns firm ID and confirmation

### Error Handling

- Form validation prevents invalid submissions
- API errors are caught and displayed in the UI
- Loading states indicate when API calls are in progress

## Clio Integration Service

The Clio Integration Service manages OAuth connections with Clio's legal practice management software.

### Implementation Details

**Service File:** `src/app/_lib/services/clioService.ts`

```typescript
// Key functions
export const getClioAuthUrl = () => {
  const clientId = process.env.NEXT_PUBLIC_CLIO_CLIENT_ID;
  const scope = 'manage_matters';
  
  return `https://app.clio.com/oauth/authorize?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(CLIO_REDIRECT_URI)}&scope=${scope}`;
};

export const exchangeClioAuthCode = async (code: string) => {
  try {
    const response = await axios.post(`${API_URL}/integrations/clio/exchange-code`, { code });
    return response.data as ClioAuthResponse;
  } catch (error) {
    console.error('Clio authentication error:', error);
    throw error;
  }
};

export const testClioConnection = async (accessToken: string) => {
  try {
    const response = await axios.get(`${API_URL}/integrations/clio/test-connection`, {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });
    return response.data;
  } catch (error) {
    console.error('Clio connection test error:', error);
    throw error;
  }
};
```

### Integration Points

- **Clio Connection Step**: Uses OAuth flow for connecting to Clio
- **OAuth Flow**:
  1. User clicks "Connect to Clio" button
  2. Application redirects to Clio authorization page
  3. User authorizes the application in Clio
  4. Clio redirects back to the callback URL with authorization code
  5. Application exchanges code for tokens using `exchangeClioAuthCode()`
  6. Application tests connection with `testClioConnection()`
- Connection status is displayed to the user
- User can skip this step and connect later

### Error Handling

- OAuth errors are captured and displayed
- Connection test failures trigger appropriate error messages
- Timeout handling for API calls

## Subscription Service

The Subscription Service manages subscription plans and billing.

### Implementation Details

**Service File:** `src/app/_lib/services/subscriptionService.ts`

```typescript
// Key functions
export const getSubscriptionPlans = async (): Promise<SubscriptionPlan[]> => {
  try {
    const response = await axios.get(`${API_URL}/subscriptions/plans`);
    return response.data.plans;
  } catch (error) {
    console.error('Error fetching subscription plans:', error);
    throw error;
  }
};

export const createSubscription = async (subscriptionData: SubscriptionRequest) => {
  try {
    const response = await axios.post(`${API_URL}/subscriptions`, subscriptionData);
    return response.data;
  } catch (error) {
    console.error('Error creating subscription:', error);
    throw error;
  }
};
```

### Integration Points

- **Subscription Step**: Uses `getSubscriptionPlans()` to display available plans
- User selects plan and billing cycle
- Application creates subscription with `createSubscription()`
- API returns subscription details and confirmation
- User can skip this step and subscribe later

### Error Handling

- Plan fetch errors are handled with retry options
- Subscription creation errors are displayed to the user
- Fallback UI is shown if plans cannot be fetched

## API Client Configuration

The application uses Axios as the HTTP client for all API interactions.

### Base Configuration

```typescript
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api.smarterfirms.com';
```

### Environment Variables

The application uses the following environment variables for API configuration:

- `NEXT_PUBLIC_API_URL`: Base URL for all API endpoints
- `NEXT_PUBLIC_CLIO_CLIENT_ID`: Client ID for Clio OAuth
- `NEXT_PUBLIC_CLIO_REDIRECT_URI`: OAuth callback URL

### Error Handling Strategy

The application implements a consistent error handling strategy across all API calls:

1. **Try-Catch Pattern**: All API calls are wrapped in try-catch blocks
2. **Error Logging**: Errors are logged to the console
3. **Error Propagation**: Errors are rethrown for handling in the UI layer
4. **User Feedback**: Friendly error messages are shown to users
5. **Loading States**: Loading indicators during API calls

## API Gateway Integration

All backend service APIs are accessed through a central API Gateway, which provides:

- Authentication and authorization
- Rate limiting
- Request validation
- API versioning
- Logging and monitoring

The Onboarding Application communicates exclusively with the API Gateway rather than directly with individual services.

## Data Flow

The typical data flow for API integration follows this pattern:

1. **User Input**: User provides information in the UI
2. **Validation**: Client-side validation with Zod schemas
3. **API Call**: Validated data is sent to the appropriate API endpoint
4. **Response Processing**: API response is processed
5. **State Update**: Application state is updated based on the response
6. **UI Update**: UI is updated to reflect the changes
7. **Navigation**: User is advanced to the next step on success

## Security Considerations

The API integration implements these security best practices:

1. **HTTPS**: All API calls use secure HTTPS connections
2. **Environment Variables**: Sensitive configuration is stored in environment variables
3. **Error Sanitization**: Error messages are sanitized before display
4. **Input Validation**: All user input is validated before sending to APIs
5. **Authentication**: API calls include proper authentication tokens when required 