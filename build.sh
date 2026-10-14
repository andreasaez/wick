#!/bin/sh
# Builds Wick.app from source. Usage: ./build.sh [--install]
set -eu

cd "$(dirname "$0")"
ROOT=$(pwd)
APP=build/Wick.app
BUNDLE_ID=dev.wick.Wick
INSTALLED=/Applications/Wick.app

# Use Apple's toolchain by absolute path, never whatever is first on PATH.
if ! /usr/bin/xcrun --sdk macosx --find swiftc >/dev/null 2>&1; then
  echo "Swift compiler not found. Install the Command Line Tools: xcode-select --install" >&2
  exit 1
fi
if [ "$(/usr/bin/uname -m)" != "arm64" ]; then
  echo "Wick supports Apple silicon Macs only." >&2
  exit 1
fi

/bin/rm -rf build
/bin/mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/icon

# The app icon is drawn from code (scripts/icon + Sources/Flame.swift), so the
# repo holds no image files. Build the drawing tool, render, then convert.
/usr/bin/xcrun --sdk macosx swiftc -O -swift-version 6 \
  scripts/icon/main.swift Sources/Flame.swift \
  -o build/icon/make-icon
build/icon/make-icon build/icon/Wick.iconset
/usr/bin/iconutil -c icns build/icon/Wick.iconset -o "$APP/Contents/Resources/Wick.icns"

# Apple silicon only.
# -file-prefix-map keeps your local folder path out of the binary.
/usr/bin/xcrun --sdk macosx swiftc -O -swift-version 6 \
  -target arm64-apple-macos13.0 \
  -file-prefix-map "$ROOT=." \
  -module-name Wick \
  Sources/*.swift \
  -o "$APP/Contents/MacOS/Wick"

/usr/bin/strip -x "$APP/Contents/MacOS/Wick"
/bin/rm -rf build/icon

/bin/cp Resources/Info.plist "$APP/Contents/Info.plist"

# Hardened runtime + sandbox entitlements. Hardened runtime blocks debuggers
# and code injection; the sandbox blocks network, files and inter-app access.
# Ad-hoc signed ("-"), so no Apple developer account is needed.
/usr/bin/codesign --force --sign - \
  --options runtime \
  --entitlements Resources/Wick.entitlements \
  "$APP"

echo "Built $APP"

if [ "${1:-}" = "--install" ]; then
  # Only ever replace a previous Wick, never some other app with the same name.
  if [ -e "$INSTALLED" ]; then
    EXISTING=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INSTALLED/Contents/Info.plist" 2>/dev/null || true)
    if [ "$EXISTING" != "$BUNDLE_ID" ]; then
      echo "$INSTALLED exists but isn't Wick ($EXISTING). Not touching it." >&2
      exit 1
    fi
  fi

  # Stop running copies of Wick only, matched by their exact paths.
  /usr/bin/pkill -f "^$INSTALLED/Contents/MacOS/Wick\$" 2>/dev/null || true
  /usr/bin/pkill -f "^$ROOT/$APP/Contents/MacOS/Wick\$" 2>/dev/null || true

  if ! { /bin/rm -rf "$INSTALLED" && /usr/bin/ditto "$APP" "$INSTALLED"; }; then
    echo "Couldn't write to /Applications. If macOS says Terminal was prevented from" >&2
    echo "modifying apps, allow it in System Settings > Privacy & Security > App Management." >&2
    exit 1
  fi
  /usr/bin/open "$INSTALLED"
  echo "Installed to $INSTALLED"
fi
