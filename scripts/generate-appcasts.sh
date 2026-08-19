#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:?usage: generate-appcasts.sh RELEASE_TAG}"
DOWNLOAD_PREFIX="https://github.com/anasubaid19/fomo-doro/releases/download/$TAG/"
RELEASE_PAGE="https://github.com/anasubaid19/fomo-doro/releases/tag/$TAG"

SPARKLE_TOOLS="$(find "$ROOT/.build/artifacts" -type d -path '*/Sparkle/bin' -print -quit)"
if [[ -z "$SPARKLE_TOOLS" || ! -x "$SPARKLE_TOOLS/generate_appcast" ]]; then
    echo "Sparkle generate_appcast tool was not found below .build/artifacts" >&2
    exit 1
fi

if [[ ! -f "$ROOT/FomoDoro.dmg" || ! -f "$ROOT/FomoDoro-macOS12-13.dmg" ]]; then
    echo "Build both DMG files before generating appcasts" >&2
    exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$WORK_DIR/modern" "$WORK_DIR/legacy"
cp "$ROOT/FomoDoro.dmg" "$WORK_DIR/modern/"
cp "$ROOT/FomoDoro-macOS12-13.dmg" "$WORK_DIR/legacy/"

generate_feed() {
    local source_dir="$1"
    local output_file="$2"
    local arguments=(
        --download-url-prefix "$DOWNLOAD_PREFIX"
        --link "$RELEASE_PAGE"
        --maximum-versions 1
        --maximum-deltas 0
        -o "$output_file"
        "$source_dir"
    )

    if [[ -n "${SPARKLE_EDDSA_PRIVATE_KEY:-}" ]]; then
        printf '%s' "$SPARKLE_EDDSA_PRIVATE_KEY" |
            "$SPARKLE_TOOLS/generate_appcast" --ed-key-file - "${arguments[@]}"
    else
        "$SPARKLE_TOOLS/generate_appcast" "${arguments[@]}"
    fi
}

generate_feed "$WORK_DIR/modern" "$ROOT/appcast-modern.xml"
generate_feed "$WORK_DIR/legacy" "$ROOT/appcast-legacy.xml"

echo "Generated signed appcast-modern.xml and appcast-legacy.xml"
