#!/bin/bash
# Fix Unlabeled Issues Script
# Applies default labels to issues that have no labels
# Useful when importing standards to an existing project

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏷️  Fix Unlabeled Issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "   Install with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
    echo "   Run: gh auth login"
    exit 1
fi

# Default labels for issues without any labels
DEFAULT_PRIORITY="P2: Medium"
DEFAULT_TYPE="feature"

# Parse arguments
INTERACTIVE=true
DRY_RUN=false
FIX_CLOSED=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            INTERACTIVE=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --include-closed)
            FIX_CLOSED=true
            shift
            ;;
        --priority)
            DEFAULT_PRIORITY="$2"
            shift 2
            ;;
        --type)
            DEFAULT_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --auto            Non-interactive mode, apply defaults to all"
            echo "  --dry-run         Show what would be done without making changes"
            echo "  --include-closed  Also fix closed issues (default: open only)"
            echo "  --priority LABEL  Default priority label (default: 'P2: Medium')"
            echo "  --type LABEL      Default type label (default: 'feature')"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Interactive mode for open issues"
            echo "  $0 --auto --include-closed  # Auto-fix all issues"
            echo "  $0 --dry-run                # Preview changes"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Get unlabeled open issues
# NOTE: gh issue list --label "" returns ALL issues, not unlabeled ones
#       Must use --json and filter for empty labels array
echo "📋 Finding unlabeled issues..."
echo ""

UNLABELED_OPEN=$(gh issue list --state open --json number,title,labels --limit 500 2>/dev/null | jq -r '.[] | select(.labels | length == 0) | "\(.number)\t\(.title)"' 2>/dev/null || echo "")
UNLABELED_OPEN_COUNT=$(echo "$UNLABELED_OPEN" | grep -c "." 2>/dev/null || echo "0")

if [ "$FIX_CLOSED" = true ]; then
    UNLABELED_CLOSED=$(gh issue list --state closed --json number,title,labels --limit 500 2>/dev/null | jq -r '.[] | select(.labels | length == 0) | "\(.number)\t\(.title)"' 2>/dev/null || echo "")
    UNLABELED_CLOSED_COUNT=$(echo "$UNLABELED_CLOSED" | grep -c "." 2>/dev/null || echo "0")
else
    UNLABELED_CLOSED=""
    UNLABELED_CLOSED_COUNT=0
fi

TOTAL_UNLABELED=$((UNLABELED_OPEN_COUNT + UNLABELED_CLOSED_COUNT))

if [ "$TOTAL_UNLABELED" -eq 0 ]; then
    echo -e "${GREEN}✅ No unlabeled issues found!${NC}"
    exit 0
fi

echo -e "${YELLOW}Found $TOTAL_UNLABELED unlabeled issue(s):${NC}"
echo "  • Open: $UNLABELED_OPEN_COUNT"
if [ "$FIX_CLOSED" = true ]; then
    echo "  • Closed: $UNLABELED_CLOSED_COUNT"
fi
echo ""

# Show available labels for reference
echo -e "${BLUE}Available Priority Labels:${NC}"
echo "  P0: Critical, P1: High, P2: Medium, P3: Low"
echo ""
echo -e "${BLUE}Available Type Labels:${NC}"
echo "  bug, feature, enhancement, documentation, refactoring, testing"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}DRY RUN - No changes will be made${NC}"
    echo ""
fi

# Function to label an issue
label_issue() {
    local ISSUE_NUM=$1
    local ISSUE_TITLE=$2
    local PRIORITY=$3
    local TYPE=$4
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}[DRY RUN] Would label #$ISSUE_NUM with: $PRIORITY, $TYPE${NC}"
    else
        echo -n "  Labeling #$ISSUE_NUM... "
        if gh issue edit "$ISSUE_NUM" --add-label "$PRIORITY,$TYPE" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗ (failed)${NC}"
        fi
    fi
}

# Process open issues
if [ "$UNLABELED_OPEN_COUNT" -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📂 Open Issues ($UNLABELED_OPEN_COUNT)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while IFS=$'\t' read -r ISSUE_NUM ISSUE_TITLE; do
        [ -z "$ISSUE_NUM" ] && continue
        
        echo ""
        echo -e "${YELLOW}#$ISSUE_NUM: $ISSUE_TITLE${NC}"
        
        if [ "$INTERACTIVE" = true ]; then
            echo "  Current labels: (none)"
            echo ""
            echo "  Select priority:"
            echo "    1) P0: Critical"
            echo "    2) P1: High"
            echo "    3) P2: Medium (default)"
            echo "    4) P3: Low"
            echo "    s) Skip this issue"
            echo ""
            read -p "  Priority [3]: " PRIORITY_CHOICE
            
            case $PRIORITY_CHOICE in
                1) PRIORITY="P0: Critical" ;;
                2) PRIORITY="P1: High" ;;
                3|"") PRIORITY="P2: Medium" ;;
                4) PRIORITY="P3: Low" ;;
                s|S) 
                    echo "  Skipped"
                    continue
                    ;;
                *) PRIORITY="P2: Medium" ;;
            esac
            
            echo ""
            echo "  Select type:"
            echo "    1) bug"
            echo "    2) feature (default)"
            echo "    3) enhancement"
            echo "    4) documentation"
            echo "    5) refactoring"
            echo "    6) testing"
            echo ""
            read -p "  Type [2]: " TYPE_CHOICE
            
            case $TYPE_CHOICE in
                1) TYPE="bug" ;;
                2|"") TYPE="feature" ;;
                3) TYPE="enhancement" ;;
                4) TYPE="documentation" ;;
                5) TYPE="refactoring" ;;
                6) TYPE="testing" ;;
                *) TYPE="feature" ;;
            esac
            
            label_issue "$ISSUE_NUM" "$ISSUE_TITLE" "$PRIORITY" "$TYPE"
        else
            # Auto mode - use defaults
            label_issue "$ISSUE_NUM" "$ISSUE_TITLE" "$DEFAULT_PRIORITY" "$DEFAULT_TYPE"
        fi
    done <<< "$UNLABELED_OPEN"
fi

# Process closed issues
if [ "$FIX_CLOSED" = true ] && [ "$UNLABELED_CLOSED_COUNT" -gt 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📁 Closed Issues ($UNLABELED_CLOSED_COUNT)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$INTERACTIVE" = true ]; then
        echo ""
        echo "Apply default labels ($DEFAULT_PRIORITY, $DEFAULT_TYPE) to all closed issues?"
        read -p "[y/N]: " CONFIRM
        
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo "Skipping closed issues"
        else
            while IFS=$'\t' read -r ISSUE_NUM ISSUE_TITLE; do
                [ -z "$ISSUE_NUM" ] && continue
                label_issue "$ISSUE_NUM" "$ISSUE_TITLE" "$DEFAULT_PRIORITY" "$DEFAULT_TYPE"
            done <<< "$UNLABELED_CLOSED"
        fi
    else
        # Auto mode
        while IFS=$'\t' read -r ISSUE_NUM ISSUE_TITLE; do
            [ -z "$ISSUE_NUM" ] && continue
            label_issue "$ISSUE_NUM" "$ISSUE_TITLE" "$DEFAULT_PRIORITY" "$DEFAULT_TYPE"
        done <<< "$UNLABELED_CLOSED"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}DRY RUN COMPLETE - No changes were made${NC}"
    echo "Run without --dry-run to apply changes"
else
    echo -e "${GREEN}✅ Done!${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
