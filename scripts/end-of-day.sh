#!/bin/bash
# End of Day Cleanup Script
# Ensures clean state: no lingering work, all docs updated, proper issue tracking

set -e

# Get project root (current directory or git root)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

DAILY_LOG="docs/DAILY_STATUS.md"
SKIP_LOG="docs/.eod_skips.log"
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# Parse Arguments
# ============================================
SKIP_CHECKS=()
SKIP_REASON=""

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-check CHECK   Skip a specific check (requires --reason)"
    echo "  --reason TEXT        Reason for skipping (required with --skip-check)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Available checks to skip:"
    echo "  uncommitted    - Uncommitted changes check"
    echo "  unpushed       - Unpushed commits check"
    echo "  branch         - Not on main branch check"
    echo "  prs            - Open pull requests check"
    echo "  unlabeled      - Unlabeled issues check"
    echo "  docs           - Documentation updates check"
    echo "  orphaned       - Orphaned files check"
    echo "  issuerefs      - Issue references in commits check"
    echo ""
    echo "Example:"
    echo "  $0 --skip-check unlabeled --reason 'Legacy issues, will fix tomorrow'"
    echo "  $0 --skip-check uncommitted --skip-check unpushed --reason 'WIP branch'"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-check)
            SKIP_CHECKS+=("$2")
            shift 2
            ;;
        --reason)
            SKIP_REASON="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate skip arguments
