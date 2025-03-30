# Documentation Repository Guidelines

## Repository Access

The central documentation repository is located at:
https://github.com/Smarter-Firms/smarter-firms-docs

You have been granted appropriate access permissions to this repository based on your team's responsibilities.

## Basic Workflow

1. Clone the repository:
   ```bash
   git clone https://github.com/Smarter-Firms/smarter-firms-docs.git
   cd smarter-firms-docs
   ```

2. Create a branch for your changes:
   ```bash
   git checkout -b your-team/feature-description
   ```

3. Add or update documentation in your team's folder:
   - Auth Service team: `/auth-service/`
   - API Gateway team: `/api-gateway/`
   - UI Service team: `/ui-service/`
   - Data Service team: `/data-service/`

4. Commit and push your changes:
   ```bash
   git add .
   git commit -m "descriptive message about your changes"
   git push origin your-team/feature-description
   ```

5. Create a pull request on GitHub for review.

## Documentation Standards

- Use Markdown format for all documentation
- Include diagrams using Mermaid syntax where helpful:
  ```mermaid
  graph TD
      A[Start] --> B[Process]
      B --> C[End]
  ```
- Follow the style guide in CONTRIBUTING.md
- Cross-reference other documents using relative links

## Required Documentation

Each team must maintain the following documentation:

1. **README.md** - Overview of your service
2. **API.md** - API endpoints and contracts
3. **Architecture.md** - Service architecture and patterns
4. **Security.md** - Security considerations and implementations
5. **Integration.md** - Integration points with other services

## Updating Cross-Cutting Documentation

For changes to architecture, API contracts, or security documentation:
1. Discuss the changes with other teams first
2. Create a pull request and request reviews from all affected teams

## Finding Documentation

To locate documentation from other teams, navigate to their folder in the repository.
You can search within the repository using GitHub's search functionality.
