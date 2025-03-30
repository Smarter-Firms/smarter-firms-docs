# Component Integration Documentation

This document details how the Smarter Firms Onboarding Application integrates with and composes components from the UI Service component library. The application follows a strict policy of using only existing UI components rather than creating custom ones.

## Integration Approach

All UI elements in the Onboarding Application come from the `@smarterfirms/ui-components` package. These components are imported and composed to create the onboarding experience.

### Integration Method

```typescript
import { ComponentName } from '@smarterfirms/ui-components';
```

## Key Components and Usage Patterns

### `StepWizard`

The `StepWizard` component serves as the core navigation mechanism for the onboarding flow.

**Import and Usage:**
```tsx
import { StepWizard } from '@smarterfirms/ui-components';

// In component:
<StepWizard 
  steps={steps} 
  currentStep={state.currentStep}
  onStepChange={handleStepChange}
/>
```

**Integration Details:**
- The `steps` array defines each step with label and component
- `currentStep` is controlled by the Onboarding Context
- `onStepChange` handler updates the context when steps change

### `AuthForm`

The `AuthForm` component handles user registration with built-in validation.

**Import and Usage:**
```tsx
import { AuthForm } from '@smarterfirms/ui-components';

// In component:
<AuthForm
  type="register"
  onSubmit={handleSubmit}
  isLoading={isLoading}
  submitButtonText="Create Account & Continue"
  includeFields={['firstName', 'lastName', 'email', 'password', 'confirmPassword', 'role']}
/>
```

**Integration Details:**
- The `type` prop configures the form for registration
- `onSubmit` handler processes form data and updates context
- `isLoading` state shows loading indicator during submission
- `includeFields` controls which fields are displayed

### Form Components

Various form components are used throughout the onboarding flow:

**Import and Usage:**
```tsx
import { Input, Select, MultiSelect } from '@smarterfirms/ui-components';

// With React Hook Form:
<Controller
  name="fieldName"
  control={control}
  render={({ field }) => (
    <Input
      label="Field Label"
      placeholder="Enter value"
      error={errors.fieldName?.message}
      {...field}
    />
  )}
/>
```

**Integration Details:**
- Form components are integrated with React Hook Form through Controllers
- Validation errors from Zod schemas are passed to the `error` prop
- Components receive field props from React Hook Form

### `ClioConnectCard`

The `ClioConnectCard` component handles the Clio integration UI.

**Import and Usage:**
```tsx
import { ClioConnectCard } from '@smarterfirms/ui-components';

// In component:
<ClioConnectCard
  isConnected={isConnected}
  isLoading={isLoading}
  onConnect={handleConnect}
  error={error}
/>
```

**Integration Details:**
- The `isConnected` state shows connection status
- `onConnect` handler initiates OAuth flow
- `error` displays connection error messages
- `isLoading` shows loading state during connection process

### `SubscriptionPlanSelector`

The `SubscriptionPlanSelector` component displays subscription plans with selection.

**Import and Usage:**
```tsx
import { SubscriptionPlanSelector } from '@smarterfirms/ui-components';

// In component:
<SubscriptionPlanSelector
  plans={plans}
  selectedPlan={selectedPlan}
  billingCycle={billingCycle}
  onPlanSelect={handlePlanSelect}
  onBillingCycleChange={handleBillingCycleChange}
/>
```

**Integration Details:**
- `plans` array comes from the subscription service API
- Selection state is managed in the component and synced to context
- Billing cycle toggle is included in the component
- UI automatically highlights popular plans

### `Card`

The `Card` component is used to group related content.

**Import and Usage:**
```tsx
import { Card } from '@smarterfirms/ui-components';

// In component:
<Card className="p-6">
  <h3 className="text-lg font-medium mb-4">Section Title</h3>
  {/* Card content */}
</Card>
```

**Integration Details:**
- Used consistently for all content grouping
- Accepts standard className prop for styling
- Often contains form sections or summary information

### `Button`

The `Button` component is used for all action elements.

