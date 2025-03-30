# Consultant Experience UI

This document details the UI components and flows specifically designed for consultants working with multiple client firms.

## Overview

The consultant experience enables users to:

- View and switch between multiple client firms
- See clear visual indicators of the current firm context
- Access cross-firm data without changing context
- Receive warnings for unsaved changes during context switching
- View detailed loading states during operations

## Components

### FirmSelector

A dropdown component that allows consultants to switch between their associated firms:

![FirmSelector component](./assets/firm-selector.png)

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

#### Features

- Sorted list of firms by last accessed time
- Color-coded access level badges (Full, Limited, Read-Only)
- Unsaved changes indicator
- Confirmation dialog when switching with unsaved changes
- Operation-in-progress indicators
- Prevents switching during active operations

### FirmContextBanner

A persistent banner that ensures consultants always know which firm context they're working in:

![FirmContextBanner component](./assets/firm-context-banner.png)

```tsx
<FirmContextBanner firm={currentFirm} className="sticky top-0 z-20" />
```

#### Features

- Color-coded by access level
- Sticky positioning ensures visibility
- Clear display of firm name and access level
- Special indicators for read-only access

### CrossFirmData

Component for fetching and displaying data from different firms without switching context:

```tsx
<CrossFirmData
  firmId="firm-123"
  endpoint="/api/reports/summary"
  renderData={(data) => (
    <ReportSummary data={data} />
  )}
  loadingLabel="Loading client report..."
/>
```

#### Features

- Clear loading states with progress indication
- Visual badge indicating data is from a different firm
- Error handling with actionable messages
- Custom render props for maximum flexibility

### ConsultantLayout

Layout wrapper that provides the complete consultant experience:

```tsx
<ConsultantLayout
  hasUnsavedChanges={formIsDirty}
  preventNavigation={true}
>
  <YourPageContent />
</ConsultantLayout>
```

#### Features

- Firm context banner
- Firm selector dropdown
- Security status indicator
- Active operations counter
- Warning banners for no firms or security issues
- Navigation prevention when changes are unsaved

## Using the useFirmContext Hook

The core of the consultant experience is powered by the `useFirmContext` hook:

```tsx
const {
  firms,                 // Array of available firms
  currentFirm,           // Currently selected firm
  loadingState,          // Detailed loading state object
  error,                 // Error message if any
  switchFirm,            // Function to switch to a different firm
  refreshFirms,          // Function to refresh the firm list
  fetchCrossFirmData,    // Function to get data from another firm
  hasPendingChanges,     // Flag for unsaved changes
  setHasPendingChanges,  // Function to update unsaved changes state
  activeFirmOperations   // Array of ongoing operations
} = useFirmContext();
```

### Loading States

The `loadingState` object provides detailed information about current loading status:

```tsx
interface LoadingState {
  type: LoadingStateType; // IDLE, INITIAL, SWITCHING, REFRESHING, CROSS_FIRM_DATA, ERROR
  message?: string;       // User-friendly loading message
  targetFirmId?: string;  // ID of firm being loaded (for switching/cross-firm)
  progress?: number;      // Optional progress value (0-100)
  startTime?: Date;       // When the operation started
}
```

### Cross-Firm Data Access

To fetch data from another firm without switching context:

```tsx
// Example: Get report data from a different firm
const reportData = await fetchCrossFirmData(
  otherFirmId,
  '/api/reports/summary',
  { params: { period: 'monthly' } }
);
```

This will:
1. Show a loading indicator
2. Add the special `X-Temporary-Firm` header
3. Track the operation in `activeFirmOperations`
4. Return the data without changing the current firm context

## Handling Unsaved Changes

To prevent data loss, set the `hasPendingChanges` flag when users have unsaved work:

```tsx
// When a form is modified
const handleFormChange = () => {
  setHasPendingChanges(true);
};

// When changes are saved
const handleFormSubmit = async () => {
  await saveData();
  setHasPendingChanges(false);
};
```

With this flag set:
1. The UI will show an "Unsaved" indicator
2. Attempts to switch firms will trigger a confirmation dialog
3. Page navigation can be blocked (with the `preventNavigation` prop)

## Best Practices

1. **Always use the ConsultantLayout** for consultant-facing pages
2. **Be explicit about unsaved changes** to prevent data loss
3. **Utilize CrossFirmData** when displaying data from multiple firms
4. **Handle loading states** for improved user experience
5. **Respect access levels** when designing UI interactions 