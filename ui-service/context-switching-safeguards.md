# Context Switching Safeguards

## Overview

Context switching between different firms in a multi-tenant application poses significant usability and data integrity challenges. This document describes the implementation of comprehensive safeguards for firm context switching in the UI Service.

## Implementation Details

The UI Service implements robust context switching safeguards with these key features:

### 1. Confirmation Dialogs for Unsaved Changes

When users attempt to switch between firms with unsaved changes, the system shows confirmation dialogs:

```jsx
// FirmSwitcher component with unsaved changes detection
const FirmSwitcher = () => {
  const { firms, currentFirm, switchFirm } = useFirmContext();
  const { hasUnsavedChanges, pendingChanges } = useUnsavedChangesTracker();
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [targetFirm, setTargetFirm] = useState(null);

  // Handle firm selection
  const handleFirmSelect = (firm) => {
    if (firm.id === currentFirm.id) {
      return; // No change needed
    }

    // Check for unsaved changes
    if (hasUnsavedChanges()) {
      // Store target firm and show confirmation dialog
      setTargetFirm(firm);
      setShowConfirmation(true);
    } else {
      // No unsaved changes, switch immediately
      switchFirm(firm.id);
    }
  };

  // Handle confirmation dialog confirm
  const handleConfirmSwitch = () => {
    // Discard changes
    discardChanges();
    
    // Switch to target firm
    switchFirm(targetFirm.id);
    
    // Close dialog
    setShowConfirmation(false);
    setTargetFirm(null);
  };

  // Handle confirmation dialog cancel
  const handleCancelSwitch = () => {
    setShowConfirmation(false);
    setTargetFirm(null);
  };

  return (
    <>
      <div className="firm-switcher">
        <select
          value={currentFirm.id}
          onChange={(e) => {
            const selectedFirm = firms.find(f => f.id === e.target.value);
            handleFirmSelect(selectedFirm);
          }}
        >
          {firms.map(firm => (
            <option key={firm.id} value={firm.id}>
              {firm.name}
            </option>
          ))}
        </select>
      </div>

      {/* Confirmation Dialog */}
      {showConfirmation && (
        <ConfirmationDialog
          title="Unsaved Changes"
          message={`You have unsaved changes in ${currentFirm.name}. Switching to ${targetFirm.name} will discard these changes.`}
          confirmLabel="Discard Changes & Switch"
          cancelLabel="Stay on Current Firm"
          onConfirm={handleConfirmSwitch}
          onCancel={handleCancelSwitch}
          pendingChanges={pendingChanges}
        />
      )}
    </>
  );
};
```

### 2. Active Operations Tracking

The system tracks active operations to prevent context switching during critical tasks:

```javascript
// Active operations tracking service
class ActiveOperationsTracker {
  constructor() {
    this.activeOperations = new Map();
    this.listeners = new Set();
  }

  // Start tracking an operation
  startOperation(operationId, metadata = {}) {
    this.activeOperations.set(operationId, {
      id: operationId,
      startTime: Date.now(),
      ...metadata
    });

    this.notifyListeners();
    return operationId;
  }

  // End tracking an operation
  endOperation(operationId) {
    if (this.activeOperations.has(operationId)) {
      this.activeOperations.delete(operationId);
      this.notifyListeners();
      return true;
    }
    return false;
  }

  // Check if any operations are active
  hasActiveOperations() {
    return this.activeOperations.size > 0;
  }

  // Get all active operations
  getActiveOperations() {
    return Array.from(this.activeOperations.values());
  }

  // Add a change listener
  addListener(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  // Notify all listeners of changes
  notifyListeners() {
    const operations = this.getActiveOperations();
    this.listeners.forEach(listener => listener(operations));
  }
}

// React hook for using the operations tracker
const useActiveOperations = () => {
  const tracker = useContext(ActiveOperationsContext);
  const [operations, setOperations] = useState(tracker.getActiveOperations());

  useEffect(() => {
    // Update state when operations change
    const unsubscribe = tracker.addListener(ops => {
      setOperations(ops);
    });

    return unsubscribe;
  }, [tracker]);

  // Helper for starting an operation with cleanup on unmount
  const startOperation = useCallback((id, metadata) => {
    tracker.startOperation(id, metadata);
    
    // Return cleanup function
    return () => tracker.endOperation(id);
  }, [tracker]);

  return {
    operations,
    hasActiveOperations: operations.length > 0,
    startOperation,
    endOperation: tracker.endOperation.bind(tracker)
  };
};
```

