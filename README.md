# Smarter Firms Documentation

This repository serves as the central documentation hub for the Smarter Firms platform. It contains architecture documents, implementation guides, and service-specific documentation.

## Documentation Organization

Documentation is organized by service and cross-cutting concerns:

### Services

- [Auth Service](./auth-service/): Authentication and authorization implementation
- [API Gateway](./api-gateway/): API Gateway configuration and integration
- [UI Service](./ui-service/): Frontend components and user experience
- [Data Service](./data-service/): Multi-tenant data management
- [Clio Integration Service](./clio-integration/): Clio API integration
- [Account Billing Service](./account-billing-service/): Billing and subscription management
- [Common Models](./common-models/): Shared data models and schemas

### Cross-Cutting Concerns

- [Architecture](./architecture/): System-wide architecture and design
- [API Contracts](./api-contracts/): API specifications and contracts
- [Operations](./operations/): Development workflow, testing, and deployment
- [Project Management](./project-management/): Project planning and progress tracking

## Documentation Strategy

We follow a structured approach to documentation management:

1. **Single Source of Truth**: This repository is the authoritative source for all stable documentation
2. **Service References**: Each service repository contains references to this central documentation
3. **Work-in-Progress**: Draft documentation is maintained in service repositories until ready to be migrated here

For complete details on our documentation approach, see the [Documentation Strategy](./DOCUMENTATION-STRATEGY.md).

## Documentation Tools

This repository includes scripts to help maintain documentation:

- `identify-and-clean-duplicates.sh`: Identifies duplicate documentation across repositories
- `clean-all-duplicates.sh`: Removes duplicates and creates references to the central repository
- `complete-docs-reorganization.sh`: Performs a comprehensive reorganization of documentation

## Contributing

When contributing to this documentation:

1. Follow the documentation workflow described in the [Documentation Strategy](./DOCUMENTATION-STRATEGY.md)
2. Ensure your documentation is accurate, clear, and follows our formatting standards
3. Include diagrams, code examples, and links to related documentation where appropriate
4. Submit a PR for review before merging changes

## Getting Help

If you have questions about documentation or can't find what you need:

1. Check the [Documentation Strategy](./DOCUMENTATION-STRATEGY.md) for guidance on where specific types of documentation should live
2. Look at the service-specific README.md files for navigation to relevant docs
3. Reach out to the team for help with finding or creating documentation
