#!/usr/bin/env bash
# Build the store updater as a UNIVERSAL binary (arm64 + x86_64) from a single
# Apple Silicon executor. One M4 Pro machine produces a binary that runs on the
# Apple Silicon fleet AND the remaining Intel machines — no per-arch build farm,
# no building on engineers' laptops.
set -euo pipefail

echo "==> Building universal binary for the whole store fleet (Apple Silicon + Intel)"
swift build -c release --arch arm64 --arch x86_64

BIN_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
BIN="${BIN_DIR}/store-updater"
echo "Built: ${BIN}"

echo "==> Architectures present in the shipped binary:"
lipo -archs "${BIN}"
lipo -archs "${BIN}" | grep -q "arm64"  || { echo "ERROR: missing arm64 slice";  exit 1; }
lipo -archs "${BIN}" | grep -q "x86_64" || { echo "ERROR: missing x86_64 slice"; exit 1; }
echo "OK — one executor produced a binary for both architectures."

mkdir -p dist
cp "${BIN}" dist/store-updater
echo "Staged universal binary at dist/store-updater"
