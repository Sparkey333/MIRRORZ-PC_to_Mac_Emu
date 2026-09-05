#!/usr/bin/env bash
# Builds mirrorz-core for Android and generates the Kotlin bindings.
#
# ABIs: arm64-v8a (devices) and x86_64 (emulator). Minimum API 29 = Android 10 (spec §5.3).
#
# Output:
#   bindings/generated/android/jniLibs/<abi>/libmirrorz_core.so
#   bindings/generated/kotlin/com/mirrorz/core/mirrorz_core.kt
#
# Requires: Android NDK (ANDROID_NDK_HOME or ANDROID_NDK_ROOT), cargo-ndk, rustup targets.
# Wire into apps/android with `sourceSets["main"].jniLibs.srcDirs(...)` and add the Kotlin
# file to the module's source set; the generated code needs `net.java.dev.jna:jna:<ver>@aar`.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
CORE_DIR="$(pwd)"
OUT_DIR="${CORE_DIR}/bindings/generated"
API_LEVEL="${MIRRORZ_ANDROID_API:-29}"
ABIS=(arm64-v8a x86_64)

if [[ -z "${ANDROID_NDK_HOME:-}" && -z "${ANDROID_NDK_ROOT:-}" ]]; then
  echo "error: set ANDROID_NDK_HOME (or ANDROID_NDK_ROOT) to your NDK directory" >&2
  exit 1
fi
if ! command -v cargo-ndk >/dev/null; then
  echo "==> installing cargo-ndk"
  cargo install cargo-ndk --locked
fi
rustup target add aarch64-linux-android x86_64-linux-android >/dev/null

rm -rf "${OUT_DIR}/android" "${OUT_DIR}/kotlin"
mkdir -p "${OUT_DIR}/android/jniLibs" "${OUT_DIR}/kotlin"

NDK_ARGS=()
for abi in "${ABIS[@]}"; do NDK_ARGS+=(-t "${abi}"); done
echo "==> cargo ndk ${ABIS[*]} (API ${API_LEVEL})"
cargo ndk "${NDK_ARGS[@]}" -P "${API_LEVEL}" -o "${OUT_DIR}/android/jniLibs" build --release --lib

# Kotlin bindings from the arm64 shared library (metadata is identical across ABIs).
echo "==> generating Kotlin bindings"
cargo run --quiet --features cli --bin uniffi-bindgen -- \
  generate --library "target/aarch64-linux-android/release/libmirrorz_core.so" \
  --language kotlin --out-dir "${OUT_DIR}/kotlin"

echo "done:"
find "${OUT_DIR}/android" "${OUT_DIR}/kotlin" -type f | sort | sed 's#^#  #'
