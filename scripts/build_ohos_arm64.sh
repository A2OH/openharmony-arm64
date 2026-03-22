#!/bin/bash
# Build full OpenHarmony for ARM64 QEMU
# Usage: ./scripts/build_ohos_arm64.sh
#
# WARNING: This is a FULL OHOS build and may take 2-4 hours.
# For quick testing, use the minimal initramfs approach instead:
#   ./scripts/build_initramfs.sh && ./scripts/qemu_boot.sh
#
# The OHOS source tree already has an ARM64 QEMU product config at:
#   vendor/ohemu/qemu_arm64_linux_min/config.json

set -e

OHOS_ROOT=${OHOS_ROOT:-/home/dspfac/openharmony}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -d "$OHOS_ROOT/build" ]; then
    echo "ERROR: OHOS source not found at $OHOS_ROOT"
    echo "Set OHOS_ROOT to your OpenHarmony source tree."
    exit 1
fi

echo "=== Building OpenHarmony ARM64 for QEMU ==="
echo "Source: $OHOS_ROOT"
echo "Product: qemu-arm64-linux-min"
echo ""
echo "WARNING: This build may take 2-4 hours."
echo "For quick testing, use ./scripts/qemu_boot.sh instead."
echo ""
read -p "Continue? [y/N] " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

cd "$OHOS_ROOT"

# The product config already exists:
# vendor/ohemu/qemu_arm64_linux_min/config.json
#   target_cpu: arm64
#   device_build_path: device/qemu/arm_virt/linux

echo "[1/3] Setting product..."
# Use hb (OHOS build helper) if available
if command -v hb &>/dev/null; then
    hb set -p qemu_arm64_linux_min
else
    echo "hb not found, using build.sh directly..."
fi

echo "[2/3] Building (this will take a while)..."
./build.sh --product-name qemu-arm64-linux-min --ccache 2>&1 | tee "$REPO_DIR/build.log"

echo "[3/3] Copying images..."
OUT_DIR="$OHOS_ROOT/out/qemu-arm64-linux-min/packages/phone/images"
if [ -d "$OUT_DIR" ]; then
    cp "$OUT_DIR/Image" "$REPO_DIR/images/Image" 2>/dev/null || true
    cp "$OUT_DIR/ramdisk.img" "$REPO_DIR/images/initramfs.img" 2>/dev/null || true
    cp "$OUT_DIR/system.img" "$REPO_DIR/images/system.img" 2>/dev/null || true
    cp "$OUT_DIR/vendor.img" "$REPO_DIR/images/vendor.img" 2>/dev/null || true
    cp "$OUT_DIR/userdata.img" "$REPO_DIR/images/userdata.img" 2>/dev/null || true
    echo "Images copied to $REPO_DIR/images/"
else
    echo "WARNING: Expected output dir not found: $OUT_DIR"
    echo "Check build.log for errors."
fi

echo "Done."
