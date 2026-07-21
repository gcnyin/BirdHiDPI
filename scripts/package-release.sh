#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
INFO_PLIST="$ROOT/Resources/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
ARCHIVE="$ROOT/dist/Bird-HiDPI-$VERSION-macos.zip"
CHECKSUM="$ARCHIVE.sha256"
APP="$ROOT/dist/Bird HiDPI.app"

"$ROOT/scripts/build-app.sh"
codesign --verify --deep --strict "$APP"

rm -f "$ARCHIVE" "$CHECKSUM"
ditto -c -k --norsrc --keepParent "$APP" "$ARCHIVE"

cd "$ROOT/dist"
shasum -a 256 "${ARCHIVE:t}" > "${CHECKSUM:t}"

echo "$ARCHIVE"
echo "$CHECKSUM"
