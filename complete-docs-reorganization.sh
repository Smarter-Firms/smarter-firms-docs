#!/bin/bash

# Complete Documentation Reorganization Script
# This script handles copying documentation from all service repositories to the central docs repository
# and then removes the duplicated files from the service repositories.

base_dir="/Users/ericpatrick/Documents/Dev/Smarter-Firms"
central_docs_dir="$base_dir/smarter-firms-docs"

# Create needed directories if they don't exist
mkdir -p "$central_docs_dir/api-gateway/security"
mkdir -p "$central_docs_dir/auth-service/api"
mkdir -p "$central_docs_dir/common-models"
mkdir -p "$central_docs_dir/clio-integration/webhooks"
mkdir -p "$central_docs_dir/account-billing-service"
mkdir -p "$central_docs_dir/ui-service/components"

echo "=== Migrating API Gateway Documentation ==="

# Copy API Gateway security documentation
cp "$base_dir/API-Gateway/API-Gateway/docs/security-headers-configuration.md" "$central_docs_dir/api-gateway/security/" 2>/dev/null
cp "$base_dir/API-Gateway/API-Gateway/docs/security-measures.md" "$central_docs_dir/api-gateway/security/" 2>/dev/null
cp "$base_dir/API-Gateway/API-Gateway/docs/geographic-anomaly-detection.md" "$central_docs_dir/api-gateway/security/" 2>/dev/null
cp "$base_dir/API-Gateway/API-Gateway/docs/rate-limiting-configuration.md" "$central_docs_dir/api-gateway/security/" 2>/dev/null
cp "$base_dir/API-Gateway/Authentication-Strategy.md" "$central_docs_dir/api-gateway/" 2>/dev/null

echo "=== Migrating Auth Service Documentation ==="

# Copy Auth Service documentation
cp "$base_dir/Auth-Service/API-Authentication-System.md" "$central_docs_dir/auth-service/" 2>/dev/null
cp "$base_dir/Auth-Service/System-Architecture.md" "$central_docs_dir/auth-service/" 2>/dev/null
cp "$base_dir/Auth-Service/First-Iteration-Tasks.md" "$central_docs_dir/auth-service/" 2>/dev/null

echo "=== Migrating UI Service Documentation ==="

# Copy UI Service documentation
cp "$base_dir/UI-Service/docs/firm-context-management.md" "$central_docs_dir/ui-service/" 2>/dev/null
cp "$base_dir/UI-Service/docs/authentication-ui-components.md" "$central_docs_dir/ui-service/components/" 2>/dev/null
cp "$base_dir/UI-Service/docs/auth-api-feedback.md" "$central_docs_dir/ui-service/" 2>/dev/null
cp "$base_dir/UI-Service/docs/auth-components.md" "$central_docs_dir/ui-service/components/" 2>/dev/null
cp "$base_dir/UI-Service/docs/auth-flows.md" "$central_docs_dir/ui-service/" 2>/dev/null
cp "$base_dir/UI-Service/docs/consultant-experience.md" "$central_docs_dir/ui-service/" 2>/dev/null
cp "$base_dir/UI-Service/docs/security-features.md" "$central_docs_dir/ui-service/" 2>/dev/null

echo "=== Migrating Clio Integration Service Documentation ==="

# Copy Clio Integration Service documentation
cp "$base_dir/Clio-Integration-Service/System-Architecture.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Production-Deployment-Guide.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/oauth-testing.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/project-status.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Auth-Integration-Guide.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Testing-Webhooks.md" "$central_docs_dir/clio-integration/webhooks/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/diagrams/webhook-flow.md" "$central_docs_dir/clio-integration/webhooks/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Common-Models-Setup.md" "$central_docs_dir/common-models/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Deployment.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/API-Gateway-Integration.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/API-Metrics.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Security-Review-OAuth.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Webhook-Handler.md" "$central_docs_dir/clio-integration/webhooks/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Webhook-Metrics.md" "$central_docs_dir/clio-integration/webhooks/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/docs/Initial-Data-Synchronization.md" "$central_docs_dir/clio-integration/" 2>/dev/null
cp "$base_dir/Clio-Integration-Service/CONTRIBUTING.md" "$central_docs_dir/clio-integration/" 2>/dev/null

echo "=== Migrating Account Billing Service Documentation ==="

