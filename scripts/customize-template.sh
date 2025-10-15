#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values (current template values)
OLD_APP_NAME="Flutter Template"
OLD_PACKAGE_NAME="flutter_template"
OLD_ANDROID_PACKAGE="com.example.flutter_template"
OLD_IOS_BUNDLE="com.example.flutterTemplate"
OLD_FIREBASE_PROJECT="mb-flutter-template"

echo -e "${GREEN}Flutter Template Customization Script${NC}"
echo "========================================"
echo

# Prompt for new app name
read -p "Enter app name (e.g., 'My Awesome App'): " NEW_APP_NAME
if [ -z "$NEW_APP_NAME" ]; then
    echo -e "${RED}Error: App name cannot be empty${NC}"
    exit 1
fi

# Prompt for new Firebase project name
read -p "Enter Firebase project name (e.g., 'my-awesome-app'): " NEW_FIREBASE_PROJECT
if [ -z "$NEW_FIREBASE_PROJECT" ]; then
    echo -e "${RED}Error: Firebase project name cannot be empty${NC}"
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

# Derive Android and iOS bundle identifiers
NEW_ANDROID_PACKAGE="${ORG_DOMAIN}.${NEW_PACKAGE_NAME}"
# iOS uses camelCase for the last segment
IOS_SUFFIX=$(echo "$NEW_PACKAGE_NAME" | perl -pe 's/(_)([a-z])/uc($2)/ge; s/^([a-z])/lc($1)/e')
NEW_IOS_BUNDLE="${ORG_DOMAIN}.${IOS_SUFFIX}"

echo
echo -e "${YELLOW}Confirmation:${NC}"
echo "  App Name: $NEW_APP_NAME"
echo "  Package Name: $NEW_PACKAGE_NAME"
echo "  Android Package: $NEW_ANDROID_PACKAGE"
echo "  iOS Bundle: $NEW_IOS_BUNDLE"
echo "  Firebase Project: $NEW_FIREBASE_PROJECT"
echo
read -p "Proceed with these values? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
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

# Update pubspec.yaml
echo "  - pubspec.yaml"
replace_in_file "pubspec.yaml" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"

# Update Android files
echo "  - android/app/build.gradle.kts"
replace_in_file "android/app/build.gradle.kts" "$OLD_ANDROID_PACKAGE" "$NEW_ANDROID_PACKAGE"

echo "  - android/app/src/main/AndroidManifest.xml"
replace_in_file "android/app/src/main/AndroidManifest.xml" "$OLD_APP_NAME" "$NEW_APP_NAME"

# Update iOS files
echo "  - ios/Runner/Info.plist"
replace_in_file "ios/Runner/Info.plist" "$OLD_APP_NAME" "$NEW_APP_NAME"
replace_in_file "ios/Runner/Info.plist" "$OLD_PACKAGE_NAME" "$NEW_PACKAGE_NAME"

echo "  - ios/Runner.xcodeproj/project.pbxproj"
replace_in_file "ios/Runner.xcodeproj/project.pbxproj" "$OLD_IOS_BUNDLE" "$NEW_IOS_BUNDLE"

# Update Dart files
echo "  - lib/screens/home_screen.dart"
replace_in_file "lib/screens/home_screen.dart" "$OLD_APP_NAME" "$NEW_APP_NAME"

# Update README
if [ -f "README.md" ]; then
    echo "  - README.md"
    replace_in_file "README.md" "$OLD_APP_NAME" "$NEW_APP_NAME"
fi

# Update Firebase files
echo "  - firebase.json"
replace_in_file "firebase.json" "$OLD_FIREBASE_PROJECT" "$NEW_FIREBASE_PROJECT"

echo "  - lib/firebase_options.dart"
replace_in_file "lib/firebase_options.dart" "$OLD_FIREBASE_PROJECT" "$NEW_FIREBASE_PROJECT"

if [ -f "android/app/google-services.json" ]; then
    echo "  - android/app/google-services.json"
    replace_in_file "android/app/google-services.json" "$OLD_FIREBASE_PROJECT" "$NEW_FIREBASE_PROJECT"
    replace_in_file "android/app/google-services.json" "$OLD_ANDROID_PACKAGE" "$NEW_ANDROID_PACKAGE"
fi

echo
echo -e "${GREEN}Committing changes...${NC}"

# Add all changes
git add -A

# Create commit
git commit -m "chore: Customize template for '$NEW_APP_NAME'

- Update app name to '$NEW_APP_NAME'
- Update package name to '$NEW_PACKAGE_NAME'
- Update bundle IDs: Android ($NEW_ANDROID_PACKAGE), iOS ($NEW_IOS_BUNDLE)
- Update Firebase project to '$NEW_FIREBASE_PROJECT'"

echo
echo -e "${GREEN}✓ Template customization complete!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "  Continue following the steps in the README.md