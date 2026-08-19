#!/bin/bash
set -euo pipefail

swift build -c release

# ponytail: inject the latest git tag as the bundle version so it never drifts
VERSION="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
VERSION="${VERSION:-0.0.0}"

APP="FomoDoro.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/FomoDoro "$APP/Contents/MacOS/FomoDoro"
./scripts/embed-sparkle.sh "$APP" ".build"

TMP_PLIST="$(mktemp)"
cp scripts/Info.plist "$TMP_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$TMP_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$TMP_PLIST"
cp "$TMP_PLIST" "$APP/Contents/Info.plist"
rm "$TMP_PLIST"

ICONSET="FomoDoro.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
sips -z 16 16 FomoDoro-icon.png --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 FomoDoro-icon.png --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 FomoDoro-icon.png --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 FomoDoro-icon.png --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 FomoDoro-icon.png --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 FomoDoro-icon.png --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 FomoDoro-icon.png --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 FomoDoro-icon.png --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 FomoDoro-icon.png --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 FomoDoro-icon.png --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o FomoDoro.icns
cp FomoDoro.icns "$APP/Contents/Resources/FomoDoro.icns"
rm -rf "$ICONSET" FomoDoro.icns

# Seal the assembled bundle after adding resources. Sparkle's nested helpers keep
# their upstream signatures; the outer app receives a valid ad-hoc signature.
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"

echo "Built $APP"