# Copy Account Billing Service documentation
cp "$base_dir/Account-Billing-Service/System-Architecture.md" "$central_docs_dir/account-billing-service/" 2>/dev/null
cp "$base_dir/Account-Billing-Service/Project-Overview.md" "$central_docs_dir/account-billing-service/" 2>/dev/null

echo "=== Migrating Common Models Documentation ==="

# Copy Common Models README (keep API documentation in the service repo)
cp "$base_dir/Common-Models/Technical-Standards.md" "$central_docs_dir/common-models/" 2>/dev/null
cp "$base_dir/Common-Models/CHANGELOG.md" "$central_docs_dir/common-models/" 2>/dev/null
cp "$base_dir/Common-Models/PR-SUMMARY.md" "$central_docs_dir/common-models/" 2>/dev/null
cp "$base_dir/Common-Models/task-list.md" "$central_docs_dir/common-models/" 2>/dev/null

echo "=== Creating Reference README Files ==="

# Create a README file explaining where documentation has moved for each service repository

# Auth Service README
cat > "$base_dir/Auth-Service/docs/README.md" << 'EOF'
# Auth Service Documentation

This directory contains work-in-progress documentation for the Auth Service. 

## Stable Documentation

Stable documentation has been moved to the central documentation repository:

- [Authentication Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/Authentication-Strategy.md)
- [Authentication Flows](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/authentication-flows.md)
- [Security Implementation Details](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/security-implementation-details.md)
- [API Authentication System](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/API-Authentication-System.md)
- [System Architecture](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/auth-service/System-Architecture.md)

For cross-cutting documentation, see:
- [Testing Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Testing-Strategy.md)
- [Development Workflow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Development-Workflow.md)
- [API Contracts](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-contracts/API-Contracts.md)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# API Gateway README
cat > "$base_dir/API-Gateway/docs/README.md" << 'EOF'
# API Gateway Documentation

This directory contains work-in-progress documentation for the API Gateway.

## Stable Documentation

Stable documentation has been moved to the central documentation repository:

- [Microservice Integration Guide](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/Microservice-Integration-Guide.md)
- [Auth Service Integration](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/auth-service-integration.md)
- [Caching](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/caching.md)
- [Service Discovery](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/service-discovery.md)
- [Deployment](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/deployment.md)
- [Developer Guide](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/docs/developer-guide.md)
- [API Gateway Tasks](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/API-Gateway-Tasks.md)
- [Authentication Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/Authentication-Strategy.md)

Security Documentation:
- [Security Headers Configuration](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/security/security-headers-configuration.md)
- [Security Measures](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/security/security-measures.md)
- [Geographic Anomaly Detection](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/security/geographic-anomaly-detection.md)
- [Rate Limiting Configuration](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/security/rate-limiting-configuration.md)

For cross-cutting documentation, see:
- [System Architecture](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/architecture/System-Architecture.md)
- [Testing Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Testing-Strategy.md)
- [Development Workflow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Development-Workflow.md)
- [API Contracts](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-contracts/API-Contracts.md)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# UI Service README
cat > "$base_dir/UI-Service/docs/README.md" << 'EOF'
# UI Service Documentation

This directory contains work-in-progress documentation for the UI Service.

## Stable Documentation

Stable documentation has been moved to the central documentation repository:

- [SSO Wireframes](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/SSO-Wireframes.md)
- [Consultant Experience](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/Consultant-Experience.md)
- [UI Service Auth Components](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/UI-Service-Auth-Components.md)
- [Auth Components](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/components/auth-components.md)
- [Authentication UI Components](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/components/authentication-ui-components.md)
- [Auth Flows](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/auth-flows.md)
- [Auth API Feedback](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/auth-api-feedback.md)
- [Firm Context Management](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/firm-context-management.md)
- [Security Features](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/ui-service/security-features.md)

For cross-cutting documentation, see:
- [Technical Standards](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/architecture/Technical-Standards.md)
- [Testing Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Testing-Strategy.md)
- [Development Workflow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Development-Workflow.md)
- [Clio Entities](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Clio-Entities.md)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# Clio Integration Service README
cat > "$base_dir/Clio-Integration-Service/docs/README.md" << 'EOF'
# Clio Integration Service Documentation

This directory contains work-in-progress documentation for the Clio Integration Service.

## Stable Documentation

Stable documentation has been moved to the central documentation repository:

