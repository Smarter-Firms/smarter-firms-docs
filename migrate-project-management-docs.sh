#!/bin/bash

# Script to migrate documents from Project-Management to the central docs repository
# according to the documentation strategy

# Create required directories if they don't exist
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/architecture/adrs
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management
mkdir -p /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/clio-integration

# Copy files to architecture section
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Repository-Definitions.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/architecture/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Repository-Setup-Checklist.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/architecture/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Interface-Contracts.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/architecture/

# Copy files to project-management section
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Development-Roadmap.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/First-Iteration-Tasks.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Next-Phase-Tasks.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Onboarding-Tasks.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/PR-Template.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Project-Documentation.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Project-Overview.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Project-Progress.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Task-Backlog.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/

# Copy files to clio-integration section
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Clio-API-Overview.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/clio-integration/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Clio-Entities.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/clio-integration/
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Clio-Integration-Tasks.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/clio-integration/

# Copy API Gateway specific documents
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/API-Gateway-Tasks.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/api-gateway/

# Copy UI Service specific documents
cp /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/UI-Service-Auth-Components.md /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/ui-service/

# Create the project-management README file
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/project-management/README.md << 'EOF'
# Project Management Documentation

This directory contains documentation related to the project management aspects of the Smarter Firms platform.

## Contents

- [Development Roadmap](./Development-Roadmap.md) - Strategic development timeline and milestones
- [First Iteration Tasks](./First-Iteration-Tasks.md) - Tasks for the initial development iteration
- [Next Phase Tasks](./Next-Phase-Tasks.md) - Planned tasks for future development phases
- [Onboarding Tasks](./Onboarding-Tasks.md) - Checklist for onboarding new team members
- [Project Overview](./Project-Overview.md) - General overview of the Smarter Firms platform
- [Project Progress](./Project-Progress.md) - Current status and progress tracking
- [Task Backlog](./Task-Backlog.md) - Prioritized list of pending tasks

## Purpose

These documents are maintained in the central documentation repository to ensure all team members have visibility into the project's progress, roadmap, and task allocation. They should be regularly updated to reflect the current state of the project.

## Contributing

To update these documents, please follow the [Documentation Strategy](../DOCUMENTATION-STRATEGY.md) guidelines.
EOF

# Create the clio-integration README file
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/smarter-firms-docs/clio-integration/README.md << 'EOF'
# Clio Integration Documentation

This directory contains documentation related to the integration with the Clio API for the Smarter Firms platform.

## Contents

- [Clio API Overview](./Clio-API-Overview.md) - Overview of the Clio API capabilities and endpoints
- [Clio Entities](./Clio-Entities.md) - Detailed information about Clio data entities and structures
- [Clio Integration Tasks](./Clio-Integration-Tasks.md) - Specific tasks for implementing Clio integration

## Purpose

These documents provide the technical foundation for integrating with the Clio API, ensuring consistent implementation across all services that interact with Clio data.

## Related Documentation

- [API Gateway Clio Service Integration](../api-gateway/docs/clio-service-integration.md) - Details on how the API Gateway interacts with the Clio Integration Service
EOF

# Note about files that are already in the central repository
echo "The following files from Project-Management are already in the central docs repository:"
echo "- Authentication-Strategy.md (in auth-service/)"
echo "- System-Architecture.md (in architecture/)"
echo "- Technical-Standards.md (in architecture/)"
echo "- Testing-Strategy.md (in operations/)"
echo "- Development-Workflow.md (in operations/)"
echo "- Microservice-Integration-Guide.md (in api-gateway/)"
echo "- SSO-Wireframes.md (in ui-service/)"
echo "- Consultant-Experience.md (in ui-service/)"
echo "- API-Contracts.md (in api-contracts/)"
echo "- Data-Model.md (in data-service/)"

echo "Migration completed!" 