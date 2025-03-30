# Testing Strategy

This document outlines the testing strategy for the Dashboard Application, including the types of tests, testing tools, best practices, and workflow.

## Testing Philosophy

The Dashboard Application follows a comprehensive testing approach:

1. **Shift-Left Testing**: Testing begins early in the development process
2. **Test Pyramid**: Emphasis on unit tests, complemented by integration and E2E tests
3. **Test-Driven Development**: Critical features are developed using TDD
4. **Continuous Testing**: Tests run automatically in the CI pipeline
5. **Quality Gates**: PRs require passing tests with minimum coverage thresholds

## Test Types

### Unit Tests

Unit tests verify individual components and functions in isolation:

- **Scope**: Individual functions, React components, hooks, utilities
- **Tools**: Jest, React Testing Library
- **Coverage Target**: 80% minimum

Example unit test for a component:

```typescript
// src/components/Button/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import Button from './Button';

describe('Button component', () => {
  it('renders correctly', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    
    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('applies primary variant styles by default', () => {
    render(<Button>Click me</Button>);
    const button = screen.getByRole('button');
    expect(button).toHaveClass('bg-primary-600');
  });

  it('applies secondary variant styles when specified', () => {
    render(<Button variant="secondary">Click me</Button>);
    const button = screen.getByRole('button');
    expect(button).toHaveClass('bg-secondary-600');
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

Example unit test for a utility function:

```typescript
// src/utils/formatters.test.ts
import { formatCurrency, formatDate, formatPercentage } from './formatters';

describe('formatters', () => {
  describe('formatCurrency', () => {
    it('formats positive numbers with $ symbol', () => {
      expect(formatCurrency(1234.56)).toBe('$1,234.56');
    });

    it('formats negative numbers with $ symbol', () => {
      expect(formatCurrency(-1234.56)).toBe('-$1,234.56');
    });

    it('handles zero', () => {
      expect(formatCurrency(0)).toBe('$0.00');
    });

    it('uses provided currency symbol', () => {
      expect(formatCurrency(1234.56, '€')).toBe('€1,234.56');
    });
  });

  describe('formatDate', () => {
    it('formats date with default format', () => {
      const date = new Date('2023-01-15');
      expect(formatDate(date)).toBe('Jan 15, 2023');
    });

    it('formats date with custom format', () => {
      const date = new Date('2023-01-15');
      expect(formatDate(date, 'yyyy-MM-dd')).toBe('2023-01-15');
    });
  });

  describe('formatPercentage', () => {
    it('formats number as percentage', () => {
      expect(formatPercentage(0.1234)).toBe('12.34%');
    });

    it('handles negative values', () => {
      expect(formatPercentage(-0.1234)).toBe('-12.34%');
    });

    it('uses specified decimal places', () => {
      expect(formatPercentage(0.1234, 1)).toBe('12.3%');
    });
  });
});
```

### Integration Tests

Integration tests verify that multiple units work together correctly:

- **Scope**: Component compositions, API service integration, state management
- **Tools**: Jest, React Testing Library, MSW (Mock Service Worker)
- **Coverage Target**: 60% minimum

Example integration test for a form component with API interaction:

```typescript
// src/components/ClientForm/ClientForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import { rest } from 'msw';
import { setupServer } from 'msw/node';
import ClientForm from './ClientForm';
import { API_BASE_URL } from '@/config';

// Mock server
const server = setupServer(
  rest.post(`${API_BASE_URL}/clients`, (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({
        id: '123',
        name: req.body.name,
        email: req.body.email,
        phone: req.body.phone,
      })
    );
  })
);

// Setup and teardown
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// QueryClient setup for React Query
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});

const renderWithProviders = (ui) => {
  return render(
    <QueryClientProvider client={queryClient}>
      {ui}
    </QueryClientProvider>
  );
};

