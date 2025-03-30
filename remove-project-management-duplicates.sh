#!/bin/bash

# Script to remove duplicate documents from the Project-Management repository
# that have now been migrated to the central documentation repository

echo "=== Removing Duplicates from Project-Management ==="
echo ""
echo "The following documents will be removed from the Project-Management repository"
echo "as they have been migrated to the central documentation repository."
echo ""

# Architecture documents
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/System-Architecture.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Technical-Standards.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Repository-Definitions.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Repository-Setup-Checklist.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Interface-Contracts.md

# Operations documents
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Development-Workflow.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Testing-Strategy.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Onboarding-Tasks.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/PR-Template.md

# Project Management documents
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Development-Roadmap.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/First-Iteration-Tasks.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Next-Phase-Tasks.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Project-Documentation.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Project-Overview.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Project-Progress.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Task-Backlog.md

# API docs
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/API-Contracts.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Microservice-Integration-Guide.md

# Service-specific documents
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Authentication-Strategy.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/API-Gateway-Tasks.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/UI-Service-Auth-Components.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/SSO-Wireframes.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Consultant-Experience.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Data-Model.md

# Clio-related documents
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Clio-API-Overview.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Clio-Entities.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Clio-Integration-Tasks.md

# Clean up agent instruction documents
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/API-Gateway-Agent-Instructions.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Data-Service-Agent-Instructions.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/Notifications-Service-Agent-Instructions.md
rm -v /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/UI-Service-Agent-Instructions.md

echo ""
echo "Creating README.md in Project-Management to explain where documents have moved"
echo ""

# Create a README file to explain where documents have moved
cat > /Users/ericpatrick/Documents/Dev/Smarter-Firms/Project-Management/README.md << 'EOF'
# Project Management Repository

## Documentation Has Moved

All documentation has been migrated to the central documentation repository:
https://github.com/Smarter-Firms/smarter-firms-docs

Please refer to the following directories:

- **Architecture Documentation**: [/architecture](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/architecture)
- **Project Management**: [/project-management](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/project-management)
- **Operations**: [/operations](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/operations)
- **API Contracts**: [/api-contracts](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/api-contracts)
- **Service Documentation**:
  - [/api-gateway](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/api-gateway)
  - [/auth-service](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/auth-service)
  - [/data-service](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/data-service)
  - [/ui-service](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/ui-service)
  - [/clio-integration](https://github.com/Smarter-Firms/smarter-firms-docs/tree/main/clio-integration)

## Documentation Strategy

Please refer to the [Documentation Strategy](https://github.com/Smarter-Firms/smarter-firms-docs/blob/main/DOCUMENTATION-STRATEGY.md) for details on our approach to documentation.
EOF

echo "Duplicate removal complete. Documents have been removed from Project-Management and moved to the central docs repository." 