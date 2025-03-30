# Technical Standards

## Technology Stack

### Frontend
- **Framework**: Next.js (React)
- **Language**: TypeScript
- **Styling**: TailwindCSS
- **State Management**: React Context + React Query
- **Testing**: Jest, React Testing Library
- **Build Tools**: Webpack (via Next.js)

### Backend
- **Framework**: Express.js
- **Language**: TypeScript
- **API Format**: REST with OpenAPI specification
- **ORM**: Prisma
- **Testing**: Jest, Supertest
- **Runtime**: Node.js (min v16.x)

### Infrastructure
- **Cloud Provider**: AWS
- **Compute**: Lambda, ECS (for long-running processes)
- **Database**: PostgreSQL (RDS)
- **Caching**: Redis (ElastiCache)
- **Storage**: S3
- **CDN**: CloudFront
- **API Gateway**: AWS API Gateway
- **IaC Tool**: AWS CDK (TypeScript)

### CI/CD
- **Platform**: GitHub Actions
- **Quality Gates**: ESLint, Prettier, TypeScript, Jest
- **Security Scanning**: Dependabot, CodeQL
- **Deployment Strategy**: Automated with environment promotion

## Coding Standards

### General
- Use TypeScript for all new code
- Follow functional programming principles where possible
- Keep functions small and focused
- Use early returns to avoid deep nesting
- Minimize side effects
- Write unit tests for business logic
- Document public APIs

### Naming Conventions
- **Files**: kebab-case for files (e.g., `user-service.ts`)
- **Classes**: PascalCase (e.g., `UserService`)
- **Functions/Methods**: camelCase (e.g., `getUserById`)
- **Variables**: camelCase (e.g., `userData`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_ATTEMPTS`)
- **Interfaces/Types**: PascalCase with prefix I for interfaces (e.g., `IUserData`)
- **Components**: PascalCase (e.g., `UserProfile`)
- **Event Handlers**: prefixed with 'handle' (e.g., `handleSubmit`)

### File Structure

#### Backend Services
```
service-name/
├── src/
│   ├── config/           # Configuration files
│   ├── controllers/      # Request handlers
│   ├── middlewares/      # Express middlewares
│   ├── models/           # Data models
│   ├── services/         # Business logic
│   ├── utils/            # Utility functions
│   ├── routes/           # API route definitions
│   ├── types/            # TypeScript type definitions
│   └── app.ts            # Application entry point
├── prisma/               # Prisma schema and migrations
├── tests/                # Test files
├── .eslintrc.js          # ESLint configuration
├── .prettierrc           # Prettier configuration
├── tsconfig.json         # TypeScript configuration
├── jest.config.js        # Jest configuration
└── package.json          # Dependencies and scripts
```

#### Frontend Applications
```
app-name/
├── public/               # Static assets
├── src/
│   ├── components/       # React components
│   │   ├── common/       # Shared components
│   │   └── [feature]/    # Feature-specific components
│   ├── hooks/            # Custom React hooks
│   ├── pages/            # Next.js pages
│   ├── services/         # API clients
│   ├── styles/           # Global styles
│   ├── types/            # TypeScript type definitions
│   └── utils/            # Utility functions
├── tests/                # Test files
├── .eslintrc.js          # ESLint configuration
├── .prettierrc           # Prettier configuration
├── tsconfig.json         # TypeScript configuration
├── jest.config.js        # Jest configuration
├── next.config.js        # Next.js configuration
└── package.json          # Dependencies and scripts
```

## API Standards

### REST Conventions
- Use plural nouns for resource endpoints (e.g., `/users`)
- Use HTTP methods appropriately (GET, POST, PUT, DELETE)
- Use appropriate status codes (200, 201, 204, 400, 401, 403, 404, 500)
- Version APIs in the URL (e.g., `/v1/users`)
- Implement pagination for list endpoints
- Use query parameters for filtering and sorting
- Use JSON for request and response bodies
- Implement HATEOAS links where appropriate

### Response Format
```json
{
  "data": {},            // Primary response data
  "meta": {              // Metadata (pagination, etc.)
    "page": 1,
    "perPage": 10,
    "totalPages": 5,
    "totalCount": 42
  },
  "links": {             // HATEOAS links
    "self": "/v1/users?page=1",
    "next": "/v1/users?page=2",
    "prev": null
  }
}
```

### Error Format
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "The requested resource was not found",
    "details": []
  }
}
```

## Security Standards

### Authentication
- Use JWT for stateless authentication
- Implement refresh token rotation
- Store tokens securely (HttpOnly cookies where possible)
- Set appropriate token expiration times
- Implement MFA for sensitive operations

### API Security
- Implement CORS with appropriate restrictions
- Use HTTPS for all communications
- Rate limit API endpoints
- Validate all inputs
- Sanitize all outputs
- Implement audit logging for security events
- Use prepared statements for database queries

### Data Protection
- Encrypt sensitive data at rest
- Use parameterized queries to prevent SQL injection
- Hash passwords using bcrypt with appropriate cost factor
- Implement proper error handling without leaking system information
- Follow principle of least privilege for database users

## Database Standards

### Schema Design
- Use snake_case for table and column names
- Define foreign key constraints
- Create indexes for frequently queried columns
- Use appropriate data types
- Implement soft deletes where appropriate
- Include created_at and updated_at timestamps

### Migrations
- Use Prisma migrations for schema changes
- Make migrations idempotent when possible
- Include both up and down migrations
- Test migrations before applying to production
- Back up database before applying migrations

## Testing Standards

### Unit Testing
- Test all business logic
- Use mocks for external dependencies
- Aim for high coverage of critical paths
- Follow AAA pattern (Arrange, Act, Assert)

### Integration Testing
- Test API endpoints
- Test database interactions
- Mock external services

### End-to-End Testing
- Test critical user flows
- Use Cypress or similar tool
- Include smoke tests for production deployments

## Documentation Standards

### Code Documentation
- Document complex algorithms
- Use JSDoc for public API functions
- Keep comments updated with code changes

### API Documentation
- Use OpenAPI Specification (formerly Swagger)
- Document all endpoints, parameters, and responses
- Include examples
- Document error codes and responses

### Repository Documentation
- Include README with setup instructions
- Document architecture decisions
- Include contribution guidelines
- Document deployment process 