#!/bin/bash

# Script to identify and clean duplicate documents across service repositories
# This script will find potential duplicates and provide commands to remove them

echo "=== Identifying Duplicate Documents ==="
echo ""
echo "The following documents may be duplicates of content now in the central docs repository."
echo "Review each case and use the provided commands to remove confirmed duplicates."
echo ""

# Check for Authentication Strategy
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Authentication-Strategy.md" ]; then
    echo "DUPLICATE: Authentication-Strategy.md in Auth-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Authentication-Strategy.md"
    echo ""
fi

# Check for System Architecture
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/System-Architecture.md" ]; then
    echo "DUPLICATE: System-Architecture.md in API-Gateway"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/System-Architecture.md"
    echo ""
fi

# Check for Technical Standards
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Technical-Standards.md" ]; then
    echo "DUPLICATE: Technical-Standards.md in UI-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Technical-Standards.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/Technical-Standards.md" ]; then
    echo "DUPLICATE: Technical-Standards.md in Account-Billing-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/Technical-Standards.md"
    echo ""
fi

# Check for Testing Strategy
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/Testing-Strategy.md" ]; then
    echo "DUPLICATE: Testing-Strategy.md in API-Gateway"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/Testing-Strategy.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Testing-Strategy.md" ]; then
    echo "DUPLICATE: Testing-Strategy.md in Auth-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Testing-Strategy.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Testing-Strategy.md" ]; then
    echo "DUPLICATE: Testing-Strategy.md in UI-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Testing-Strategy.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Testing-Strategy.md" ]; then
    echo "DUPLICATE: Testing-Strategy.md in Clio-Integration-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Testing-Strategy.md"
    echo ""
fi

# Check for Development Workflow
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/Development-Workflow.md" ]; then
    echo "DUPLICATE: Development-Workflow.md in API-Gateway"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/Development-Workflow.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Development-Workflow.md" ]; then
    echo "DUPLICATE: Development-Workflow.md in Auth-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Development-Workflow.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Development-Workflow.md" ]; then
    echo "DUPLICATE: Development-Workflow.md in UI-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Development-Workflow.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Development-Workflow.md" ]; then
    echo "DUPLICATE: Development-Workflow.md in Clio-Integration-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Development-Workflow.md"
    echo ""
fi

# Check for Microservice Integration Guide
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Microservice-Integration-Guide.md" ]; then
    echo "DUPLICATE: Microservice-Integration-Guide.md in Clio-Integration-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Microservice-Integration-Guide.md"
    echo ""
fi

# Check for SSO Wireframes
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/SSO-Wireframes.md" ]; then
    echo "DUPLICATE: SSO-Wireframes.md in UI-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/SSO-Wireframes.md"
    echo ""
fi

# Check for Consultant Experience
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Consultant-Experience.md" ]; then
    echo "DUPLICATE: Consultant-Experience.md in UI-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Consultant-Experience.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Consultant-Experience.md" ]; then
    echo "DUPLICATE: Consultant-Experience.md in Auth-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/Consultant-Experience.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Data-Service/Consultant-Experience.md" ]; then
    echo "DUPLICATE: Consultant-Experience.md in Data-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Data-Service/Consultant-Experience.md"
    echo ""
fi

# Check for API Contracts
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/API-Contracts.md" ]; then
    echo "DUPLICATE: API-Contracts.md in API-Gateway"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/API-Gateway/API-Contracts.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/API-Contracts.md" ]; then
    echo "DUPLICATE: API-Contracts.md in Auth-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Auth-Service/API-Contracts.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/API-Contracts.md" ]; then
    echo "DUPLICATE: API-Contracts.md in Account-Billing-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/API-Contracts.md"
    echo ""
fi

# Check for Data Model
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/Data-Model.md" ]; then
    echo "DUPLICATE: Data-Model.md in Account-Billing-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Account-Billing-Service/Data-Model.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Common-Models/Data-Model.md" ]; then
    echo "DUPLICATE: Data-Model.md in Common-Models"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Common-Models/Data-Model.md"
    echo ""
fi

# Check for Clio Entities
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-Entities.md" ]; then
    echo "DUPLICATE: Clio-Entities.md in Clio-Integration-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-Entities.md"
    echo ""
fi

if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Clio-Entities.md" ]; then
    echo "DUPLICATE: Clio-Entities.md in UI-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/UI-Service/Clio-Entities.md"
    echo ""
fi

# Check for Clio API Overview
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-API-Overview.md" ]; then
    echo "DUPLICATE: Clio-API-Overview.md in Clio-Integration-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-API-Overview.md"
    echo ""
fi

# Check for Clio Integration Tasks
if [ -f "/Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-Integration-Tasks.md" ]; then
    echo "DUPLICATE: Clio-Integration-Tasks.md in Clio-Integration-Service"
    echo "Command to remove: rm /Users/ericpatrick/Documents/Dev/Smarter-Firms/Clio-Integration-Service/Clio-Integration-Tasks.md"
    echo ""
fi

echo ""
echo "=== Instructions ==="
echo ""
echo "For each duplicate file you wish to remove, run the provided command."
echo "Then, update the service repository's documentation to reference the files in the central docs repo."
echo ""
echo "For example, add this to the service README.md or a docs/README.md file:"
echo ""
echo '```'
echo "## Documentation"
echo ""
echo "Key documentation for this service is available in the central documentation repository:"
echo ""
echo "- [Document Name](https://github.com/Smarter-Firms/smarter-firms-docs/path/to/document.md)"
echo '```' 