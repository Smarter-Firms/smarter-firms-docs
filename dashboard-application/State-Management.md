# State Management

This document outlines the state management approach for the Dashboard Application, describing how different types of state are handled and the patterns used.

## State Management Philosophy

The Dashboard Application uses a hybrid approach to state management, selecting the appropriate tool based on the type and scope of state being managed:

1. **Server State**: Data from APIs and backend services - Managed by React Query
2. **Global App State**: Application-wide state like authentication - Managed by React Context API
3. **Local Component State**: UI state specific to a component - Managed by React's built-in useState/useReducer

This approach follows the principle of using the simplest possible solution for each type of state.

## Server State Management

### React Query

React Query is used for fetching, caching, synchronizing, and updating server state. It provides a declarative API that integrates well with React's component model.

#### Key Features Used:

- **Caching**: Automatic caching of query results with configurable stale times
- **Refetching**: Automatic background refetching of stale data
- **Pagination and Infinite Queries**: For handling large data sets
- **Mutations**: For updating server state
- **Query Invalidation**: For managing cache invalidation
- **Prefetching**: For improving perceived performance

#### Example Usage:

```tsx
// Fetching data with React Query
const { data, isLoading, error } = useQuery(
  ['clients', { status: 'active' }],
  () => fetchClients({ status: 'active' }),
  {
    staleTime: 5 * 60 * 1000, // 5 minutes
    refetchOnWindowFocus: true,
    retry: 3,
  }
);

// Mutating data with React Query
const { mutate, isLoading: isSaving } = useMutation(
  (newClient) => createClient(newClient),
  {
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries(['clients']);
    },
  }
);
```

### API Service Layer

All API calls are abstracted through service modules that encapsulate the API logic. This provides a clean separation between data fetching and the UI.

```tsx
// src/services/clients.ts
import axios from 'axios';
import { Client, ClientStatus } from '@/types';

// Fetch all clients
export const fetchClients = async (status?: ClientStatus): Promise<Client[]> => {
  try {
    const params = status ? { status } : {};
    const response = await axios.get('/api/clients', { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching clients:', error);
    throw error;
  }
};
```

## Global Application State

### React Context API

For global application state that needs to be accessed by many components, we use React Context API. This includes authentication state, user preferences, and other application-level state.

#### Authentication Context

```tsx
// src/hooks/useAuth.tsx
import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { User, AuthState } from '@/types';

type AuthAction = 
  | { type: 'LOGIN_SUCCESS'; payload: User }
  | { type: 'LOGOUT' }
  | { type: 'LOGIN_FAILURE'; payload: string };

const authReducer = (state: AuthState, action: AuthAction): AuthState => {
  switch (action.type) {
    case 'LOGIN_SUCCESS':
      return {
        ...state,
        user: action.payload,
        isAuthenticated: true,
        error: null,
      };
    case 'LOGOUT':
      return {
        ...state,
        user: null,
        isAuthenticated: false,
        error: null,
      };
    case 'LOGIN_FAILURE':
      return {
        ...state,
        user: null,
        isAuthenticated: false,
        error: action.payload,
      };
    default:
      return state;
  }
};

// Create context
const AuthContext = createContext<{
  state: AuthState;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}>({
  state: { user: null, isAuthenticated: false, error: null },
  login: async () => {},
  logout: () => {},
});

// Provider component
export const AuthProvider: React.FC = ({ children }) => {
  const [state, dispatch] = useReducer(authReducer, {
    user: null,
    isAuthenticated: false,
    error: null,
  });

  // Implementation of login and logout functions
  // ...

  return (
    <AuthContext.Provider value={{ state, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

// Hook for using the auth context
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
```

#### Context Composition

Multiple contexts are composed at the application root to provide different slices of global state:

```tsx
// src/pages/_app.tsx
function MyApp({ Component, pageProps }) {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ThemeProvider>
          <NotificationProvider>
            <Component {...pageProps} />
          </NotificationProvider>
        </ThemeProvider>
      </AuthProvider>
      <ReactQueryDevtools />
    </QueryClientProvider>
  );
}
```

