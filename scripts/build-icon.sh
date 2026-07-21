#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
MASTER="$ROOT/Resources/AppIcon.png"
OUTPUT="$ROOT/Resources/AppIcon.icns"
TEMP_DIR="$(mktemp -d)"
ICONSET="$TEMP_DIR/AppIcon.iconset"
trap 'rm -rf "$TEMP_DIR"' EXIT

swift "$ROOT/scripts/generate-icon.swift" "$MASTER"
mkdir -p "$ICONSET"

resize() {
    sips -z "$2" "$2" "$MASTER" --out "$ICONSET/$1" >/dev/null
}

resize icon_16x16.png 16
resize icon_16x16@2x.png 32
resize icon_32x32.png 32
resize icon_32x32@2x.png 64
resize icon_128x128.png 128
resize icon_128x128@2x.png 256
resize icon_256x256.png 256
resize icon_256x256@2x.png 512
resize icon_512x512.png 512
resize icon_512x512@2x.png 1024

iconutil -c icns "$ICONSET" -o "$OUTPUT"
echo "$OUTPUT"
