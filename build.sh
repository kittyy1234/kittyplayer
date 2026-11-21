#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
APP_NAME="KittyPlayer"
APP="$BUILD/$APP_NAME.app"
DMG="$BUILD/$APP_NAME.dmg"
SOURCES="$ROOT/Sources/KittyPlayer"
RESOURCES="$ROOT/Resources"

ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" && "$ARCH" != "x86_64" ]]; then
  ARCH="arm64"
fi

echo "Building $APP_NAME ($ARCH)…"
rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

SRC=( "$SOURCES"/*.swift )

echo "  compiling $ARCH"
swiftc -O -target "${ARCH}-apple-macos12" \
  -framework AppKit -framework WebKit -framework Foundation -framework CryptoKit \
  "${SRC[@]}" \
  -o "$APP/Contents/MacOS/KittyPlayer"
chmod +x "$APP/Contents/MacOS/KittyPlayer"

cp "$RESOURCES/overlay.html" "$APP/Contents/Resources/overlay.html"

ICON_SRC=""
for candidate in \
  "$ROOT/Icon.png" \
  "$RESOURCES/Icon.png" \
  "$RESOURCES/AppIcon.icns"
do
  if [[ -f "$candidate" ]]; then
    ICON_SRC="$candidate"
    break
  fi
done

ICON_KEY=""
if [[ -n "$ICON_SRC" ]]; then
  if [[ "$ICON_SRC" == *.icns ]]; then
    cp "$ICON_SRC" "$APP/Contents/Resources/AppIcon.icns"
    ICON_KEY=$'\n  <key>CFBundleIconFile</key>\n  <string>AppIcon</string>'
  else
    ICONSET="$BUILD/AppIcon.iconset"
    mkdir -p "$ICONSET"
    sips -z 16 16     "$ICON_SRC" --out "$ICONSET/icon_16x16.png" >/dev/null
    sips -z 32 32     "$ICON_SRC" --out "$ICONSET/diana.ag@example.org" >/dev/null
    sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_32x32.png" >/dev/null
    sips -z 64 64     "$ICON_SRC" --out "$ICONSET/ivan.p@example.net" >/dev/null
    sips -z 128 128   "$ICON_SRC" --out "$ICONSET/icon_128x128.png" >/dev/null
    sips -z 256 256   "$ICON_SRC" --out "$ICONSET/wendy.h@example.net" >/dev/null
    sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_256x256.png" >/dev/null
    sips -z 512 512   "$ICON_SRC" --out "$ICONSET/wendy.h@example.net" >/dev/null
    sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET/walt.e@example.net" >/dev/null
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
    ICON_KEY=$'\n  <key>CFBundleIconFile</key>\n  <string>AppIcon</string>'
  fi
else
  echo "  (no Icon.png – default icon)"
fi

cat > "$APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>KittyPlayer</string>
  <key>CFBundleDisplayName</key>
  <string>KittyPlayer</string>
  <key>CFBundleIdentifier</key>
  <string>com.kittyy1234.KittyPlayer</string>
  <key>CFBundleVersion</key>
  <string>2.1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>2.1.0</string>
  <key>CFBundleExecutable</key>
  <string>KittyPlayer</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>KittyPlayer needs to control Spotify and Apple Music.</string>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
  </dict>${ICON_KEY}
</dict>
</plist>
PLIST

echo -n "APPL????" > "$APP/Contents/PkgInfo"
codesign --force --deep --sign - "$APP" 2>/dev/null || true
xattr -cr "$APP" 2>/dev/null || true

echo "App: $APP"
echo "Creating DMG…"
STAGE="$BUILD/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "KittyPlayer" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "DMG: $DMG"
echo "Done."
