#!/bin/bash
set -euo pipefail

APP_PATH="${1:?usage: embed-sparkle.sh APP_PATH BUILD_ROOT}"
BUILD_ROOT="${2:?usage: embed-sparkle.sh APP_PATH BUILD_ROOT}"

SPARKLE_FRAMEWORK="$(find "$BUILD_ROOT/artifacts" -type d -name Sparkle.framework -path '*macos*' -print -quit)"
if [[ -z "$SPARKLE_FRAMEWORK" ]]; then
    echo "Sparkle.framework was not found below $BUILD_ROOT/artifacts" >&2
    exit 1
fi

mkdir -p "$APP_PATH/Contents/Frameworks"
# Sparkle.framework contains versioned symlinks; ditto preserves them and its signature.
ditto "$SPARKLE_FRAMEWORK" "$APP_PATH/Contents/Frameworks/Sparkle.framework"
