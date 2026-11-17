# E404 Custom Kernel for POCO X3 Pro (vayu / bhima)
### Modified with ReSukiSU (BakaSU v4.2.0-rc3), SuSFS v1.5.5, and eBPF

![Device](https://img.shields.io/badge/Device-POCO%20X3%20Pro%20(vayu%2Fbhima)-blue)
![SoC](https://img.shields.io/badge/SoC-Snapdragon%20860%20(SM8150--AC)-orange)
![Kernel](https://img.shields.io/badge/Kernel-Linux%204.14.356-green)
![Compiler](https://img.shields.io/badge/Compiler-Neutron%20Clang%2024%20(ThinLTO)-red)
![Android](https://img.shields.io/badge/Android-12%20--%2017%2B%20(Tested%20on%20crDroid%2012.13)-purple)
![Root](https://img.shields.io/badge/Root-BakaSU%20%2B%20SuSFS%20v1.5.5-red)

---

## 👨‍💻 Maintainer & Credits
- **Compiled & Maintained by**: [Dalu Raziq Hidayatullah](https://github.com/fakfekrill-glitch)
- **Base Source**: [deutereium/xiaomi_sm8150_kernel_e404 (Release R3)](https://github.com/deutereium/xiaomi_sm8150_kernel_e404)

---

## 📱 Device & OS Compatibility
- **Device**: Xiaomi POCO X3 Pro (`vayu` / `bhima`)
- **Platform**: Qualcomm Snapdragon 860 (SM8150-AC)
- **Linux Kernel Base**: `4.14.356`
- **Supported ROMs**:
  - Fully tested, booted, and verified on **crDroid 12.13 (Android 16)**.
  - Compatible with AOSP-based custom ROMs from Android 12, 13, 14, 15, 16, up to Android 17 (Baklava).
  - Also compatible with MIUI 12.5 / 13 / 14 and HyperOS (using Non-BPF build).

---

## ⚡ Features & Changelog

### 🚀 E404 Base R3 Highlights (by deutereium)
- **Android 17 Native Support**:
  - Backport 5.15 Android Binder IPC.
  - Backport `clone3()` syscall.
  - Backport 5.15 `bpf_atomic` instruction set.
- **Subsystem & Performance Upgrades**:
  - Backport 5.10 RCU & 5.10 zram.
  - Fixed HyperOS slow animation & 60Hz issue after reboot.
  - Added 6000mAh battery kernel profile.
  - Added multi IR driver support.
  - Removed 140MHz GPU idling frequency and dropped CABC / multi-gen LRU.
- **Bleeding-Edge Toolchain**: Built with **Neutron Clang 24.0.0git** with ThinLTO.

---

### 🛡️ Modified Upgrades (SuSFS + BakaSU by Dalu Raziq)

#### 1. Advanced Root & Stealth Engine
- **ReSukiSU / BakaSU (v4.2.0-rc3)**:
  - KernelSU Next fork with granular per-app root management and module unmount capabilities.
- **SuSFS (v1.5.5)**:
  - Kernel-level stealth filesystem hiding root traces, KSU mounts, and overlayfs paths.
  - Passes detection by DuckDetector, DexGuard RASP, Native Detectors, and banking apps.
  - Integrated modern SuSFS API compatibility (`susfs_auto_add_sus_path`, `susfs_auto_add_sus_bind_mount`, `SUSFS_MAGIC`).

#### 2. Critical Non-GKI 4.14 Bug Fixes
- **Type-Safe `sucompat` Syscall Hooks**:
  - Resolved a critical bootloop/crash in `KernelSU/kernel/feature/sucompat.c` and `sucompat.h` where `faccessat` and `stat` syscall hooks mistakenly dereferenced user-space pointers as `struct filename*` on non-GKI 4.14 kernels (causing page fault at `"/init"` / `0x692e0074696e692f`).
  - Added compile-time `CONFIG_KSU_SUSFS_USE_STRUCT_FILENAME` guard for legacy non-GKI compatibility.
- **Dynamic Stack Buffer Allocation**:
  - Replaced large stack buffers in `fs/susfs/` with dynamic heap allocations (`kmalloc`/`kfree`) to eliminate kernel stack overflow warnings during Clang 24 ThinLTO compilation.
- **Clean Inode & Retval Hooks**:
  - Cleaned up duplicate `fstat` counts and ensured no-op returns for `ksu_handle_newfstat_ret` under SuSFS.

---

## 📦 Kernel Variants & Flashing Guide

We provide 2 distinct flashable variants:

| Variant | Recommended OS | Description |
|---|---|---|
| **`RE404-VAYU-ResukiSU-SuSFS-BPF.zip`** | **Android 15, 16, 17+** | Full eBPF subsystem enabled. Required for modern Android network offload & tethering. |
| **`RE404-VAYU-ResukiSU-SuSFS-NON-BPF.zip`** | **Android 12, 13, 14, MIUI, HyperOS** | Standard netd compatibility without eBPF conflicts on legacy vendor blobs. |

### How to Flash:
1. Reboot into custom recovery (**OrangeFox Recovery** or **TWRP** recommended).
2. (Optional) Backup your existing `boot` partition.
3. Flash the selected AnyKernel3 zip file.
4. Wipe Dalvik & Cache.
5. Reboot to system.
6. Install the **KernelSU / BakaSU Manager** app.

---

## 🛠️ Building From Source

### Compile Command
```bash
# Clone the repository
git clone https://github.com/fakfekrill-glitch/xiaomi_sm8150_kernel_e404_modified -b main-susfs kernel
cd kernel

# For BPF variant (Android 15, 16, 17+):
./compile.sh vaybpf sus bpf neutron

# For Non-BPF variant (Android 12, 13, 14, MIUI):
./compile.sh vayu sus neutron
```

---

## 📜 Credits & Acknowledgments
- [deutereium](https://github.com/deutereium) for original E404 kernel source & R3 backports
- [Baka-SU / ReSukiSU Team](https://github.com/Baka-SU)
- [simonpunk](https://gitlab.com/simonpunk/susfs4ksu) for SuSFS
- [tiann](https://github.com/tiann) for KernelSU
- [osm0sis](https://github.com/osm0sis) for AnyKernel3
- [dakkshesh07](https://github.com/dakkshesh07) for Neutron Clang toolchain
- **Dalu Raziq Hidayatullah** (`fakfekrill-glitch`) for porting, debugging non-GKI 4.14 SuSFS fixes, and packaging.

---
**License**: [GPL-2.0](LICENSE)
