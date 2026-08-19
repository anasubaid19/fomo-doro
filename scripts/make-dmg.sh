#!/bin/bash
set -euo pipefail

STAGE="dmg-staging"
rm -rf "$STAGE" FomoDoro.dmg
mkdir -p "$STAGE"
ditto FomoDoro.app "$STAGE/FomoDoro.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "FomoDoro" -srcfolder "$STAGE" -ov -format UDZO FomoDoro.dmg
rm -rf "$STAGE"
echo "Built FomoDoro.dmg"
