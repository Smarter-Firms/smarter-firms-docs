# Smarter Firms Documentation Strategy

This document outlines our approach to documentation across the Smarter Firms platform to maintain consistency, avoid duplication, and ensure all team members can find the information they need.

## Documentation Structure

Our documentation is organized into a clear hierarchy:

### 1. Central Documentation Repository (`smarter-firms-docs`)

This is the single source of truth for all finalized documentation. It contains:

- System-wide architecture documentation
- Cross-service integration patterns
- Shared technical standards and guidelines
- Service-specific documentation in dedicated folders

### 2. Service Repositories

Service repositories should contain:

- README.md with basic setup instructions
- In-progress documentation (drafts)
- Code-specific documentation (API endpoints, etc.)
- Implementation notes that are likely to change frequently

## Documentation Workflow

1. **Initial Documentation Creation**:
   - New documentation should be drafted in the service repository
   - Use a `docs/` folder at the root of the service repository

2. **Review and Stabilization**:
   - Documentation is reviewed as part of the PR process
   - Once the documented feature is stabilized, the documentation should be considered for promotion

3. **Promotion to Central Repository**:
   - Documentation that is valuable across teams should be moved to the central repository
   - Create a PR against the `smarter-firms-docs` repository
   - Remove duplicated content from the service repository and add a reference to the central docs

4. **Maintenance**:
   - Updates to existing documentation should be made in the central repository
   - When significant changes are made to a service that affects its documentation, update both the service repo docs and central docs accordingly

## Documentation Categories

| Type | Location | Examples |
|------|----------|----------|
| Architecture | Central Repo | System diagrams, service boundaries |
| API Contracts | Central Repo | Interface definitions, OpenAPI specs |
| Implementation Guides | Central Repo | Security implementation, multi-tenant patterns |
| Setup Instructions | Service Repo | Environment setup, local development |
| Code-level Documentation | Service Repo | Function documentation, class structure |
| Work-in-progress | Service Repo | Feature documentation during development |

## Avoiding Duplication

1. **Use References**: Instead of duplicating content, reference the canonical documentation
2. **Clear Ownership**: Each document should have a clear owner responsible for updates
3. **Regular Cleanup**: Periodically audit documentation to remove outdated or duplicated content

## Documentation Format

1. All documentation should be written in Markdown
2. Use diagrams (Mermaid, PlantUML) for visual explanations
3. Include code examples where appropriate
4. Follow a consistent structure with clear headings

## Documentation Review

All documentation PRs should be reviewed for:

1. Technical accuracy
2. Clarity and comprehensiveness
3. Proper placement in the documentation hierarchy
4. Avoidance of duplication

## Special Considerations

### API Documentation

- OpenAPI/Swagger specifications should be maintained in the service repositories
- The compiled API documentation should be published to the central repository

### Architecture Decision Records (ADRs)

- ADRs should always be stored in the central repository
- ADRs should never be modified once approved (only new ADRs should be added)

## Recommendation for Current State

1. Audit all service repositories for valuable documentation
2. Move stable, cross-team documentation to the central repository
3. Remove duplicated content from service repositories
4. Update READMEs to point to the central documentation 