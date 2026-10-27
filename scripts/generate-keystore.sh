#!/usr/bin/env bash
# Creates the release signing key for MindDrop and prints the values to store
# as GitHub repository secrets.
#
#   ./scripts/generate-keystore.sh [output-dir]
#
# Requires `keytool` (ships with any Java JDK). Keep the generated .jks file and
# passwords somewhere safe: every future update must be signed with the same key,
# otherwise Android refuses to install it over the existing app.
set -euo pipefail

OUT_DIR="${1:-$HOME/minddrop-signing}"
KEYSTORE="$OUT_DIR/minddrop-release.jks"
ALIAS="minddrop"

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool not found. Install a Java JDK (e.g. 'sudo apt install openjdk-17-jdk')." >&2
  exit 1
fi

if [ -e "$KEYSTORE" ]; then
  echo "A keystore already exists at $KEYSTORE — refusing to overwrite it." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

PASSWORD="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)"

keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -storetype PKCS12 \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 4096 \
  -validity 10000 \
  -storepass "$PASSWORD" \
  -keypass "$PASSWORD" \
  -dname "CN=MindDrop, O=MindDrop, C=XX" >/dev/null

base64 -w0 "$KEYSTORE" > "$OUT_DIR/keystore.base64.txt"
{
  echo "ANDROID_KEYSTORE_BASE64  -> contents of keystore.base64.txt"
  echo "ANDROID_KEYSTORE_PASSWORD = $PASSWORD"
  echo "ANDROID_KEY_ALIAS         = $ALIAS"
  echo "ANDROID_KEY_PASSWORD      = $PASSWORD"
} > "$OUT_DIR/secrets.txt"
chmod 600 "$OUT_DIR"/*

cat <<MSG

✅ Keystore created: $KEYSTORE

Add these four secrets in GitHub → your repo → Settings → Secrets and variables → Actions:

  ANDROID_KEYSTORE_BASE64   = contents of $OUT_DIR/keystore.base64.txt
  ANDROID_KEYSTORE_PASSWORD = $PASSWORD
  ANDROID_KEY_ALIAS         = $ALIAS
  ANDROID_KEY_PASSWORD      = $PASSWORD

(The same values are saved in $OUT_DIR/secrets.txt.)

⚠️  Back up $OUT_DIR somewhere safe and never commit it.
    Losing the key means future updates can't be installed over the current app.
MSG
