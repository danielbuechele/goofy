#!/bin/bash
set -e

# Get the project directory (parent of scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_FILE="$PROJECT_DIR/goofy.xcodeproj/project.pbxproj"

# Get current build number from project
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PROJECT_FILE" | sed 's/.*= //' | sed 's/;.*//')

# Get current marketing version base (e.g., "4.0" or "4.0.139")
CURRENT_MARKETING=$(grep -m1 'MARKETING_VERSION = ' "$PROJECT_FILE" | sed 's/.*= //' | sed 's/;.*//')

# Extract the major.minor part (first two components only)
MARKETING_BASE=$(echo "$CURRENT_MARKETING" | cut -d. -f1,2)

# Increment build number
NEW_BUILD=$((CURRENT_BUILD + 1))

# Create new marketing version: major.minor.build
NEW_MARKETING="${MARKETING_BASE}.${NEW_BUILD}"

# Update build number in project file (all occurrences)
sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PROJECT_FILE"

# Update marketing version in project file (all occurrences)
sed -i '' "s/MARKETING_VERSION = ${CURRENT_MARKETING};/MARKETING_VERSION = ${NEW_MARKETING};/g" "$PROJECT_FILE"

echo "Build ${NEW_BUILD}, version ${NEW_MARKETING}"
