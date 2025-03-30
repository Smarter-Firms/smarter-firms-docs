# Detailed Loading States

## Overview

Providing clear feedback to users during data loading and processing operations is essential for a good user experience, especially in multi-tenant applications. This document describes the implementation of granular loading states in the UI Service, with a focus on cross-firm data access.

## Loading State Implementation

The UI Service implements a comprehensive set of loading states for different scenarios:

### 1. General Loading State System

The core loading state system provides context-aware loading indicators:

```javascript
// Loading state types
const LoadingStateType = {
  INITIAL: 'initial',
  FIRM_SWITCHING: 'firm_switching',
  CROSS_FIRM_DATA: 'cross_firm_data',
  BACKGROUND_UPDATE: 'background_update',
  ACTION_PROCESSING: 'action_processing',
  ERROR_RECOVERY: 'error_recovery'
};

// Loading state context provider
const LoadingStateProvider = ({ children }) => {
  const [loadingStates, setLoadingStates] = useState({});
  
  // Add a loading state
  const startLoading = (id, type = LoadingStateType.INITIAL, metadata = {}) => {
    setLoadingStates(prev => ({
      ...prev,
      [id]: {
        id,
        type,
        startTime: Date.now(),
        metadata
      }
    }));
    
    return id;
  };
  
  // Remove a loading state
  const stopLoading = (id) => {
    setLoadingStates(prev => {
      const newStates = { ...prev };
      delete newStates[id];
      return newStates;
    });
  };
  
  // Check if any loading states match the given type
  const isLoading = (type) => {
    if (!type) {
      return Object.keys(loadingStates).length > 0;
    }
    
    return Object.values(loadingStates).some(state => state.type === type);
  };
  
  // Get all loading states of a specific type
  const getLoadingStates = (type) => {
    if (!type) {
      return Object.values(loadingStates);
    }
    
    return Object.values(loadingStates).filter(state => state.type === type);
  };
  
  // Context value
  const contextValue = {
    loadingStates,
    startLoading,
    stopLoading,
    isLoading,
    getLoadingStates
  };
  
  return (
    <LoadingStateContext.Provider value={contextValue}>
      {children}
    </LoadingStateContext.Provider>
  );
};

// React hook for using loading states
const useLoadingState = () => {
  const context = useContext(LoadingStateContext);
  
  if (!context) {
    throw new Error('useLoadingState must be used within a LoadingStateProvider');
  }
  
  return context;
};
```

### 2. Initial Loading State

The system provides a clear initial loading state for application startup:

```jsx
// Initial application loading
const AppInitializer = ({ children }) => {
  const { startLoading, stopLoading } = useLoadingState();
  const [initialized, setInitialized] = useState(false);
  
  // Initialize application
  useEffect(() => {
    const initialize = async () => {
      const loadingId = startLoading('app_initialization', LoadingStateType.INITIAL, {
        message: 'Loading application...'
      });
      
      try {
        // Load essential data
        await Promise.all([
          authService.initializeAuth(),
          configService.loadConfig(),
          firmService.loadUserFirms()
        ]);
        
        setInitialized(true);
      } catch (error) {
        console.error('Failed to initialize application:', error);
      } finally {
        stopLoading(loadingId);
      }
    };
    
    initialize();
  }, [startLoading, stopLoading]);
  
  // Show loading screen until initialized
  if (!initialized) {
    return <InitialLoadingScreen />;
  }
  
  // Render children once initialized
  return <>{children}</>;
};

// Initial loading screen component
const InitialLoadingScreen = () => {
  const { getLoadingStates } = useLoadingState();
  const initialLoadingStates = getLoadingStates(LoadingStateType.INITIAL);
  
  // Get loading message from first initial loading state
  const loadingMessage = initialLoadingStates[0]?.metadata?.message || 'Loading...';
  
  return (
    <div className="initial-loading-screen">
      <Logo size="large" />
      <LoadingSpinner size="large" />
      <p className="loading-message">{loadingMessage}</p>
    </div>
  );
};
```

### 3. Firm Switching State

The system provides a clear loading state during firm context switching:

