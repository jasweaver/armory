#!/bin/bash

# Apply standard GitHub labels to the current repository

echo "🏷️  Applying standard GitHub labels to repository..."

# Priority Labels
gh label create "P0: Critical" --description "Critical priority - immediate action required" --color "d73a4a" --force
gh label create "P1: High" --description "High priority - should be addressed soon" --color "ff9500" --force
gh label create "P2: Medium" --description "Medium priority - normal workflow" --color "fbca04" --force
gh label create "P3: Low" --description "Low priority - nice to have" --color "0e8a16" --force

# Type Labels
gh label create "bug" --description "Something isn't working" --color "d73a4a" --force
gh label create "bugfix" --description "Bug fixes" --color "ee0701" --force
gh label create "feature" --description "New features" --color "a2eeef" --force
gh label create "enhancement" --description "New feature or request" --color "a2eeef" --force
gh label create "refactoring" --description "Code refactoring" --color "5319e7" --force
gh label create "documentation" --description "Improvements or additions to documentation" --color "0075ca" --force
gh label create "testing" --description "Testing and QA work" --color "008672" --force

# Category Labels
gh label create "architecture" --description "Architecture and design" --color "d4c5f9" --force
gh label create "infrastructure" --description "Infrastructure work" --color "0052cc" --force
gh label create "security" --description "Security work" --color "b60205" --force
gh label create "ci-cd" --description "CI/CD integration" --color "1d76db" --force
gh label create "library" --description "Shared library work" --color "c5def5" --force
gh label create "reporting" --description "Reporting and visualization" --color "bfdadc" --force
gh label create "planning" --description "Planning and design" --color "d4c5f9" --force

# Workflow Labels
gh label create "good first issue" --description "Good for newcomers" --color "7057ff" --force
gh label create "help wanted" --description "Extra attention is needed" --color "008672" --force
gh label create "question" --description "Further information is requested" --color "d876e3" --force
gh label create "duplicate" --description "This issue or pull request already exists" --color "cfd3d7" --force
gh label create "invalid" --description "This doesn't seem right" --color "e4e669" --force
gh label create "wontfix" --description "This will not be worked on" --color "ffffff" --force

# Project-Specific Labels for Vending Machine
gh label create "azure" --description "Azure-specific work" --color "0078d4" --force
gh label create "vmware" --description "VMware-specific work" --color "607078" --force
gh label create "ansible" --description "Ansible automation work" --color "ee0000" --force
gh label create "servicenow" --description "ServiceNow integration work" --color "62d84e" --force
gh label create "frontend" --description "Frontend/React work" --color "61dafb" --force
gh label create "backend" --description "Backend/API work" --color "68a063" --force
gh label create "database" --description "Database work" --color "336791" --force
gh label create "deployment" --description "Deployment and provisioning" --color "ff6b6b" --force
gh label create "deprovisioning" --description "Deprovisioning and cleanup" --color "95a5a6" --force

# Epic Labels (customize per project)
gh label create "epic-1" --description "Epic 1: Foundation & Setup" --color "0366d6" --force
gh label create "epic-2" --description "Epic 2: Service Catalog" --color "6f42c1" --force
gh label create "epic-3" --description "Epic 3: Core Provisioning" --color "1d76db" --force
gh label create "epic-4" --description "Epic 4: Lifecycle Management" --color "d876e3" --force
gh label create "epic-5" --description "Epic 5: Enterprise Integration" --color "959da5" --force
gh label create "epic-6" --description "Epic 6: Multi-Cloud Support" --color "ff7518" --force
gh label create "epic-7" --description "Epic 7: Production Ready" --color "c5def5" --force

echo "✅ All labels have been applied successfully!"
echo ""
echo "View labels at: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/labels"
