# Repository Setup Checklist

Use this checklist when setting up each new repository for the Smarter Firms project to ensure consistency across all components.

## Initial Repository Setup

- [ ] Create repository in GitHub organization with appropriate name
- [ ] Add description and topics to repository
- [ ] Configure branch protection rules for `main`
  - [ ] Require pull request reviews before merging
  - [ ] Require status checks to pass before merging
  - [ ] Require linear history
- [ ] Set up CODEOWNERS file to ensure proper review process
- [ ] Create README.md with repository description and quick start guide
- [ ] Add LICENSE file (MIT License)
- [ ] Configure GitHub repository settings
  - [ ] Disable squash/rebase merging, enable only merge commits
  - [ ] Enable automatic deletion of head branches
  - [ ] Enable vulnerability alerts

## Development Environment

- [ ] Create .gitignore file appropriate for the repository type
- [ ] Set up .editorconfig file for consistent formatting
- [ ] Configure ESLint and Prettier
  - [ ] .eslintrc.js with project standards
  - [ ] .prettierrc with project standards
  - [ ] Add lint and format scripts to package.json
- [ ] Configure TypeScript (for TS repositories)
  - [ ] tsconfig.json with project standards
  - [ ] Include necessary type definitions
- [ ] Create VS Code workspace settings (.vscode/settings.json)
  - [ ] Configure recommended extensions
  - [ ] Add debugging configurations

## CI/CD Configuration

- [ ] Set up GitHub Actions workflows
  - [ ] Lint and test workflow on pull requests
  - [ ] Build workflow on pull requests
  - [ ] Deploy workflow for staging on merge to develop
  - [ ] Deploy workflow for production on merge to main
- [ ] Configure status checks in branch protection
- [ ] Set up CodeQL security scanning
- [ ] Configure Dependabot
- [ ] Set up code coverage reporting
- [ ] Add workflow badges to README.md

## Backend Repositories

- [ ] Initialize Node.js project
  - [ ] package.json with appropriate dependencies
  - [ ] Configure scripts (dev, build, test, lint, etc.)
  - [ ] Set up directory structure following standards
- [ ] Configure testing framework (Jest)
  - [ ] jest.config.js
  - [ ] Setup test directory structure
  - [ ] Add example tests
- [ ] Set up database connection (if applicable)
  - [ ] Configure Prisma
  - [ ] Create initial schema.prisma
  - [ ] Set up migrations
- [ ] Configure environment variables
  - [ ] .env.example file
  - [ ] .env file (added to .gitignore)
  - [ ] Environment validation logic
- [ ] Add Docker configuration
  - [ ] Dockerfile
  - [ ] .dockerignore
  - [ ] docker-compose.yml for local development
- [ ] Set up API documentation
  - [ ] OpenAPI/Swagger configuration
  - [ ] Documentation generation script

## Frontend Repositories

- [ ] Initialize Next.js project
  - [ ] Configure project settings
  - [ ] Set up directory structure following standards
- [ ] Configure TailwindCSS
  - [ ] tailwind.config.js with project theme
  - [ ] Add necessary plugin configurations
- [ ] Set up component structure
  - [ ] Create common components directory
  - [ ] Add component templates
- [ ] Configure state management
  - [ ] Set up React Context providers
  - [ ] Configure React Query (if applicable)
- [ ] Set up routing and layouts
- [ ] Configure testing framework
  - [ ] Jest + React Testing Library
  - [ ] Add example component tests
- [ ] Configure image and asset handling
- [ ] Set up internationalization (if needed)
- [ ] Add accessibility testing
- [ ] Configure build optimization
  - [ ] Next.js performance settings
  - [ ] Bundle analysis configuration

## Infrastructure Repositories

- [ ] Configure AWS CDK
  - [ ] Set up TypeScript config
  - [ ] Create stack definitions
  - [ ] Set up environment configurations
- [ ] Create CI/CD deployment script
- [ ] Configure AWS resource definitions
  - [ ] Network resources
  - [ ] Compute resources
  - [ ] Database resources
  - [ ] Storage resources
- [ ] Set up monitoring and logging
- [ ] Configure backup and disaster recovery
- [ ] Document infrastructure architecture

## Documentation

- [ ] Complete README.md with detailed information
  - [ ] Project overview
  - [ ] Architecture diagram
  - [ ] Setup instructions
  - [ ] Development workflow
  - [ ] Testing strategy
  - [ ] Deployment process
- [ ] Add API/component documentation
- [ ] Create CONTRIBUTING.md with contribution guidelines
- [ ] Document integration points with other repositories
- [ ] Add architecture decision records (ADRs) for major decisions

## Security

- [ ] Review for hardcoded secrets/credentials
- [ ] Implement security best practices
  - [ ] Input validation
  - [ ] Content security policies
  - [ ] CORS configuration
  - [ ] Rate limiting
- [ ] Configure authentication mechanisms
- [ ] Set up authorization rules
- [ ] Document security considerations

## Final Checks

- [ ] Verify all configuration files are committed
- [ ] Ensure CI/CD pipeline works correctly
- [ ] Confirm development environment setup works
- [ ] Test complete workflows end-to-end
- [ ] Review documentation completeness
- [ ] Create initial release/tag 