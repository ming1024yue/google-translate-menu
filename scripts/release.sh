#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
MODE="${1:---preview}"
if [[ "$MODE" != "--preview" && "$MODE" != "--publish" ]]; then
  print -u2 'Usage: ./scripts/release.sh --preview | --publish'; exit 1
fi
if [[ "$MODE" == "--publish" ]]; then
  : "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to your Developer ID Application certificate name}"
  : "${NOTARY_PROFILE:?Set NOTARY_PROFILE to a notarytool keychain profile}"
  if [[ "$SIGNING_IDENTITY" != 'Developer ID Application:'* ]]; then
    print -u2 'A Developer ID Application identity is required.'; exit 1
  fi
  security find-identity -v -p codesigning | /usr/bin/grep -F -- "$SIGNING_IDENTITY" >/dev/null
fi
./build.sh
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
APP='build/Google Translate Menu.app'
WORK=$(mktemp -d /private/tmp/gtmenu-release.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
mkdir -p release
if [[ "$MODE" == "--publish" ]]; then
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP"
  codesign --verify --strict --verbose=2 "$APP"
  ditto -c -k --keepParent "$APP" "$WORK/app.zip"
  xcrun notarytool submit "$WORK/app.zip" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json > "$WORK/app-notary.json"
  cp "$WORK/app-notary.json" release/app-notary.json
  /usr/bin/grep -q '"status" *: *"Accepted"' "$WORK/app-notary.json"
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
  spctl --assess --type execute --verbose=2 "$APP"
  NAME="GoogleTranslateMenu-${VERSION}-arm64"
else
  NAME="GoogleTranslateMenu-${VERSION}-arm64-PREVIEW-UNNOTARIZED"
fi
mkdir -p "$WORK/image"
ditto "$APP" "$WORK/image/Google Translate Menu.app"
ln -s /Applications "$WORK/image/Applications"
cp release/INSTALL.txt "$WORK/image/安装说明.txt"
hdiutil create -volname 'Google Translate Menu' -srcfolder "$WORK/image" -ov -format UDZO "$WORK/$NAME.dmg"
if [[ "$MODE" == "--publish" ]]; then
  codesign --timestamp --sign "$SIGNING_IDENTITY" "$WORK/$NAME.dmg"
  xcrun notarytool submit "$WORK/$NAME.dmg" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json > "$WORK/dmg-notary.json"
  cp "$WORK/dmg-notary.json" release/dmg-notary.json
  /usr/bin/grep -q '"status" *: *"Accepted"' "$WORK/dmg-notary.json"
  xcrun stapler staple "$WORK/$NAME.dmg"
  xcrun stapler validate "$WORK/$NAME.dmg"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$WORK/$NAME.dmg"
fi
cp "$WORK/$NAME.dmg" "release/$NAME.dmg"
(cd release && shasum -a 256 "$NAME.dmg" > "$NAME.dmg.sha256")
print "Created: $PWD/release/$NAME.dmg"