### 3. Navigation Interception

The system intercepts navigation attempts when there are unsaved changes:

```javascript
// Navigation guard for unsaved changes
const useNavigationGuard = () => {
  const { hasUnsavedChanges } = useUnsavedChangesTracker();
  const { hasActiveOperations } = useActiveOperations();
  const location = useLocation();
  
  // Set up blocking prompt for React Router
  useBlocker(
    ({ currentLocation, nextLocation }) => {
      // Don't block navigation to the same page
      if (currentLocation.pathname === nextLocation.pathname) {
        return false;
      }
      
      // Block if there are unsaved changes or active operations
      return hasUnsavedChanges() || hasActiveOperations;
    },
    ({ blocker, history }) => {
      // Show custom confirmation dialog
      showNavigationConfirmDialog({
        message: hasActiveOperations 
          ? 'You have active operations in progress. Leaving this page will interrupt them.'
          : 'You have unsaved changes. Are you sure you want to leave this page?',
        onConfirm: () => {
          // Allow navigation to proceed
          blocker.proceed();
        },
        onCancel: () => {
          // Stay on current page
          blocker.reset();
        }
      });
    }
  );

  // Handle browser beforeunload event
  useEffect(() => {
    const handleBeforeUnload = (e) => {
      if (hasUnsavedChanges() || hasActiveOperations) {
        // Standard way to show browser confirmation
        e.preventDefault();
        e.returnValue = ''; // Chrome requires returnValue to be set
        return ''; // Legacy browsers require a return value
      }
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [hasUnsavedChanges, hasActiveOperations]);
};
```

### 4. Visual Indicators for Pending Changes

The system provides clear visual indicators when there are pending changes:

```jsx
// PendingChangesIndicator component
const PendingChangesIndicator = () => {
  const { hasUnsavedChanges, pendingChanges } = useUnsavedChangesTracker();
  
  if (!hasUnsavedChanges()) {
    return null;
  }
  
  // Count changes by type
  const changeCount = Object.entries(pendingChanges).reduce(
    (count, [type, changes]) => count + Object.keys(changes).length,
    0
  );
  
  return (
    <div className="pending-changes-indicator">
      <AlertIcon />
      <span>{changeCount} unsaved {changeCount === 1 ? 'change' : 'changes'}</span>
      <Tooltip content={
        <div className="changes-breakdown">
          <h4>Unsaved Changes</h4>
          <ul>
            {Object.entries(pendingChanges).map(([type, changes]) => (
              <li key={type}>
                {type}: {Object.keys(changes).length} {Object.keys(changes).length === 1 ? 'item' : 'items'}
              </li>
            ))}
          </ul>
        </div>
      } />
    </div>
  );
};
```

### 5. Active Operations Indicators

The system shows clear indicators when operations are in progress:

```jsx
// ActiveOperationsIndicator component
const ActiveOperationsIndicator = () => {
  const { operations, hasActiveOperations } = useActiveOperations();
  
  if (!hasActiveOperations) {
    return null;
  }
  
  // Group operations by type
  const operationsByType = operations.reduce((grouped, op) => {
    const type = op.type || 'unknown';
    if (!grouped[type]) {
      grouped[type] = [];
    }
    grouped[type].push(op);
    return grouped;
  }, {});
  
  return (
    <div className="active-operations-indicator">
      <SpinnerIcon className="spinning" />
      <span>{operations.length} active {operations.length === 1 ? 'operation' : 'operations'}</span>
      <Tooltip content={
        <div className="operations-breakdown">
          <h4>Active Operations</h4>
          <ul>
            {Object.entries(operationsByType).map(([type, ops]) => (
              <li key={type}>
                {type}: {ops.length} {ops.length === 1 ? 'operation' : 'operations'}
              </li>
            ))}
          </ul>
        </div>
      } />
    </div>
  );
};
```

## Integration with Firm Context Switching

### Firm Context Provider with Safeguards

