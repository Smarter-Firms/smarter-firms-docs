# Contributing to Clio Integration Service

Thank you for considering contributing to the Clio Integration Service! This document provides guidelines and instructions for contributing to the project.

## Development Setup

### Prerequisites

- Node.js v18+
- npm or yarn
- PostgreSQL
- Redis
- A Clio developer account (for API access)

### Setup Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/smarter-firms/clio-integration-service.git
   cd clio-integration-service
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up environment variables:**
   ```bash
   cp .env.example .env
   ```
   Then edit the `.env` file to set up your local configuration.

4. **Set up the database:**
   ```bash
   npm run db:migrate
   ```

5. **Start Redis:**
   Make sure Redis is running on your machine or via Docker:
   ```bash
   docker run -d -p 6379:6379 redis:6
   ```

6. **Start the development server:**
   ```bash
   npm run dev
   ```

## Development Workflow

### Branching Strategy

- `main` - Production-ready code
- `dev` - Development branch for integration
- Feature branches - For new features and fixes

Always create a new branch based on `dev` for your work:
```bash
git checkout dev
git pull
git checkout -b feature/your-feature-name
```

### Code Quality

Before committing your changes, make sure to:

1. **Lint your code:**
   ```bash
   npm run lint
   ```

2. **Run type checking:**
   ```bash
   npx tsc --noEmit
   ```

3. **Run tests:**
   ```bash
   npm test
   ```

### Pull Request Process

1. Push your changes to your feature branch
2. Create a pull request against the `dev` branch
3. Fill out the PR template with:
   - Description of changes
   - Link to related issue
   - Any breaking changes
   - Screenshots (if applicable)
4. Request reviews from team members
5. Address review comments

## Testing

### Test Structure

- Unit tests: Test individual components in isolation
- Integration tests: Test interaction between components
- End-to-end tests: Test complete workflows

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### Testing the Webhook Components

To test webhook functionality, you'll need:

1. A running instance of the application
2. A tunnel to the internet (e.g., using ngrok)
3. A Clio developer account with webhook permissions

See [Testing-Webhooks.md](./docs/Testing-Webhooks.md) for detailed instructions.

## Webhook Metrics Dashboard

To run the webhook metrics dashboard:

```bash
npm run webhook:dashboard
```

This will start a terminal-based dashboard that shows real-time webhook metrics.

## API Documentation

The API documentation is available at `/api-docs` when running the service. It is generated from OpenAPI specifications.

## Deployment

The CI/CD pipeline automatically deploys:
- The `dev` branch to the development environment
- The `main` branch to the production environment

For manual deployment, follow these steps:

1. Build the application:
   ```bash
   npm run build
   ```

2. Deploy the `dist` directory to your server.

## Troubleshooting

### Common Issues

- **Missing Dependencies:** If you see module not found errors, try running `npm install` again.
- **Database Connection Issues:** Check your PostgreSQL connection settings in `.env`.
- **Redis Connection Issues:** Ensure Redis is running and accessible.
- **Webhook Errors:** Check the webhook logs and make sure your ngrok URL is properly set up.

### Getting Help

If you encounter any issues, please:
1. Check the existing issues on GitHub
2. Ask in the team Slack channel
3. Create a new issue with detailed information

## License

The project is licensed under the UNLICENSED license. See the LICENSE file for details. 