# State Management Documentation

This document details the state management approach used in the Smarter Firms Onboarding Application. The application uses a combination of React Context for global state and local component state for UI-specific concerns.

## State Management Architecture

The Onboarding Application follows a hierarchical state management approach:

1. **Global Onboarding State**: Managed by Context API
2. **Step-Specific State**: Managed by local component state
3. **Form State**: Managed by React Hook Form
4. **UI State**: Managed by local component state

This approach keeps state management simple and predictable while avoiding unnecessary complexity.

## Onboarding Context

The core of the application's state management is the `OnboardingContext`, which stores all the data collected during the onboarding process.

### Implementation

**File Location:** `src/app/_lib/onboarding/OnboardingContext.tsx`

```typescript
// Context definition
interface OnboardingContextType {
  state: OnboardingState;
  updateUserDetails: (details: Partial<UserDetails>) => void;
  updateFirmDetails: (details: Partial<FirmDetails>) => void;
  updateClioConnection: (connection: Partial<ClioConnection>) => void;
  updateSubscriptionDetails: (subscription: Partial<SubscriptionDetails>) => void;
  nextStep: () => void;
  prevStep: () => void;
  goToStep: (step: number) => void;
  completeOnboarding: () => void;
}

// Context provider
export const OnboardingProvider = ({ children }: { children: ReactNode }) => {
  const [state, setState] = useState<OnboardingState>(defaultState);

  // State update methods
  const updateUserDetails = (details: Partial<UserDetails>) => {
    setState((prev) => ({
      ...prev,
      userDetails: {
        ...prev.userDetails,
        ...details,
      },
    }));
  };

  // Other update methods...

  // Navigation methods
  const nextStep = () => {
    setState((prev) => ({
      ...prev,
      currentStep: Math.min(prev.currentStep + 1, 5),
    }));
  };

  const prevStep = () => {
    setState((prev) => ({
      ...prev,
      currentStep: Math.max(prev.currentStep - 1, 1),
    }));
  };

  // ... other methods

  return (
    <OnboardingContext.Provider
      value={{
        state,
        updateUserDetails,
        updateFirmDetails,
        updateClioConnection,
        updateSubscriptionDetails,
        nextStep,
        prevStep,
        goToStep,
        completeOnboarding,
      }}
    >
      {children}
    </OnboardingContext.Provider>
  );
};

// Custom hook for consuming the context
export const useOnboarding = (): OnboardingContextType => {
  const context = useContext(OnboardingContext);
  if (context === undefined) {
    throw new Error('useOnboarding must be used within an OnboardingProvider');
  }
  return context;
};
```

### Data Structure

The context manages the following state structure:

```typescript
interface OnboardingState {
  currentStep: number;
  userDetails: UserDetails;
  firmDetails: FirmDetails;
  clioConnection: ClioConnection;
  subscriptionDetails: SubscriptionDetails;
  isComplete: boolean;
}
```

Each section of data has its own interface:

```typescript
interface UserDetails {
  firstName: string;
  lastName: string;
  email: string;
  role: string;
}

interface FirmDetails {
  firmName: string;
  firmSize: string;
  practiceAreas: string[];
  address: {
    street: string;
    city: string;
    state: string;
    zipCode: string;
    country: string;
  };
}

interface ClioConnection {
  connected: boolean;
  accessToken?: string;
  refreshToken?: string;
  expiresAt?: number;
}

interface SubscriptionDetails {
  planId: string;
  planName: string;
  billingCycle: 'monthly' | 'annually';
  price: number;
}
```

### Context Provider Setup

The context provider wraps the entire onboarding application to ensure state is available throughout the flow:

```tsx
// In src/app/onboarding/page.tsx
const OnboardingContainer = () => {
  return (
    <OnboardingProvider>
      <OnboardingPage />
    </OnboardingProvider>
  );
};
```

## Form State Management

Form state is managed using React Hook Form, which provides a performant and flexible solution for handling form state and validation.

### React Hook Form Integration

**Example from FirmDetailsStep:**

```tsx
// Form state setup with React Hook Form
const { control, handleSubmit, formState: { errors } } = useForm<FirmDetailsFormData>({
  resolver: zodResolver(firmDetailsSchema),
  defaultValues: {
    firmName: state.firmDetails.firmName,
    firmSize: state.firmDetails.firmSize,
    practiceAreas: state.firmDetails.practiceAreas,
    street: state.firmDetails.address.street,
    city: state.firmDetails.address.city,
    state: state.firmDetails.address.state,
    zipCode: state.firmDetails.address.zipCode,
    country: state.firmDetails.address.country,
  },
});

// Form submission handler
const onSubmit = async (data: FirmDetailsFormData) => {
  // Process form data and update context
  updateFirmDetails({
    firmName: data.firmName,
    firmSize: data.firmSize,
    practiceAreas: data.practiceAreas,
    address: {
      street: data.street,
      city: data.city,
      state: data.state,
      zipCode: data.zipCode,
      country: data.country,
    },
  });
  
  // Call API and handle response
};
```

