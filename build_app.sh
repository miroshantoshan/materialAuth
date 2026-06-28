#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
APP_NAME="MaterialAuth"
APP="$ROOT/dist/$APP_NAME.app"

cd "$ROOT"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/release/MaterialAuth" "$APP/Contents/MacOS/MaterialAuth"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/MaterialAuth.icns" "$APP/Contents/Resources/MaterialAuth.icns"

xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
echo "$APP"
