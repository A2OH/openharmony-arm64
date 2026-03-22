# OpenHarmony ARM64 on QEMU

Run OpenHarmony on `qemu-system-aarch64` with Dalvik/ART runtime deployment.

Part of the [A2OH (Android-to-OpenHarmony)](https://github.com/A2OH) project.

## Quick Start

```bash
# Boot ARM64 QEMU (30s timeout, serial console)
./scripts/qemu_boot.sh

# Boot interactive (no timeout, Ctrl-A X to quit)
./scripts/qemu_boot.sh 0

# Deploy Dalvik VM and boot
./scripts/deploy_art.sh /path/to/dalvikvm-aarch64 /path/to/test.dex
./scripts/qemu_boot.sh 0
```

## Architecture

```
Host (x86_64 Linux / WSL2)
  |
  +-- qemu-system-aarch64 (QEMU 8.2, virt machine)
        |
        +-- Linux 5.10 ARM64 kernel (from OHOS source)
        +-- Minimal initramfs
              |
              +-- /init          (static aarch64 binary)
              +-- /art/dalvikvm  (Dalvik VM, deployed)
              +-- /art/test.dex  (DEX files, deployed)
              +-- /art/core-*.jar (boot classpath)
```

## Prerequisites

- QEMU: Already extracted at `/home/dspfac/openharmony/tools/qemu-extracted/`
  - Or install: `apt install qemu-system-arm` (needs sudo)
- OHOS source: `/home/dspfac/openharmony/` (for cross compiler + QEMU binary)
- ARM64 kernel: Pre-built at `images/Image` (Linux 5.10, Cortex-A57)

## Directory Structure

```
openharmony-arm64/
+-- images/
|   +-- Image              # ARM64 Linux kernel (31MB)
|   +-- initramfs.img      # Minimal rootfs with init
+-- scripts/
|   +-- qemu_boot.sh       # Boot QEMU (main entry point)
|   +-- build_initramfs.sh # Rebuild initramfs from source
|   +-- deploy_art.sh      # Bake Dalvik VM into initramfs
|   +-- run_benchmark.sh   # Run Dalvik benchmark
|   +-- build_ohos_arm64.sh# Full OHOS build (2-4 hours)
+-- configs/
|   +-- kernel_defconfig   # ARM64 kernel config for QEMU
|   +-- product.json       # OHOS product definition (qemu-arm64-linux-min)
+-- art-deploy/
|   +-- init.c             # Minimal init source (aarch64)
|   +-- run.sh             # Dalvik launch script (runs inside guest)
```

## Boot Verification

The minimal init binary prints system info on boot:

```
============================================
  OpenHarmony ARM64 QEMU - Minimal Init
  Westlake / A2OH Project
============================================

[init] PID 1 running on aarch64
[cpuinfo] processor  : 0
[cpuinfo] BogoMIPS   : 125.00
[cpuinfo] Features   : fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
[meminfo] MemTotal:   479056 kB
[init] System ready.
[init] SUCCESS: ARM64 QEMU boot verified!
```

## Deploying Dalvik VM

1. Cross-compile dalvikvm for aarch64:
   ```bash
   cd /path/to/dalvik-port
   CC=/home/dspfac/openharmony/prebuilts/gcc/linux-x86/aarch64/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcc
   make ARCH=aarch64 CC=$CC
   ```

2. Deploy into initramfs:
   ```bash
   ./scripts/deploy_art.sh ./dalvik-port/build-aarch64/dalvikvm ./test.dex
   ```

3. Boot and run:
   ```bash
   ./scripts/qemu_boot.sh 0
   ```

## Full OHOS Build (Optional)

The OHOS source tree already includes an ARM64 QEMU product config at
`vendor/ohemu/qemu_arm64_linux_min/config.json`. To build the full system:

```bash
./scripts/build_ohos_arm64.sh
```

This takes 2-4 hours and produces system.img, vendor.img, etc. The minimal
initramfs approach is recommended for development.

## QEMU Machine Details

| Parameter | Value |
|-----------|-------|
| Machine | virt (ARM Virtual Machine) |
| CPU | Cortex-A57 (ARMv8-A, 64-bit) |
| SMP | 2 cores |
| RAM | 512 MB |
| Console | ttyAMA0 (PL011 UART) |
| Block | virtio-blk-device (MMIO) |
| Network | virtio-net-device (optional) |
| Kernel | Linux 5.10.184 (OHOS patched) |

## Related Repositories

- [A2OH/westlake](https://github.com/A2OH/westlake) - Main engine (AOSP shim + OHBridge)
- [A2OH/dalvik-universal](https://github.com/A2OH/dalvik-universal) - Dalvik VM port
- [A2OH/openharmony-wsl](https://github.com/A2OH/openharmony-wsl) - OHOS on WSL2 (ARM32)
