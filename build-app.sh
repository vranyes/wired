#!/bin/sh
# Build the Wired menu-bar app and wrap it in Wired.app.
set -eu

cd "$(dirname "$0")"

APP_NAME="Wired"
BUNDLE_ID="com.personal.wired"
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

# App icon: render the SVG source to .icns (rebuilt when the SVG changes).
ICON_SVG="Resources/AppIcon.svg"
ICON_ICNS=".build/AppIcon.icns"
if [ ! -f "$ICON_ICNS" ] || [ "$ICON_SVG" -nt "$ICON_ICNS" ]; then
  echo "==> rendering app icon"
  rm -rf .build/AppIcon.iconset .build/AppIcon-master.png
  mkdir -p .build/AppIcon.iconset
  qlmanage -t -s 1024 -o .build "$ICON_SVG" >/dev/null 2>&1
  mv ".build/$(basename "$ICON_SVG").png" .build/AppIcon-master.png
  sips -z 16 16     .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_16x16.png >/dev/null
  sips -z 32 32     .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_16x16@2x.png >/dev/null
  sips -z 32 32     .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_32x32.png >/dev/null
  sips -z 64 64     .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_32x32@2x.png >/dev/null
  sips -z 128 128   .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_128x128.png >/dev/null
  sips -z 256 256   .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_256x256.png >/dev/null
  sips -z 256 256   .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_128x128@2x.png >/dev/null
  sips -z 512 512   .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_256x256@2x.png >/dev/null
  sips -z 512 512   .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_512x512.png >/dev/null
  sips -z 1024 1024 .build/AppIcon-master.png --out .build/AppIcon.iconset/icon_512x512@2x.png >/dev/null
  iconutil -c icns .build/AppIcon.iconset -o "$ICON_ICNS"
fi
cp "$ICON_ICNS" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Ad-hoc sign so macOS lets it run locally without a quarantine fight.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true
fi

echo "==> done: $(pwd)/$APP_BUNDLE"
echo "Run with: open \"$APP_BUNDLE\""
echo "Check assertions with: pmset -g assertions | grep -i -A2 wired"
