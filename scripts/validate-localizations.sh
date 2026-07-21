#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
BASE_LOCALE="en"
LOCALES=(en de es fr ga it nb pt sv zh-Hans zh-Hant)
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

plutil -lint "$ROOT/Resources/Info.plist" >/dev/null

for locale in "${LOCALES[@]}"; do
    LOCALIZABLE="$ROOT/Resources/$locale.lproj/Localizable.strings"
    INFO_PLIST="$ROOT/Resources/$locale.lproj/InfoPlist.strings"
    plutil -lint "$LOCALIZABLE" "$INFO_PLIST" >/dev/null
    sed -n 's/^"\([^"]*\)".*/\1/p' "$LOCALIZABLE" | sort -u > "$TEMP_DIR/$locale.keys"
done

for locale in "${LOCALES[@]:1}"; do
    diff -u "$TEMP_DIR/$BASE_LOCALE.keys" "$TEMP_DIR/$locale.keys"
done

echo "Localization resources are valid: ${LOCALES[*]}"