- [Clio API Overview](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Clio-API-Overview.md)
- [Clio Entities](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Clio-Entities.md)
- [Clio Integration Tasks](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Clio-Integration-Tasks.md)
- [System Architecture](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/System-Architecture.md)
- [Production Deployment Guide](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Production-Deployment-Guide.md)
- [OAuth Testing](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/oauth-testing.md)
- [Project Status](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/project-status.md)
- [Auth Integration Guide](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Auth-Integration-Guide.md)
- [Deployment](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Deployment.md)
- [API Gateway Integration](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/API-Gateway-Integration.md)
- [API Metrics](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/API-Metrics.md)
- [Security Review OAuth](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Security-Review-OAuth.md)
- [Initial Data Synchronization](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/Initial-Data-Synchronization.md)

Webhook Documentation:
- [Testing Webhooks](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/webhooks/Testing-Webhooks.md)
- [Webhook Flow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/webhooks/webhook-flow.md)
- [Webhook Handler](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/webhooks/Webhook-Handler.md)
- [Webhook Metrics](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/clio-integration/webhooks/Webhook-Metrics.md)

For cross-cutting documentation, see:
- [Microservice Integration Guide](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-gateway/Microservice-Integration-Guide.md)
- [Testing Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Testing-Strategy.md)
- [Development Workflow](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/operations/Development-Workflow.md)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# Account Billing Service README
cat > "$base_dir/Account-Billing-Service/docs/README.md" << 'EOF'
# Account Billing Service Documentation

This directory contains work-in-progress documentation for the Account Billing Service.

## Stable Documentation

Stable documentation has been moved to the central documentation repository:

- [System Architecture](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/account-billing-service/System-Architecture.md)
- [Project Overview](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/account-billing-service/Project-Overview.md)

For cross-cutting documentation, see:
- [Technical Standards](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/architecture/Technical-Standards.md)
- [API Contracts](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/api-contracts/API-Contracts.md)
- [Data Model](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/Data-Model.md)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

# Common Models README
cat > "$base_dir/Common-Models/docs/README.md" << 'EOF'
# Common Models Documentation

This directory contains API documentation for the Common Models package.

## Stable Documentation

The following stable documentation has been moved to the central documentation repository:

- [Technical Standards](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/common-models/Technical-Standards.md)
- [CHANGELOG](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/common-models/CHANGELOG.md)
- [PR SUMMARY](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/common-models/PR-SUMMARY.md)
- [Task List](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/common-models/task-list.md)
- [Data Model](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/Data-Model.md)

## API Documentation

This directory contains auto-generated API documentation for the Common Models package including:
- Interfaces
- Types
- Enumerations
- Variables (Schemas)
- Functions

These files are maintained automatically through code generation and should not be manually edited.
EOF

# Data Service README
cat > "$base_dir/Data-Service/docs/README.md" << 'EOF'
# Data Service Documentation

This directory contains work-in-progress documentation for the Data Service.

## Stable Documentation

All documentation has been moved to the central documentation repository:

- [Index](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/index.md)
- [Multi-Tenant Implementation Guide](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/multi-tenant-implementation-guide.md)
- [Row-Level Security](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/row-level-security.md)
- [Repository Pattern](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/repository-pattern.md)
- [Cache Invalidation](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/cache-invalidation.md)
- [Key Rotation](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/key-rotation.md)
- [Resilience Testing](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/resilience-testing.md)
- [Query Optimization](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/query-optimization.md)
- [Security Implementation](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/security-implementation.md)
- [Database Migration Plan](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/database-migration-plan.md)
- [Data Model](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/data-service/Data-Model.md)

## Local Documentation

This directory should contain:
- Draft documentation for features in development
- Implementation notes that are frequently changing
- Service-specific setup instructions

When documentation in this directory is stabilized, it should be reviewed and moved to the central repository.
EOF

echo "=== Cleaning Up Duplicate Files ==="

# Now remove the duplicated files from service repositories

# Remove files from Auth Service
rm -f "$base_dir/Auth-Service/Authentication-Strategy.md" 2>/dev/null
rm -f "$base_dir/Auth-Service/authentication-flows.md" 2>/dev/null
rm -f "$base_dir/Auth-Service/security-implementation-details.md" 2>/dev/null
rm -f "$base_dir/Auth-Service/System-Architecture.md" 2>/dev/null
rm -f "$base_dir/Auth-Service/API-Authentication-System.md" 2>/dev/null
rm -f "$base_dir/Auth-Service/First-Iteration-Tasks.md" 2>/dev/null

