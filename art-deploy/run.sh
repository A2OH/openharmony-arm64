#!/bin/sh
# Run Dalvik VM inside the QEMU ARM64 environment
# This script runs inside the guest (called by init if dalvikvm is present)

export ANDROID_DATA=/tmp/android-data
export ANDROID_ROOT=/art

mkdir -p $ANDROID_DATA/dalvik-cache $ANDROID_ROOT/bin

echo "[art-run] Starting Dalvik VM on ARM64..."
echo "[art-run] ANDROID_DATA=$ANDROID_DATA"
echo "[art-run] ANDROID_ROOT=$ANDROID_ROOT"

BOOTCP=""
for jar in /art/core-android-*.jar; do
    [ -f "$jar" ] || continue
    if [ -z "$BOOTCP" ]; then
        BOOTCP="$jar"
    else
        BOOTCP="$BOOTCP:$jar"
    fi
done

if [ -n "$BOOTCP" ]; then
    echo "[art-run] Boot classpath: $BOOTCP"
    BOOTCP_ARG="-Xbootclasspath:$BOOTCP"
else
    BOOTCP_ARG=""
fi

DEX="${1:-/art/test.dex}"
CLASS="${2:-HelloWorld}"

if [ ! -f "$DEX" ]; then
    echo "[art-run] ERROR: DEX file not found: $DEX"
    echo "[art-run] Deploy a DEX file first with scripts/deploy_art.sh"
    exit 1
fi

echo "[art-run] DEX: $DEX"
echo "[art-run] Class: $CLASS"
echo ""

/art/dalvikvm \
    -Xverify:none -Xdexopt:none \
    $BOOTCP_ARG \
    -classpath "$DEX" \
    "$CLASS"

echo ""
echo "[art-run] Dalvik VM exited with status $?"