### Form Validation with Zod

Form validation is implemented using Zod schemas, which provide type safety and descriptive error messages.

**Example Schema:**

```typescript
const firmDetailsSchema = z.object({
  firmName: z.string().min(2, 'Firm name is required'),
  firmSize: z.string().min(1, 'Please select your firm size'),
  practiceAreas: z.array(z.string()).min(1, 'Please select at least one practice area'),
  street: z.string().min(1, 'Street address is required'),
  city: z.string().min(1, 'City is required'),
  state: z.string().min(1, 'State is required'),
  zipCode: z.string().min(1, 'ZIP code is required'),
  country: z.string().min(1, 'Country is required'),
});

type FirmDetailsFormData = z.infer<typeof firmDetailsSchema>;
```

## UI State Management

Each step component maintains its own local UI state for handling:

1. **Loading States**: During API calls
2. **Error States**: For displaying error messages
3. **UI Interactions**: For modals, toasts, etc.

**Example from SubscriptionStep:**

```tsx
// UI state
const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null);
const [billingCycle, setBillingCycle] = useState<'monthly' | 'annually'>('monthly');
const [isLoading, setIsLoading] = useState(false);
const [showConfirmModal, setShowConfirmModal] = useState(false);
const [showToast, setShowToast] = useState(false);
const [error, setError] = useState<string | null>(null);

// State update handlers
const handlePlanSelect = (plan: SubscriptionPlan) => {
  setSelectedPlan(plan);
};

const handleBillingCycleChange = (cycle: 'monthly' | 'annually') => {
  setBillingCycle(cycle);
};
```

## State Flow Between Components

The application follows a unidirectional data flow pattern:

1. **Parent to Child**: Props flow down the component tree
2. **Context to Component**: Global state is accessed via context hooks
3. **Component to Context**: Components update global state via context methods
4. **Component to API**: Components make API calls and update state based on response

## State Persistence

The onboarding state is not persisted across page reloads by default. However, the application could be enhanced with state persistence using:

1. **LocalStorage**: For basic state persistence
2. **Server-Side Storage**: For more secure state persistence

## Step Navigation State

Step navigation is managed by the `currentStep` property in the onboarding context:

```typescript
// Navigation methods in OnboardingContext
const nextStep = () => {
  setState((prev) => ({
    ...prev,
    currentStep: Math.min(prev.currentStep + 1, 5),
  }));
};

const prevStep = () => {
  setState((prev) => ({
    ...prev,
    currentStep: Math.max(prev.currentStep - 1, 1),
  }));
};

const goToStep = (step: number) => {
  if (step >= 1 && step <= 5) {
    setState((prev) => ({
      ...prev,
      currentStep: step,
    }));
  }
};
```

The `StepWizard` component uses this state to determine which step to display.

## State Update Patterns

The application uses these patterns for state updates:

### Functional Updates

State updates use the functional update pattern to ensure they are based on the latest state:

```typescript
setState((prev) => ({
  ...prev,
  someProperty: newValue,
}));
```

### Immutable Updates

All state updates maintain immutability by creating new objects rather than mutating existing ones:

```typescript
updateFirmDetails({
  ...existingDetails,
  newProperty: newValue,
});
```

### Partial Updates

Context update methods accept partial objects to allow updating only specific fields:

```typescript
// Only update first name and last name, leave other fields unchanged
updateUserDetails({
  firstName: 'John',
  lastName: 'Doe',
});
```

## Error State Management

Error states are managed at multiple levels:

1. **Form Validation Errors**: Managed by React Hook Form
2. **API Error Responses**: Captured in local component state
3. **Network Errors**: Handled with try-catch blocks

**Example error handling:**

```typescript
try {
  const response = await someApiCall();
  // Handle success
} catch (err: any) {
  setError(err.response?.data?.message || 'A generic error occurred');
} finally {
  setIsLoading(false);
}
```

## Best Practices Implemented

The state management approach follows these best practices:

1. **Separation of Concerns**: Global state vs. local UI state
2. **Type Safety**: All state interfaces are fully typed
3. **Immutability**: State is never directly mutated
4. **Predictable Updates**: State updates follow consistent patterns
5. **Error Handling**: Comprehensive error state management
6. **Validation**: Form validation with descriptive error messages
7. **Context Access**: Custom hooks for accessing context
8. **State Initialization**: Default values for all state properties 