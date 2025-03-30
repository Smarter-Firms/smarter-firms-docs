# Onboarding Flow Documentation

The Smarter Firms onboarding process guides new users through a 5-step wizard that collects necessary information and configures their account. This document outlines each step in detail, including the UI components used, data collected, validations, and transitions.

## Onboarding Context

The entire onboarding flow uses a shared context (`OnboardingContext`) to manage state across steps. This context provides:

- Current step tracking
- Data storage for each step
- Navigation methods (next, previous, go to specific step)
- Completion state

## Step 1: Account Creation

The first step creates the user's account and collects basic user information.

### UI Components Used
- `AuthForm` from UI Components library
- `Toast` for success notification

### Data Collected
- First Name
- Last Name
- Email Address
- Password
- Role in the firm

### Validation
- Email must be valid format
- Password must meet complexity requirements
- All fields are required

### API Integration
- Calls `registerUser()` from `authService`
- Creates user account in Auth Service

### User Flow
1. User fills out basic information
2. System validates form data
3. On submit, API creates user account
4. On success, user receives confirmation toast
5. User is automatically advanced to Step 2

### Error Handling
- Form validation errors are displayed inline
- API errors are displayed in an error alert
- Network errors trigger appropriate error messages

## Step 2: Firm Details

The second step collects information about the law firm.

### UI Components Used
- `Card` for grouping related fields
- `Input`, `Select`, `MultiSelect` form components
- `Button` for navigation
- `Toast` for success notification

### Data Collected
- Firm Name
- Firm Size (selection)
- Practice Areas (multi-select)
- Address Information (street, city, state, zip, country)

### Validation
- Firm name is required
- At least one practice area must be selected
- All address fields are required

### API Integration
- Calls `createFirm()` from `firmService`
- Fetches practice areas and firm sizes from API for dropdowns

### User Flow
1. User fills out firm information
2. System validates form data
3. On submit, API creates firm record
4. On success, user receives confirmation toast
5. User is automatically advanced to Step 3

### Error Handling
- Form validation errors are displayed inline
- API errors are handled with appropriate messages

## Step 3: Clio Connection

The third step allows the user to connect their Clio account via OAuth.

### UI Components Used
- `ClioConnectCard` for OAuth connection interface
- `Button` for navigation
- `Toast` for success notification

### Data Collected
- Clio OAuth connection status
- Access token and refresh token (stored securely)

### API Integration
- Integrates with Clio OAuth flow
- Uses `exchangeClioAuthCode()` from `clioService`
- Tests connection with `testClioConnection()`

### User Flow
1. User is presented with Clio connection option
2. User clicks "Connect to Clio" button
3. User is redirected to Clio authorization page
4. After authorization, Clio redirects back with auth code
5. System exchanges code for tokens
6. Connection status is displayed to user
7. User can proceed to next step or skip

### Special Handling
- Users can skip this step and connect later
- Connection status is persisted in the onboarding context
- OAuth callback is handled by a dedicated page

## Step 4: Subscription Selection

The fourth step allows users to select a subscription plan.

### UI Components Used
- `SubscriptionPlanSelector` for plan selection
- `Modal` for confirmation
- `Button` for navigation
- `Toast` for success notification

### Data Collected
- Subscription Plan ID and name
- Billing cycle (monthly or annually)
- Price information

### API Integration
- Fetches available plans with `getSubscriptionPlans()`
- Creates subscription with `createSubscription()`

### User Flow
1. User sees available subscription plans
2. User selects a plan and billing cycle
3. User confirms selection in a modal
4. System creates subscription record
5. User receives confirmation toast
6. User advances to final step

### Special Handling
- Users can skip this step and subscribe later
- Popular plans are highlighted
- Pricing comparison between monthly and annual billing

## Step 5: Confirmation

The final step shows a summary of all collected information and completes the onboarding process.

### UI Components Used
- `Card` for information sections
- `Icon` for visual indicators
- `Divider` for visual separation
- `Button` for completion

### Data Displayed
- User account details
- Firm information
- Clio connection status
- Subscription details

### API Integration
- Marks onboarding as complete
- Redirects to dashboard

### User Flow
1. User reviews all collected information
2. User clicks "Go to Dashboard" button
3. System marks onboarding as complete
4. User is redirected to the main application dashboard

## Navigation

The onboarding flow uses a `StepWizard` component for navigation, which provides:

- Visual indicator of current step
- Step labels
- Progress tracking
- Ability to go back to previous steps

### Navigation Rules

- Users can always go back to previous steps
- Users can only proceed to the next step after completing the current step
- Some steps can be skipped (Clio connection, Subscription)
- Navigation between steps preserves data
- Direct URL access is protected - must complete previous steps first

## Mobile Responsiveness

The entire onboarding flow is fully responsive:

- Layout adjusts based on screen size
- Form fields stack on mobile
- Buttons maintain appropriate size for touch targets
- Step indicators adapt to smaller screens 