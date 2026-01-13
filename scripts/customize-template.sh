#!/bin/bash

# Get the directory where this script is located (scripts/)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of scripts)
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to root directory so we can process all files
cd "$ROOT_DIR" || exit 1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values (current template values)
OLD_APP_NAME="Full Stack Template"
OLD_PACKAGE_NAME="fllstck_tmplt"
OLD_SNAKE_CASE_NAME="fllstck_tmplt"
OLD_KEBAB_CASE_NAME="fllstck-tmplt"
OLD_CAMEL_CASE_NAME="fllstckTmplt"
OLD_ANDROID_PACKAGE="com.example.fllstck_tmplt"
OLD_IOS_BUNDLE="com.example.fllstckTmplt"

echo -e "${GREEN}Flutter Template Customization Script${NC}"
echo "========================================"
echo

# Get app name from argument or prompt
if [ -n "$1" ]; then
    NEW_APP_NAME="$1"
else
    read -p "Enter app name (e.g., 'My Awesome App'): " NEW_APP_NAME
    if [ -z "$NEW_APP_NAME" ]; then
        echo -e "${RED}Error: App name cannot be empty${NC}"
        exit 1
    fi
fi

# Prompt for organization/domain for bundle ID (skip if app name was provided as argument)
if [ -n "$1" ]; then
    ORG_DOMAIN="com.michaelbylstra"
else
    read -p "Enter organization domain [com.michaelbylstra]: " ORG_DOMAIN
    ORG_DOMAIN=${ORG_DOMAIN:-com.michaelbylstra}
fi

