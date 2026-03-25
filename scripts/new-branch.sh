#!/bin/bash

# Helper script to create a new feature branch with proper naming

set -e

# Check if we're on main
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  Warning: You're not on main branch (currently on: $CURRENT_BRANCH)"
    echo "It's recommended to create branches from main."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get issue number and description
if [ -z "$1" ]; then
    echo "Usage: ./scripts/new-branch.sh <issue-number> [description]"
    echo "Example: ./scripts/new-branch.sh 3 \"project setup\""
    echo ""
    echo "Branch types:"
    echo "  - feature (default)"
    echo "  - fix"
    echo "  - docs"
    echo "  - refactor"
    echo "  - test"
    echo "  - chore"
    echo ""
    read -p "Enter issue number: " ISSUE_NUM
else
    ISSUE_NUM=$1
fi

if [ -z "$2" ]; then
    read -p "Enter brief description: " DESCRIPTION
else
    DESCRIPTION=$2
fi

# Get branch type
echo ""
echo "Select branch type:"
echo "1) feature (new feature)"
echo "2) fix (bug fix)"
echo "3) docs (documentation)"
echo "4) refactor (code refactoring)"
echo "5) test (testing)"
echo "6) chore (maintenance)"
read -p "Enter number (default: 1): " TYPE_NUM

case $TYPE_NUM in
    2) BRANCH_TYPE="fix" ;;
    3) BRANCH_TYPE="docs" ;;
    4) BRANCH_TYPE="refactor" ;;
    5) BRANCH_TYPE="test" ;;
    6) BRANCH_TYPE="chore" ;;
    *) BRANCH_TYPE="feature" ;;
esac

# Convert description to lowercase and replace spaces with hyphens
BRANCH_DESC=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

# Create branch name
BRANCH_NAME="${BRANCH_TYPE}/${ISSUE_NUM}-${BRANCH_DESC}"

echo ""
echo "📝 Creating branch: $BRANCH_NAME"
echo ""

# Update main if we're on it
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "🔄 Updating main branch..."
    git pull origin main
fi

# Create and checkout new branch
git checkout -b "$BRANCH_NAME"

echo ""
echo "✅ Created and switched to branch: $BRANCH_NAME"
echo ""
echo "Next steps:"
echo "  1. Make your changes"
echo "  2. Commit: git commit -m 'Your commit message'"
echo "  3. Push: git push -u origin $BRANCH_NAME"
echo "  4. Create PR: gh pr create --web"
echo ""
echo "💡 Tip: Reference issue in commits: 'Your message - relates to #$ISSUE_NUM'"
echo "💡 Use 'Closes #$ISSUE_NUM' in PR description to auto-close issue when merged"
