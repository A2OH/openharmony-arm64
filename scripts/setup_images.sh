#!/bin/bash
# Set up kernel and initramfs images for QEMU boot
# Usage: ./scripts/setup_images.sh
#
# This script copies the pre-built ARM64 kernel from the OHOS source tree
# and builds the minimal initramfs.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OHOS_ROOT=${OHOS_ROOT:-/home/dspfac/openharmony}

CC_DIR="$OHOS_ROOT/prebuilts/gcc/linux-x86/aarch64/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu"
CC="$CC_DIR/bin/aarch64-linux-gnu-gcc"

mkdir -p "$REPO_DIR/images"

echo "=== Setting up ARM64 QEMU images ==="

# Step 1: Copy kernel
KERNEL_SRC="$OHOS_ROOT/out/KERNEL_OBJ/kernel/src_tmp/linux-5.10/arch/arm64/boot/Image"
if [ -f "$KERNEL_SRC" ]; then
    echo "[1/2] Copying ARM64 kernel from OHOS build..."
    cp "$KERNEL_SRC" "$REPO_DIR/images/Image"
    echo "  $KERNEL_SRC -> images/Image"
else
    echo "[1/2] WARNING: Pre-built kernel not found at:"
    echo "  $KERNEL_SRC"
    echo "  Build OHOS first, or place an ARM64 Image at images/Image manually."
fi

# Step 2: Build initramfs
if [ -x "$CC" ]; then
    echo "[2/2] Building initramfs..."
    "$SCRIPT_DIR/build_initramfs.sh"
else
    echo "[2/2] WARNING: Cross compiler not found at $CC"
    echo "  Cannot build initramfs. Set OHOS_ROOT or build manually."
fi

echo ""
echo "Images ready:"
ls -lh "$REPO_DIR/images/" 2>/dev/null
echo ""
echo "Boot with: ./scripts/qemu_boot.sh"