**Import and Usage:**
```tsx
import { Button } from '@smarterfirms/ui-components';

// In component:
<Button
  type="submit"
  isLoading={isLoading}
  variant="primary"
  onClick={handleAction}
>
  Button Text
</Button>
```

**Integration Details:**
- Variants include: primary, secondary, outline
- Loading state shows spinner during async operations
- Consistent styling across all action elements

### `Toast`

The `Toast` component provides non-intrusive notifications.

**Import and Usage:**
```tsx
import { Toast } from '@smarterfirms/ui-components';

// In component:
{showToast && (
  <Toast
    type="success"
    title="Success Title"
    message="Success message details"
    onClose={() => setShowToast(false)}
    autoClose={true}
    autoCloseDelay={3000}
  />
)}
```

**Integration Details:**
- Used for success and error notifications
- Component state is managed with local state hooks
- Auto-closes after specified delay
- Used consistently across all steps

### `Modal`

The `Modal` component provides dialogs for confirmations.

**Import and Usage:**
```tsx
import { Modal } from '@smarterfirms/ui-components';

// In component:
<Modal
  isOpen={showModal}
  onClose={() => setShowModal(false)}
  title="Confirmation Title"
>
  {/* Modal content */}
</Modal>
```

**Integration Details:**
- Used for subscription confirmation
- Manages its own open/close state
- Implements accessibility best practices

### `LoadingIndicator`

The `LoadingIndicator` component shows loading states.

**Import and Usage:**
```tsx
import { LoadingIndicator } from '@smarterfirms/ui-components';

// In component:
<LoadingIndicator size="large" />
```

**Integration Details:**
- Used on loading pages and redirects
- Sized appropriately for context

## Composition Patterns

The application employs several composition patterns:

### Step Component Pattern

Each step in the onboarding flow follows a consistent pattern:

```tsx
const StepComponent = () => {
  // Get context and local state
  const { state, updateState, nextStep, prevStep } = useOnboarding();
  const [localState, setLocalState] = useState(...);

  // API interaction handlers
  const handleSubmit = async (data) => {
    // Process data, call API, update context
    // On success, advance to next step
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-semibold">Step Title</h2>
      <p className="text-gray-600">Step description</p>
      
      {/* Step content using UI components */}
      
      <div className="flex justify-between mt-6">
        <Button onClick={prevStep}>Back</Button>
        <Button onClick={handleContinue}>Continue</Button>
      </div>
    </div>
  );
};
```

### Form Component Pattern

Form fields are consistently wrapped with React Hook Form Controllers:

```tsx
<Controller
  name="fieldName"
  control={control}
  render={({ field }) => (
    <FormComponent
      label="Field Label"
      error={errors.fieldName?.message}
      {...field}
    />
  )}
/>
```

### Card Content Pattern

Card components follow a consistent internal structure:

```tsx
<Card className="p-6">
  <div className="flex items-center mb-4">
    <Icon name="icon-name" className="w-6 h-6 mr-2 text-primary" />
    <h3 className="text-lg font-medium">Section Title</h3>
  </div>
  
  {/* Card content */}
</Card>
```

## Styling Integration

The application uses TailwindCSS for layout and styling, which integrates with the UI components:

- UI components accept className props for custom styling
- Application uses consistent spacing with Tailwind classes (e.g., `space-y-6`, `mt-4`)
- Responsive design uses Tailwind's responsive prefixes (e.g., `md:grid-cols-2`)
- Color scheme comes from the UI Service theme

## Best Practices Implemented

The component integration follows these best practices:

1. **Consistent Patterns**: Each component type is used consistently throughout the app
2. **Separation of Concerns**: UI components handle presentation while containers manage state
3. **Prop Forwarding**: Props are properly forwarded to UI components
4. **Accessibility**: UI components maintain accessibility features
5. **Responsive Design**: Components adapt to different screen sizes
6. **Error Handling**: Validation errors and API errors are consistently displayed
7. **Loading States**: Loading indicators are used during async operations 