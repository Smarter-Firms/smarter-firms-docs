# Smarter Firms Development Workflow

This document outlines the development workflow for the Smarter Firms project, including branching strategy, code review process, and release management.

## Branching Strategy

We follow a modified Git Flow branching strategy:

### Main Branches

- **main**: Production-ready code that has been deployed to production
- **develop**: Integration branch for features, contains the latest development code

### Supporting Branches

- **feature/\***: Feature branches for new functionality
- **bugfix/\***: Branches for fixing bugs
- **hotfix/\***: Branches for critical production fixes
- **release/\***: Branches for preparing releases

### Branch Naming Conventions

- Feature branches: `feature/SF-{issue-number}-{short-description}`
  - Example: `feature/SF-123-implement-user-auth`
- Bugfix branches: `bugfix/SF-{issue-number}-{short-description}`
  - Example: `bugfix/SF-456-fix-login-validation`
- Hotfix branches: `hotfix/SF-{issue-number}-{short-description}`
  - Example: `hotfix/SF-789-fix-critical-security-issue`
- Release branches: `release/v{major}.{minor}.{patch}`
  - Example: `release/v1.2.0`

## Workflow Process

### Feature Development

1. **Create Branch**: Create a new feature branch from `develop`
   ```bash
   git checkout develop
   git pull
   git checkout -b feature/SF-123-implement-user-auth
   ```

2. **Implement Changes**: Make changes, following the coding standards

3. **Commit Changes**: Use conventional commit messages
   ```bash
   git add .
   git commit -m "feat(auth): implement user registration flow"
   ```

4. **Push Changes**: Push to remote repository
   ```bash
   git push -u origin feature/SF-123-implement-user-auth
   ```

5. **Create Pull Request**: Create a PR to merge into `develop`
   - Fill out the PR template
   - Assign reviewers
   - Link related issues

6. **Code Review**: Address feedback and make necessary changes

7. **Merge**: After approval, merge into `develop` (use squash merge)
   - Delete the feature branch after merging

### Bug Fixing

1. **Create Branch**: Create a bugfix branch from `develop`
   ```bash
   git checkout develop
   git pull
   git checkout -b bugfix/SF-456-fix-login-validation
   ```

2. **Fix Bug**: Implement the fix, including tests

3. **Follow**: Follow the same commit, push, PR, and review process as feature development

### Hotfix Process

1. **Create Branch**: Create a hotfix branch from `main`
   ```bash
   git checkout main
   git pull
   git checkout -b hotfix/SF-789-fix-critical-security-issue
   ```

2. **Implement Fix**: Fix the issue, including tests

3. **Create PR**: Create a PR to merge into both `main` and `develop`

4. **Deploy**: After approval, merge into `main` and deploy immediately
   - Also merge into `develop` to ensure the fix is included in future releases

### Release Process

1. **Create Branch**: Create a release branch from `develop`
   ```bash
   git checkout develop
   git pull
   git checkout -b release/v1.2.0
   ```

2. **Finalize**: Make final adjustments, update version numbers, and prepare release notes

3. **Create PR**: Create a PR to merge into `main`

4. **Deploy**: After approval, merge into `main` and tag the release
   ```bash
   git checkout main
   git pull
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
   ```

5. **Merge Back**: Merge changes back into `develop`

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation changes
- **style**: Changes that do not affect the meaning of the code (formatting, etc.)
- **refactor**: Code changes that neither fix a bug nor add a feature
- **perf**: Performance improvements
- **test**: Adding or fixing tests
- **chore**: Changes to the build process or auxiliary tools

### Scopes

Scopes should reference the area of the codebase being modified:

- **auth**: Authentication related changes
- **clio**: Clio integration related changes
- **billing**: Billing related changes
- **data**: Data service related changes
- **ui**: UI components and frontend changes
- **api**: API related changes
- **db**: Database schema changes
- **infra**: Infrastructure related changes

### Examples

```
feat(auth): implement JWT refresh token flow

- Add token refresh endpoint
- Implement token rotation for security
- Add tests for the refresh flow

Closes #123
```

```
fix(ui): resolve login form validation issues

Fixes a bug where the login form would submit even with invalid inputs.

Fixes #456
```

## Pull Request Process

### PR Template