```jsx
// Firm switcher with loading state
const FirmSwitcher = () => {
  const { firms, currentFirm, switchFirm } = useFirmContext();
  const { startLoading, stopLoading, isLoading } = useLoadingState();
  
  // Handle firm selection
  const handleFirmSelect = async (firmId) => {
    try {
      // Start loading state
      const loadingId = startLoading('firm_switch', LoadingStateType.FIRM_SWITCHING, {
        fromFirmId: currentFirm?.id,
        toFirmId: firmId,
        firmName: firms.find(f => f.id === firmId)?.name
      });
      
      // Switch firm
      await switchFirm(firmId);
    } finally {
      // Stop loading after firm switch (with slight delay for UX)
      setTimeout(() => {
        stopLoading('firm_switch');
      }, 300);
    }
  };
  
  // Disable switcher during loading
  const isSwitching = isLoading(LoadingStateType.FIRM_SWITCHING);
  
  return (
    <div className="firm-switcher">
      <select
        value={currentFirm?.id || ''}
        onChange={(e) => handleFirmSelect(e.target.value)}
        disabled={isSwitching}
      >
        {firms.map(firm => (
          <option key={firm.id} value={firm.id}>
            {firm.name}
          </option>
        ))}
      </select>
      
      {isSwitching && (
        <div className="firm-switching-indicator">
          <LoadingSpinner size="small" />
          <span>Switching...</span>
        </div>
      )}
    </div>
  );
};
```

### 4. Cross-Firm Data Loading State

The system provides clear indicators when loading data from a different firm:

```jsx
// Cross-firm data component
const CrossFirmData = ({ firmId, resourceType, resourceId, render }) => {
  const { currentFirm } = useFirmContext();
  const { startLoading, stopLoading } = useLoadingState();
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);
  
  // Is this data from the current firm?
  const isCrossFirm = firmId && currentFirm && firmId !== currentFirm.id;
  
  // Load cross-firm data
  useEffect(() => {
    const loadData = async () => {
      // Reset state
      setData(null);
      setError(null);
      setLoading(true);
      
      let loadingId = null;
      
      // Start cross-firm loading state for non-current firm data
      if (isCrossFirm) {
        loadingId = startLoading(`cross_firm_${resourceType}_${resourceId}`, 
          LoadingStateType.CROSS_FIRM_DATA, {
            firmId,
            resourceType,
            resourceId,
            targetFirmName: await getFirmName(firmId)
          }
        );
      }
      
      try {
        // Fetch data from specified firm
        const result = await dataService.getResource(firmId, resourceType, resourceId);
        setData(result);
      } catch (err) {
        console.error(`Error loading ${resourceType} from firm ${firmId}:`, err);
        setError(err);
      } finally {
        setLoading(false);
        
        // Stop loading state
        if (loadingId) {
          stopLoading(loadingId);
        }
      }
    };
    
    loadData();
  }, [firmId, resourceType, resourceId, isCrossFirm, startLoading, stopLoading]);
  
  // Show appropriate loading state
  if (loading) {
    return (
      <div className={`data-loading ${isCrossFirm ? 'cross-firm' : ''}`}>
        <LoadingSpinner size="medium" />
        {isCrossFirm && (
          <span className="cross-firm-loading-message">
            Loading data from {getFirmName(firmId)}...
          </span>
        )}
      </div>
    );
  }
  
  // Show error state
  if (error) {
    return (
      <div className="data-error">
        <ErrorIcon />
        <span>Failed to load {resourceType}</span>
        {isCrossFirm && <span> from {getFirmName(firmId)}</span>}
      </div>
    );
  }
  
  // Render data using provided render function
  return (
    <div className={`data-container ${isCrossFirm ? 'cross-firm-data' : ''}`}>
      {isCrossFirm && (
        <div className="cross-firm-indicator">
          <ExternalDataIcon />
          <span>Data from {getFirmName(firmId)}</span>
        </div>
      )}
      {render(data)}
    </div>
  );
};
```

### 5. Visual Indicators for Different Loading States

The system provides distinct visual indicators for different loading states:

