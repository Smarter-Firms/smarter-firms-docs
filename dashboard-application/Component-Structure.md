# Component Structure

This document outlines the component hierarchy and organization for the Dashboard Application, explaining the purpose of each component category and how they interact.

## Component Hierarchy

The Dashboard Application follows a hierarchical component structure:

```
Layout
└── Page (Dashboard, Clients, Matters, Reports, etc.)
    ├── Section Components
    │   ├── UI Components
    │   │   └── Common Components
    │   └── Feature Components
    └── Widget Components
```

## Component Categories

### Common Components

Common components are reusable UI elements used throughout the application. They implement the design system and provide a consistent user experience.

- `Layout.tsx` - The main application layout with navigation and header
- `Button.tsx` - Button components with various styles and states
- `Card.tsx` - Card container components
- `Form/*.tsx` - Form components (Input, Select, Checkbox, etc.)
- `Table/*.tsx` - Table components for data display
- `Modal.tsx` - Modal dialog component
- `Dropdown.tsx` - Dropdown menu component
- `NotificationCenter.tsx` - Notification display and management component
- `Spinner.tsx` - Loading indicator
- `Avatar.tsx` - User avatar component
- `Badge.tsx` - Status badge component
- `Tooltip.tsx` - Tooltip component

### Dashboard Components

Components specific to the dashboard page and data visualization.

- `KPICard.tsx` - Key Performance Indicator display card
- `ChartContainer.tsx` - Container for charts with consistent styling
- `LineChart.tsx` - Line chart component using Chart.js
- `BarChart.tsx` - Bar chart component using Chart.js
- `PieChart.tsx` - Pie chart component using Chart.js
- `ActivityFeed.tsx` - Recent activity display component
- `DashboardWidget.tsx` - Base widget component for dashboard

### Client Components

Components for client management and display.

- `ClientList.tsx` - Client listing component with filtering and sorting
- `ClientCard.tsx` - Client summary card
- `ClientDetail.tsx` - Detailed client information display
- `ClientForm.tsx` - Form for creating/editing clients
- `ClientSearch.tsx` - Search component for clients
- `ClientStatusBadge.tsx` - Status indicator for clients

### Matter Components

Components for matter management and display.

- `MatterList.tsx` - Matter listing component with filtering and sorting
- `MatterCard.tsx` - Matter summary card
- `MatterDetail.tsx` - Detailed matter information display
- `MatterForm.tsx` - Form for creating/editing matters
- `MatterTimeline.tsx` - Timeline component for matter events
- `MatterStatusIndicator.tsx` - Status indicator for matters

### Report Components

Components for report generation and display.

- `ReportBuilder.tsx` - Interface for building custom reports
- `ReportTemplate.tsx` - Pre-defined report template
- `ReportViewer.tsx` - Component for viewing generated reports
- `ReportFilter.tsx` - Filter controls for reports
- `ExportControls.tsx` - Controls for exporting reports
- `ChartSelector.tsx` - Component for selecting chart types in reports

### Admin Components

Components for administrative functions.

- `UserManagement.tsx` - Interface for managing users
- `RoleManagement.tsx` - Interface for managing roles and permissions
- `SettingsPanel.tsx` - Administrative settings panel
- `AuditLog.tsx` - Component for viewing system audit logs
- `IntegrationConfig.tsx` - Configuration component for integrations

## Component Composition Patterns

### Composition Over Inheritance

The Dashboard Application favors composition over inheritance. Components are designed to be composed together to create more complex UI elements.

Example:
```tsx
// Using composition to build a feature component
<Card>
  <Card.Header>
    <Heading>Client Information</Heading>
  </Card.Header>
  <Card.Body>
    <Form>
      <Form.Input label="Name" />
      <Form.Input label="Email" />
    </Form>
  </Card.Body>
  <Card.Footer>
    <Button variant="primary">Save</Button>
    <Button variant="secondary">Cancel</Button>
  </Card.Footer>
</Card>
```

### Container/Presenter Pattern

For components that involve data fetching and business logic, we use the container/presenter pattern to separate concerns.

Example:
```tsx
// Container component handles data fetching and logic
const ClientListContainer: React.FC = () => {
  const { data, isLoading } = useQuery('clients', fetchClients);
  return <ClientListPresenter clients={data} isLoading={isLoading} />;
};

// Presenter component is purely for UI rendering
const ClientListPresenter: React.FC<ClientListProps> = ({ clients, isLoading }) => {
  if (isLoading) return <Spinner />;
  return (
    <Table>
      {clients.map(client => (
        <TableRow key={client.id}>
          <TableCell>{client.name}</TableCell>
          <TableCell>{client.email}</TableCell>
        </TableRow>
      ))}
    </Table>
  );
};
```

### Higher-Order Components (HOCs)

HOCs are used for cross-cutting concerns like authentication and authorization.

Example:
```tsx
// Higher-order component for authentication
const withAuth = <P extends object>(Component: React.ComponentType<P>, requiredRoles?: UserRole[]) => {
  const WithAuth: React.FC<P> = (props) => {
    const { authState } = useAuth();
    if (!authState.isAuthenticated) return <Redirect to="/login" />;
    if (requiredRoles && !requiredRoles.includes(authState.user?.role)) {
      return <Redirect to="/unauthorized" />;
    }
    return <Component {...props} />;
  };
  return WithAuth;
};
```

## Component Lifecycle Management

### Mounting and Initialization

Components that require data fetching use React Query's `useQuery` hook for efficient data loading and caching.

Example:
```tsx
const DashboardPage: React.FC = () => {
  const { data: dashboardData, isLoading } = useQuery('dashboardData', fetchDashboardData);
  
  if (isLoading) return <PageLoader />;
  
  return (
    <Layout>
      <KPISection kpis={dashboardData.kpis} />
      <ChartSection charts={dashboardData.charts} />
    </Layout>
  );
};
```

### Cleanup and Disposal

Components that set up subscriptions or timers use the `useEffect` cleanup function to prevent memory leaks.

Example:
```tsx
const NotificationListener: React.FC = () => {
  useEffect(() => {
    const intervalId = setInterval(() => {
      // Check for new notifications
    }, 30000);
    
    return () => {
      clearInterval(intervalId);
    };
  }, []);
  
  return null;
};
```

## Component Documentation Standards

Each component folder includes:

1. The component file (ComponentName.tsx)
2. A test file (ComponentName.test.tsx)
3. An optional styles file if needed (ComponentName.module.css)
4. A README.md with:
   - Purpose of the component
   - Props API documentation
   - Usage examples
   - Accessibility considerations

Example component documentation:
```md
# Button Component

A flexible button component that supports various styles and states.

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| variant | 'primary' \| 'secondary' \| 'danger' | 'primary' | The button style variant |
| size | 'small' \| 'medium' \| 'large' | 'medium' | The button size |
| isLoading | boolean | false | Whether to show a loading indicator |
| disabled | boolean | false | Whether the button is disabled |
| onClick | () => void | | Click handler function |

## Examples

```jsx
<Button variant="primary" size="large">Save Changes</Button>
<Button variant="secondary" isLoading={isSaving}>Processing</Button>
```

## Accessibility

- Uses proper button role
- Includes loading state announcement for screen readers
- Follows color contrast guidelines
``` 