# Derive snake_case name (lowercase, hyphens to spaces)
NEW_SNAKE_CASE_NAME=$(echo "$NEW_APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr '-' '_')

# Derive kebab-case name (lowercase, spaces to hyphens)
NEW_KEBAB_CASE_NAME=$(echo "$NEW_APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')

# Derive camelCase (for bundle IDs)
NEW_CAMEL_CASE_NAME=$(echo "$NEW_SNAKE_CASE_NAME" | perl -pe 's/(_)([a-z])/uc($2)/ge; s/^([a-z])/lc($1)/e')

# Derive package name (same as snake_case)
NEW_PACKAGE_NAME="$NEW_SNAKE_CASE_NAME"

# Derive Android and iOS bundle identifiers
NEW_ANDROID_PACKAGE="${ORG_DOMAIN}.${NEW_PACKAGE_NAME}"
NEW_IOS_BUNDLE="${ORG_DOMAIN}.${NEW_CAMEL_CASE_NAME}"

echo
echo -e "${YELLOW}Confirmation:${NC}"
echo "  App Name: $NEW_APP_NAME"
echo "  kebab-case Name: $NEW_KEBAB_CASE_NAME"
echo "  snake_case Name: $NEW_SNAKE_CASE_NAME"
echo "  kebab-case Name: $NEW_KEBAB_CASE_NAME"
echo "  Package Name: $NEW_PACKAGE_NAME"
echo "  Android Package: $NEW_ANDROID_PACKAGE"
echo "  iOS Bundle: $NEW_IOS_BUNDLE"
echo

# Skip confirmation if app name was provided as argument
if [ -z "$1" ]; then
    read -p "Proceed with these values? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted${NC}"
        exit 1
    fi
fi

echo
echo -e "${GREEN}Updating files...${NC}"

# Function to replace in file (works on both macOS and Linux)
replace_in_file() {
    local file=$1
    local old=$2
    local new=$3

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|$old|$new|g" "$file"
    else
        sed -i "s|$old|$new|g" "$file"
    fi
}

# Function to check if a file should be excluded from replacements
should_exclude_file() {
    local file=$1

    # Exclude the customize-template script itself
    if [[ "$file" == "scripts/customize-template.sh" ]]; then
        return 0
    fi

    # Exclude top-level README.md
    if [[ "$file" == "README.md" ]]; then
        return 0
    fi

    # Exclude .github directory
    if [[ "$file" == .github/* ]]; then
        return 0
    fi

    return 1
}

# Function to replace all template variables in all git-tracked files
replace_everywhere() {
    echo "  - Processing all files in repository..."

    # Get all git-tracked files (automatically excludes .gitignored files)
    git ls-files | while read -r file; do
        # Skip if file should be excluded
        if should_exclude_file "$file"; then
            continue
        fi

        # Skip if file doesn't exist (shouldn't happen with git ls-files, but safety check)
        if [ ! -f "$file" ]; then
            continue
        fi

        # Check if file is binary (skip binary files)
        if file --mime "$file" | grep -q "charset=binary"; then
            continue
        fi

        # Replace all template variables in this file
        replace_in_file "$file" "$OLD_APP_NAME" "$NEW_APP_NAME"
        replace_in_file "$file" "$OLD_SNAKE_CASE_NAME" "$NEW_SNAKE_CASE_NAME"
        replace_in_file "$file" "$OLD_KEBAB_CASE_NAME" "$NEW_KEBAB_CASE_NAME"
        replace_in_file "$file" "$OLD_CAMEL_CASE_NAME" "$NEW_CAMEL_CASE_NAME"
        replace_in_file "$file" "$OLD_ANDROID_PACKAGE" "$NEW_ANDROID_PACKAGE"
        replace_in_file "$file" "$OLD_IOS_BUNDLE" "$NEW_IOS_BUNDLE"
    done
}

# Replace all template variables everywhere (except excluded files)
replace_everywhere

# Rename workspace file
OLD_WORKSPACE_FILE="fllstck-tmplt.code-workspace"
NEW_WORKSPACE_FILE="${NEW_KEBAB_CASE_NAME}.code-workspace"
if [ -f "$OLD_WORKSPACE_FILE" ]; then
    echo "  - Renaming workspace file"
    git mv "$OLD_WORKSPACE_FILE" "$NEW_WORKSPACE_FILE"
fi

# Move MainActivity.kt to new package directory structure
OLD_ANDROID_PATH="mobile-app/android/app/src/main/kotlin/$(echo $OLD_ANDROID_PACKAGE | tr '.' '/')"
NEW_ANDROID_PATH="mobile-app/android/app/src/main/kotlin/$(echo $NEW_ANDROID_PACKAGE | tr '.' '/')"

if [ -f "$OLD_ANDROID_PATH/MainActivity.kt" ]; then
    echo "  - Moving MainActivity.kt to new package directory"
    mkdir -p "$NEW_ANDROID_PATH"
    mv "$OLD_ANDROID_PATH/MainActivity.kt" "$NEW_ANDROID_PATH/MainActivity.kt"
    # Remove old directory structure if empty, working from deepest to shallowest
    # Stop if directory is not empty or if it's part of the new path
    CURRENT_DIR="$OLD_ANDROID_PATH"
    while [ "$CURRENT_DIR" != "mobile-app/android/app/src/main/kotlin" ] && [ -d "$CURRENT_DIR" ]; do
        # Only remove if directory is empty and not part of new path
        if [ -z "$(ls -A "$CURRENT_DIR")" ] && [[ "$NEW_ANDROID_PATH" != "$CURRENT_DIR"* ]]; then
            rmdir "$CURRENT_DIR"
            CURRENT_DIR="$(dirname "$CURRENT_DIR")"
        else
            break
        fi
    done
fi

echo
echo -e "${GREEN}Committing changes...${NC}"

# Add all changes
git add -A

# Create commit
git commit -m "chore: Customize template for '$NEW_APP_NAME'

- Update app name to '$NEW_APP_NAME'
- Update package name to '$NEW_PACKAGE_NAME'
- Update bundle IDs: Android ($NEW_ANDROID_PACKAGE), iOS ($NEW_IOS_BUNDLE)"

echo
echo -e "${GREEN}✓ Template customization complete!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "  Continue following the steps in the README.md"
