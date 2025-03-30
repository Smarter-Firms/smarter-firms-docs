# Firm Context Management

This document describes the components and hooks that manage firm context for consultants working with multiple client firms.

## Overview

The firm context management system provides a framework for consultants to:

- Switch between client firms
- View data from multiple firms
- Maintain data integrity during context switches
- Provide clear visual indicators of current firm context

## Core Components

### FirmContextProvider

```tsx
// Root application wrapper
<FirmContextProvider>
  <ConsultantLayout>
    <YourAppContent />
  </ConsultantLayout>
</FirmContextProvider>
```

The `FirmContextProvider` is the central state manager for firm-related data:

- Loads and caches firm data
- Tracks current firm selection
- Manages loading states
- Handles errors related to firm operations
- Provides a context API for child components

### useFirmContext Hook

```tsx
const { 
  firms,
  currentFirm,
  loadingState,
  switchFirm,
  registerUnsavedChanges,
  clearUnsavedChanges,
  hasUnsavedChanges,
  fetchCrossFirmData
} = useFirmContext();
```

The hook exposes the following:

| Property/Method | Type | Description |
|-----------------|------|-------------|
| `firms` | `Firm[]` | Array of available firms |
| `currentFirm` | `Firm` | Currently selected firm |
| `loadingState` | `LoadingState` | Current loading state object |
| `switchFirm` | `(firmId: string) => Promise<boolean>` | Method to change firm context |
| `registerUnsavedChanges` | `(id: string) => void` | Register unsaved changes by ID |
| `clearUnsavedChanges` | `(id: string) => void` | Clear unsaved changes by ID |
| `hasUnsavedChanges` | `() => boolean` | Check if any unsaved changes exist |
| `fetchCrossFirmData` | `<T>(firmId: string, endpoint: string, options?: AxiosRequestConfig) => Promise<T>` | Fetch data from another firm without switching context |

### Loading States

The context provides detailed loading states through the `loadingState` object:

```tsx
interface LoadingState {
  loading: boolean;
  type: LoadingStateType;
  firmId?: string;
  error?: AppError;
}

enum LoadingStateType {
  INITIAL = 'initial',
  SWITCH = 'switch',
  CROSS_FIRM = 'cross_firm',
  ERROR = 'error',
  NONE = 'none'
}
```

## UI Components

### FirmSelector

![Firm Selector Component](./assets/firm-selector.png)

```tsx
<FirmSelector 
  firms={firms}
  currentFirmId={currentFirm?.id}
  loading={loadingState.loading && loadingState.type === LoadingStateType.SWITCH}
  onSelect={handleFirmSelect}
  hasUnsavedChanges={hasUnsavedChanges()}
/>
```

Features:
- Dropdown for firm selection
- Sorts firms by last accessed time
- Color-coded badges for access levels
- Shows loading state during firm switch
- Prompts confirmation for unsaved changes

### FirmContextBanner

![Firm Context Banner](./assets/firm-context-banner.png)

```tsx
<FirmContextBanner 
  currentFirm={currentFirm}
  loading={loadingState.loading}
/>
```

Features:
- Persistent banner showing current firm context
- Color-coded access level indicator
- Shows loading state during operations
- Adapts to mobile/desktop layouts

### CrossFirmData

```tsx
<CrossFirmData<ClientData>
  firmId={otherFirmId}
  endpoint="/api/v1/clients/summary"
  renderData={(data) => (
    <ClientSummary data={data} />
  )}
  renderLoading={() => <Skeleton count={3} />}
  renderError={(error) => <ErrorMessage error={error} />}
/>
```

Features:
- Fetches data from different firm without switching context
- Handles loading and error states
- Provides render props for customization
- Maintains performance through memoization

## Handling Unsaved Changes

The system provides protection against data loss when switching firms:

```tsx
// In a form component
const { registerUnsavedChanges, clearUnsavedChanges } = useFirmContext();
const formId = "client-form-123";

useEffect(() => {
  if (formState.isDirty) {
    registerUnsavedChanges(formId);
  } else {
    clearUnsavedChanges(formId);
  }
  
  return () => clearUnsavedChanges(formId);
}, [formState.isDirty]);
```

Protection includes:
- Registration system for components with unsaved changes
- Confirmation dialog when switching with unsaved changes
- Cleanup on component unmount
- API for programmatic checking

## Best Practices

### Firm Switching

```tsx
// Good: Properly handle errors and loading states
const handleSwitchFirm = async (firmId) => {
  try {
    const switched = await switchFirm(firmId);
    if (switched) {
      fetchClientData(); // Refresh data for new firm
    }
  } catch (error) {
    const processedError = processApiError(error);
    showNotification({
      type: 'error',
      message: processedError.message,
      suggestions: processedError.suggestions
    });
  }
};
```

### Cross-Firm Data Access

```tsx
// Good: Type-safe cross-firm data fetch with error handling
const fetchCrossClientData = async () => {
  try {
    setLoading(true);
    const data = await fetchCrossFirmData<ClientData>(
      otherFirmId,
      '/api/v1/clients',
      { params: { limit: 5 } }
    );
    setClients(data);
  } catch (error) {
    setError(processApiError(error));
  } finally {
    setLoading(false);
  }
};
```

### Form Integration

```tsx
// Good: Integrate with form libraries
useEffect(() => {
  // With React Hook Form
  const subscription = watch((value, { name, type }) => {
    if (type === 'change') {
      registerUnsavedChanges('my-form');
    }
  });
  
  return () => {
    subscription.unsubscribe();
    clearUnsavedChanges('my-form');
  };
}, [watch, registerUnsavedChanges, clearUnsavedChanges]);
```

## API Integration

The firm context system integrates with the following API endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/firms` | GET | Get list of accessible firms |
| `/api/v1/firms/:firmId/switch` | POST | Switch current firm context |
| Various | GET | Cross-firm data access with `X-Temporary-Firm` header |

## Error Handling

Errors are processed using the `processApiError` utility:

```tsx
try {
  await switchFirm(firmId);
} catch (error) {
  const appError = processApiError(error);
  
  // Specialized handling based on error category
  switch (appError.category) {
    case ErrorCategory.PERMISSION:
      showPermissionError(appError.message);
      break;
    case ErrorCategory.NETWORK:
      retryWithBackoff(switchFirm, firmId);
      break;
    default:
      showGeneralError(appError.message);
  }
}
``` 