describe('ClientForm integration', () => {
  it('submits form data and shows success message', async () => {
    const onSuccess = jest.fn();
    renderWithProviders(<ClientForm onSuccess={onSuccess} />);
    
    // Fill out form
    await userEvent.type(screen.getByLabelText(/name/i), 'Test Client');
    await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com');
    await userEvent.type(screen.getByLabelText(/phone/i), '1234567890');
    
    // Submit form
    fireEvent.click(screen.getByRole('button', { name: /save/i }));
    
    // Wait for success
    await waitFor(() => {
      expect(onSuccess).toHaveBeenCalledWith({
        id: '123',
        name: 'Test Client',
        email: 'test@example.com',
        phone: '1234567890',
      });
    });
    
    expect(screen.getByText(/client saved successfully/i)).toBeInTheDocument();
  });
  
  it('displays validation errors', async () => {
    renderWithProviders(<ClientForm />);
    
    // Submit without filling form
    fireEvent.click(screen.getByRole('button', { name: /save/i }));
    
    // Check validation errors
    expect(screen.getByText(/name is required/i)).toBeInTheDocument();
    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
    expect(screen.getByText(/phone is required/i)).toBeInTheDocument();
  });
  
  it('handles API errors', async () => {
    // Override server response for this test
    server.use(
      rest.post(`${API_BASE_URL}/clients`, (req, res, ctx) => {
        return res(
          ctx.status(400),
          ctx.json({
            message: 'Validation error',
            errors: {
              email: 'Email already exists',
            },
          })
        );
      })
    );
    
    renderWithProviders(<ClientForm />);
    
    // Fill out form
    await userEvent.type(screen.getByLabelText(/name/i), 'Test Client');
    await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com');
    await userEvent.type(screen.getByLabelText(/phone/i), '1234567890');
    
    // Submit form
    fireEvent.click(screen.getByRole('button', { name: /save/i }));
    
    // Check error message
    await waitFor(() => {
      expect(screen.getByText(/email already exists/i)).toBeInTheDocument();
    });
  });
});
```

### End-to-End Tests

E2E tests verify complete user flows and application behavior:

- **Scope**: Full user journeys, cross-page interactions
- **Tools**: Cypress, Playwright
- **Coverage**: Critical user paths

Example E2E test for client management:

```typescript
// cypress/e2e/client-management.cy.ts
describe('Client Management', () => {
  beforeEach(() => {
    // Login before each test
    cy.login('admin@example.com', 'password123');
  });

  it('allows user to create, view, edit, and delete a client', () => {
    // Navigate to clients page
    cy.visit('/clients');
    cy.contains('h1', 'Clients');
    
    // Create new client
    cy.contains('button', 'Add Client').click();
    cy.get('input[name="name"]').type('E2E Test Client');
    cy.get('input[name="email"]').type('e2e-test@example.com');
    cy.get('input[name="phone"]').type('1234567890');
    cy.get('input[name="address.street"]').type('123 Test St');
    cy.get('input[name="address.city"]').type('Test City');
    cy.get('input[name="address.state"]').type('Test State');
    cy.get('input[name="address.zipCode"]').type('12345');
    cy.get('select[name="status"]').select('active');
    cy.contains('button', 'Save').click();
    
    // Verify client was created
    cy.contains('Client saved successfully');
    cy.contains('E2E Test Client').should('be.visible');
    
    // View client details
    cy.contains('E2E Test Client').click();
    cy.contains('h2', 'E2E Test Client');
    cy.contains('e2e-test@example.com');
    
    // Edit client
    cy.contains('button', 'Edit').click();
    cy.get('input[name="phone"]').clear().type('9876543210');
    cy.contains('button', 'Save').click();
    cy.contains('Client updated successfully');
    cy.contains('9876543210');
    
    // Delete client
    cy.contains('button', 'Delete').click();
    cy.contains('button', 'Confirm').click();
    cy.contains('Client deleted successfully');
    cy.contains('E2E Test Client').should('not.exist');
  });
  
  it('handles pagination and filtering', () => {
    // Navigate to clients page
    cy.visit('/clients');
    
    // Filter clients
    cy.get('input[placeholder="Search clients"]').type('Test');
    cy.contains('button', 'Apply').click();
    cy.get('[data-testid="client-row"]').should('have.length.at.least', 1);
    cy.get('[data-testid="client-row"]').each(($el) => {
      cy.wrap($el).should('contain.text', 'Test');
    });
    
    // Reset filter
    cy.get('button[aria-label="Clear search"]').click();
    
    // Test pagination
    cy.get('[data-testid="pagination"]').should('exist');
    cy.get('[data-testid="page-2"]').click();
    cy.url().should('include', 'page=2');
    cy.get('[data-testid="client-row"]').should('have.length.at.least', 1);
  });
});
```

### Visual Regression Tests

Visual regression tests detect unintended visual changes:

- **Scope**: UI components, page layouts
- **Tools**: Cypress with Percy, Storybook with Chromatic
- **Coverage**: Key UI components and pages

Example visual regression test configuration:

```typescript
// cypress/e2e/visual-regression.cy.ts
describe('Visual Regression Tests', () => {
  beforeEach(() => {
    cy.login('admin@example.com', 'password123');
  });

  it('Dashboard page looks correct', () => {
    cy.visit('/dashboard');
    cy.waitForPageLoad();
    cy.percySnapshot('Dashboard Page');
  });

  it('Clients list page looks correct', () => {
    cy.visit('/clients');
    cy.waitForPageLoad();
    cy.percySnapshot('Clients List Page');
  });

  it('Client details page looks correct', () => {
    cy.visit('/clients/1');
    cy.waitForPageLoad();
    cy.percySnapshot('Client Details Page');
  });

  it('Reports page looks correct', () => {
    cy.visit('/reports');
    cy.waitForPageLoad();
    cy.percySnapshot('Reports Page');
  });

  it('Settings page looks correct', () => {
    cy.visit('/settings');
    cy.waitForPageLoad();
    cy.percySnapshot('Settings Page');
  });
});
```

### Accessibility Tests

Accessibility tests ensure the application is usable by everyone:

- **Scope**: All UI components and pages
- **Tools**: Jest-Axe, Cypress-Axe
- **Standards**: WCAG 2.1 AA

Example accessibility test:

```typescript
// src/components/Button/Button.test.tsx
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import Button from './Button';