## Local Component State

### React useState

For simple component-local state, we use React's built-in useState hook. This is appropriate for form inputs, toggles, and other UI state that doesn't need to be shared.

```tsx
const ClientForm: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await submitClientData({ name, email });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
    </form>
  );
};
```

### React useReducer

For more complex component state logic, we use useReducer which allows for more predictable state transitions and better testing.

```tsx
type State = {
  step: number;
  formData: {
    clientInfo: { name: string; email: string };
    matterDetails: { title: string; description: string };
  };
  errors: string[];
};

type Action =
  | { type: 'NEXT_STEP' }
  | { type: 'PREV_STEP' }
  | { type: 'UPDATE_CLIENT_INFO'; payload: Partial<State['formData']['clientInfo']> }
  | { type: 'UPDATE_MATTER_DETAILS'; payload: Partial<State['formData']['matterDetails']> }
  | { type: 'SET_ERRORS'; payload: string[] };

const formReducer = (state: State, action: Action): State => {
  switch (action.type) {
    case 'NEXT_STEP':
      return { ...state, step: state.step + 1 };
    case 'PREV_STEP':
      return { ...state, step: Math.max(0, state.step - 1) };
    case 'UPDATE_CLIENT_INFO':
      return {
        ...state,
        formData: {
          ...state.formData,
          clientInfo: { ...state.formData.clientInfo, ...action.payload },
        },
      };
    // Other cases...
    default:
      return state;
  }
};

const MultiStepForm: React.FC = () => {
  const [state, dispatch] = useReducer(formReducer, {
    step: 0,
    formData: {
      clientInfo: { name: '', email: '' },
      matterDetails: { title: '', description: '' },
    },
    errors: [],
  });

  // Form steps and submission logic
};
```

## State Management Patterns

### Container/Presenter Pattern

For components that involve both UI and state logic, we use the container/presenter pattern to separate concerns:

```tsx
// Container component with state logic
const ClientListContainer: React.FC = () => {
  const [filter, setFilter] = useState('');
  const { data, isLoading } = useQuery(['clients', filter], () => 
    fetchClients({ nameFilter: filter })
  );

  return (
    <ClientListPresenter 
      clients={data} 
      isLoading={isLoading} 
      filter={filter}
      onFilterChange={setFilter} 
    />
  );
};

// Presenter component focusing on UI rendering
const ClientListPresenter: React.FC<ClientListPresenterProps> = ({
  clients,
  isLoading,
  filter,
  onFilterChange,
}) => {
  return (
    <div>
      <SearchInput value={filter} onChange={onFilterChange} />
      {isLoading ? (
        <LoadingSpinner />
      ) : (
        <ClientTable clients={clients} />
      )}
    </div>
  );
};
```

### Hooks for Reusable Logic

Custom hooks are used to encapsulate and reuse stateful logic:

```tsx
// Custom hook for pagination
const usePagination = <T,>(items: T[], itemsPerPage: number) => {
  const [currentPage, setCurrentPage] = useState(1);
  
  const totalPages = Math.ceil(items.length / itemsPerPage);
  
  const currentItems = items.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );
  
  const nextPage = () => {
    setCurrentPage((prev) => Math.min(prev + 1, totalPages));
  };
  
  const prevPage = () => {
    setCurrentPage((prev) => Math.max(prev - 1, 1));
  };
  
  const goToPage = (page: number) => {
    setCurrentPage(Math.min(Math.max(page, 1), totalPages));
  };
  
  return {
    currentPage,
    totalPages,
    currentItems,
    nextPage,
    prevPage,
    goToPage,
  };
};

// Usage in a component
const ClientList: React.FC = () => {
  const { data: clients = [] } = useQuery('clients', fetchClients);
  
  const {
    currentItems: paginatedClients,
    currentPage,
    totalPages,
    nextPage,
    prevPage,
    goToPage,
  } = usePagination(clients, 10);
  
  return (
    <div>
      <ClientTable clients={paginatedClients} />
      <Pagination
        currentPage={currentPage}
        totalPages={totalPages}
        onNextPage={nextPage}
        onPrevPage={prevPage}
        onGoToPage={goToPage}
      />
    </div>
  );
};
```

