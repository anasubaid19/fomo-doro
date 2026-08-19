# FomoDoro Legacy

This package is the compatibility build for macOS 12 Monterey and macOS 13 Ventura.
It is intentionally isolated from the main macOS 14+ package:

- separate Swift package and source directory;
- separate bundle identifier and application name;
- separate JSON data store in Application Support;
- no SwiftData, Swift Charts, or macOS 14-only SwiftUI APIs;
- universal release binary for Intel and Apple Silicon Macs.

Build the app and DMG from the repository root:

```sh
./legacy/build-app.sh
./legacy/make-dmg.sh
```

The resulting release asset is `FomoDoro-macOS12-13.dmg`.
