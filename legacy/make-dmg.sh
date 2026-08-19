#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STAGE="legacy-dmg-staging"
DMG="FomoDoro-macOS12-13.dmg"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
ditto "FomoDoro Legacy.app" "$STAGE/FomoDoro Legacy.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "FomoDoro for macOS 12-13" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"
echo "Built $DMG"
