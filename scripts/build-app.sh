#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
cd "$ROOT"

swift build -c release --product BirdHiDPI
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$ROOT/dist/Bird HiDPI.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/BirdHiDPI" "$APP/Contents/MacOS/BirdHiDPI"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/LICENSE" "$APP/Contents/Resources/LICENSE"
cp -R "$ROOT"/Resources/*.lproj "$APP/Contents/Resources/"
codesign --force --deep --sign - "$APP"

echo "$APP"
