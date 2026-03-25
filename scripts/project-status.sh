#!/bin/bash
# Project Status Check - Quick non-blocking health overview
# Run anytime to see project state without blocking

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Project Status - $(date '+%Y-%m-%d %H:%M')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ISSUES=0
WARNINGS=0

# ============================================
# Git Status
# ============================================
echo -e "${BLUE}🔧 Git Status${NC}"

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "   Branch: $CURRENT_BRANCH"

# Uncommitted changes
if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "   Changes: ${GREEN}Clean${NC}"
else
    CHANGED_FILES=$(git status --short | wc -l | tr -d ' ')
    echo -e "   Changes: ${YELLOW}$CHANGED_FILES uncommitted file(s)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Unpushed commits
UNPUSHED=$(git log @{u}.. --oneline 2>/dev/null | wc -l | tr -d ' ' || echo "0")
if [ "$UNPUSHED" -gt 0 ]; then
    echo -e "   Unpushed: ${YELLOW}$UNPUSHED commit(s)${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "   Unpushed: ${GREEN}None${NC}"
fi

echo ""

# ============================================
# Time Tracking
# ============================================
echo -e "${BLUE}⏱️  Time Tracking${NC}"

if [ -f ".time_session" ]; then
    START_TIME=$(cat .time_session | head -1)
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    HOURS=$((ELAPSED / 3600))
    MINUTES=$(((ELAPSED % 3600) / 60))
    echo -e "   Status: ${GREEN}Active${NC} (${HOURS}h ${MINUTES}m)"
else
    echo -e "   Status: ${CYAN}Not tracking${NC}"
fi

# Today's logged time
TODAY=$(date '+%Y-%m-%d')
if [ -f "docs/TIME_LOG.md" ] && grep -q "$TODAY" "docs/TIME_LOG.md" 2>/dev/null; then
    TIME_TODAY=$(grep "$TODAY" "docs/TIME_LOG.md" | tail -1 | awk -F'|' '{print $5}' | sed 's/(.*//' | xargs)
    echo "   Logged today: $TIME_TODAY"
else
    echo "   Logged today: 0h 0m"
fi

echo ""

# ============================================
# GitHub Issues
# ============================================
echo -e "${BLUE}📋 GitHub Issues${NC}"

if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    OPEN_ISSUES=$(gh issue list --state open 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    CLOSED_ISSUES=$(gh issue list --state closed 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    
    echo "   Open: $OPEN_ISSUES"
    echo "   Closed: $CLOSED_ISSUES"
    
    # Unlabeled open issues (must use JSON + jq, --label "" returns ALL issues)
    UNLABELED_OPEN=$(gh issue list --state open --json number,labels --limit 500 2>/dev/null | jq '[.[] | select(.labels | length == 0)] | length' 2>/dev/null || echo "0")
    UNLABELED_OPEN=$(echo "$UNLABELED_OPEN" | tr -d '[:space:]')
    if [ "$UNLABELED_OPEN" -gt 0 ]; then
        echo -e "   Unlabeled (open): ${RED}$UNLABELED_OPEN${NC}"
        ISSUES=$((ISSUES + 1))
    else
        echo -e "   Unlabeled (open): ${GREEN}0${NC}"
    fi
    
    # Stale issues (no updates in 14+ days)
    STALE_DATE=$(date -v-14d '+%Y-%m-%d' 2>/dev/null || date -d '14 days ago' '+%Y-%m-%d' 2>/dev/null || echo "")
    if [ -n "$STALE_DATE" ]; then
        STALE_ISSUES=$(gh issue list --state open --search "updated:<$STALE_DATE" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        if [ "$STALE_ISSUES" -gt 0 ]; then
            echo -e "   Stale (14+ days): ${YELLOW}$STALE_ISSUES${NC}"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "   Stale (14+ days): ${GREEN}0${NC}"
        fi
    fi
    
    # High priority
    P0_ISSUES=$(gh issue list --label "P0: Critical" --state open 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    P1_ISSUES=$(gh issue list --label "P1: High" --state open 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$P0_ISSUES" -gt 0 ]; then
        echo -e "   P0 Critical: ${RED}$P0_ISSUES${NC}"
    fi
    if [ "$P1_ISSUES" -gt 0 ]; then
        echo -e "   P1 High: ${YELLOW}$P1_ISSUES${NC}"
    fi
else
    echo -e "   ${YELLOW}GitHub CLI not available or not authenticated${NC}"
fi

echo ""

# ============================================
# Pull Requests
# ============================================
echo -e "${BLUE}🔀 Pull Requests${NC}"

if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    OPEN_PRS=$(gh pr list --state open 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$OPEN_PRS" -gt 0 ]; then
        echo -e "   Open: ${YELLOW}$OPEN_PRS${NC}"
        gh pr list --state open 2>/dev/null | head -5 | while read -r line; do
            echo "     • $line"
        done
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "   Open: ${GREEN}0${NC}"
    fi
else
    echo -e "   ${YELLOW}GitHub CLI not available${NC}"
fi

echo ""

# ============================================
# Documentation
# ============================================
echo -e "${BLUE}📚 Documentation${NC}"

# Check key docs exist
DOCS_OK=true
for doc in "README.md" "docs/DAILY_STATUS.md" "docs/TIME_LOG.md"; do
    if [ ! -f "$doc" ]; then
        echo -e "   Missing: ${RED}$doc${NC}"
        DOCS_OK=false
        ISSUES=$((ISSUES + 1))
    fi
done

if [ "$DOCS_OK" = true ]; then
    echo -e "   Core docs: ${GREEN}Present${NC}"
fi

# Last DAILY_STATUS update
if [ -f "docs/DAILY_STATUS.md" ]; then
    LAST_STATUS=$(grep "^## [0-9]" docs/DAILY_STATUS.md 2>/dev/null | head -1 | awk '{print $2}')
    if [ -n "$LAST_STATUS" ]; then
        echo "   Last status entry: $LAST_STATUS"
    fi
fi

echo ""

# ============================================
# Summary
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ISSUES" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✅ Project is healthy!${NC}"
elif [ "$ISSUES" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) - review recommended${NC}"
else
    echo -e "${RED}❌ $ISSUES issue(s), $WARNINGS warning(s) - action needed${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Quick actions:"
echo "  ./scripts/end-of-day.sh          # Full EOD check"
echo "  ./scripts/track-time.sh start    # Start time tracking"
echo "  ./scripts/fix-unlabeled-issues.sh # Fix unlabeled issues"