```markdown
## Description
[Provide a brief description of the changes introduced by this PR]

## Related Issue
[Link to the related issue, e.g., Closes #123]

## Type of Change
- [ ] Feature (new functionality)
- [ ] Bug Fix (fixes an issue)
- [ ] Documentation Update
- [ ] Code Refactoring (no functional changes)
- [ ] Performance Improvement
- [ ] Test Addition/Update
- [ ] Infrastructure Change

## How Has This Been Tested?
[Describe the tests you ran to verify your changes]

## Screenshots (if applicable)
[Add screenshots here]

## Checklist
- [ ] My code follows the project's coding standards
- [ ] I have added tests that prove my fix/feature works
- [ ] All existing tests pass
- [ ] I have updated the documentation accordingly
- [ ] My changes generate no new warnings or errors
- [ ] I have checked for potential security issues
- [ ] I have considered the performance impact of my changes
```

### Code Review Guidelines

#### For Authors:

1. **Keep PRs Small**: Aim for focused changes that can be reviewed in under 30 minutes
2. **Self-Review**: Review your own code before submitting for review
3. **Tests**: Include relevant tests for your changes
4. **Documentation**: Update documentation affected by your changes
5. **Respond Promptly**: Address review comments in a timely manner

#### For Reviewers:

1. **Be Timely**: Aim to review PRs within 24 hours
2. **Be Constructive**: Provide specific, actionable feedback
3. **Consider**: Review for functionality, code quality, test coverage, and security
4. **Approve**: Only approve if the changes meet all requirements
5. **Be Thorough**: Don't rush reviews, quality is important

## Continuous Integration

All branches are subject to CI checks before merging:

1. **Linting**: Code style validation
2. **Type Checking**: TypeScript type checking
3. **Unit Tests**: Must pass all unit tests
4. **Integration Tests**: Must pass all integration tests
5. **Coverage**: Code coverage must meet minimum thresholds
6. **Security Scans**: Dependency vulnerability checks
7. **Build Verification**: Ensure the application builds successfully

## Deployment Process

### Environments

- **Development**: Automatic deployment from the `develop` branch
- **Staging**: Automatic deployment from `release/*` branches
- **Production**: Manual deployment from the `main` branch after approval

### Deployment Checklist

1. **Testing**: Verify all tests pass in the target environment
2. **Database**: Confirm database migrations are ready
3. **Dependencies**: Check for any new dependencies or updates
4. **Documentation**: Ensure documentation is updated
5. **Rollback Plan**: Have a plan for rollback if issues arise
6. **Monitoring**: Set up monitoring for the new changes

## Version Management

We use Semantic Versioning (SemVer) for version numbering:

- **Major (X.0.0)**: Incompatible API changes
- **Minor (0.X.0)**: New functionality in a backward-compatible manner
- **Patch (0.0.X)**: Backward-compatible bug fixes

## Release Cycle

- **Weekly Releases**: Regular feature releases every Thursday
- **Hotfixes**: As needed for critical issues
- **Major Releases**: Scheduled and communicated well in advance

## Documentation Requirements

- Each PR should update relevant documentation
- API changes must be reflected in the API documentation
- Significant changes should be documented in the changelog
- Architecture changes require updating architectural documentation

## Conflict Resolution

For technical disagreements:
1. Discuss in the PR comments
2. If unresolved, schedule a synchronous discussion
3. If still unresolved, escalate to the technical lead
4. Document the final decision and rationale

## Local Development Environment

### Prerequisites

- Node.js v16+ (v18 LTS recommended)
- PostgreSQL 14+
- Git
- VS Code (recommended editor)
- AWS CLI v2
- Docker & Docker Compose (for integration testing)

### Initial Setup

1. Clone the repository
2. Install dependencies: `npm install`
3. Copy `.env.example` to `.env` and configure
4. Run the database setup: `npm run db:setup`
5. Start the development server: `npm run dev`

### Environment Configuration

- Each repository should have an `.env.example` file with all required variables
- Third-party services (Mailgun, Twilio) should have their own configuration sections
- Local services use `localhost` connections
- AWS dev environment uses dedicated endpoints

### Testing Webhooks and OAuth Callbacks

For testing webhook endpoints and OAuth callbacks during local development, we use ngrok to create a secure tunnel to your local development environment.

#### Ngrok Configuration

We have a permanent ngrok URL for the project:

```
quality-foal-skilled.ngrok-free.app
```

