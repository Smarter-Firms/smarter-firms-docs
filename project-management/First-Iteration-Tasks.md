# First Iteration Tasks for AI Agent

## Overview

This document outlines the first set of tasks to be assigned to the AI agent for implementation. These tasks are focused on establishing the foundational components of the Auth Service, which is the first priority service in our implementation order.

## Tasks

### Task 1: Set up Auth Service Project Structure

**Description:**
Create the basic project structure for the Auth Service, including setting up TypeScript, Express, and the necessary configuration files.

**Requirements:**
- Initialize a new Node.js project with TypeScript
- Set up Express.js with middleware for JSON parsing, CORS, etc.
- Configure environment variables using dotenv
- Implement a basic server that listens on the configured port
- Set up a proper folder structure following best practices
- Configure ESLint and Prettier for code quality
- Set up Jest for testing
- Create a README.md with setup and usage instructions

**Expected Deliverables:**
- Complete project skeleton with proper structure
- Working Express server that responds to a basic health check endpoint
- Documentation for setup and development

### Task 2: Implement Prisma Schema for User Management

**Description:**
Define the Prisma schema for user management, including tables for users, roles, and permissions.

**Requirements:**
- Set up Prisma ORM with PostgreSQL
- Define User model with fields for:
  - ID, email, password, first name, last name, created at, updated at
  - Email verification status
  - Account status (active, suspended, etc.)
- Define Role model for role-based access control
- Define Permission model for granular permissions
- Create relationships between User, Role, and Permission models
- Create seed data script for initial roles and permissions
- Implement database migrations for the schema

**Expected Deliverables:**
- Prisma schema file with all required models
- Migration scripts
- Seed data script
- Documentation on the database schema

### Task 3: Implement User Registration Endpoint

**Description:**
Create an API endpoint for user registration that validates input data and creates a new user in the database.

**Requirements:**
- Implement POST /api/v1/auth/register endpoint
- Use Zod for request validation
- Hash passwords securely using bcrypt
- Validate unique email addresses
- Generate an email verification token
- Proper error handling and response formatting
- Unit and integration tests

**Expected Deliverables:**
- Implementation of the registration endpoint
- Input validation logic
- Password hashing logic
- Tests for various scenarios
- Documentation for the endpoint

### Task 4: Implement User Login Endpoint with JWT

**Description:**
Create an API endpoint for user login that validates credentials and issues JWT tokens.

**Requirements:**
- Implement POST /api/v1/auth/login endpoint
- Validate user credentials against the database
- Generate JWT access token with appropriate expiration
- Generate JWT refresh token with longer expiration
- Include user data in the response (excluding sensitive information)
- Proper error handling and response formatting
- Unit and integration tests

**Expected Deliverables:**
- Implementation of the login endpoint
- JWT token generation logic
- Tests for various scenarios
- Documentation for the endpoint

## Implementation Guidelines

1. Follow the project's coding standards and practices
2. Ensure all code is typed properly with TypeScript
3. Write unit tests for all business logic
4. Write integration tests for API endpoints
5. Document all functions, classes, and endpoints
6. Follow the API response format specified in the API Contracts document
7. Ensure error handling is consistent and comprehensive
8. Use the repository pattern for database operations
9. Implement dependency injection for better testability
10. Follow security best practices, especially for authentication

## Resources

- API Contracts document for response formats
- System Architecture document for overall architecture
- Data Model document for database design
- Technical Standards document for coding standards
- Development Workflow document for contribution guidelines
- Testing Strategy document for testing approach

## Timeline

These tasks should be completed within 1 week, with daily progress updates.

## Acceptance Criteria

- Code follows project standards and passes all linting checks
- All tests pass with at least 80% code coverage
- API endpoints adhere to the defined API contracts
- Documentation is complete and accurate
- The implementation is secure, following best practices for authentication
- The code is reviewed and approved by at least one team member

## Next Steps After Completion

Once these tasks are completed, the next focus will be on:
1. Implementing token refresh endpoints
2. Adding user profile management
3. Implementing password reset functionality 