expect.extend(toHaveNoViolations);

describe('Button accessibility', () => {
  it('has no accessibility violations', async () => {
    const { container } = render(<Button>Click me</Button>);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('has no accessibility violations when disabled', async () => {
    const { container } = render(<Button disabled>Click me</Button>);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
```

Example Cypress accessibility test:

```typescript
// cypress/e2e/accessibility.cy.ts
describe('Accessibility Tests', () => {
  beforeEach(() => {
    cy.login('admin@example.com', 'password123');
    cy.injectAxe();
  });

  it('Dashboard page has no detectable accessibility violations', () => {
    cy.visit('/dashboard');
    cy.waitForPageLoad();
    cy.checkA11y();
  });

  it('Login page has no detectable accessibility violations', () => {
    cy.logout();
    cy.visit('/login');
    cy.injectAxe();
    cy.checkA11y();
  });

  it('Clients page has no detectable accessibility violations', () => {
    cy.visit('/clients');
    cy.waitForPageLoad();
    cy.checkA11y();
  });
});
```

## Test Configuration

### Jest Configuration

```javascript
// jest.config.js
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testPathIgnorePatterns: ['<rootDir>/.next/', '<rootDir>/node_modules/'],
  moduleNameMapper: {
    '^@/components/(.*)$': '<rootDir>/src/components/$1',
    '^@/context/(.*)$': '<rootDir>/src/context/$1',
    '^@/hooks/(.*)$': '<rootDir>/src/hooks/$1',
    '^@/services/(.*)$': '<rootDir>/src/services/$1',
    '^@/utils/(.*)$': '<rootDir>/src/utils/$1',
    '^@/lib/(.*)$': '<rootDir>/src/lib/$1',
    '^@/config$': '<rootDir>/src/config/index.ts',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
  },
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': ['babel-jest', { presets: ['next/babel'] }],
  },
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{js,jsx,ts,tsx}',
    '!src/pages/_app.tsx',
    '!src/pages/_document.tsx',
  ],
};
```

### Cypress Configuration

```javascript
// cypress.config.js
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    viewportWidth: 1280,
    viewportHeight: 720,
    video: false,
    screenshotOnRunFailure: true,
    defaultCommandTimeout: 10000,
    setupNodeEvents(on, config) {
      // Add plugins here
    },
  },
  
  component: {
    devServer: {
      framework: 'next',
      bundler: 'webpack',
    },
  },
  
  env: {
    apiUrl: 'http://localhost:3001',
    coverage: true,
  },
});
```

## Testing Utilities

### Custom Test Hooks

```typescript
// src/test-utils/hooks.ts
import { renderHook } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/context/AuthContext';

