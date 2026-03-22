# OpenHarmony ARM64 QEMU

在 `qemu-system-aarch64` 上运行 OpenHarmony，并部署 Dalvik/ART 运行时。

属于 [A2OH (Android-to-OpenHarmony)](https://github.com/A2OH) 项目。

## 快速开始

```bash
# 启动 ARM64 QEMU（30秒超时，串口控制台）
./scripts/qemu_boot.sh

# 交互模式启动（无超时，Ctrl-A X 退出）
./scripts/qemu_boot.sh 0

# 部署 Dalvik 虚拟机并启动
./scripts/deploy_art.sh /path/to/dalvikvm-aarch64 /path/to/test.dex
./scripts/qemu_boot.sh 0
```

## 系统架构

```
宿主机 (x86_64 Linux / WSL2)
  |
  +-- qemu-system-aarch64 (QEMU 8.2, virt 虚拟机)
        |
        +-- Linux 5.10 ARM64 内核（来自 OHOS 源码）
        +-- 最小化 initramfs
              |
              +-- /init          (静态 aarch64 二进制)
              +-- /art/dalvikvm  (Dalvik 虚拟机，部署后可用)
              +-- /art/test.dex  (DEX 文件)
              +-- /art/core-*.jar (启动类路径)
```

## 环境要求

- QEMU：已解压至 `/home/dspfac/openharmony/tools/qemu-extracted/`
- OHOS 源码：`/home/dspfac/openharmony/`（交叉编译器 + QEMU 二进制）
- ARM64 内核：预编译于 `images/Image`（Linux 5.10, Cortex-A57）

## 目录结构

```
openharmony-arm64/
+-- images/              # 内核 + initramfs 镜像
+-- scripts/             # 启动、构建、部署脚本
+-- configs/             # 内核配置 + OHOS 产品定义
+-- art-deploy/          # init 源码 + Dalvik 启动脚本
```

## 启动验证

```
============================================
  OpenHarmony ARM64 QEMU - Minimal Init
  Westlake / A2OH Project
============================================

[init] PID 1 running on aarch64
[cpuinfo] Features   : fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
[meminfo] MemTotal:   479056 kB
[init] SUCCESS: ARM64 QEMU boot verified!
```

## 相关仓库

- [A2OH/westlake](https://github.com/A2OH/westlake) - 主引擎（AOSP shim + OHBridge）
- [A2OH/dalvik-universal](https://github.com/A2OH/dalvik-universal) - Dalvik 虚拟机移植
- [A2OH/openharmony-wsl](https://github.com/A2OH/openharmony-wsl) - WSL2 上的 OHOS（ARM32）
