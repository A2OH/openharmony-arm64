#!/bin/bash
# Boot OpenHarmony ARM64 on QEMU aarch64
# Usage: ./scripts/qemu_boot.sh [timeout_seconds]
#
# Prerequisites:
#   - QEMU extracted at $OHOS_ROOT/tools/qemu-extracted/ (default)
#   - OR qemu-system-aarch64 on PATH
#   - Kernel Image at images/Image
#   - Initramfs at images/initramfs.img

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TIMEOUT=${1:-30}

# OHOS source root (for QEMU binary + libs)
OHOS_ROOT=${OHOS_ROOT:-/home/dspfac/openharmony}

# Locate qemu-system-aarch64
if [ -x "$OHOS_ROOT/tools/qemu-extracted/usr/bin/qemu-system-aarch64" ]; then
    QEMU="$OHOS_ROOT/tools/qemu-extracted/usr/bin/qemu-system-aarch64"
    QEMU_LIB="$OHOS_ROOT/tools/qemu-extracted/usr/lib/x86_64-linux-gnu"
    QEMU_SHARE="$OHOS_ROOT/tools/qemu-extracted/usr/share/qemu"
    export LD_LIBRARY_PATH="$QEMU_LIB"
    QEMU_EXTRA="-L $QEMU_SHARE"
elif command -v qemu-system-aarch64 &>/dev/null; then
    QEMU="qemu-system-aarch64"
    QEMU_EXTRA=""
else
    echo "ERROR: qemu-system-aarch64 not found."
    echo "Set OHOS_ROOT to point to your OpenHarmony source tree,"
    echo "or install qemu-system-aarch64 on your system."
    exit 1
fi

KERNEL="$REPO_DIR/images/Image"
INITRD="$REPO_DIR/images/initramfs.img"

if [ ! -f "$KERNEL" ]; then
    echo "ERROR: Kernel not found at $KERNEL"
    echo "Build or copy the ARM64 kernel Image first."
    exit 1
fi

if [ ! -f "$INITRD" ]; then
    echo "ERROR: Initramfs not found at $INITRD"
    echo "Build the initramfs with: scripts/build_initramfs.sh"
    exit 1
fi

echo "=== OpenHarmony ARM64 QEMU Boot ==="
echo "QEMU:    $QEMU"
echo "Kernel:  $KERNEL"
echo "Initrd:  $INITRD"
echo "Timeout: ${TIMEOUT}s"
echo ""

# Boot options:
#   -M virt          QEMU ARM virt machine (virtio MMIO)
#   -cpu cortex-a57  Cortex-A57 (ARMv8-A, 64-bit)
#   -smp 2           2 CPUs
#   -m 512           512 MB RAM
#   -nographic       serial console only (no GUI)

BOOT_ARGS="console=ttyAMA0 rdinit=/init"

# If an ART overlay image exists, attach it as a virtio block device
ART_EXTRA=""
if [ -f "$REPO_DIR/images/art-overlay.img" ]; then
    ART_EXTRA="-drive if=none,file=$REPO_DIR/images/art-overlay.img,format=raw,id=art -device virtio-blk-device,drive=art"
    BOOT_ARGS="$BOOT_ARGS art_disk=/dev/vda"
    echo "ART overlay: $REPO_DIR/images/art-overlay.img"
fi

# If OHOS system/vendor images exist, attach them too
OHOS_EXTRA=""
if [ -f "$REPO_DIR/images/system.img" ] && [ -f "$REPO_DIR/images/vendor.img" ]; then
    OHOS_EXTRA="-drive if=none,file=$REPO_DIR/images/system.img,format=raw,id=system -device virtio-blk-device,drive=system"
    OHOS_EXTRA="$OHOS_EXTRA -drive if=none,file=$REPO_DIR/images/vendor.img,format=raw,id=vendor -device virtio-blk-device,drive=vendor"
    BOOT_ARGS="$BOOT_ARGS ohos.required_mount.system=/dev/block/vdb@/usr@ext4@ro,barrier=1@wait,required ohos.required_mount.vendor=/dev/block/vdc@/vendor@ext4@ro,barrier=1@wait,required"
    echo "OHOS images: system.img + vendor.img"
fi

echo ""
echo "--- Boot log ---"

if [ "$TIMEOUT" -eq 0 ]; then
    # Interactive mode (no timeout)
    env LD_LIBRARY_PATH="${QEMU_LIB:-}" $QEMU \
        -M virt -cpu cortex-a57 -smp 2 -m 512 -nographic \
        $QEMU_EXTRA \
        $ART_EXTRA \
        $OHOS_EXTRA \
        -kernel "$KERNEL" -initrd "$INITRD" \
        -append "$BOOT_ARGS"
else
    timeout "$TIMEOUT" env LD_LIBRARY_PATH="${QEMU_LIB:-}" $QEMU \
        -M virt -cpu cortex-a57 -smp 2 -m 512 -nographic \
        $QEMU_EXTRA \
        $ART_EXTRA \
        $OHOS_EXTRA \
        -kernel "$KERNEL" -initrd "$INITRD" \
        -append "$BOOT_ARGS" || true
fi

echo ""
echo "--- Boot complete ---"
