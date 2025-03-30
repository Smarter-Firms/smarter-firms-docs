# Smarter Firms Documentation Strategy

## Core Principles

1. **Single Source of Truth** - All stable documentation lives in the central documentation repository (`smarter-firms-docs`).
2. **Clear References** - Service repositories reference documentation in the central repository.
3. **Draft in Service Repos** - Work-in-progress documentation can be maintained in service repositories until stabilized.
4. **Consistent Structure** - Documentation is organized consistently across all repositories.
5. **Automation** - Scripts automate common documentation tasks (like finding duplicates).

## Documentation Workflow

### 1. Draft Phase
- Create initial documentation in your service's `docs/` directory
- Use Markdown format with proper headings and structure
- Include code examples and diagrams as needed

### 2. Review Phase
- Include documentation review as part of PR reviews
- Refine documentation based on feedback
- Keep documentation in your service repo until stabilized

### 3. Stabilization Phase
- When a feature is complete and documentation is stabilized:
  - Create a PR to move it to the central docs repository
  - Place it in the appropriate folder (e.g., `/auth-service/`, `/api-gateway/`)
  - Update your service's `docs/README.md` to reference the central docs

### 4. Maintenance Phase
- All future updates should be made to the central docs
- Reference central docs from service READMEs and code

## File Structure

### Central Documentation Repository
- `architecture/` - System-wide architecture documents
- `operations/` - DevOps, workflows, and processes
- `api-contracts/` - API specifications and contracts
- `<service-name>/` - Service-specific documentation
- `DOCUMENTATION-STRATEGY.md` - This file
- `README.md` - Repository overview and navigation
- Helper scripts for documentation management

### Service Repositories
- `docs/README.md` - References to central documentation
- `docs/<file>.md` - Work-in-progress documentation only

## Documentation Standards

1. **Format** - Use Markdown for all documentation
2. **Diagrams** - Use Mermaid or PlantUML for diagrams
3. **Code Examples** - Include fully functional, tested code examples
4. **Links** - Use relative links within the repository, GitHub URLs for cross-repository links
5. **Headers** - Use consistent header levels and naming
6. **Tables of Contents** - Include for documents longer than 2 screens

## Service-Specific Documentation Guidelines

### Auth Service
- Authentication flows with diagrams
- Security implementation details
- API authentication documentation
- Integration guides for other services

### API Gateway
- Service integration guides
- Security measures and configurations
- Rate limiting and caching strategies
- Deployment procedures

### UI Service
- Component documentation with examples
- Authentication UI flows
- Firm context management
- Responsive design guidelines

### Data Service
- Multi-tenant implementation details
- Repository pattern implementation
- Row-level security guidelines
- Query optimization guidelines
- Caching strategies

### Clio Integration Service
- Clio API documentation
- Webhook handling procedures
- OAuth implementation details
- Data synchronization strategies

### Account Billing Service
- Billing models documentation
- Payment processing details
- Subscription management
- Integration with Auth Service

### Common Models
- Model definitions and schema documentation
- Versioning guidelines
- Type system documentation
- Migration guides

## Documentation Tools

The central documentation repository includes scripts to help maintain documentation:

- `identify-and-clean-duplicates.sh` - Find duplicate docs
- `clean-all-duplicates.sh` - Remove duplicates and add reference READMEs
- `complete-docs-reorganization.sh` - Comprehensive documentation reorganization

## Best Practices

1. **Update Documentation with Code Changes** - When code changes, update docs
2. **Cross-Reference** - Link related documentation
3. **Use Templates** - Follow standard templates for common doc types
4. **Versioning** - Indicate compatibility with software versions
5. **Keep History** - Maintain a changelog for significant doc changes
6. **Review Process** - Include documentation in code reviews
7. **Validate Links** - Ensure all links are valid
8. **Accessibility** - Ensure documentation is accessible to all users 