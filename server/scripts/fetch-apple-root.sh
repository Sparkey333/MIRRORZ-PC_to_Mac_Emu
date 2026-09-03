#!/usr/bin/env bash
# Downloads Apple Root CA - G3 (trust anchor for App Store Server Notifications / StoreKit 2 JWS)
# and converts it to PEM for the server. Run at deploy/build time; verify the fingerprint against
# https://www.apple.com/certificateauthority/ before trusting it.
set -euo pipefail
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/src/billing/certs"
mkdir -p "$OUT_DIR"
TMP="$(mktemp)"
curl -fsSL https://www.apple.com/certificateauthority/AppleRootCA-G3.cer -o "$TMP"
openssl x509 -inform der -in "$TMP" -out "$OUT_DIR/AppleRootCA-G3.pem"
rm -f "$TMP"
echo "Wrote $OUT_DIR/AppleRootCA-G3.pem"
openssl x509 -in "$OUT_DIR/AppleRootCA-G3.pem" -noout -subject -fingerprint -sha256
