# E404 Custom Kernel for POCO X3 Pro (vayu / bhima)
### Modified with ReSukiSU (BakaSU v4.2.0-rc3), SuSFS v1.5.5, and eBPF

![Device](https://img.shields.io/badge/Device-POCO%20X3%20Pro%20(vayu%2Fbhima)-blue)
![SoC](https://img.shields.io/badge/SoC-Snapdragon%20860%20(SM8150--AC)-orange)
![Kernel](https://img.shields.io/badge/Kernel-Linux%204.14.356-green)
![Android](https://img.shields.io/badge/Android-12%20--%2017%2B%20(Tested%20on%20crDroid%2012.13)-purple)
![Root](https://img.shields.io/badge/Root-BakaSU%20%2B%20SuSFS%20v1.5.5-red)

---

## 👨‍💻 Maintainer & Credits
- **Compiled & Maintained by**: [Dalu Raziq Hidayatullah](https://github.com/fakfekrill-glitch)
- **Base Source**: [deutereium/xiaomi_sm8150_kernel_e404](https://github.com/deutereium/xiaomi_sm8150_kernel_e404)

---

## 📱 Device & OS Compatibility
- **Device**: Xiaomi POCO X3 Pro (`vayu` / `bhima`)
- **Platform**: Qualcomm Snapdragon 860 (SM8150-AC)
- **Linux Kernel Base**: `4.14.356`
- **Supported ROMs**:
  - Fully tested, booted, and verified on **crDroid 12.13 (Android 16)**.
  - Compatible with Android 12, 13, 14, 15, 16, and upcoming Android 17 (Baklava) AOSP-based custom ROMs.

---

## ⚡ Features & Modifications

### 1. Root & Stealth Engine (ReSukiSU / BakaSU + SuSFS)
- **BakaSU / ReSukiSU (v4.2.0-rc3)**:
  - Advanced KernelSU Next implementation with native `sucompat` support.
  - Granular per-app root management and unmount capabilities.
- **SuSFS (v1.5.5)**:
  - Kernel-level stealth filesystem hiding module paths, KSU mounts, and overlayfs from advanced root detectors.
  - Cleanly bypasses checks from DuckDetector, DexGuard RASP, Native Root Detectors, and banking security mechanisms.
  - Implements modern SuSFS API compatibility (`susfs_auto_add_sus_path`, `susfs_auto_add_sus_bind_mount`, `SUSFS_MAGIC`).

### 2. Critical Non-GKI 4.14/4.19 Kernel Fixes
- **Type-Safe `sucompat` Syscall Hooks**:
  - Resolved a critical crash/bootloop bug in `KernelSU/kernel/feature/sucompat.c` and `sucompat.h` where `faccessat` and `stat` hooks previously dereferenced user-space pointers as `struct filename*` on non-GKI 4.14 kernels (which caused kernel paging faults at `"/init"` / `0x692e0074696e692f`).
  - Added compile-time guards (`CONFIG_KSU_SUSFS_USE_STRUCT_FILENAME`) guaranteeing type safety between GKI and legacy non-GKI architectures.
- **Dynamic Stack Buffer Allocation**:
  - Replaced large stack buffers in `fs/susfs/` with dynamic heap allocations (`kmalloc`/`kfree`) to prevent kernel stack overflows during ThinLTO compilation.
- **Clean Inode & Retval Hooks**:
  - Cleaned up duplicate `fstat` counts and ensured no-op returns for `ksu_handle_newfstat_ret` under SuSFS.

### 3. Networking & Android 16/17 Subsystems
- **Extended Berkeley Packet Filter (eBPF)**:
  - Enabled `CONFIG_BPF_SYSCALL`, `CONFIG_NET_CLS_ACT`, `CONFIG_NET_SCH_INGRESS`, and `CONFIG_CGROUP_BPF`.
  - Native support for modern Android 15, 16, and 17+ network telemetry, tethering hardware offload, and BPF maps without requiring unstable uname spoofing.

### 4. Compiler & Optimization
- **Toolchain**: Neutron Clang 19 with ThinLTO (Link Time Optimization)
- **Packaging**: Integrated with AnyKernel3 flashable zip, preserving vendor/dtbo configurations.

---

## 📦 Flashing Guide
1. Reboot into custom recovery (**OrangeFox Recovery** or **TWRP** recommended).
2. (Optional but recommended) Backup your existing `boot` partition.
3. Flash the AnyKernel3 zip:
   ```
   RE404-POCO_X3_PRO-ReSukiSU-SuSFS-BPF-DaluRaziq.zip
   ```
4. Wipe Dalvik & Cache.
5. Reboot to system.
6. Install the **KernelSU / BakaSU Manager** app.

---

## 🛠️ Building From Source

### Prerequisites
- Linux x86_64 build environment
- Neutron Clang 19 in `../toolchains/neutron-clang`
- AnyKernel3 in `../AnyKernel3`

### Compile Command
```bash
# Clone the repository
git clone https://github.com/fakfekrill-glitch/xiaomi_sm8150_kernel_e404_modified -b main-susfs kernel
cd kernel

# Run compilation script
./compile.sh vayu sus bpf neutron
```
The output zip will be placed in the parent directory.

---

## 📜 Credits & Acknowledgments
- [deutereium](https://github.com/deutereium) for original E404 kernel source
- [Baka-SU / ReSukiSU Team](https://github.com/Baka-SU)
- [simonpunk](https://gitlab.com/simonpunk/susfs4ksu) for SuSFS
- [tiann](https://github.com/tiann) for KernelSU
- [osm0sis](https://github.com/osm0sis) for AnyKernel3
- **Dalu Raziq Hidayatullah** (`fakfekrill-glitch`) for porting, debugging non-GKI 4.14 SuSFS fixes, and packaging.

---
**License**: [GPL-2.0](LICENSE)
