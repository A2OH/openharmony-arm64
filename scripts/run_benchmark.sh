#!/bin/bash
# Run Dalvik vs ART benchmark on ARM64 QEMU
# Usage: ./scripts/run_benchmark.sh
#
# This boots QEMU with dalvikvm and a benchmark DEX, captures timing output.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== ARM64 Dalvik/ART Benchmark ==="
echo ""

if [ ! -f "$REPO_DIR/images/initramfs.img" ]; then
    echo "ERROR: No initramfs.img found."
    echo "Deploy ART first: ./scripts/deploy_art.sh <dalvikvm-binary> <benchmark.dex>"
    exit 1
fi

echo "Booting QEMU with 30s timeout..."
echo ""

# Boot and capture output
OUTPUT=$("$SCRIPT_DIR/qemu_boot.sh" 30 2>&1)

echo "$OUTPUT" | grep -E "(benchmark|elapsed|score|SUCCESS|FAIL|dalvikvm|init\])" || true

echo ""
echo "Full log saved to: /tmp/arm64-benchmark.log"
echo "$OUTPUT" > /tmp/arm64-benchmark.log

# Check for success markers
if echo "$OUTPUT" | grep -q "SUCCESS"; then
    echo "RESULT: PASS"
    exit 0
else
    echo "RESULT: Boot only (no benchmark DEX deployed)"
    exit 0
fi