## Performance Optimization

### Memoization

React's memoization hooks (useMemo and useCallback) are used to optimize performance by preventing unnecessary re-renders:

```tsx
const ClientFilterPanel: React.FC<ClientFilterPanelProps> = ({ 
  clients, 
  onFilterChange 
}) => {
  // Memoize expensive computation
  const clientsByRegion = useMemo(() => {
    return clients.reduce((acc, client) => {
      const region = client.region || 'Unknown';
      if (!acc[region]) {
        acc[region] = [];
      }
      acc[region].push(client);
      return acc;
    }, {});
  }, [clients]);
  
  // Memoize callback to prevent unnecessary re-renders
  const handleFilterChange = useCallback((region) => {
    onFilterChange(region);
  }, [onFilterChange]);
  
  return (
    <FilterList 
      regions={Object.keys(clientsByRegion)} 
      onSelect={handleFilterChange} 
    />
  );
};
```

### React.memo

Components that receive the same props frequently are wrapped with React.memo to prevent unnecessary re-renders:

```tsx
const ClientCard: React.FC<ClientCardProps> = React.memo(({ client }) => {
  return (
    <div className="card">
      <h3>{client.name}</h3>
      <p>{client.email}</p>
    </div>
  );
});
```

## Error Handling

### Error Boundaries

Error boundaries are used to catch JavaScript errors in UI components and prevent the whole application from crashing:

```tsx
class ErrorBoundary extends React.Component {
  state = { hasError: false, error: null };
  
  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }
  
  componentDidCatch(error, errorInfo) {
    // Log error to monitoring service
    console.error('UI Error:', error, errorInfo);
  }
  
  render() {
    if (this.state.hasError) {
      return <ErrorFallback error={this.state.error} />;
    }
    
    return this.props.children;
  }
}

// Usage
const App = () => (
  <ErrorBoundary>
    <Dashboard />
  </ErrorBoundary>
);
```

### API Error Handling

Consistent error handling for API requests using React Query's error handling:

```tsx
const { data, error, isError } = useQuery('clients', fetchClients, {
  onError: (error) => {
    // Log to monitoring service
    console.error('API Error:', error);
    
    // Show user-friendly message
    notifyUser({
      type: 'error',
      message: 'Unable to load clients. Please try again later.',
    });
  },
});

// In the component
if (isError) {
  return <ErrorDisplay message="Failed to load clients" error={error} />;
}
```

## Data Flow Diagram

```
┌─────────────────┐      ┌───────────────┐      ┌───────────────┐
│                 │      │               │      │               │
│  API Services   │<─────│  React Query  │<─────│  UI Components│
│                 │      │               │      │               │
└────────┬────────┘      └───────┬───────┘      └───────┬───────┘
         │                       │                      │
         │                       │                      │
         ▼                       ▼                      ▼
┌─────────────────┐      ┌───────────────┐      ┌───────────────┐
│                 │      │               │      │               │
│ Backend Servers │      │  Query Cache  │      │ React Context │
│                 │      │               │      │               │
└─────────────────┘      └───────────────┘      └───────────────┘
```

## State Management Best Practices

1. **Define clear boundaries** between different types of state
2. **Use the right tool for the job** based on the type and scope of state
3. **Keep component state as local as possible**
4. **Centralize server state management** with React Query
5. **Abstract API logic** into service modules
6. **Use TypeScript** to ensure type safety in state management
7. **Implement consistent error handling** across the application
8. **Document state management patterns** for team consistency
9. **Use dev tools** like React Query DevTools to inspect and debug state
10. **Test state management logic** with unit and integration tests 