```jsx
// Global loading indicator component
const GlobalLoadingIndicator = () => {
  const { isLoading, getLoadingStates } = useLoadingState();
  
  // If nothing is loading, don't render
  if (!isLoading()) {
    return null;
  }
  
  // Check for different loading types
  const isFirmSwitching = isLoading(LoadingStateType.FIRM_SWITCHING);
  const isCrossFirmLoading = isLoading(LoadingStateType.CROSS_FIRM_DATA);
  const isBackgroundUpdate = isLoading(LoadingStateType.BACKGROUND_UPDATE);
  const isActionProcessing = isLoading(LoadingStateType.ACTION_PROCESSING);
  
  // Get states for detailed information
  const loadingStates = getLoadingStates();
  
  // Determine primary loading type (priority order)
  const getPrimaryLoadingType = () => {
    if (isFirmSwitching) return LoadingStateType.FIRM_SWITCHING;
    if (isActionProcessing) return LoadingStateType.ACTION_PROCESSING;
    if (isCrossFirmLoading) return LoadingStateType.CROSS_FIRM_DATA;
    if (isBackgroundUpdate) return LoadingStateType.BACKGROUND_UPDATE;
    return LoadingStateType.INITIAL;
  };
  
  const primaryType = getPrimaryLoadingType();
  
  // Get appropriate message based on primary type
  const getMessage = () => {
    switch (primaryType) {
      case LoadingStateType.FIRM_SWITCHING:
        const switchState = getLoadingStates(LoadingStateType.FIRM_SWITCHING)[0];
        return `Switching to ${switchState.metadata.firmName}...`;
        
      case LoadingStateType.CROSS_FIRM_DATA:
        const crossFirmStates = getLoadingStates(LoadingStateType.CROSS_FIRM_DATA);
        return `Loading data from ${crossFirmStates.length} other ${crossFirmStates.length === 1 ? 'firm' : 'firms'}...`;
        
      case LoadingStateType.ACTION_PROCESSING:
        const actionState = getLoadingStates(LoadingStateType.ACTION_PROCESSING)[0];
        return actionState.metadata.message || 'Processing...';
        
      case LoadingStateType.BACKGROUND_UPDATE:
        return 'Updating in background...';
        
      default:
        return 'Loading...';
    }
  };
  
  return (
    <div className={`global-loading-indicator type-${primaryType}`}>
      <LoadingSpinner size="small" />
      <span className="loading-message">{getMessage()}</span>
    </div>
  );
};
```

## Integration with API Client

The loading state system is integrated with the API client for automatic tracking:

```javascript
// API client with loading state integration
class ApiClient {
  constructor(loadingStateManager) {
    this.loadingStateManager = loadingStateManager;
    this.axios = axios.create({
      baseURL: API_BASE_URL,
      timeout: 30000
    });
    
    // Request interceptor for loading states
    this.axios.interceptors.request.use(
      (config) => {
        // Don't track background requests
        if (config.background) {
          return config;
        }
        
        // Determine loading state type
        let loadingType = LoadingStateType.INITIAL;
        
        if (config.crossFirm) {
          loadingType = LoadingStateType.CROSS_FIRM_DATA;
        } else if (config.method.toUpperCase() !== 'GET') {
          loadingType = LoadingStateType.ACTION_PROCESSING;
        }
        
        // Create loading ID based on request
        const loadingId = `api_${config.method}_${config.url.replace(/\//g, '_')}`;
        
        // Start loading
        const metadata = {
          url: config.url,
          method: config.method,
          firmId: config.crossFirm ? config.headers['X-Firm-ID'] : undefined
        };
        
        this.loadingStateManager.startLoading(loadingId, loadingType, metadata);
        
        // Store loading ID on config for response interceptor
        config.loadingId = loadingId;
        
        return config;
      },
      (error) => Promise.reject(error)
    );
    
    // Response interceptor for loading states
    this.axios.interceptors.response.use(
      (response) => {
        // Stop loading if request had a loading ID
        if (response.config.loadingId) {
          this.loadingStateManager.stopLoading(response.config.loadingId);
        }
        
        return response;
      },
      (error) => {
        // Stop loading on error
        if (error.config?.loadingId) {
          this.loadingStateManager.stopLoading(error.config.loadingId);
        }
        
        return Promise.reject(error);
      }
    );
  }
  
  // Make request to specific firm
  async requestFromFirm(firmId, config) {
    return this.request({
      ...config,
      crossFirm: firmId !== getCurrentFirmId(),
      headers: {
        ...config.headers,
        'X-Firm-ID': firmId
      }
    });
  }
  
  // Background request (no loading indicator)
  async backgroundRequest(config) {
    return this.request({
      ...config,
      background: true
    });
  }
  
  // Regular request
  async request(config) {
    return this.axios(config);
  }
}
```

## CrossFirmData Component

The `CrossFirmData` component simplifies fetching and displaying data from other firms:

```jsx
// Usage example of CrossFirmData component
const MatterSummary = ({ matterId, firmId }) => {
  return (
    <CrossFirmData
      firmId={firmId}
      resourceType="matters"
      resourceId={matterId}
      render={(data) => (
        <div className="matter-summary">
          <h3>{data.title}</h3>
          <div className="matter-details">
            <div className="matter-client">
              <strong>Client:</strong> {data.clientName}
            </div>
            <div className="matter-status">
              <strong>Status:</strong> {data.status}
            </div>
            <div className="matter-created">
              <strong>Created:</strong> {formatDate(data.createdAt)}
            </div>
          </div>
        </div>
      )}
    />
  );
};

