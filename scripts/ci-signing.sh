#!/usr/bin/env bash
# Writes android/key.properties + keystore from CI secrets.
# Without secrets the build falls back to the debug key (with a warning).
set -euo pipefail

if [ -z "${KEYSTORE_BASE64:-}" ]; then
  echo "::warning title=Unsigned release::ANDROID_KEYSTORE_BASE64 is not set. The APK will be signed with a throwaway debug key, so it cannot be installed as an update over other builds. See docs/BUILDING.md."
  echo "signed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

for name in KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD; do
  if [ -z "${!name:-}" ]; then
    echo "::error::Secret for $name is missing (see docs/BUILDING.md)."
    exit 1
  fi
done

echo "$KEYSTORE_BASE64" | base64 --decode > android/app/release.jks
{
  echo "storeFile=release.jks"
  echo "storePassword=$KEYSTORE_PASSWORD"
  echo "keyAlias=$KEY_ALIAS"
  echo "keyPassword=$KEY_PASSWORD"
} > android/key.properties

echo "Release signing configured."
echo "signed=true" >> "${GITHUB_OUTPUT:-/dev/null}"
