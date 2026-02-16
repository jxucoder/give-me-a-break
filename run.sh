#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$ROOT_DIR/GiveMeABreak"
APP_PATH="$PROJECT_DIR/build/Build/Products/Debug/Give Me A Break.app"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

pushd "$PROJECT_DIR" >/dev/null

# Build if app does not exist yet, or when explicitly requested.
if [[ "${1:-}" == "--rebuild" || ! -d "$APP_PATH" ]]; then
  xcodebuild \
    -project "GiveMeABreak.xcodeproj" \
    -scheme "GiveMeABreak" \
    -configuration Debug \
    -derivedDataPath "build" \
    build
fi

open -n "$APP_PATH"
popd >/dev/null
