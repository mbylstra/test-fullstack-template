#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values (current template values)
OLD_APP_NAME="Full Stack Template"
OLD_PACKAGE_NAME="fllstcktmplt"
OLD_KEBAB_NAME="fllstck-tmplt"
OLD_CAMEL_CASE="fllstckTmplt"
OLD_ANDROID_PACKAGE="com.example.fllstcktmplt"
OLD_IOS_BUNDLE="com.example.fllstckTmplt"

echo -e "${GREEN}Flutter Template Customization Script${NC}"
echo "========================================"
echo

# Prompt for new app name
read -p "Enter app name (e.g., 'My Awesome App'): " NEW_APP_NAME
if [ -z "$NEW_APP_NAME" ]; then
    echo -e "${RED}Error: App name cannot be empty${NC}"
    exit 1
fi

# Prompt for organization/domain for bundle ID
read -p "Enter organization domain (e.g., 'com.mycompany'): " ORG_DOMAIN
if [ -z "$ORG_DOMAIN" ]; then
    echo -e "${RED}Error: Organization domain cannot be empty${NC}"
    exit 1
fi

# Derive package name from app name (lowercase, spaces to underscores)
NEW_PACKAGE_NAME=$(echo "$NEW_APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr '-' '_')

# Derive kebab-case name (lowercase, spaces to hyphens)
NEW_KEBAB_NAME=$(echo "$NEW_APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')

# Derive camelCase (for bundle IDs)
NEW_CAMEL_CASE=$(echo "$NEW_PACKAGE_NAME" | perl -pe 's/(_)([a-z])/uc($2)/ge; s/^([a-z])/lc($1)/e')

# Derive Android and iOS bundle identifiers
NEW_ANDROID_PACKAGE="${ORG_DOMAIN}.${NEW_PACKAGE_NAME}"
NEW_IOS_BUNDLE="${ORG_DOMAIN}.${NEW_CAMEL_CASE}"

echo
echo -e "${YELLOW}Confirmation:${NC}"
echo "  App Name: $NEW_APP_NAME"
echo "  Package Name: $NEW_PACKAGE_NAME"
echo "  Kebab Name: $NEW_KEBAB_NAME"
echo "  Android Package: $NEW_ANDROID_PACKAGE"
echo "  iOS Bundle: $NEW_IOS_BUNDLE"
echo
read -p "Proceed with these values? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
fi

echo
echo -e "${GREEN}Updating files...${NC}"

# Set sed suffix based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_SUFFIX=" ''"
else
    SED_SUFFIX=""
fi

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

# Function to replace in all files in a directory (excluding binary files)
replace_in_directory() {
    local dir=$1
    local old=$2
    local new=$3

    if [ ! -d "$dir" ]; then
        return
    fi

    # Only process text files, exclude binary files
    if [[ "$OSTYPE" == "darwin"* ]]; then
        find "$dir" -type f ! -name "*.png" ! -name "*.jpg" ! -name "*.jpeg" ! -name "*.ico" ! -name "*.jar" ! -name "*.keystore" ! -name "*.ttf" ! -name "*.otf" -exec grep -Il . {} \; 2>/dev/null | while read -r file; do
            sed -i '' "s|$old|$new|g" "$file" 2>/dev/null || true
        done
    else
        find "$dir" -type f ! -name "*.png" ! -name "*.jpg" ! -name "*.jpeg" ! -name "*.ico" ! -name "*.jar" ! -name "*.keystore" ! -name "*.ttf" ! -name "*.otf" -exec grep -Il . {} \; 2>/dev/null | while read -r file; do
            sed -i "s|$old|$new|g" "$file" 2>/dev/null || true
        done
    fi
}

# Update root level files
echo "  - pubspec.yaml"
replace_in_file "pubspec.yaml" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"

if [ -f "README.md" ]; then
    echo "  - README.md"
    replace_in_file "README.md" "$OLD_APP_NAME" "$NEW_APP_NAME"
    replace_in_file "README.md" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
fi

# Update Android directory
echo "  - android/"
replace_in_directory "android" "$OLD_APP_NAME" "$NEW_APP_NAME"
replace_in_directory "android" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"
replace_in_directory "android" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
replace_in_directory "android" "$OLD_ANDROID_PACKAGE" "$NEW_ANDROID_PACKAGE"

# Move MainActivity.kt to new package directory structure
OLD_ANDROID_PATH="android/app/src/main/kotlin/$(echo $OLD_ANDROID_PACKAGE | tr '.' '/')"
NEW_ANDROID_PATH="android/app/src/main/kotlin/$(echo $NEW_ANDROID_PACKAGE | tr '.' '/')"

if [ -f "$OLD_ANDROID_PATH/MainActivity.kt" ]; then
    echo "  - Moving MainActivity.kt to new package directory"
    mkdir -p "$NEW_ANDROID_PATH"
    mv "$OLD_ANDROID_PATH/MainActivity.kt" "$NEW_ANDROID_PATH/MainActivity.kt"
    # Remove old directory structure if empty, working from deepest to shallowest
    # Stop if directory is not empty or if it's part of the new path
    CURRENT_DIR="$OLD_ANDROID_PATH"
    while [ "$CURRENT_DIR" != "android/app/src/main/kotlin" ] && [ -d "$CURRENT_DIR" ]; do
        # Only remove if directory is empty and not part of new path
        if [ -z "$(ls -A "$CURRENT_DIR")" ] && [[ "$NEW_ANDROID_PATH" != "$CURRENT_DIR"* ]]; then
            rmdir "$CURRENT_DIR"
            CURRENT_DIR="$(dirname "$CURRENT_DIR")"
        else
            break
        fi
    done
fi

# Update iOS directory
echo "  - ios/"
replace_in_directory "ios" "$OLD_APP_NAME" "$NEW_APP_NAME"
replace_in_directory "ios" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"
replace_in_directory "ios" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
replace_in_directory "ios" "$OLD_CAMEL_CASE" "$NEW_CAMEL_CASE"
replace_in_directory "ios" "$OLD_IOS_BUNDLE" "$NEW_IOS_BUNDLE"

# Update macOS directory
echo "  - macos/"
replace_in_directory "macos" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"
replace_in_directory "macos" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
replace_in_directory "macos" "$OLD_CAMEL_CASE" "$NEW_CAMEL_CASE"
replace_in_directory "macos" "$OLD_IOS_BUNDLE" "$NEW_IOS_BUNDLE"
replace_in_directory "macos" "$OLD_PACKAGE_NAME.app" "$NEW_PACKAGE_NAME.app"

# Update Linux directory
echo "  - linux/"
replace_in_directory "linux" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"
replace_in_directory "linux" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
replace_in_directory "linux" "$OLD_ANDROID_PACKAGE" "$NEW_ANDROID_PACKAGE"

# Update Windows directory
echo "  - windows/"
replace_in_directory "windows" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"
replace_in_directory "windows" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
replace_in_directory "windows" "$OLD_PACKAGE_NAME.exe" "$NEW_PACKAGE_NAME.exe"

# Update Web directory
echo "  - web/"
replace_in_directory "web" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"
replace_in_directory "web" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"

# Update lib directory
echo "  - lib/"
replace_in_directory "lib" "$OLD_APP_NAME" "$NEW_APP_NAME"
replace_in_directory "lib" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
replace_in_directory "lib" "package:$OLD_PACKAGE_NAME" "package:$NEW_PACKAGE_NAME"

# Update test directory
echo "  - test/"
replace_in_directory "test" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
replace_in_directory "test" "package:$OLD_PACKAGE_NAME" "package:$NEW_PACKAGE_NAME"

# Update widgetbook directory
echo "  - widgetbook/"
replace_in_directory "widgetbook" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"
replace_in_directory "widgetbook" "$OLD_KEBAB_NAME" "$NEW_KEBAB_NAME"
replace_in_directory "widgetbook" "package:$OLD_PACKAGE_NAME" "package:$NEW_PACKAGE_NAME"

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