// Create a wrapper with providers for testing hooks
export const createTestQueryClient = () => new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
      cacheTime: 0,
    },
  },
  logger: {
    log: console.log,
    warn: console.warn,
    error: () => {},
  },
});

export const renderHookWithProviders = (
  hookFn,
  {
    wrapWithAuth = true,
    authState = {
      user: {
        id: 'test-user',
        name: 'Test User',
        email: 'test@example.com',
        role: 'admin',
        permissions: ['view:dashboard', 'view:clients', 'edit:clients'],
      },
      isAuthenticated: true,
      isLoading: false,
      error: null,
    },
    ...options
  } = {}
) => {
  const queryClient = createTestQueryClient();
  
  const Wrapper = ({ children }) => {
    let content = children;
    
    // Wrap with QueryClientProvider
    content = (
      <QueryClientProvider client={queryClient}>
        {content}
      </QueryClientProvider>
    );
    
    // Wrap with AuthProvider if requested
    if (wrapWithAuth) {
      // Mock the AuthContext values
      jest.mock('@/context/AuthContext', () => ({
        ...jest.requireActual('@/context/AuthContext'),
        useAuth: () => authState,
      }));
      
      content = <AuthProvider>{content}</AuthProvider>;
    }
    
    return content;
  };
  
  return renderHook(hookFn, { wrapper: Wrapper, ...options });
};
```

### Custom Component Rendering

```typescript
// src/test-utils/render.tsx
import { render, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/context/AuthContext';

// Create a wrapper with providers for testing components
export function renderWithProviders(
  ui: React.ReactElement,
  {
    wrapWithAuth = true,
    authState = {
      user: {
        id: 'test-user',
        name: 'Test User',
        email: 'test@example.com',
        role: 'admin',
        permissions: ['view:dashboard', 'view:clients', 'edit:clients'],
      },
      isAuthenticated: true,
      isLoading: false,
      error: null,
    },
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    }),
    ...renderOptions
  }: {
    wrapWithAuth?: boolean;
    authState?: object;
    queryClient?: QueryClient;
  } & Omit<RenderOptions, 'wrapper'> = {}
) {
  function Wrapper({ children }: { children: React.ReactNode }) {
    let content = children;
    
    // Wrap with QueryClientProvider
    content = (
      <QueryClientProvider client={queryClient}>
        {content}
      </QueryClientProvider>
    );
    
    // Wrap with AuthProvider if requested
    if (wrapWithAuth) {
      // Mock the AuthContext values
      jest.mock('@/context/AuthContext', () => ({
        ...jest.requireActual('@/context/AuthContext'),
        useAuth: () => authState,
      }));
      
      content = <AuthProvider>{content}</AuthProvider>;
    }
    
    return <>{content}</>;
  }
  
  return { ...render(ui, { wrapper: Wrapper, ...renderOptions }) };
}
```

### Mock Data Factories

```typescript
// src/test-utils/factories.ts
import { faker } from '@faker-js/faker';
import { Client, Matter, User, Notification } from '@/types';