To start ngrok and route traffic to your local server (e.g., on port 3000):

```bash
ngrok http --url=quality-foal-skilled.ngrok-free.app 3000
```

#### Usage with Services

1. **Stripe Webhooks**: Configure your local Account & Billing Service to receive webhooks through ngrok:
   - Webhook URL: `https://quality-foal-skilled.ngrok-free.app/api/webhooks/stripe`

2. **Clio OAuth**: Configure your local Clio Integration Service to use ngrok for OAuth callbacks:
   - Redirect URI: `https://quality-foal-skilled.ngrok-free.app/api/clio/oauth/callback`

3. **Testing API Endpoints**: Expose your local API through ngrok for testing with mobile devices or third-party tools:
   - Base URL: `https://quality-foal-skilled.ngrok-free.app/api`

Remember to update your local environment variables to use these URLs when testing with ngrok.

## Git Workflow

### Branching Strategy

We follow a modified GitFlow approach:

- `main` - Production-ready code
- `develop` - Integration branch for feature work
- `feature/*` - New features and non-emergency bug fixes
- `bugfix/*` - Bug fixes
- `hotfix/*` - Emergency fixes for production
- `release/*` - Release preparation

### Branch Naming

Use the following convention:
```
<type>/<issue-number>-<short-description>
```

Example: `feature/SF-123-implement-user-authentication`

### Commit Messages

Follow conventional commits format:
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example: `feat(auth): implement JWT refresh token mechanism`

## Code Review Process

### Pull Request Requirements

1. Create a PR from your feature branch to `develop`
2. Fill in the PR template with:
   - Description of changes
   - Link to related issues
   - Testing instructions
   - Screenshots (if applicable)
3. Assign at least one reviewer
4. Ensure CI checks pass

### Review Guidelines

- Review PRs within 24 hours when possible
- Use GitHub's review features for comments
- Address all comments before merging
- Require all CI checks to pass
- Use squash merging to keep history clean

## Testing Requirements

### Unit Testing

- Write unit tests for business logic
- Aim for 80%+ coverage of service and utility code
- Run tests before committing: `npm test`

### Integration Testing

- Test API endpoints with supertest
- Test database interactions with test database
- Run integration tests: `npm run test:integration`

### End-to-End Testing

- Test critical user flows
- Run in CI/CD pipeline for pull requests to `develop` and `main`

## Deployment Process

### Environments

- **Development**: Automatic deployments from `develop` branch
- **Staging**: Manual promotion from development
- **Production**: Manual promotion from staging

### Deployment Steps

1. Merge feature branches into `develop`
2. CI/CD deploys to development environment
3. Test in development environment
4. Create release branch when ready
5. Promote to staging for UAT
6. Merge to `main` when approved
7. Tag release with version number
8. CI/CD deploys to production

## Cross-Repository Development

### Dependency Management

- Use the same version of shared dependencies across repositories
- Document breaking changes in shared interfaces
- Version common packages semantically

### Coordination Workflow

1. Create issues in all affected repositories
2. Implement changes in shared code first
3. Update dependent repositories
4. Test changes together before merging

## Third-Party Integration Guidelines

### Mailgun Integration

- Implement in Auth-Service repository
- Use environment variables for API keys
- Create wrapper service with retry logic
- Implement email templates in separate files
- Log all email events

### Twilio Integration

- Implement in Auth-Service repository
- Use environment variables for credentials
- Create SMS service with rate limiting
- Implement message templates
- Log all SMS events

### Authenticator App Support

- Implement TOTP (Time-based One-Time Password) standard
- Support popular authenticator apps (Google Authenticator, Authy, etc.)
- Store secret keys securely
- Provide recovery codes during setup
- Allow fallback to SMS

## Troubleshooting

### Common Issues

- **Prisma Client Issues**: Run `npx prisma generate` after schema changes
- **Database Connection**: Verify PostgreSQL is running and credentials are correct
- **JWT Issues**: Check token expiration and secret configuration
- **AWS Credential Issues**: Run `aws configure` to set up credentials

### Logging

- Use structured logging (JSON format)
- Include request IDs in logs
- Log errors with stack traces
- Use different log levels appropriately (debug, info, warn, error)

## CI/CD Integration

### GitHub Actions

- Lint and test on pull requests
- Build and deploy on merge to `develop`