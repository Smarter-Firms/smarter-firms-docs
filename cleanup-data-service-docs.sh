#!/bin/bash

# Script to clean up remaining documents in Data-Service/docs directory

base_dir="/Users/ericpatrick/Documents/Dev/Smarter-Firms"
data_service_docs_dir="$base_dir/Data-Service/docs"

echo "=== Cleaning up Data Service docs ==="
echo "Removing documents that have been migrated to the central repository..."

# Remove all .md files except README.md
find "$data_service_docs_dir" -type f -name "*.md" ! -name "README.md" -exec rm -v {} \;

echo "=== Cleanup complete ==="
echo "Only README.md should remain in the Data-Service/docs directory." 