```jsx
// FirmContextProvider with integrated safeguards
const FirmContextProvider = ({ children }) => {
  const [currentFirm, setCurrentFirm] = useState(null);
  const [firms, setFirms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [switching, setSwitching] = useState(false);
  const { hasUnsavedChanges } = useUnsavedChangesTracker();
  const { hasActiveOperations } = useActiveOperations();
  const navigate = useNavigate();
  
  // Load user's firms
  useEffect(() => {
    const loadFirms = async () => {
      try {
        setLoading(true);
        const userFirms = await firmService.getUserFirms();
        setFirms(userFirms);
        
        // Set initial firm (from URL param, localStorage, or first firm)
        const initialFirmId = getInitialFirmId(userFirms);
        if (initialFirmId) {
          const firm = userFirms.find(f => f.id === initialFirmId);
          if (firm) {
            setCurrentFirm(firm);
          } else {
            setCurrentFirm(userFirms[0]);
          }
        } else {
          setCurrentFirm(userFirms[0]);
        }
      } catch (error) {
        console.error('Failed to load firms:', error);
      } finally {
        setLoading(false);
      }
    };
    
    loadFirms();
  }, []);
  
  // Switch firm with safeguards
  const switchFirm = async (firmId) => {
    // Don't switch if already on this firm
    if (currentFirm && currentFirm.id === firmId) {
      return;
    }
    
    // Check for unsaved changes or active operations
    if (hasUnsavedChanges() || hasActiveOperations) {
      return new Promise((resolve, reject) => {
        showConfirmationDialog({
          title: 'Switching Firms',
          message: hasActiveOperations
            ? 'You have active operations in progress. Switching firms will interrupt them.'
            : 'You have unsaved changes. Switching firms will discard these changes.',
          confirmLabel: 'Switch Anyway',
          cancelLabel: 'Stay on Current Firm',
          onConfirm: async () => {
            try {
              // Proceed with firm switch
              await executeFirmSwitch(firmId);
              resolve();
            } catch (error) {
              reject(error);
            }
          },
          onCancel: () => {
            reject(new Error('Firm switch cancelled by user'));
          }
        });
      });
    } else {
      // No safeguards needed, proceed with switch
      return executeFirmSwitch(firmId);
    }
  };
  
  // Execute the firm switch
  const executeFirmSwitch = async (firmId) => {
    try {
      setSwitching(true);
      
      // Find the firm
      const firm = firms.find(f => f.id === firmId);
      if (!firm) {
        throw new Error(`Firm with ID ${firmId} not found`);
      }
      
      // Update URL and localStorage
      updateFirmInUrl(firmId);
      localStorage.setItem('lastFirmId', firmId);
      
      // Set the current firm
      setCurrentFirm(firm);
      
      // Navigate to dashboard or current route with new firm
      navigate(getCurrentRouteWithNewFirm(firmId));
      
      return firm;
    } finally {
      setSwitching(false);
    }
  };
  
  // Context value
  const contextValue = {
    currentFirm,
    firms,
    loading,
    switching,
    switchFirm
  };
  
  return (
    <FirmContext.Provider value={contextValue}>
      {children}
    </FirmContext.Provider>
  );
};
```

## Tracking Unsaved Changes

The system implements a comprehensive mechanism for tracking unsaved changes:

