#!/bin/zsh
set -eu
cd -P "$(dirname "$0")"
APP="build/Google Translate Menu.app"
mkdir -p "$APP/Contents/MacOS"
MODULE_CACHE=$(mktemp -d /private/tmp/gtmenu-module-cache.XXXXXX)
trap 'rm -rf "$MODULE_CACHE"' EXIT
xcrun swiftc -module-cache-path "$MODULE_CACHE" Sources/App.swift -parse-as-library -target arm64-apple-macosx13.0 -O -o "$APP/Contents/MacOS/GoogleTranslateMenu"
cp Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
printf 'Built: %s\n' "$PWD/$APP"
