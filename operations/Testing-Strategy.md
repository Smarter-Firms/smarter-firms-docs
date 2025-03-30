# Smarter Firms Testing Strategy

This document outlines the testing strategy for the Smarter Firms platform, including test types, coverage requirements, and CI/CD integration.

## Testing Objectives

1. Ensure code quality and reliability across all services
2. Prevent regressions when adding new features or fixing bugs
3. Validate system integration between services
4. Verify API contracts between frontend and backend
5. Ensure performance meets requirements under expected load
6. Validate security measures and prevent common vulnerabilities

## Test Types and Standards

### Unit Tests

Unit tests validate individual functions, methods, and components in isolation.

**Standards:**
- **Coverage Requirement**: Minimum 80% code coverage
- **Frameworks**: 
  - Backend: Jest with ts-jest
  - Frontend: Vitest or Jest with React Testing Library
- **Implementation**: 
  - Focus on pure logic and business rules
  - Use dependency injection to allow for proper mocking
  - Avoid testing implementation details
  - Aim for fast execution

**Example backend unit test:**

```typescript
// Auth service - User service unit test
describe('UserService', () => {
  let userService: UserService;
  let userRepositoryMock: jest.Mocked<UserRepository>;
  
  beforeEach(() => {
    userRepositoryMock = {
      findByEmail: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    } as any;
    
    userService = new UserService(userRepositoryMock);
  });
  
  describe('registerUser', () => {
    it('should throw an error if user with email already exists', async () => {
      // Arrange
      const userData = { email: 'test@example.com', password: 'Password123', firstName: 'Test', lastName: 'User' };
      userRepositoryMock.findByEmail.mockResolvedValue({ id: '1', email: 'test@example.com' } as any);
      
      // Act & Assert
      await expect(userService.registerUser(userData)).rejects.toThrow('User with this email already exists');
      expect(userRepositoryMock.findByEmail).toHaveBeenCalledWith('test@example.com');
    });
    
    it('should create a new user with hashed password', async () => {
      // Arrange
      const userData = { email: 'test@example.com', password: 'Password123', firstName: 'Test', lastName: 'User' };
      userRepositoryMock.findByEmail.mockResolvedValue(null);
      userRepositoryMock.create.mockResolvedValue({ id: '1', ...userData, password: 'hashed_password' } as any);
      
      // Act
      const result = await userService.registerUser(userData);
      
      // Assert
      expect(result.email).toBe('test@example.com');
      expect(result.firstName).toBe('Test');
      expect(result.password).not.toBe('Password123'); // Password should be hashed
      expect(userRepositoryMock.create).toHaveBeenCalled();
    });
  });
});
```

**Example frontend unit test:**

```typescript
// Login component test
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LoginForm } from './LoginForm';

const mockLogin = jest.fn();

describe('LoginForm', () => {
  beforeEach(() => {
    mockLogin.mockClear();
  });
  
  it('should display validation errors for empty form submission', async () => {
    // Arrange
    render(<LoginForm onLogin={mockLogin} />);
    const submitButton = screen.getByRole('button', { name: /login/i });
    
    // Act
    await userEvent.click(submitButton);
    
    // Assert
    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
    expect(screen.getByText(/password is required/i)).toBeInTheDocument();
    expect(mockLogin).not.toHaveBeenCalled();
  });
  
  it('should call onLogin with form data when submitted with valid data', async () => {
    // Arrange
    render(<LoginForm onLogin={mockLogin} />);
    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const submitButton = screen.getByRole('button', { name: /login/i });
    
    // Act
    await userEvent.type(emailInput, 'test@example.com');
    await userEvent.type(passwordInput, 'password123');
    await userEvent.click(submitButton);
    
    // Assert
    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123',
      });
    });
  });
});
```

### Integration Tests

Integration tests validate the interaction between different components and services.

**Standards:**
- **Coverage Requirement**: Critical paths must be covered
- **Frameworks**: 
  - Backend: Jest with supertest
  - Database: testcontainers for PostgreSQL
- **Implementation**:
  - Test API endpoints with actual HTTP requests
  - Use test databases with real schema
  - Validate response structures against API contracts
  - Verify error handling

**Example API integration test:**

```typescript
// Auth service - Authentication API integration test
import { app } from '../app';
import request from 'supertest';
import { prisma } from '../prisma';
import { hashPassword } from '../utils/auth';

describe('Auth API', () => {
  beforeAll(async () => {
    // Setup test database
    await prisma.$connect();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  beforeEach(async () => {
    // Clean database between tests
    await prisma.user.deleteMany({});
  });

  describe('POST /api/v1/auth/register', () => {
    it('should register a new user and return tokens', async () => {
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'test@example.com',
          password: 'Password123',
          firstName: 'Test',
          lastName: 'User'
        });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.user.email).toBe('test@example.com');
      expect(response.body.data.tokens.accessToken).toBeDefined();
      expect(response.body.data.tokens.refreshToken).toBeDefined();
      
      // Verify user was created in database
      const createdUser = await prisma.user.findUnique({
        where: { email: 'test@example.com' }
      });
      expect(createdUser).not.toBeNull();
    });

    it('should return 400 if email already exists', async () => {
      // Create user first
      await prisma.user.create({
        data: {
          email: 'test@example.com',
          password: await hashPassword('Password123'),
          firstName: 'Test',
          lastName: 'User'
        }
      });

      // Try to register with same email
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'test@example.com',
          password: 'Password123',
          firstName: 'Test',
          lastName: 'User'
        });

      expect(response.status).toBe(400);
      expect(response.body.status).toBe('error');
      expect(response.body.message).toContain('already exists');
    });
  });

  describe('POST /api/v1/auth/login', () => {
    beforeEach(async () => {
      // Create test user
      await prisma.user.create({
        data: {
          email: 'test@example.com',
          password: await hashPassword('Password123'),
          firstName: 'Test',
          lastName: 'User'
        }
      });
    });

    it('should login user and return tokens', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'test@example.com',
          password: 'Password123'
        });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.user.email).toBe('test@example.com');
      expect(response.body.data.tokens.accessToken).toBeDefined();
      expect(response.body.data.tokens.refreshToken).toBeDefined();
    });

    it('should return 401 for invalid credentials', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'test@example.com',
          password: 'WrongPassword'
        });

      expect(response.status).toBe(401);
      expect(response.body.status).toBe('error');
      expect(response.body.message).toContain('Invalid credentials');
    });
  });
});
```

