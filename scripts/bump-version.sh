#!/usr/bin/env bash
set -euo pipefail

PBXPROJ="GiveMeABreak/GiveMeABreak.xcodeproj/project.pbxproj"

usage() {
    echo "Usage: $0 <version>  (e.g. 1.2.0)"
    exit 1
}

[[ $# -eq 1 ]] || usage
VERSION="$1"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: version must be in semver format (e.g. 1.2.0)"
    exit 1
fi

if ! [ -f "$PBXPROJ" ]; then
    echo "Error: $PBXPROJ not found. Run this script from the repo root."
    exit 1
fi

CURRENT=$(grep -m1 'MARKETING_VERSION' "$PBXPROJ" | sed 's/.*= *//;s/;.*//')
echo "Bumping version: $CURRENT -> $VERSION"

sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $VERSION/g" "$PBXPROJ"

BUILD=$(($(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | sed 's/.*= *//;s/;.*//') + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*/CURRENT_PROJECT_VERSION = $BUILD/g" "$PBXPROJ"

echo "Set MARKETING_VERSION=$VERSION, CURRENT_PROJECT_VERSION=$BUILD"

git add "$PBXPROJ"
git commit -m "Bump version to $VERSION (build $BUILD)"
git tag "v$VERSION"

echo ""
echo "Done! Push the tag to trigger the release pipeline:"
echo "  git push origin main v$VERSION"
