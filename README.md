# Smarter Firms Documentation

Welcome to the central documentation repository for the Smarter Firms platform. This repository serves as the single source of truth for all stabilized documentation across our microservices architecture.

## Documentation Structure

The documentation is organized by service and cross-cutting concerns:

- **[api-contracts](./api-contracts/)** - Interface definitions between services
- **[api-gateway](./api-gateway/)** - API Gateway documentation
- **[architecture](./architecture/)** - System-wide architecture documentation
- **[auth-service](./auth-service/)** - Authentication service documentation
- **[data-service](./data-service/)** - Data access service documentation
- **[operations](./operations/)** - Development workflow and operational procedures
- **[security](./security/)** - Security standards and implementation details
- **[ui-service](./ui-service/)** - Frontend service documentation

## Documentation Strategy

This repository follows a specific documentation strategy to maintain consistency and avoid duplication across our services. For details on how documentation should be managed, please refer to the [Documentation Strategy](./DOCUMENTATION-STRATEGY.md) document.

Key principles:
- This repository is the single source of truth for stabilized documentation
- Service repositories should reference this central repository
- Documentation should first be drafted in service repositories before being promoted here
- All cross-service documentation belongs here

## Contributing

If you want to contribute to this documentation repository, please follow these steps:

1. Review the [Documentation Strategy](./DOCUMENTATION-STRATEGY.md)
2. Create a branch for your changes
3. Make your updates
4. Submit a pull request
5. Update references in service repositories if needed

For more details, see the [Contributing Guide](./CONTRIBUTING.md).

## Getting Started

New team members should start with the following documentation:

1. [System Architecture](./architecture/System-Architecture.md)
2. [Technical Standards](./architecture/Technical-Standards.md)
3. [Development Workflow](./operations/Development-Workflow.md)
4. Service-specific documentation for your assigned service