// Factory for generating test clients
export const createClient = (overrides = {}): Client => ({
  id: faker.string.uuid(),
  name: faker.company.name(),
  email: faker.internet.email(),
  phone: faker.phone.number(),
  address: {
    street: faker.location.streetAddress(),
    city: faker.location.city(),
    state: faker.location.state(),
    zipCode: faker.location.zipCode(),
    country: faker.location.country(),
  },
  status: faker.helpers.arrayElement(['active', 'inactive', 'pending']),
  createdAt: faker.date.past().toISOString(),
  updatedAt: faker.date.recent().toISOString(),
  ...overrides,
});

// Factory for generating test matters
export const createMatter = (overrides = {}): Matter => ({
  id: faker.string.uuid(),
  title: faker.lorem.sentence(),
  description: faker.lorem.paragraph(),
  clientId: faker.string.uuid(),
  status: faker.helpers.arrayElement(['open', 'closed', 'pending']),
  assignedTo: faker.string.uuid(),
  startDate: faker.date.past().toISOString(),
  dueDate: faker.date.future().toISOString(),
  createdAt: faker.date.past().toISOString(),
  updatedAt: faker.date.recent().toISOString(),
  ...overrides,
});

// Factory for generating test users
export const createUser = (overrides = {}): User => ({
  id: faker.string.uuid(),
  name: faker.person.fullName(),
  email: faker.internet.email(),
  role: faker.helpers.arrayElement(['admin', 'manager', 'user']),
  permissions: [],
  createdAt: faker.date.past().toISOString(),
  updatedAt: faker.date.recent().toISOString(),
  ...overrides,
});

// Factory for generating test notifications
export const createNotification = (overrides = {}): Notification => ({
  id: faker.string.uuid(),
  userId: faker.string.uuid(),
  title: faker.lorem.sentence(),
  message: faker.lorem.paragraph(),
  type: faker.helpers.arrayElement(['info', 'success', 'warning', 'error']),
  isRead: faker.datatype.boolean(),
  createdAt: faker.date.recent().toISOString(),
  ...overrides,
});
```

## Testing Workflow

### Local Testing

The development workflow for tests includes:

1. **Writing Tests**: Tests are written alongside code
2. **Running Tests**: Tests can be run locally with various commands
3. **Watching Mode**: Tests run automatically on file changes
4. **Coverage Reports**: Coverage reports are generated locally

Example npm scripts:

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:e2e": "cypress run",
    "test:e2e:open": "cypress open",
    "test:ci": "jest --ci --coverage && cypress run"
  }
}
```

### CI/CD Integration

Tests are integrated into the CI/CD pipeline:

1. **Pre-commit Hooks**: Run linters and unit tests
2. **CI Builds**: Run all tests and generate coverage
3. **Pull Requests**: Require passing tests and coverage thresholds
4. **Deployment**: Only deploy code with passing tests

Example GitHub Actions workflow:

```yaml
name: Test

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Run unit and integration tests
        run: npm run test:coverage
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
      
      - name: Start app for E2E tests
        run: npm run build && npm run start &
        env:
          NODE_ENV: test
      
      - name: Run E2E tests
        run: npm run test:e2e
      
      - name: Upload E2E artifacts
        uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: cypress-screenshots
          path: cypress/screenshots
```

## Test Monitoring and Reporting

The testing process includes monitoring and reporting:

1. **Coverage Reports**: Generated after test runs
2. **Test Dashboards**: CI/CD platforms provide test results
3. **Regression Tracking**: Track failures and flaky tests
4. **Historical Data**: Track test metrics over time

Example tools for reporting:

- **Jest HTML Reporter**: For unit and integration test reports
- **Cypress Dashboard**: For E2E test reporting
- **Codecov**: For coverage tracking
- **Percy**: For visual regression tracking

## Testing Best Practices

The application follows these testing best practices:

1. **Test Independence**: Tests should not depend on each other
2. **Deterministic Tests**: Tests should be reliable and not flaky
3. **Fast Feedback**: Unit tests should run quickly
4. **Realistic Data**: Use realistic test data
5. **Isolation**: Mock external dependencies
6. **Focus on Behavior**: Test behavior, not implementation details
7. **Maintainability**: Keep tests clean and maintainable
8. **Documentation**: Tests serve as living documentation 