if [ ${#SKIP_CHECKS[@]} -gt 0 ] && [ -z "$SKIP_REASON" ]; then
    echo -e "${RED}❌ Error: --skip-check requires --reason${NC}"
    echo "Example: $0 --skip-check unlabeled --reason 'Legacy issues'"
    exit 1
fi

# Log skipped checks
if [ ${#SKIP_CHECKS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Skipping checks: ${SKIP_CHECKS[*]}${NC}"
    echo -e "${YELLOW}   Reason: $SKIP_REASON${NC}"
    echo ""
    
    # Log to file for audit trail
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skipped: ${SKIP_CHECKS[*]} | Reason: $SKIP_REASON" >> "$SKIP_LOG"
fi

# Helper function to check if a check should be skipped
should_skip() {
    local check_name=$1
    for skip in "${SKIP_CHECKS[@]}"; do
        if [ "$skip" = "$check_name" ]; then
            return 0  # true, should skip
        fi
    done
    return 1  # false, don't skip
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌙 End of Day Cleanup - $(date '+%Y-%m-%d %H:%M')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ISSUES_FOUND=0
WARNINGS_FOUND=0
TIME_SUMMARY=""
TIME_TRACKED_TODAY=""
STRICT_MODE=true  # Enforce all checks - no warnings, only blocking issues

# ============================================
# 1. Check and Stop Active Time Tracking Session
# ============================================
echo "📊 Checking time tracking..."
if [ -f ".time_session" ]; then
    echo -e "${BLUE}ℹ️  Active time tracking session found - stopping now...${NC}"
    echo ""
    
    # Capture the status before stopping
    TIME_SUMMARY=$(./scripts/track-time.sh status 2>&1)
    echo "$TIME_SUMMARY"
    echo ""
    
    # Stop the timer
    STOP_OUTPUT=$(./scripts/track-time.sh stop 2>&1)
    echo "$STOP_OUTPUT"
    echo ""
    
    # Extract time for summary - look for the logged duration
    TIME_TRACKED_TODAY=$(echo "$STOP_OUTPUT" | grep "⏰ Duration:" | sed 's/.*Duration: //' | sed 's/ (.*//')
    
    echo -e "${GREEN}✅ Time tracking stopped and logged${NC}"
else
    echo -e "${GREEN}✅ No active time tracking session${NC}"
    
    # Check if there's time logged today and show the last/total entry
    TODAY=$(date '+%Y-%m-%d')
    if grep -q "$TODAY" "docs/TIME_LOG.md" 2>/dev/null; then
        # Get the last entry's duration for today (5th column: "Xh Ym (decimal)")
        TIME_TRACKED_TODAY=$(grep "$TODAY" "docs/TIME_LOG.md" | tail -1 | awk -F'|' '{print $5}' | sed 's/(.*//' | xargs)
        
        if [ -n "$TIME_TRACKED_TODAY" ]; then
            echo -e "${BLUE}📊 Time logged today: $TIME_TRACKED_TODAY${NC}"
        fi
    fi
fi
echo ""

# ============================================
# 2. Check for Uncommitted Changes
# ============================================
echo "📝 Checking for uncommitted changes..."
if should_skip "uncommitted"; then
    echo -e "${YELLOW}⏭️  Skipped (reason: $SKIP_REASON)${NC}"
elif ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠️  ISSUE: You have uncommitted changes!${NC}"
    echo ""
    git status --short
    echo ""
    echo "Please commit your changes:"
    echo "  git add <files>"
    echo "  git commit -m 'your message'"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ No uncommitted changes${NC}"
fi
echo ""

# ============================================
# 3. Check for Unpushed Commits
# ============================================
echo "⬆️  Checking for unpushed commits..."
if should_skip "unpushed"; then
    echo -e "${YELLOW}⏭️  Skipped (reason: $SKIP_REASON)${NC}"
else
    UNPUSHED=$(git log @{u}.. --oneline 2>/dev/null | wc -l || echo "0")
    if [ "$UNPUSHED" -gt 0 ]; then
        echo -e "${RED}❌ BLOCKING: You have $UNPUSHED unpushed commit(s)!${NC}"
        echo -e "${RED}   All work MUST hit the pipeline before EOD.${NC}"
        git log @{u}.. --oneline
        echo ""
        echo "Push your commits now:"
        echo "  git push"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}✅ All commits are pushed${NC}"
    fi
fi
echo ""

# ============================================
# 4. Check Current Branch
# ============================================
echo "🌿 Checking current branch..."
CURRENT_BRANCH=$(git branch --show-current)
if should_skip "branch"; then
    echo -e "${YELLOW}⏭️  Skipped (reason: $SKIP_REASON)${NC}"
elif [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${RED}❌ BLOCKING: You're on branch '$CURRENT_BRANCH' (not main)${NC}"
    echo -e "${RED}   All feature branches must be merged and you must return to main.${NC}"
    echo ""
    echo "Merge your work and switch to main:"
    echo "  git checkout main"
    echo "  git merge $CURRENT_BRANCH  # if not already merged via PR"
    echo "  git branch -d $CURRENT_BRANCH  # cleanup feature branch"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ On main branch${NC}"
fi
echo ""

# ============================================
# 5. Check for Open Pull Requests
# ============================================
echo "🔀 Checking for open pull requests..."
if should_skip "prs"; then
    echo -e "${YELLOW}⏭️  Skipped (reason: $SKIP_REASON)${NC}"
else
    OPEN_PRS=$(gh pr list --state open 2>/dev/null | wc -l || echo "0")
    if [ "$OPEN_PRS" -gt 0 ]; then
        echo -e "${RED}❌ BLOCKING: You have $OPEN_PRS open pull request(s)!${NC}"
        echo -e "${RED}   NO PRs can be left open at EOD - merge or close them.${NC}"
        gh pr list --state open
        echo ""
        echo "Merge all PRs now:"
        echo "  gh pr merge <number> --squash  # or --merge/--rebase"
        echo "  gh pr close <number>  # if abandoning"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}✅ No open pull requests${NC}"
    fi
fi
echo ""

# ============================================
# 6. Check for Temp/Session Files
# ============================================
echo "🗑️  Checking for temporary files..."
TEMP_FILES=0
if ls .time* 1> /dev/null 2>&1; then
    echo -e "${BLUE}ℹ️  Cleaning up time tracking temp files...${NC}"
    rm -f .time_monitor.log .time_paused .time_monitor_pid
    echo "   Cleaned: .time_monitor.log, .time_paused, .time_monitor_pid"
    TEMP_FILES=$((TEMP_FILES + 1))
fi

if ls /tmp/issue-*.md 1> /dev/null 2>&1; then
    echo -e "${BLUE}ℹ️  Issue templates found in /tmp (may be intentional)${NC}"
    ls -1 /tmp/issue-*.md
    TEMP_FILES=$((TEMP_FILES + 1))
fi

if [ "$TEMP_FILES" -eq 0 ]; then
    echo -e "${GREEN}✅ No temporary files found${NC}"
fi
echo ""

# ============================================
# 6a. Check for Orphaned/Unneeded Files (BLOCKING)
# ============================================
echo "🔍 Checking for orphaned and unneeded files..."
if should_skip "orphaned"; then
    echo -e "${YELLOW}⏭️  Skipped (reason: $SKIP_REASON)${NC}"
else
    ORPHAN_FILES=()
    ORPHAN_COUNT=0

    # Check for untracked files (excluding intentionally untracked)
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null)
    if [ -n "$UNTRACKED" ]; then
    # Filter out known OK patterns (like .env.local, etc.)
    PROBLEM_UNTRACKED=$(echo "$UNTRACKED" | grep -vE "^\.env\.local$|^\.env\.development\.local$|^\.env\.test\.local$|^\.env\.production\.local$" || true)
    if [ -n "$PROBLEM_UNTRACKED" ]; then
        while IFS= read -r file; do
            ORPHAN_FILES+=("$file")
            ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        done <<< "$PROBLEM_UNTRACKED"
    fi
fi

# Check for common backup/temp files that should never be committed
BACKUP_PATTERNS=(
    "*.bak"
    "*.orig"
    "*.swp"
    "*.swo"
    "*~"
    "*.tmp"
    "*.temp"
    "*.log"
    ".DS_Store"
    "Thumbs.db"
    "*.pyc"
    "__pycache__"
    "*.class"
    "node_modules"
    ".pytest_cache"
    ".mypy_cache"
    "*.egg-info"
    "dist/"
    "build/"
    "*.o"
    "*.a"
    ".coverage"
    "htmlcov/"
    ".tox/"
    ".nox/"
    "*.sqlite3"
    "*.db"
)

for pattern in "${BACKUP_PATTERNS[@]}"; do
    # Check if any files matching pattern exist and are tracked
    FOUND_FILES=$(git ls-files "$pattern" 2>/dev/null)
    if [ -n "$FOUND_FILES" ]; then
        while IFS= read -r file; do
            ORPHAN_FILES+=("$file (should be in .gitignore)")
            ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        done <<< "$FOUND_FILES"
    fi
done

# Check for empty directories
EMPTY_DIRS=$(find . -type d -empty -not -path "./.git/*" 2>/dev/null)
if [ -n "$EMPTY_DIRS" ]; then
    while IFS= read -r dir; do
        ORPHAN_FILES+=("$dir (empty directory)")
        ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
    done <<< "$EMPTY_DIRS"
fi

# Check for files that look like they were meant to be deleted
STALE_PATTERNS=(
    "*_old.*"
    "*_backup.*"
    "*_copy.*"
    "*.deleted"
    "*.remove"
    "Copy of *"
    "* - Copy*"
)

for pattern in "${STALE_PATTERNS[@]}"; do
    FOUND_STALE=$(find . -name "$pattern" -not -path "./.git/*" 2>/dev/null)
    if [ -n "$FOUND_STALE" ]; then
        while IFS= read -r file; do
            ORPHAN_FILES+=("$file (looks like stale/backup file)")
            ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        done <<< "$FOUND_STALE"
    fi
done

# Display results
if [ "$ORPHAN_COUNT" -gt 0 ]; then
    echo -e "${RED}❌ BLOCKING: Found $ORPHAN_COUNT orphaned/unneeded file(s)!${NC}"
    echo -e "${RED}   Clean up these files before EOD:${NC}"
    echo ""
    for file in "${ORPHAN_FILES[@]}"; do
        echo -e "${RED}   • $file${NC}"
    done
    echo ""
    echo "Fix options:"
    echo "  # Add to tracking if needed:"
    echo "  git add <file>"
    echo ""
    echo "  # Add to .gitignore if should be ignored:"
    echo "  echo '<pattern>' >> .gitignore"
    echo ""
    echo "  # Delete if not needed:"
    echo "  rm <file>  # or rm -rf <directory>"
    echo ""
    echo "  # Remove from git if accidentally tracked:"
    echo "  git rm --cached <file>"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ No orphaned or unneeded files found${NC}"
fi
fi  # end of orphaned skip check
echo ""

# ============================================
# 7. Check Issue Board Status
# ============================================
echo "📋 Checking GitHub issues..."
OPEN_ISSUES=$(gh issue list --state open 2>/dev/null | wc -l || echo "0")
echo "   Open issues: $OPEN_ISSUES"

# ============================================
# 7a. Check that today's work created or updated issues
# ============================================
echo ""
echo "🔗 Checking issue linkage for today's commits..."
if should_skip "issuerefs"; then
    echo -e "${YELLOW}⏭️  Skipped (reason: $SKIP_REASON)${NC}"
else
    COMMITS_TODAY_COUNT=$(git log --since="00:00" --oneline --no-merges 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COMMITS_TODAY_COUNT" -gt 0 ]; then
        # Get all commit messages from today
        ALL_COMMIT_MSGS=$(git log --since="00:00" --pretty=format:"%s" 2>/dev/null)
        
        # Check for issue references (#123 pattern)
        ISSUE_REFS=$(echo "$ALL_COMMIT_MSGS" | grep -oE "#[0-9]+" | sort -u | wc -l | tr -d ' ')
        
        if [ "$ISSUE_REFS" -eq 0 ]; then
            echo -e "${RED}❌ BLOCKING: $COMMITS_TODAY_COUNT commit(s) today but NO issue references!${NC}"
            echo -e "${RED}   ALL work must be tied to issues. Create issues for any untracked work.${NC}"
            echo ""
            echo "Today's commits without issue refs:"
            git log --since="00:00" --pretty=format:"  • %s" --no-merges 2>/dev/null
            echo ""
            echo ""
            echo "Fix by either:"
            echo "  1. Create issues for untracked work:"
            echo "     gh issue create --title \"Work done: <description>\" --body \"<details>\""
            echo "  2. Amend commits to include issue refs:"
            echo "     git commit --amend -m \"Your message #123\""
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        else
            echo -e "${GREEN}✅ Found $ISSUE_REFS issue reference(s) in today's commits${NC}"
        fi
    else
        echo -e "${GREEN}✅ No commits today to check${NC}"
    fi
fi
echo ""

# ============================================
# 7b. Check for issues that should be updated from current branch work
# ============================================
echo "📝 Checking for issues needing updates..."
# Get issues assigned to current user that are in-progress
IN_PROGRESS_ISSUES=$(gh issue list --assignee "@me" --label "status: in-progress" --state open 2>/dev/null | wc -l || echo "0")
if [ "$IN_PROGRESS_ISSUES" -gt 0 ]; then
    echo -e "${YELLOW}ℹ️  You have $IN_PROGRESS_ISSUES in-progress issue(s) assigned to you:${NC}"
    gh issue list --assignee "@me" --label "status: in-progress" --state open
    echo ""
    echo "Consider updating these issues with today's progress before EOD."
fi

# Check for issues without labels
# NOTE: Only check OPEN issues - closed issues are historical and shouldn't block EOD
#       For existing projects, run ./scripts/fix-unlabeled-issues.sh to bulk-fix
# NOTE: gh issue list --label "" returns ALL issues, not unlabeled ones
#       Must use --json and filter for empty labels array
if should_skip "unlabeled"; then
    echo -e "${YELLOW}⏭️  Skipped unlabeled check (reason: $SKIP_REASON)${NC}"
else
    # Get unlabeled open issues using JSON output and jq filtering
    UNLABELED_ISSUES=$(gh issue list --state open --json number,title,labels --limit 500 2>/dev/null | jq -r '.[] | select(.labels | length == 0) | "#\(.number) \(.title)"' 2>/dev/null || echo "")
    UNLABELED=$(echo "$UNLABELED_ISSUES" | grep -c "^#" 2>/dev/null || echo "0")
    UNLABELED=$(echo "$UNLABELED" | tr -d '[:space:]')
    
    if [ "$UNLABELED" -gt 0 ]; then
        echo -e "${RED}❌ BLOCKING: $UNLABELED open issue(s) without labels!${NC}"
        echo -e "${RED}   ALL open issues must be properly tagged before EOD.${NC}"
        echo "$UNLABELED_ISSUES"
        echo ""
        echo "Label issues now:"
        echo "  gh issue edit <number> --add-label \"P2: Medium,feature\""
        echo "  ./scripts/fix-unlabeled-issues.sh  # bulk-fix all unlabeled issues"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}✅ All open issues are labeled${NC}"
    fi

    # Check for unlabeled closed issues (warning only, not blocking)
    UNLABELED_CLOSED_ISSUES=$(gh issue list --state closed --json number,labels --limit 500 2>/dev/null | jq -r '.[] | select(.labels | length == 0) | .number' 2>/dev/null || echo "")
    UNLABELED_CLOSED=$(echo "$UNLABELED_CLOSED_ISSUES" | grep -c "^[0-9]" 2>/dev/null || echo "0")
    UNLABELED_CLOSED=$(echo "$UNLABELED_CLOSED" | tr -d '[:space:]')
    
    if [ "$UNLABELED_CLOSED" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  WARNING: $UNLABELED_CLOSED closed issue(s) without labels (historical)${NC}"
        echo "   Run ./scripts/fix-unlabeled-issues.sh to fix these"
        WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
    fi
fi  # end of unlabeled skip check
echo ""

# ============================================
# 8. Comprehensive Documentation Verification
# ============================================
echo "📚 Comprehensive documentation verification..."
if should_skip "docs"; then
    echo -e "${YELLOW}⏭️  Skipped (reason: $SKIP_REASON)${NC}"
    DOC_UPDATES_NEEDED=0
    DOC_WARNINGS=()
else
    DOC_UPDATES_NEEDED=0
    DOC_WARNINGS=()

    # Get today's commits with file changes
    COMMITS_TODAY_FILES=$(git log --since="00:00" --name-only --pretty=format: 2>/dev/null | sort -u | grep -v "^$")

# Analyze what was done today
BACKEND_CHANGES=$(echo "$COMMITS_TODAY_FILES" | grep "^backend/" | wc -l | tr -d ' \n')
[ -z "$BACKEND_CHANGES" ] && BACKEND_CHANGES=0
FRONTEND_CHANGES=$(echo "$COMMITS_TODAY_FILES" | grep "^frontend/" | wc -l | tr -d ' \n')
[ -z "$FRONTEND_CHANGES" ] && FRONTEND_CHANGES=0
INFRA_CHANGES=$(echo "$COMMITS_TODAY_FILES" | grep "^infrastructure/" | wc -l | tr -d ' \n')
[ -z "$INFRA_CHANGES" ] && INFRA_CHANGES=0
SCRIPT_CHANGES=$(echo "$COMMITS_TODAY_FILES" | grep "^scripts/" | wc -l | tr -d ' \n')
[ -z "$SCRIPT_CHANGES" ] && SCRIPT_CHANGES=0
DOC_CHANGES=$(echo "$COMMITS_TODAY_FILES" | grep "^docs/" | wc -l | tr -d ' \n')
[ -z "$DOC_CHANGES" ] && DOC_CHANGES=0

# Get commit messages from today
COMMIT_MESSAGES=$(git log --since="00:00" --pretty=format:"%s" 2>/dev/null)

# Get counts for today
COMMITS_TODAY=$(git log --since="00:00" --oneline --no-merges 2>/dev/null | wc -l | tr -d ' ')
CLOSED_ISSUES_TODAY=$(gh issue list --state closed --search "closed:>=$(date '+%Y-%m-%d')" 2>/dev/null | wc -l || echo "0")
TODAY=$(date '+%Y-%m-%d')

echo "📊 Today's Activity Analysis:"
echo "   Backend changes: $BACKEND_CHANGES files"
echo "   Frontend changes: $FRONTEND_CHANGES files"
echo "   Infrastructure changes: $INFRA_CHANGES files"
echo "   Script changes: $SCRIPT_CHANGES files"
echo "   Doc changes: $DOC_CHANGES files"
echo "   Commits: $COMMITS_TODAY"
echo "   Issues closed: $CLOSED_ISSUES_TODAY"
echo ""

# ============================================
# 8.1 Check README.md
# ============================================
if [ "$COMMITS_TODAY" -gt 0 ]; then
    README_UPDATED=$(echo "$COMMITS_TODAY_FILES" | grep "^README.md" | wc -l | tr -d ' \n')
    [ -z "$README_UPDATED" ] && README_UPDATED=0
    
    # Check if README should have been updated
    if echo "$COMMIT_MESSAGES" | grep -iqE "(feat|feature|add|new|complete|implement)"; then
        if [ "$README_UPDATED" -eq 0 ]; then
            DOC_WARNINGS+=("README.md - New features added but README not updated")
            DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
        fi
    fi
    
    # Check if Current Status section needs updating
    if [ "$CLOSED_ISSUES_TODAY" -gt 0 ]; then
        if [ "$README_UPDATED" -eq 0 ]; then
            DOC_WARNINGS+=("README.md - Issues closed but 'Current Status' section may need update")
            DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
        fi
    fi
fi

# ============================================
# 8.2 Check PROJECT_PLAN.md
# ============================================
PROJECT_PLAN_UPDATED=$(echo "$COMMITS_TODAY_FILES" | grep "^docs/PROJECT_PLAN.md" | wc -l | tr -d ' \n')
[ -z "$PROJECT_PLAN_UPDATED" ] && PROJECT_PLAN_UPDATED=0
PLAN_DAYS_OLD=$(find docs/PROJECT_PLAN.md -mtime +14 2>/dev/null | wc -l | tr -d ' ')

if [ "$CLOSED_ISSUES_TODAY" -gt 0 ] && [ "$PROJECT_PLAN_UPDATED" -eq 0 ]; then
    DOC_WARNINGS+=("PROJECT_PLAN.md - Issues completed but release tracking not updated")
    DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
elif [ "$PLAN_DAYS_OLD" -gt 0 ] && [ "$COMMITS_TODAY" -gt 2 ]; then
    DOC_WARNINGS+=("PROJECT_PLAN.md - Not updated in 14+ days despite active development")
    DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
fi

# ============================================
# 8.3 Check STATUS.md
# ============================================
STATUS_UPDATED=$(echo "$COMMITS_TODAY_FILES" | grep "^docs/STATUS.md" | wc -l | tr -d ' \n')
[ -z "$STATUS_UPDATED" ] && STATUS_UPDATED=0
STATUS_DAYS_OLD=$(find docs/STATUS.md -mtime +7 2>/dev/null | wc -l | tr -d ' ')

if [ "$STATUS_DAYS_OLD" -gt 0 ] && [ "$COMMITS_TODAY" -gt 0 ]; then
    DOC_WARNINGS+=("STATUS.md - Project status not updated in 7+ days")
    DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
fi

# ============================================
# 8.4 Check ARCHITECTURE.md
# ============================================
ARCH_UPDATED=$(echo "$COMMITS_TODAY_FILES" | grep "^docs/ARCHITECTURE.md" | wc -l | tr -d ' \n')
[ -z "$ARCH_UPDATED" ] && ARCH_UPDATED=0

if [ "$BACKEND_CHANGES" -gt 5 ] || [ "$INFRA_CHANGES" -gt 2 ]; then
    if [ "$ARCH_UPDATED" -eq 0 ]; then
        DOC_WARNINGS+=("ARCHITECTURE.md - Significant code changes but architecture not documented")
        DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
    fi
fi

# Check for new models/services in backend
if echo "$COMMITS_TODAY_FILES" | grep -q "backend/app/models/"; then
    if [ "$ARCH_UPDATED" -eq 0 ]; then
        DOC_WARNINGS+=("ARCHITECTURE.md - New models added but architecture may need update")
        DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
    fi
fi

# ============================================
# 8.5 Check TIME_LOG.md
# ============================================
TIME_LOG_UPDATED=$(echo "$COMMITS_TODAY_FILES" | grep "^docs/TIME_LOG.md" | wc -l | tr -d ' \n')
[ -z "$TIME_LOG_UPDATED" ] && TIME_LOG_UPDATED=0

if [ "$COMMITS_TODAY" -gt 0 ] && [ "$TIME_LOG_UPDATED" -eq 0 ]; then
    # Check if there are entries for today
    if ! grep -q "$TODAY" "docs/TIME_LOG.md" 2>/dev/null; then
        DOC_WARNINGS+=("TIME_LOG.md - Work done today but no time logged")
        DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
    fi
fi

# ============================================
# 8.6 Check ISSUE_SUMMARY.md Consistency
# ============================================
ISSUE_SUMMARY_UPDATED=$(echo "$COMMITS_TODAY_FILES" | grep "^docs/ISSUE_SUMMARY.md" | wc -l | tr -d ' \n')
[ -z "$ISSUE_SUMMARY_UPDATED" ] && ISSUE_SUMMARY_UPDATED=0

if [ "$CLOSED_ISSUES_TODAY" -gt 0 ]; then
    # Will be auto-updated by script, but check if manual edits needed
    DOC_WARNINGS+=("ISSUE_SUMMARY.md - Verify closed issues are properly documented")
fi

# ============================================
# 8.7 Cross-Reference Validation
# ============================================
echo "🔍 Cross-reference validation..."

# Check if closed issues are mentioned in commits
if [ "$CLOSED_ISSUES_TODAY" -gt 0 ]; then
    CLOSED_ISSUE_NUMBERS=$(gh issue list --state closed --search "closed:>=$(date '+%Y-%m-%d')" 2>/dev/null | awk '{print $1}')
    
    for ISSUE_NUM in $CLOSED_ISSUE_NUMBERS; do
        if ! echo "$COMMIT_MESSAGES" | grep -q "#$ISSUE_NUM"; then
            DOC_WARNINGS+=("Commit messages - Issue #$ISSUE_NUM closed but not referenced in commits")
            DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
        fi
    done
fi

# Check if PR references issues
if [ -n "$COMMIT_MESSAGES" ]; then
    PR_REFS=$(echo "$COMMIT_MESSAGES" | grep -oE "#[0-9]+" | sort -u)
    if [ -z "$PR_REFS" ] && [ "$COMMITS_TODAY" -gt 1 ]; then
        DOC_WARNINGS+=("Commit messages - Multiple commits but no issue references found")
        DOC_UPDATES_NEEDED=$((DOC_UPDATES_NEEDED + 1))
    fi
fi

# ============================================
# 8.8 Display Documentation Status (BLOCKING)
# ============================================
echo ""
if [ "$DOC_UPDATES_NEEDED" -eq 0 ]; then
    echo -e "${GREEN}✅ All documentation verified and current${NC}"
else
    echo -e "${RED}❌ BLOCKING: Documentation must be updated before EOD!${NC}"
    echo -e "${RED}   $DOC_UPDATES_NEEDED documentation issue(s) found:${NC}"
    echo ""
    for warning in "${DOC_WARNINGS[@]}"; do
        echo -e "${RED}   • $warning${NC}"
    done
    echo ""
    echo "Update documentation and commit before proceeding."
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi
fi  # end of docs skip check
echo ""

# ============================================
# 9. Update Issue Summary Counts (only if no blocking issues)
# ============================================
# NOTE: Deferred until checks pass to avoid creating uncommitted changes that block EOD
if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo "📊 Updating issue summary..."

    # Get current issue counts
    TOTAL_OPEN=$(gh issue list --state open 2>/dev/null | wc -l || echo "0")
    TOTAL_CLOSED=$(gh issue list --state closed 2>/dev/null | wc -l || echo "0")
    P0_ISSUES=$(gh issue list --label "P0: Critical" --state open 2>/dev/null | wc -l || echo "0")
    P1_ISSUES=$(gh issue list --label "P1: High" --state open 2>/dev/null | wc -l || echo "0")

    # Update ISSUE_SUMMARY.md Quick Stats section
    if [ -f "docs/ISSUE_SUMMARY.md" ]; then
        # Create backup
        cp docs/ISSUE_SUMMARY.md docs/ISSUE_SUMMARY.md.bak
        
        # Update the Quick Stats section
        sed -i.tmp "/^## Quick Stats/,/^### By Epic/ {
            s/- \*\*Total Open Issues:\*\* [0-9]*/- **Total Open Issues:** $TOTAL_OPEN/
            s/- \*\*Total Closed Issues:\*\* [0-9]*/- **Total Closed Issues:** $TOTAL_CLOSED/
            s/- \*\*P0: Critical:\*\* [0-9]* issues/- **P0: Critical:** $P0_ISSUES issues/
            s/- \*\*P1: High:\*\* [0-9]* issues/- **P1: High:** $P1_ISSUES issues/
        }" docs/ISSUE_SUMMARY.md
        
        rm -f docs/ISSUE_SUMMARY.md.tmp
    
    if ! diff -q docs/ISSUE_SUMMARY.md docs/ISSUE_SUMMARY.md.bak > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Updated ISSUE_SUMMARY.md with current counts${NC}"
        rm -f docs/ISSUE_SUMMARY.md.bak
    else
        mv docs/ISSUE_SUMMARY.md.bak docs/ISSUE_SUMMARY.md
        echo -e "${GREEN}✅ ISSUE_SUMMARY.md already current${NC}"
    fi
    else
        echo -e "${YELLOW}⚠️  WARNING: docs/ISSUE_SUMMARY.md not found${NC}"
        WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
    fi
    echo ""
else
    echo "📊 Skipping issue summary update until blocking issues are resolved..."
    # Still need to get counts for the final summary
    TOTAL_OPEN=$(gh issue list --state open 2>/dev/null | wc -l || echo "0")
    TOTAL_CLOSED=$(gh issue list --state closed 2>/dev/null | wc -l || echo "0")
    echo ""
fi

# ============================================
# 10. Update Daily Status Log (Only if no blocking issues so far)
# ============================================
# NOTE: We defer doc updates until AFTER all checks pass to avoid the loop where:
#   EOD updates docs → uncommitted changes → user commits → EOD runs again → updates docs again
if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo "📖 Updating daily status log..."

    # Initialize daily log if it doesn't exist
    if [ ! -f "$DAILY_LOG" ]; then
        cat > "$DAILY_LOG" << 'EOF'
# Daily Status Log

Track daily progress and end-of-day state.

---

EOF
    fi

    # Get today's summary
    TODAY=$(date '+%Y-%m-%d')
    COMMITS_TODAY=$(git log --since="00:00" --oneline --no-merges 2>/dev/null | wc -l | tr -d ' ')
    CLOSED_ISSUES_TODAY=$(gh issue list --state closed --search "closed:>=$(date '+%Y-%m-%d')" 2>/dev/null | wc -l || echo "0")

    # Get last commit message
    LAST_COMMIT=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "No commits")

    # Get time log summary for today
    TIME_TODAY="0h 0m"
    if grep -q "$TODAY" "$PROJECT_ROOT/docs/TIME_LOG.md" 2>/dev/null; then
        TIME_TODAY=$(grep "$TODAY" "$PROJECT_ROOT/docs/TIME_LOG.md" | tail -1 | awk -F'|' '{print $4}' | xargs | cut -d' ' -f1,2)
    fi

    # Check if we already have an entry for today to avoid duplicate entries
    if ! grep -q "^## $TODAY" "$DAILY_LOG" 2>/dev/null; then
        # Create today's entry
        cat >> "$DAILY_LOG" << EOF

## $TODAY - $(date '+%A')

**End of Day Status:**
- ✅ Time tracking: Stopped
- ✅ Git status: Clean
- ✅ Branch: $CURRENT_BRANCH
- ✅ Open PRs: $OPEN_PRS
- ✅ Temp files: Cleaned

**Today's Work:**
- Commits: $COMMITS_TODAY
- Issues closed: $CLOSED_ISSUES_TODAY
- Time tracked: $TIME_TODAY
- Last commit: $LAST_COMMIT

**Open Issues:** $OPEN_ISSUES active

**Current Sprint:** Epic 1 (Foundation) & Epic 2 (Service Catalog)

**Next Session:**
- Continue with Issue #9 (Service Catalog UI) or Issue #7 (CI/CD Pipeline)
- Review open PRs if any
- Check for new issues or updates

---
EOF
        echo -e "${GREEN}✅ Daily status log updated${NC}"
    else
        echo -e "${GREEN}✅ Daily status log already has entry for today${NC}"
    fi

    # ============================================
    # 11. Auto-commit EOD documentation updates
    # ============================================
    # Automatically commit the updates this script made to avoid the loop
    if git diff --name-only | grep -qE "^docs/(DAILY_STATUS|ISSUE_SUMMARY)\.md$"; then
        echo ""
        echo "📝 Auto-committing EOD documentation updates..."
        git add docs/DAILY_STATUS.md docs/ISSUE_SUMMARY.md 2>/dev/null
        git commit -m "docs: EOD auto-update $(date '+%Y-%m-%d')" --no-verify 2>/dev/null
        echo -e "${GREEN}✅ EOD documentation updates committed${NC}"
        
        # Push the EOD commit
        if git push 2>/dev/null; then
            echo -e "${GREEN}✅ EOD commit pushed${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not push EOD commit (may need manual push)${NC}"
        fi
    fi
    echo ""
else
    echo ""
    echo -e "${YELLOW}⏸️  Skipping daily status update until blocking issues are resolved${NC}"
    echo ""
fi

# ============================================
# 12. Generate Summary Report
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 END OF DAY SUMMARY (STRICT MODE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$ISSUES_FOUND" -eq 0 ] && [ "$WARNINGS_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✅ CLEAN STATE - Ready to end the day!${NC}"
    echo ""
    echo "Summary:"
    if [ -n "$TIME_TRACKED_TODAY" ]; then
        echo -e "  • Time tracked today: ${GREEN}$TIME_TRACKED_TODAY${NC}"
    fi
    echo "  • Time tracking: Stopped"
    echo "  • Git: All changes committed and pushed"
    echo "  • Branch: $CURRENT_BRANCH"
    echo "  • Pull Requests: None open"
    echo "  • Issues: All properly labeled ($TOTAL_OPEN open)"
    echo "  • Documentation: Verified and current"
    echo "  • Temp files: Cleaned"
    echo "  • Daily log: Updated"
    echo ""
    if [ "$DOC_UPDATES_NEEDED" -gt 0 ]; then
        echo -e "${BLUE}📚 Documentation recommendations ($DOC_UPDATES_NEEDED items):${NC}"
        for warning in "${DOC_WARNINGS[@]}"; do
            echo -e "${BLUE}   • $warning${NC}"
        done
        echo ""
    fi
    echo -e "${BLUE}📖 View daily log: cat docs/DAILY_STATUS.md${NC}"
    echo -e "${BLUE}📊 View time log: cat docs/TIME_LOG.md${NC}"
    echo -e "${BLUE}📋 View issues: cat docs/ISSUE_SUMMARY.md${NC}"
    echo ""
    echo "🌙 Have a great evening!"
else
    echo -e "${RED}❌ ISSUES FOUND - Please resolve before ending the day${NC}"
    echo ""
    echo "Summary:"
    if [ -n "$TIME_TRACKED_TODAY" ]; then
        echo -e "  • Time tracked today: ${GREEN}$TIME_TRACKED_TODAY${NC}"
    fi
    echo "  🔴 Critical issues: $ISSUES_FOUND"
    echo "  ⚠️  Warnings: $WARNINGS_FOUND"
    echo ""
    if [ "$DOC_UPDATES_NEEDED" -gt 0 ]; then
        echo -e "${YELLOW}📚 Documentation recommendations ($DOC_UPDATES_NEEDED items):${NC}"
        for warning in "${DOC_WARNINGS[@]}"; do
            echo -e "${YELLOW}   • $warning${NC}"
        done
        echo ""
    fi
    echo "Please address the issues listed above and run this script again."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit with error if issues found
if [ "$ISSUES_FOUND" -gt 0 ]; then
    exit 1
fi

exit 0