# Remove files from API Gateway
rm -f "$base_dir/API-Gateway/Authentication-Strategy.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/API-Gateway-Tasks.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/API-Gateway/docs/security-headers-configuration.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/API-Gateway/docs/security-measures.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/API-Gateway/docs/geographic-anomaly-detection.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/API-Gateway/docs/rate-limiting-configuration.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/API-Gateway/docs/auth-service-integration.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/auth-service-integration.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/developer-guide.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/caching.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/clio-service-integration.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/ui-service-integration.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/service-discovery.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/deployment.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/executive-summary.md" 2>/dev/null
rm -f "$base_dir/API-Gateway/docs/service-integration.md" 2>/dev/null

# Remove files from UI Service
rm -f "$base_dir/UI-Service/SSO-Wireframes.md" 2>/dev/null
rm -f "$base_dir/UI-Service/Consultant-Experience.md" 2>/dev/null
rm -f "$base_dir/UI-Service/Technical-Standards.md" 2>/dev/null
rm -f "$base_dir/UI-Service/UI-Service-Auth-Components.md" 2>/dev/null
rm -f "$base_dir/UI-Service/docs/firm-context-management.md" 2>/dev/null
rm -f "$base_dir/UI-Service/docs/authentication-ui-components.md" 2>/dev/null
rm -f "$base_dir/UI-Service/docs/auth-api-feedback.md" 2>/dev/null
rm -f "$base_dir/UI-Service/docs/auth-components.md" 2>/dev/null
rm -f "$base_dir/UI-Service/docs/auth-flows.md" 2>/dev/null
rm -f "$base_dir/UI-Service/docs/consultant-experience.md" 2>/dev/null
rm -f "$base_dir/UI-Service/docs/security-features.md" 2>/dev/null
rm -f "$base_dir/UI-Service/Clio-Entities.md" 2>/dev/null
rm -f "$base_dir/UI-Service/API-Gateway-Tasks.md" 2>/dev/null
rm -f "$base_dir/UI-Service/Project-Progress.md" 2>/dev/null
rm -f "$base_dir/UI-Service/Next-Phase-Tasks.md" 2>/dev/null

# Remove files from Clio Integration Service
rm -f "$base_dir/Clio-Integration-Service/Clio-API-Overview.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/Clio-Entities.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/Clio-Integration-Tasks.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/System-Architecture.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/Production-Deployment-Guide.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/oauth-testing.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/project-status.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/Auth-Integration-Guide.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/Testing-Webhooks.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/diagrams/webhook-flow.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/Deployment.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/API-Gateway-Integration.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/API-Metrics.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/Security-Review-OAuth.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/Webhook-Handler.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/Webhook-Metrics.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/docs/Initial-Data-Synchronization.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/Microservice-Integration-Guide.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/Testing-Strategy.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/Development-Workflow.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/API-Contracts.md" 2>/dev/null
rm -f "$base_dir/Clio-Integration-Service/PR-Template.md" 2>/dev/null

# Remove files from Data Service
rm -f "$base_dir/Data-Service/Consultant-Experience.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/cache-invalidation.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/database-migration-plan.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/index.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/key-rotation.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/multi-tenant-implementation-guide.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/query-optimization.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/repository-pattern.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/resilience-testing.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/row-level-security.md" 2>/dev/null
rm -f "$base_dir/Data-Service/docs/security-implementation.md" 2>/dev/null

# Remove files from Account Billing Service
rm -f "$base_dir/Account-Billing-Service/Technical-Standards.md" 2>/dev/null
rm -f "$base_dir/Account-Billing-Service/API-Contracts.md" 2>/dev/null
rm -f "$base_dir/Account-Billing-Service/Data-Model.md" 2>/dev/null
rm -f "$base_dir/Account-Billing-Service/System-Architecture.md" 2>/dev/null
rm -f "$base_dir/Account-Billing-Service/Project-Overview.md" 2>/dev/null

# Remove files from Common Models
rm -f "$base_dir/Common-Models/Technical-Standards.md" 2>/dev/null
rm -f "$base_dir/Common-Models/Data-Model.md" 2>/dev/null

echo "=== Documentation Reorganization Complete ==="
echo ""
echo "All documentation has been migrated to the central docs repository"
echo "and duplicates have been removed from service repositories."
echo ""
echo "Each service repository now has a README.md in its docs directory"
echo "that references the central documentation." 