#!/usr/bin/env bash
# Generates the Swift and Kotlin bindings for mirrorz-core from a host build of the
# library. Library mode reads the UniFFI metadata embedded in the compiled artifact, so
# the bindings always match the code that was actually compiled.
#
# Output:
#   bindings/generated/swift/   MirrorzCore.swift, MirrorzCoreFFI.h, MirrorzCoreFFI.modulemap
#   bindings/generated/kotlin/  com/mirrorz/core/mirrorz_core.kt
#
# Usage: scripts/generate-bindings.sh [--profile debug|release] [--swift-only|--kotlin-only]
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
CORE_DIR="$(pwd)"
OUT_DIR="${CORE_DIR}/bindings/generated"
PROFILE="release"
LANGS=(swift kotlin)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --swift-only) LANGS=(swift); shift ;;
    --kotlin-only) LANGS=(kotlin); shift ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ "${PROFILE}" == "release" ]]; then
  cargo build --release --lib
else
  cargo build --lib
fi

# Pick whichever shared-library extension the host produced.
LIB=""
for candidate in \
  "target/${PROFILE}/libmirrorz_core.dylib" \
  "target/${PROFILE}/libmirrorz_core.so" \
  "target/${PROFILE}/mirrorz_core.dll"; do
  if [[ -f "${candidate}" ]]; then LIB="${candidate}"; break; fi
done
if [[ -z "${LIB}" ]]; then
  echo "error: no built library found under target/${PROFILE}" >&2
  exit 1
fi

for lang in "${LANGS[@]}"; do
  dest="${OUT_DIR}/${lang}"
  rm -rf "${dest}"
  mkdir -p "${dest}"
  echo "==> ${lang} bindings -> ${dest}"
  cargo run --quiet --features cli --bin uniffi-bindgen -- \
    generate --library "${LIB}" --language "${lang}" --out-dir "${dest}"
done

echo "done: $(find "${OUT_DIR}" -type f | sort | sed 's#^#  #')"
