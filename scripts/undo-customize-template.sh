#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Template Undo Script${NC}"
echo "=========================================="
echo

# Get the directory where this script is located (scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the project root directory (parent of scripts)
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
# Path to customize script
CUSTOMIZE_SCRIPT="$SCRIPT_DIR/customize-template.sh"

# Change to root directory for git operations
cd "$ROOT_DIR" || exit 1

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if there are any uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}Error: There are uncommitted changes. Please commit or stash them first.${NC}"
    exit 1
fi

# Get the last commit message to verify it's the customization commit
LAST_COMMIT=$(git log -1 --pretty=format:"%s")
if [[ ! "$LAST_COMMIT" =~ ^chore:\ Customize\ template\ for ]]; then
    echo -e "${RED}Error: Last commit is not a template customization commit${NC}"
    echo "Last commit: $LAST_COMMIT"
    exit 1
fi

echo
echo -e "${YELLOW}This will:${NC}"
echo "  1. Reset the last commit"
echo "  2. Preserve any changes to scripts/customize-template.sh"
echo "  3. Discard all other changes"
echo

read -p "Proceed? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
fi

echo
echo -e "${GREEN}Undoing customization...${NC}"

# Save any changes to scripts/customize-template.sh before resetting
TEMP_CUSTOMIZE=$(mktemp)
if [ -f "$CUSTOMIZE_SCRIPT" ]; then
    cp "$CUSTOMIZE_SCRIPT" "$TEMP_CUSTOMIZE"
fi

# Reset to the previous commit
git reset --hard HEAD~1

# Restore the customize script if there were changes
if [ -f "$TEMP_CUSTOMIZE" ]; then
    # Check if file content differs from what we just reset to
    if ! cmp -s "$TEMP_CUSTOMIZE" "$CUSTOMIZE_SCRIPT" 2>/dev/null; then
        cp "$TEMP_CUSTOMIZE" "$CUSTOMIZE_SCRIPT"
        git add "$CUSTOMIZE_SCRIPT"
        echo "  - Restored changes to scripts/customize-template.sh"
    fi
    rm "$TEMP_CUSTOMIZE"
fi

echo
echo -e "${GREEN}✓ Template customization undone!${NC}"
echo
echo -e "${YELLOW}Status:${NC}"
git status
