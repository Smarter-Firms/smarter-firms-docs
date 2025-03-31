# Service Teams Standardization Tasks

## Overview

This document outlines the required tasks for all service teams to integrate with the standardized components being developed by the UI-Service, Infrastructure, and API Gateway teams. Completing these tasks will ensure consistent styling, streamlined deployment, and proper service integration across the platform.

## Required Actions for All Service Teams

Each service team must complete the following actions during the standardization period:

1. **UI & Styling Integration**
2. **AWS Development Environment Integration**
3. **API Standards Compliance**
4. **Testing and Verification**

## Timeline

| Phase | Sequence | Focus |
|-------|----------|-------|
| **Preparation** | Phase 1 (Week 1) | Review standards, plan integration work |
| **Implementation** | Phase 3 (Week 3) | Implement required changes |
| **Verification** | Phase 4, First Half (Week 4, Days 1-4) | Test and verify compliance |
| **Reporting** | Phase 4, Second Half (Week 4, Days 5-7) | Report status and resolve issues |

## Detailed Tasks by Category

### 1. UI & Styling Integration

| Task | Description | Priority | Sequence |
|------|-------------|----------|----------|
| **Tailwind Package Adoption** | Update your service to use the centralized Tailwind package | High | Step 1 (Phase 3, Days 1-3) |
| **Component Audit** | Identify custom styling that should be migrated | Medium | Step 2 (Phase 3, Days 1-2) |
| **Theme Implementation** | Apply standardized theme variables | High | Step 3 (Phase 3, Days 3-5) |
| **Visual Testing** | Verify visual consistency | Medium | Step 4 (Phase 3, Days 5-7) |

#### Implementation Steps

1. Replace your local `tailwind.config.js` with a reference to the shared package:

```javascript
// tailwind.config.js
const sharedConfig = require('@smarter-firms/tailwind-config');

module.exports = sharedConfig({
  // Service-specific overrides (if allowed)
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
    // Add your service-specific content paths
  ]
});
```

2. Update any hardcoded color values or styling to use theme variables
3. Verify component appearance matches the design system
4. Report any issues or special needs to the UI-Service team

### 2. AWS Development Environment Integration

| Task | Description | Priority | Sequence |
|------|-------------|----------|----------|
| **CI/CD Pipeline Setup** | Configure your service's deployment pipeline | High | Step 1 (Phase 3, Days 1-4) |
| **Environment Configuration** | Update environment variables and secrets | High | Step 2 (Phase 3, Days 2-4) |
| **Service Registration** | Register with service discovery | High | Step 3 (Phase 3, Days 4-6) |
| **Integration Testing** | Verify proper deployment and operation | High | Step 4 (Phase 3, Day 7 - Phase 4, Day 2) |

#### Implementation Steps

1. Implement the provided GitHub Actions workflow template:

```yaml
# .github/workflows/deploy-to-dev.yml
name: Deploy to Dev Environment

on:
  push:
    branches: [ dev, feature/* ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      # Add the standard deployment steps (provided by Infrastructure team)
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2
          
      # Additional standard steps will be provided
```

2. Update environment configuration to use AWS Secrets Manager
3. Register your service with the service discovery mechanism
4. Perform integration tests to verify proper operation

### 3. API Standards Compliance

| Task | Description | Priority | Sequence |
|------|-------------|----------|----------|
| **API Audit** | Review existing APIs for compliance | High | Step 1 (Phase 3, Days 1-3) |
| **Standards Implementation** | Update APIs to follow standards | High | Step 2 (Phase 3, Days 3-6) |
| **OpenAPI Documentation** | Create/update OpenAPI specifications | Medium | Step 3 (Phase 3, Days 4-7) |
| **Authentication Integration** | Implement standardized auth flows | High | Step 4 (Phase 3, Days 5-7) |

#### Implementation Steps

1. Review your API endpoints against the standards document
2. Update request/response formats to match the standard:

```typescript
// Example response format
interface StandardResponse<T> {
  data: T;
  meta: {
    pagination?: {
      currentPage: number;
      pageSize: number;
      totalPages: number;
      totalItems: number;
    };
    requestId: string;
    timestamp: string;
  };
  links?: {
    self: string;
    next?: string;
    previous?: string;
  };
  errors?: Array<{
    code: string;
    message: string;
    detail?: string;
    path?: string;
    timestamp: string;
  }>;
}
```

3. Create or update OpenAPI specifications
4. Integrate with the standardized authentication flow

### 4. Testing and Verification

| Task | Description | Priority | Sequence |
|------|-------------|----------|----------|
| **Integration Testing** | Test service with other services | High | Step 1 (Phase 4, Days 1-3) |
| **UI Verification** | Verify visual consistency | Medium | Step 2 (Phase 4, Days 1-2) |
| **Performance Testing** | Verify performance meets standards | Medium | Step 3 (Phase 4, Days 2-4) |
| **Documentation Review** | Update service documentation | Medium | Step 4 (Phase 4, Days 3-5) |

#### Implementation Steps

1. Create integration tests with dependent services
2. Verify UI components render correctly
3. Perform performance testing against defined metrics
4. Update documentation to reflect changes

## Required Updates by Service Type

### Frontend Services

- Update to use shared Tailwind configuration
- Migrate from local component styling to shared theme
- Update API client to match new standards
- Implement authentication flow

### Backend Services

- Update API endpoints to follow standards
- Implement standardized error handling
- Configure service discovery registration
- Update deployment pipeline

### Data Services

- Implement standardized data pagination
- Update API formats to match standards
- Configure proper connection handling
- Implement observability standards

## Reporting and Support

- Daily check-ins during the implementation period
- Designated Slack channel for standardization questions
- Office hours with core teams (UI, Infrastructure, API Gateway)
- Standardization status report due at the end of Phase 4

## Success Criteria for Service Teams

- Service successfully deployed to AWS development environment
- UI components render consistently with design system
- APIs follow the documented standards
- Integration tests pass with other services
- Documentation updated to reflect changes

## AI Agent Instructions for Service Teams

```
You are a full-stack developer responsible for updating a microservice to comply with new standardization requirements.

CONTEXT:
- The service needs to adopt a centralized Tailwind configuration
- Deployment must be configured for the AWS development environment
- APIs must follow the new standards documentation
- Integration with other services must be verified

TASKS:
1. Update the Tailwind configuration to use the shared package
2. Configure the deployment pipeline for AWS
3. Update API endpoints to follow the standards
4. Create/update integration tests
5. Verify compliance with all standards

Follow the detailed instructions in the Service-Teams-Tasks.md document and consult with the core teams if you encounter issues.
```

## Getting Help

If your service team encounters challenges implementing these standards, there are several resources available:

1. **Documentation**: Comprehensive documentation is available in the central repository
2. **Office Hours**: Daily office hours are available with each core team
3. **Slack Channel**: #standardization-support channel for questions
4. **Technical Leads**: You can request 1:1 assistance from technical leads

We understand that each service has unique requirements, and we're committed to supporting your team through this standardization process. The goal is not just compliance, but improving the overall development experience and product quality. 