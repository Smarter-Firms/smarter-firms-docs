#!/bin/bash

# Script to remove all duplicate documents from service repositories
# that are now in the central documentation repository

echo "=== Removing Duplicates from All Service Repositories ==="
echo ""
echo "The following documents will be removed from service repositories"
echo "as they have been migrated to the central documentation repository."
echo ""

# Auth Service duplicates
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Authentication-Strategy.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Testing-Strategy.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Development-Workflow.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Consultant-Experience.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/API-Contracts.md 2>/dev/null

# API Gateway duplicates
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/System-Architecture.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/Testing-Strategy.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/Development-Workflow.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/API-Contracts.md 2>/dev/null

# UI Service duplicates
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Technical-Standards.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Testing-Strategy.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Development-Workflow.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/SSO-Wireframes.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Consultant-Experience.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Clio-Entities.md 2>/dev/null

# Clio Integration Service duplicates
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Testing-Strategy.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Development-Workflow.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Microservice-Integration-Guide.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-Entities.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-API-Overview.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-Integration-Tasks.md 2>/dev/null

# Account Billing Service duplicates
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/Technical-Standards.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/API-Contracts.md 2>/dev/null
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/Data-Model.md 2>/dev/null

# Data Service duplicates
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Data-Service/Consultant-Experience.md 2>/dev/null

# Common Models duplicates
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Common-Models/Data-Model.md 2>/dev/null

echo ""
echo "=== Creating README files with references ==="
echo ""

# Create Auth Service docs README
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/docs
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/docs/README.md << 'EOF'
# Auth Service Documentation

This directory contains work-in-progress documentation for the Auth Service. 

## Stable Documentation

The following stable documentation has been moved to the central documentation repository:

- [Authentication Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/Authentication-Strategy.md)
- [Authentication Flows](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/authentication-flows.md)
- [Security Implementation Details](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/security-implementation-details.md)
- [API Specification (OpenAPI)](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/auth-api-specification.yaml)
- [Testing Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Testing-Strategy.md)
- [Development Workflow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Development-Workflow.md)
- [API Contracts](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-contracts/API-Contracts.md)
- [Consultant Experience](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/Consultant-Experience.md)

Please refer to the central documentation repository for the most up-to-date information:
[https://github.com/Smarter-Firms/smarter-firms-docs](https://github.com/Smarter-Firms/smarter-firms-docs)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# Create API Gateway docs README
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/docs
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/docs/README.md << 'EOF'
# API Gateway Documentation

This directory contains work-in-progress documentation for the API Gateway.

## Stable Documentation

The following stable documentation has been moved to the central documentation repository:

- [System Architecture](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/architecture/System-Architecture.md)
- [Auth Service Integration](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/auth-service-integration.md)
- [Caching](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/caching.md)
- [Service Discovery](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/service-discovery.md)
- [Deployment](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/deployment.md)
- [Developer Guide](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/developer-guide.md)
- [Testing Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Testing-Strategy.md)
- [Development Workflow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Development-Workflow.md)
- [API Contracts](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-contracts/API-Contracts.md)

Please refer to the central documentation repository for the most up-to-date information:
[https://github.com/Smarter-Firms/smarter-firms-docs](https://github.com/Smarter-Firms/smarter-firms-docs)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# Create UI Service docs README
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/docs
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/docs/README.md << 'EOF'
# UI Service Documentation

This directory contains work-in-progress documentation for the UI Service.

## Stable Documentation

The following stable documentation has been moved to the central documentation repository:

- [Technical Standards](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/architecture/Technical-Standards.md)
- [SSO Wireframes](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/SSO-Wireframes.md)
- [Consultant Experience](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/Consultant-Experience.md)
- [Testing Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Testing-Strategy.md)
- [Development Workflow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Development-Workflow.md)
- [Clio Entities](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Clio-Entities.md)

Please refer to the central documentation repository for the most up-to-date information:
[https://github.com/Smarter-Firms/smarter-firms-docs](https://github.com/Smarter-Firms/smarter-firms-docs)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# Create Clio Integration Service docs README
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/docs
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/docs/README.md << 'EOF'
# Clio Integration Service Documentation

This directory contains work-in-progress documentation for the Clio Integration Service.

## Stable Documentation

The following stable documentation has been moved to the central documentation repository:

- [Clio API Overview](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Clio-API-Overview.md)
- [Clio Entities](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Clio-Entities.md)
- [Clio Integration Tasks](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Clio-Integration-Tasks.md)
- [Microservice Integration Guide](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/Microservice-Integration-Guide.md)
- [Testing Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Testing-Strategy.md)
- [Development Workflow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Development-Workflow.md)

Please refer to the central documentation repository for the most up-to-date information:
[https://github.com/Smarter-Firms/smarter-firms-docs](https://github.com/Smarter-Firms/smarter-firms-docs)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# Create Account Billing Service docs README
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/docs
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/docs/README.md << 'EOF'
# Account Billing Service Documentation

This directory contains work-in-progress documentation for the Account Billing Service.

## Stable Documentation

The following stable documentation has been moved to the central documentation repository:

- [Technical Standards](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/architecture/Technical-Standards.md)
- [API Contracts](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-contracts/API-Contracts.md)
- [Data Model](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/Data-Model.md)

Please refer to the central documentation repository for the most up-to-date information:
[https://github.com/Smarter-Firms/smarter-firms-docs](https://github.com/Smarter-Firms/smarter-firms-docs)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# Create Common Models docs README
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/Common-Models/docs
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/Common-Models/docs/README.md << 'EOF'
# Common Models Documentation

This directory contains work-in-progress documentation for the Common Models package.

## Stable Documentation

The following stable documentation has been moved to the central documentation repository:

- [Data Model](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/Data-Model.md)

Please refer to the central documentation repository for the most up-to-date information:
[https://github.com/Smarter-Firms/smarter-firms-docs](https://github.com/Smarter-Firms/smarter-firms-docs)

## Local Documentation

This directory contains:
- Auto-generated API documentation for Common Models types, interfaces, and functions
- Specific information about schema implementations

When stable documentation in this directory is created, it should be reviewed and moved to the central repository.
EOF

echo "Duplicate removal complete. Documents have been removed from service repositories and replaced with references to the central docs repository." 