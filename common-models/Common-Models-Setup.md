# Common-Models Package Setup

The Clio Integration Service depends on the `@smarter-firms/common-models` package, which contains shared data types, validation schemas, and utilities used across the Smarter Firms platform. This document explains how to set up and use this package during development and deployment.

## Local Development Setup

For local development, we use a workspace-based approach to reference the Common-Models package directly from the local filesystem. This allows you to make changes to both packages simultaneously without publishing intermediary versions.

### Step 1: Clone the Common-Models Repository

```bash
# Navigate to your development directory (same parent as clio-integration-service)
cd /path/to/your/dev/directory

# Clone the common-models repository
git clone https://github.com/smarter-firms/common-models.git
```

### Step 2: Configure Package Resolution

The Clio Integration Service's `package.json` already includes a resolution configuration that points to the local copy of the Common-Models package:

```json
"resolutions": {
  "@smarter-firms/common-models": "portal:../common-models"
}
```

This tells npm/yarn to use the local version of the package instead of trying to download it from the registry.

### Step 3: Install Dependencies

When installing dependencies, use the `--force` flag to ensure proper resolution:

```bash
npm install --force
# or with yarn
yarn install --force
```

## Using Common-Models Types and Schemas

Once set up, you can import and use types, schemas, and utilities from the package:

```typescript
// Import types
import { ClioMatter, ClioContact, WebhookEvent } from '@smarter-firms/common-models';

// Import validation schemas
import { matterSchema, contactSchema } from '@smarter-firms/common-models/schemas';

// Import utilities
import { transformClioData } from '@smarter-firms/common-models/utils';

// Example usage
function processMatter(data: unknown): ClioMatter {
  // Validate incoming data
  const validatedData = matterSchema.parse(data);
  
  // Transform data if needed
  const transformedData = transformClioData(validatedData);
  
  return transformedData;
}
```

## CI/CD Pipeline Integration

In CI/CD environments, we use a different approach since the filesystem structure differs from local development.

### Option 1: Private NPM Registry

In production builds, we use a private NPM registry to host the Common-Models package:

1. Make sure your CI/CD pipeline has access to the private registry
2. Configure npm authentication in your CI pipeline:

```yaml
steps:
  - name: Setup NPM auth
    run: |
      echo "//npm.smarter-firms.com/:_authToken=${{ secrets.NPM_TOKEN }}" > .npmrc
```

3. Update the package.json for production builds to use the registry version:

```json
"dependencies": {
  "@smarter-firms/common-models": "^1.0.0"
}
```

### Option 2: GitHub Packages

Alternatively, you can use GitHub Packages to host the Common-Models package:

1. Configure authentication for GitHub Packages:

```yaml
steps:
  - name: Setup GitHub Packages auth
    run: |
      echo "//npm.pkg.github.com/:_authToken=${{ secrets.GITHUB_TOKEN }}" > .npmrc
      echo "@smarter-firms:registry=https://npm.pkg.github.com" >> .npmrc
```

## Troubleshooting

### Module Not Found Errors

If you encounter "Cannot find module '@smarter-firms/common-models'" errors:

1. Verify your directory structure:
   ```
   /path/to/dev/
   ├── common-models/
   └── clio-integration-service/
   ```

2. Check that Common-Models is built:
   ```bash
   cd ../common-models
   npm run build
   ```

3. Try reinstalling dependencies with the force flag:
   ```bash
   npm install --force
   ```

### Type Errors

If you get TypeScript errors related to Common-Models types:

1. Check versions compatibility between the packages
2. Run `npm run db:generate` to ensure Prisma types are up to date
3. Make sure TypeScript configuration includes the proper paths

## Keeping Common-Models Updated

When updating the Common-Models package:

1. Pull latest changes from the Common-Models repository
2. Build the package: `cd ../common-models && npm run build`
3. Restart your development server to pick up the changes 