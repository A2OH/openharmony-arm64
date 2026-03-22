#!/bin/bash
# Build the minimal ARM64 initramfs for QEMU boot
# Usage: ./scripts/build_initramfs.sh
#
# This creates a minimal initramfs with:
#   - Static init binary (aarch64)
#   - Mountpoints for proc, sys, dev, tmp
#   - /art directory for Dalvik VM deployment
#   - /bin directory for optional busybox

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OHOS_ROOT=${OHOS_ROOT:-/home/dspfac/openharmony}

# Cross compiler
CC_DIR="$OHOS_ROOT/prebuilts/gcc/linux-x86/aarch64/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu"
CC="$CC_DIR/bin/aarch64-linux-gnu-gcc"

if [ ! -x "$CC" ]; then
    echo "ERROR: aarch64 cross compiler not found at $CC"
    echo "Set OHOS_ROOT to your OpenHarmony source tree."
    exit 1
fi

WORKDIR=$(mktemp -d)
trap "rm -rf $WORKDIR" EXIT

echo "=== Building ARM64 Initramfs ==="
echo "Cross compiler: $CC"
echo ""

# Step 1: Compile the init binary
echo "[1/3] Compiling init.c -> init (static aarch64)..."
$CC -static -O2 -o "$WORKDIR/init" "$REPO_DIR/art-deploy/init.c"
file "$WORKDIR/init"

# Step 2: Create rootfs directory tree
echo "[2/3] Creating rootfs layout..."
mkdir -p "$WORKDIR/rootfs"/{proc,sys,dev,tmp,bin,art,etc,mnt}
cp "$WORKDIR/init" "$WORKDIR/rootfs/init"
chmod 755 "$WORKDIR/rootfs/init"

# Step 3: Build cpio archive
echo "[3/3] Packing initramfs..."
cd "$WORKDIR/rootfs"
find . | cpio -o -H newc 2>/dev/null | gzip > "$REPO_DIR/images/initramfs.img"

echo ""
echo "Output: $REPO_DIR/images/initramfs.img"
ls -lh "$REPO_DIR/images/initramfs.img"
echo "Done."