```javascript
class UnsavedChangesTracker {
  constructor() {
    this.changes = {};
    this.listeners = new Set();
  }
  
  // Track a new change
  trackChange(type, id, data) {
    if (!this.changes[type]) {
      this.changes[type] = {};
    }
    
    this.changes[type][id] = {
      id,
      data,
      timestamp: Date.now()
    };
    
    this.notifyListeners();
  }
  
  // Remove a tracked change
  removeChange(type, id) {
    if (this.changes[type] && this.changes[type][id]) {
      delete this.changes[type][id];
      
      // Clean up empty types
      if (Object.keys(this.changes[type]).length === 0) {
        delete this.changes[type];
      }
      
      this.notifyListeners();
      return true;
    }
    
    return false;
  }
  
  // Clear all changes
  clearChanges() {
    this.changes = {};
    this.notifyListeners();
  }
  
  // Check if there are any unsaved changes
  hasUnsavedChanges() {
    return Object.keys(this.changes).length > 0;
  }
  
  // Get all pending changes
  getPendingChanges() {
    return { ...this.changes };
  }
  
  // Add a change listener
  addListener(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }
  
  // Notify all listeners of changes
  notifyListeners() {
    const hasChanges = this.hasUnsavedChanges();
    const pendingChanges = this.getPendingChanges();
    
    this.listeners.forEach(listener => {
      listener(hasChanges, pendingChanges);
    });
  }
}

// React hook for using the changes tracker
const useUnsavedChangesTracker = () => {
  const tracker = useContext(UnsavedChangesContext);
  const [hasChanges, setHasChanges] = useState(tracker.hasUnsavedChanges());
  const [pendingChanges, setPendingChanges] = useState(tracker.getPendingChanges());
  
  useEffect(() => {
    // Update state when changes occur
    const unsubscribe = tracker.addListener((hasChanges, pendingChanges) => {
      setHasChanges(hasChanges);
      setPendingChanges(pendingChanges);
    });
    
    return unsubscribe;
  }, [tracker]);
  
  return {
    trackChange: tracker.trackChange.bind(tracker),
    removeChange: tracker.removeChange.bind(tracker),
    clearChanges: tracker.clearChanges.bind(tracker),
    hasUnsavedChanges: () => hasChanges,
    pendingChanges
  };
};
```

## Best Practices for Developers

### 1. Properly Track Changes

Always track form changes using the `useUnsavedChangesTracker` hook:

```jsx
const MyForm = () => {
  const { trackChange, removeChange } = useUnsavedChangesTracker();
  const [formData, setFormData] = useState({
    name: '',
    email: ''
  });
  
  // When form data changes, track it
  useEffect(() => {
    // Only track if form has been modified
    if (formData.name || formData.email) {
      trackChange('userForm', 'myForm', formData);
    }
    
    return () => {
      // Clean up on unmount
      removeChange('userForm', 'myForm');
    };
  }, [formData, trackChange, removeChange]);
  
  // Handle form submission
  const handleSubmit = async (e) => {
    e.preventDefault();
    await submitForm(formData);
    // Remove change tracking after successful submit
    removeChange('userForm', 'myForm');
  };
  
  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
    </form>
  );
};
```

### 2. Track Active Operations

Always track long-running operations:

```jsx
const DataGrid = () => {
  const { startOperation, endOperation } = useActiveOperations();
  const [isImporting, setIsImporting] = useState(false);
  
  // Import data
  const importData = async () => {
    const operationId = startOperation('import', { type: 'data_import' });
    
    try {
      setIsImporting(true);
      await dataService.importData();
    } finally {
      setIsImporting(false);
      endOperation(operationId);
    }
  };
  
  return (
    <div>
      <button 
        onClick={importData} 
        disabled={isImporting}
      >
        {isImporting ? 'Importing...' : 'Import Data'}
      </button>
    </div>
  );
};
```

### 3. Use React Query Integration

For React Query users, integrate with the tracking system:

```jsx
// React Query integration
const useSafeMutation = (mutationFn, options = {}) => {
  const { startOperation, endOperation } = useActiveOperations();
  
  return useMutation({
    ...options,
    mutationFn,
    onMutate: async (variables) => {
      // Start operation tracking
      const operationId = startOperation('mutation', {
        type: options.mutationKey || 'unknown_mutation',
        variables
      });
      
      // Store operation ID for later cleanup
      variables.__operationId = operationId;
      
      // Call original onMutate if provided
      if (options.onMutate) {
        return options.onMutate(variables);
      }
    },
    onSettled: (data, error, variables, context) => {
      // End operation tracking
      if (variables.__operationId) {
        endOperation(variables.__operationId);
      }
      
      // Call original onSettled if provided
      if (options.onSettled) {
        options.onSettled(data, error, variables, context);
      }
    }
  });
};
```

## References

- [React Router - Blocking Navigation](https://reactrouter.com/docs/en/v6/api#useblocker)
- [Form Management Best Practices](https://www.smashingmagazine.com/2022/03/form-design-best-practices/)
- [Smarter Firms UX Guidelines](../ui-service/ux-guidelines.md) 