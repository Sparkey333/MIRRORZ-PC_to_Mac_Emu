#!/usr/bin/env bash
# Builds mirrorz-core for Apple platforms and packages it as an XCFramework the
# macOS app and the iOS companion link against, plus the generated Swift source.
#
# Targets (Apple silicon first, per spec §5.2):
#   aarch64-apple-darwin   macOS
#   aarch64-apple-ios      iOS / iPadOS devices
#   aarch64-apple-ios-sim  iOS simulator on Apple silicon Macs
# Set MIRRORZ_UNIVERSAL=1 to also build x86_64-apple-darwin and x86_64-apple-ios-sim and
# lipo them into fat slices (Intel Macs / Intel simulators).
#
# Output:
#   bindings/generated/apple/MirrorzCoreFFI.xcframework   static library + C header + modulemap
#   bindings/generated/apple/MirrorzCore.swift            add to the SwiftPM package / Xcode target
#
# Requires: Xcode command line tools (xcodebuild, lipo), rustup with the targets above.
# Must run on macOS. See README.md for wiring the output into apps/macos and apps/ios.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
CORE_DIR="$(pwd)"
OUT_DIR="${CORE_DIR}/bindings/generated/apple"
STAGE="${CORE_DIR}/target/apple-stage"
LIB_NAME="libmirrorz_core.a"
FFI_MODULE="MirrorzCoreFFI"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: build-apple.sh must run on macOS (needs xcodebuild and Apple SDKs)" >&2
  exit 1
fi
command -v xcodebuild >/dev/null || { echo "error: xcodebuild not found (install Xcode command line tools)" >&2; exit 1; }

MAC_TARGETS=(aarch64-apple-darwin)
IOS_TARGETS=(aarch64-apple-ios)
SIM_TARGETS=(aarch64-apple-ios-sim)
if [[ "${MIRRORZ_UNIVERSAL:-0}" == "1" ]]; then
  MAC_TARGETS+=(x86_64-apple-darwin)
  SIM_TARGETS+=(x86_64-apple-ios-sim)
fi

for t in "${MAC_TARGETS[@]}" "${IOS_TARGETS[@]}" "${SIM_TARGETS[@]}"; do
  rustup target add "$t" >/dev/null
  echo "==> cargo build --release --target $t"
  cargo build --release --lib --target "$t"
done

rm -rf "${STAGE}" "${OUT_DIR}"
mkdir -p "${STAGE}/headers" "${OUT_DIR}"

# One slice per platform; lipo when a platform has more than one architecture.
make_slice() {
  local name="$1"; shift
  local libs=()
  for t in "$@"; do libs+=("target/${t}/release/${LIB_NAME}"); done
  mkdir -p "${STAGE}/${name}"
  if [[ ${#libs[@]} -eq 1 ]]; then
    cp "${libs[0]}" "${STAGE}/${name}/${LIB_NAME}"
  else
    lipo -create "${libs[@]}" -output "${STAGE}/${name}/${LIB_NAME}"
  fi
}
make_slice macos "${MAC_TARGETS[@]}"
make_slice ios "${IOS_TARGETS[@]}"
make_slice ios-sim "${SIM_TARGETS[@]}"

# Swift bindings + C header + modulemap from the macOS slice (metadata is identical across slices).
echo "==> generating Swift bindings"
cargo run --quiet --features cli --bin uniffi-bindgen -- \
  generate --library "${STAGE}/macos/${LIB_NAME}" --language swift --out-dir "${STAGE}/swift"
cp "${STAGE}/swift/${FFI_MODULE}.h" "${STAGE}/headers/"
# An XCFramework expects the modulemap to be named module.modulemap inside the headers dir.
cp "${STAGE}/swift/${FFI_MODULE}.modulemap" "${STAGE}/headers/module.modulemap"
cp "${STAGE}/swift/MirrorzCore.swift" "${OUT_DIR}/MirrorzCore.swift"

echo "==> xcodebuild -create-xcframework"
xcodebuild -create-xcframework \
  -library "${STAGE}/macos/${LIB_NAME}"   -headers "${STAGE}/headers" \
  -library "${STAGE}/ios/${LIB_NAME}"     -headers "${STAGE}/headers" \
  -library "${STAGE}/ios-sim/${LIB_NAME}" -headers "${STAGE}/headers" \
  -output "${OUT_DIR}/${FFI_MODULE}.xcframework"

echo "done:"
echo "  ${OUT_DIR}/${FFI_MODULE}.xcframework"
echo "  ${OUT_DIR}/MirrorzCore.swift"