// Using the component
const ClientMattersList = () => {
  const { data: matters } = useQuery('matters', getMatters);
  
  return (
    <div className="matters-list">
      <h2>Related Matters</h2>
      {matters?.map(matter => (
        <div key={matter.id} className="matter-card">
          {matter.isCrossFirm ? (
            <CrossFirmData
              firmId={matter.firmId}
              resourceType="matters"
              resourceId={matter.id}
              render={(data) => (
                <MatterSummary data={data} />
              )}
            />
          ) : (
            <MatterSummary data={matter} />
          )}
        </div>
      ))}
    </div>
  );
};
```

## Cross-Firm Data Visualization

The system provides visual indicators for cross-firm data:

```jsx
// Cross-firm data visualization component
const CrossFirmBadge = ({ firmId, small = false }) => {
  const { firmName, firmColor } = useFirmDetails(firmId);
  
  return (
    <div 
      className={`cross-firm-badge ${small ? 'small' : ''}`}
      style={{ backgroundColor: firmColor || '#6E6E6E' }}
    >
      <CrossFirmIcon size={small ? 12 : 16} />
      <span className="firm-name">{firmName || 'Other Firm'}</span>
    </div>
  );
};

// Component to display data with source firm information
const DataWithSourceIndicator = ({ data, showSource = true }) => {
  const { currentFirm } = useFirmContext();
  const isCrossFirm = data.firmId && data.firmId !== currentFirm?.id;
  
  return (
    <div className={`data-container ${isCrossFirm ? 'cross-firm-data' : ''}`}>
      {showSource && isCrossFirm && (
        <CrossFirmBadge firmId={data.firmId} />
      )}
      <div className="data-content">
        {/* Render data content here */}
        {data.name}
      </div>
    </div>
  );
};
```

## Best Practices for Developers

### 1. Use Appropriate Loading State Types

Always use the appropriate loading state type for different operations:

```javascript
const { startLoading, stopLoading } = useLoadingState();

// For initial page or component loading
const loadingId = startLoading('page_load', LoadingStateType.INITIAL);

// For background data refreshes
const refreshId = startLoading('data_refresh', LoadingStateType.BACKGROUND_UPDATE);

// For user-initiated actions
const actionId = startLoading('save_document', LoadingStateType.ACTION_PROCESSING, {
  message: 'Saving document...'
});
```

### 2. Provide Contextual Information

Always include helpful metadata with loading states:

```javascript
// Good: Include context information
startLoading('export_data', LoadingStateType.ACTION_PROCESSING, {
  message: 'Exporting client data to CSV...',
  dataType: 'clients',
  exportFormat: 'csv',
  recordCount: clients.length
});

// Bad: Minimal information
startLoading('export');
```

### 3. Use CrossFirmData for All Cross-Firm Operations

Always use the `CrossFirmData` component for cross-firm data access:

```jsx
// Good: Using CrossFirmData component
<CrossFirmData
  firmId={otherFirmId}
  resourceType="clients"
  resourceId={clientId}
  render={(client) => (
    <ClientDetails client={client} />
  )}
/>

// Bad: Manual cross-firm fetch without proper loading states
const ClientView = ({ clientId, firmId }) => {
  const [client, setClient] = useState(null);
  
  useEffect(() => {
    fetchClient(firmId, clientId).then(setClient);
  }, [clientId, firmId]);
  
  if (!client) return <div>Loading...</div>;
  
  return <ClientDetails client={client} />;
};
```

### 4. Handle Loading State Cleanup

Always clean up loading states, especially in error cases:

```javascript
const submitForm = async (data) => {
  const loadingId = startLoading('submit_form', LoadingStateType.ACTION_PROCESSING);
  
  try {
    await api.post('/forms', data);
    showSuccess('Form submitted successfully');
  } catch (error) {
    showError('Failed to submit form');
    console.error(error);
  } finally {
    // Always clean up loading state
    stopLoading(loadingId);
  }
};
```

## References

- [Loading State UX Best Practices](https://www.smashingmagazine.com/2023/02/loading-state-pattern-design-system/)
- [Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Smarter Firms UX Guidelines](../ui-service/ux-guidelines.md) 