### End-to-End Tests

End-to-end tests validate the complete user flow across the entire system.

**Standards:**
- **Coverage Requirement**: Critical user journeys must be covered
- **Frameworks**: Playwright or Cypress
- **Implementation**:
  - Focus on critical user flows (e.g., registration, login, subscription, Clio integration)
  - Run against a deployed test environment
  - Simulate real user interactions
  - Test mobile and desktop viewports

**Example E2E test:**

```typescript
// E2E test for user registration and login
import { test, expect } from '@playwright/test';

test.describe('Authentication Flow', () => {
  test('User can register and login', async ({ page }) => {
    // Generate unique email for test
    const testEmail = `test-${Date.now()}@example.com`;
    
    // Navigate to registration page
    await page.goto('/register');
    
    // Fill registration form
    await page.fill('input[name="email"]', testEmail);
    await page.fill('input[name="password"]', 'SecurePassword123!');
    await page.fill('input[name="firstName"]', 'Test');
    await page.fill('input[name="lastName"]', 'User');
    
    // Submit form
    await page.click('button[type="submit"]');
    
    // Verify registration success
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('.user-menu')).toContainText('Test User');
    
    // Logout
    await page.click('.user-menu');
    await page.click('text=Logout');
    
    // Verify redirect to login page
    await expect(page).toHaveURL('/login');
    
    // Login with created account
    await page.fill('input[name="email"]', testEmail);
    await page.fill('input[name="password"]', 'SecurePassword123!');
    await page.click('button[type="submit"]');
    
    // Verify login success
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('.user-menu')).toContainText('Test User');
  });
});
```

### API Contract Tests

API contract tests validate that services adhere to their defined API contracts.

**Standards:**
- **Coverage Requirement**: All public API endpoints must be covered
- **Framework**: Pact for contract testing
- **Implementation**:
  - Define contracts between consumers and providers
  - Verify that providers fulfill the contract expectations
  - Run as part of the CI pipeline before deployment

### Performance Tests

Performance tests evaluate system behavior under load.

**Standards:**
- **Tool**: k6 for load testing
- **Implementation**:
  - Define baseline performance requirements
  - Test API endpoints under expected load
  - Measure response times, error rates, and resource usage
  - Run periodically and before major releases

### Security Tests

Security tests identify potential vulnerabilities in the application.

**Standards:**
- **Tools**: OWASP ZAP for automated scanning
- **Implementation**:
  - Regular automated scans for common vulnerabilities
  - Manual penetration testing for critical components
  - Dependency scanning for security issues

## Test Environment Strategy

### Local Development Testing

- Developers run unit tests and targeted integration tests locally
- Use Docker Compose or local databases for integration tests
- Pre-commit hooks enforce test execution before pushing

### CI/CD Pipeline Testing

- **GitHub Actions**:
  1. Run linting and code formatting checks
  2. Execute unit tests for all services
  3. Run integration tests using containerized dependencies
  4. Build Docker images for deployment
  5. Deploy to staging environment
  6. Run E2E tests against staging
  7. Deploy to production (after approval)

## Test Data Management

- Integration tests use isolated test databases
- Test data is generated programmatically with factories
- Sensitive test data is never stored in repositories
- E2E tests create and clean up their own test data

## Testing Tools and Libraries

### Backend
- **Testing Framework**: Jest
- **API Testing**: Supertest
- **Database Testing**: testcontainers, prisma-test-environment
- **Mocking**: Jest mocks, mock-service-worker
- **Coverage**: Istanbul (built into Jest)

### Frontend
- **Component Testing**: Vitest or Jest with React Testing Library
- **E2E Testing**: Playwright
- **API Mocking**: mock-service-worker (MSW)
- **Visual Regression**: Percy or Chromatic

### DevOps
- **CI/CD**: GitHub Actions
- **Load Testing**: k6
- **Security Testing**: OWASP ZAP, Snyk

## Continuous Improvement

- Regular review of test coverage and quality
- Post-incident analysis to identify testing gaps
- Quarterly security testing exercises
- Performance test baseline reviews

## Reporting and Monitoring

- Test results published to GitHub Actions dashboard
- Coverage reports generated and stored
- Performance test results compared against baselines
- Security scan results tracked over time 