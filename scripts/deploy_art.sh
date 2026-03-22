#!/bin/bash
# Deploy Dalvik/ART runtime into the ARM64 initramfs
# Usage: ./scripts/deploy_art.sh [dalvik_binary] [dex_file]
#
# This rebuilds the initramfs with the Dalvik VM and DEX files baked in,
# so they're available at /art/ when QEMU boots.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OHOS_ROOT=${OHOS_ROOT:-/home/dspfac/openharmony}
WESTLAKE=${WESTLAKE:-/home/dspfac/android-to-openharmony-migration}

# Cross compiler
CC_DIR="$OHOS_ROOT/prebuilts/gcc/linux-x86/aarch64/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu"
CC="$CC_DIR/bin/aarch64-linux-gnu-gcc"

DALVIK_BIN="${1:-}"
DEX_FILE="${2:-}"

WORKDIR=$(mktemp -d)
trap "rm -rf $WORKDIR" EXIT

echo "=== Deploy ART/Dalvik to ARM64 QEMU ==="

# Step 1: Compile init
echo "[1/4] Compiling init..."
$CC -static -O2 -o "$WORKDIR/init" "$REPO_DIR/art-deploy/init.c"

# Step 2: Create rootfs
echo "[2/4] Creating rootfs..."
mkdir -p "$WORKDIR/rootfs"/{proc,sys,dev,tmp,bin,art,etc,mnt}
cp "$WORKDIR/init" "$WORKDIR/rootfs/init"
chmod 755 "$WORKDIR/rootfs/init"

# Step 3: Copy ART/Dalvik files
echo "[3/4] Copying ART runtime..."
mkdir -p "$WORKDIR/rootfs/art/bin"

if [ -n "$DALVIK_BIN" ] && [ -f "$DALVIK_BIN" ]; then
    cp "$DALVIK_BIN" "$WORKDIR/rootfs/art/dalvikvm"
    chmod 755 "$WORKDIR/rootfs/art/dalvikvm"
    echo "  Dalvik VM: $DALVIK_BIN"
else
    echo "  WARNING: No dalvikvm binary specified."
    echo "  Usage: $0 <dalvikvm-aarch64-binary> [test.dex]"
    echo ""
    echo "  Build dalvikvm for aarch64 first:"
    echo "    cd $WESTLAKE/dalvik-port"
    echo "    make ARCH=aarch64 CC=$CC"
    echo ""
    echo "  Proceeding without dalvikvm (boot-only test)..."
fi

if [ -n "$DEX_FILE" ] && [ -f "$DEX_FILE" ]; then
    cp "$DEX_FILE" "$WORKDIR/rootfs/art/test.dex"
    echo "  DEX file:  $DEX_FILE"
fi

# Copy any core libraries if they exist
if [ -d "$WESTLAKE/dalvik-port" ]; then
    for jar in "$WESTLAKE/dalvik-port"/core-android-*.jar; do
        if [ -f "$jar" ]; then
            cp "$jar" "$WORKDIR/rootfs/art/"
            echo "  Core JAR:  $(basename $jar)"
        fi
    done
fi

# Step 4: Pack initramfs
echo "[4/4] Packing initramfs..."
cd "$WORKDIR/rootfs"
find . | cpio -o -H newc 2>/dev/null | gzip > "$REPO_DIR/images/initramfs.img"

echo ""
echo "Output: $REPO_DIR/images/initramfs.img"
ls -lh "$REPO_DIR/images/initramfs.img"
echo ""
echo "Boot with: ./scripts/qemu_boot.sh 0   (interactive, no timeout)"
echo "Done."
