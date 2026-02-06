#!/usr/bin/env bash
set -euo pipefail

SCHEME="${SCHEME:-OpenWhisper}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_ROOT="${BUILD_ROOT:-$PWD/.artifacts/build}"
OUTPUT_ROOT="${OUTPUT_ROOT:-$PWD/.artifacts/release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$BUILD_ROOT/${SCHEME}.xcarchive}"
APP_PATH="$ARCHIVE_PATH/Products/Applications/${SCHEME}.app"
ZIP_PATH="${ZIP_PATH:-$OUTPUT_ROOT/${SCHEME}.zip}"

SIGN_AND_NOTARIZE="${SIGN_AND_NOTARIZE:-0}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_SPECIFIC_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-}"

mkdir -p "$BUILD_ROOT" "$OUTPUT_ROOT"
rm -rf "$ARCHIVE_PATH" "$ZIP_PATH"

echo "Building macOS archive for scheme: $SCHEME"
xcodebuild \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive

if [[ ! -d "$APP_PATH" ]]; then
  echo "Archive did not contain app at expected path: $APP_PATH" >&2
  exit 1
fi

if [[ "$SIGN_AND_NOTARIZE" == "1" ]]; then
  if [[ -z "$CODESIGN_IDENTITY" || -z "$APPLE_ID" || -z "$APPLE_TEAM_ID" || -z "$APPLE_APP_SPECIFIC_PASSWORD" ]]; then
    echo "Missing signing/notarization env vars." >&2
    echo "Required: CODESIGN_IDENTITY, APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD" >&2
    exit 1
  fi

  echo "Signing app with identity: $CODESIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_PATH"
  codesign --verify --deep --strict "$APP_PATH"
fi

echo "Packaging app bundle into zip: $ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ "$SIGN_AND_NOTARIZE" == "1" ]]; then
  echo "Submitting zip for notarization"
  xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

  echo "Stapling notarization ticket to app bundle"
  xcrun stapler staple "$APP_PATH"

  echo "Rebuilding notarized zip"
  rm -f "$ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
fi

echo "Release artifact ready: $ZIP_PATH"
