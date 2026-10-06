#!/bin/sh
# Build the Awake menu-bar app and wrap it in Awake.app.
set -eu

cd "$(dirname "$0")"

APP_NAME="Awake"
BUNDLE_ID="com.personal.awake"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

echo "==> swift build -c release"
swift build -c release --build-system native

echo "==> assembling $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Ad-hoc sign so macOS lets it run locally without a quarantine fight.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true
fi

echo "==> done: $(pwd)/$APP_BUNDLE"
echo "Run with: open \"$APP_BUNDLE\""
echo "Check assertions with: pmset -g assertions | grep -i -A2 awake"
