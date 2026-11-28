# E404 Custom Kernel for POCO X3 Pro (vayu / bhima)
### Built with ReSukiSU (BakaSU v4.2.0-rc3), SuSFS v1.5.5, MGLRU, Deep Sleep Wakelock Blocker & eBPF

![Device](https://img.shields.io/badge/Device-POCO%20X3%20Pro%20(vayu%2Fbhima)-blue)
![SoC](https://img.shields.io/badge/SoC-Snapdragon%20860%20(SM8150--AC)-orange)
![Kernel](https://img.shields.io/badge/Kernel-4.14.356%20(4.19.404R)-green)
![Compiler](https://img.shields.io/badge/Compiler-Neutron%20Clang%2024%20(ThinLTO)-red)
![Android](https://img.shields.io/badge/Android-12%20--%2017%2B%20(Tested%20on%20crDroid%2012.13)-purple)
![Root](https://img.shields.io/badge/Root-BakaSU%20%2B%20SuSFS%20v1.5.5-red)

---

## Maintainer & Contacts
- **Compiled & Maintained by**: **Dalu Raziq Hidayatullah** ([@fakfekrill-glitch](https://github.com/fakfekrill-glitch))
- **Base Source**: [@deutereium](https://github.com/deutereium) ([xiaomi_sm8150_kernel_e404](https://github.com/deutereium/xiaomi_sm8150_kernel_e404))

### Socials & Contact
[![Telegram](https://img.shields.io/badge/Telegram-@PushyAja-blue?logo=telegram)](https://t.me/PushyAja)
[![Instagram](https://img.shields.io/badge/Instagram-dalu.hidayatullah-E4405F?logo=instagram)](https://instagram.com/dalu.hidayatullah)
[![Discord](https://img.shields.io/badge/Discord-pushygamertag27-5865F2?logo=discord)](https://discord.com)

- **Telegram**: [@PushyAja](https://t.me/PushyAja)
- **Instagram**: [@dalu.hidayatullah](https://instagram.com/dalu.hidayatullah)
- **Discord**: `pushygamertag27`

---

## Device & OS Compatibility
- **Device**: Xiaomi POCO X3 Pro (`vayu` / `bhima`)
- **Platform**: Qualcomm Snapdragon 860 (`SM8150-AC`)
- **Kernel Base**: Linux `4.14.356` (reported as `4.19.404R` via `scripts/POST-GEN.sh` for modern Android compatibility)
- **Supported ROMs**:
  - Tested and verified on **crDroid 12.13 (Android 16)** with MGLRU, BPF, SuSFS v1.5.5, and Deep Sleep Wakelock Blocker active.
  - Compatible with AOSP custom ROMs from Android 12 through Android 17 (Baklava).
  - Compatible with MIUI 12.5 / 13 / 14 and HyperOS using the **Non-BPF** build.

---

## Features & Architecture

### 1. Upstream E404 Base Highlights
- **Modern Android Backports**:
  - Linux 5.15 Android Binder IPC, `clone3()` syscall, and `bpf_atomic` support for Android 15–17+.
  - Backported 5.10 RCU and 5.10 ZRAM stack.
  - Fixed HyperOS slow animations and 60Hz lock after reboot.
  - Multi-IR driver support, disabled 140MHz GPU idling step, and dropped CABC.
- **Zero-Warning ThinLTO Build**:
  - Built with **Neutron Clang 24.0.0** & **Neutron LLD 24.0.0** (`CONFIG_LTO_CLANG_THIN=y`) with tree-wide warning cleanups and unused subsystems (`CONFIG_EDAC`, `CONFIG_QCOM_DLOAD_MODE`) disabled while preserving `pstore` (`ramoops`).

### 2. Multi-Gen LRU (MGLRU) & Memory Management
- **Multi-Gen LRU (`CONFIG_LRU_GEN=y`, `CONFIG_LRU_GEN_ENABLED=y`)**:
  - Backported 4-generation / 4-tier page reclaim engine tuned for arm64 without hardware accessed-bit page walks (`/sys/kernel/mm/lru_gen/enabled` reports `0x0001`, using `iterate_mm_list_nowalk()` + `lru_gen_look_around()`).
  - Configured with `min_ttl_ms = 0` to prevent premature OOM invocations.
  - Fixed non-critical zero-scanned `vmpressure_global()` events so MGLRU aging/sorting passes do not trigger false `pressure = 100` kills in **Simple LMK** (`CONFIG_ANDROID_SIMPLE_LMK=y`).
  - Fixed clean file page deactivation (`lru_deactivate_file_fn`) to keep pages on MGLRU generational lists instead of legacy LRU lists, alongside fixes for `reclaim_state` initialization, `PG_active` ordering, `p4d_entry` pagewalk handling, IRQ-safe `mm_list->lock`, and fork/exec task tracking.
- **ZRAM & VM Defaults**:
  - **ZSTD** default ZRAM compression (`CONFIG_ZRAM_DEF_COMP_ZSTD=y`) with `page_cluster = 0` to remove unnecessary swap readahead decompression overhead.
  - Tuned defaults: `vm_swappiness = 100`, `dirty_background_ratio = 5`, and `vfs_cache_pressure = 80`.

### 3. Root & Stealth Engine (ReSukiSU + SuSFS)
- **ReSukiSU / BakaSU (`v4.2.0-rc3`)**:
  - Built-in KernelSU Next fork (`CONFIG_KSU=y`) with `sulog` and `adb_root` features enabled.
- **SuSFS (`v1.5.5`)**:
  - Kernel-level stealth (`SUS_PATH`, `SUS_MOUNT`, `SUS_KSTAT`, `SPOOF_UNAME`, `SPOOF_CMDLINE_OR_BOOTCONFIG`, `OPEN_REDIRECT`, `SUS_MAP`, and hidden KernelSU/SuSFS symbols).
  - Non-GKI 4.14 fixes for type-safe `sucompat` `faccessat`/`stat` hooks and dynamic heap allocation in `fs/susfs/` to avoid ThinLTO stack frame bloat.

### 4. Deep Sleep Wakelock Blocker
- **Boeffla-Style Kernel Wakelock Blocker (`drivers/base/power/wakeup.c`)**:
  - Enabled by default (`enable_wakelock_blocker = Y`) with spinlock synchronization across both sysfs interfaces:
    - `/sys/module/wakeup/parameters/blocked_wakelocks`
    - `/sys/class/misc/boeffla_wakelock_blocker/wakelock_blocker`
  - **Default Blocklist**: `wlan_pno_wl;wlan_netlink_wl;wlan_wow_wl;wlan_extscan_wl;netmgr_wl;IPA_WS;qcom_rx_wakelock`
  - Deliberately excludes `timerfd` and `sensor_ind` so alarms, system timers, sensors, and push notifications continue working reliably during Deep Sleep.

### 5. Fast Charging (6A / 3A) & Custom Battery Profiles
- **Fast Charge Override (`/sys/kernel/fast_charge/force_fast_charge`)**:
  - Enabled by default (`1`), overriding `FCC` to `6,000,000 µA` (6A) and `USB_ICL` to `3,000,000 µA` (3A) while clearing thermal/slow charging throttles.
- **Switchable Fuel Gauge Profiles (`/sys/e404/batt_profile` & `/sys/e404/batt_capacity_mah`)**:
  - `0` / `e404_args=batt_def`: Original OEM battery (`5160 mAh`)
  - `1` / `e404_args=batt_6k`: Custom `6000 mAh` profile (Default)
  - `2` / `e404_args=batt_65k`: Custom `6500 mAh` profile (`fg-gen4-batterydata-vayu-6500mah.dtsi`)
  - Silenced `ds28e16` authentication `dmesg` log spam for aftermarket batteries without OEM crypto ICs.

### 6. Networking, Storage & 120Hz Responsiveness
- **Networking**: Default **`bbrplus`** TCP congestion control (with `bbr` and `westwood` available) + **`fq`** default queueing discipline (`CONFIG_DEFAULT_NET_SCH="fq"`), TCP Fast Open enabled for client & server (`sysctl_tcp_fastopen = 3`), and `sysctl_tcp_slow_start_after_idle = 0`.
- **Filesystem**: Enabled **F2FS Compression** (`LZO`, `LZ4`, `ZSTD`).
- **Scheduler & Input**: `schedutil` rate limit reduced to `1000 µs` (`1ms`) for 120Hz frame pacing, Prime core touch boost enabled in `cpu-boost`, and `CONFIG_IRQ_SBALANCE=y`.

### 7. Built-in `e404` CLI System Fetch Tool
Flashing the AnyKernel3 zip automatically installs the `e404` POSIX/mksh-compatible system fetch utility into available paths (`/data/adb/ksu/bin`, `/data/adb/magisk`, Termux `usr/bin`, or `/data/local/tmp`). Run `e404` in Termux or MT Manager Terminal to inspect live CPU/GPU frequencies, RAM & ZRAM compression, battery voltage/current/capacity, TCP congestion algorithm, Deep Sleep blocker status, and MGLRU capability mask.

---

## Verification & Proof (BakaSU, SuSFS & M-Banking)

Running with **BakaSU (`v4.2.0-rc3`)**, **SuSFS (`v1.5.5`)**, and passing banking / integrity checks on POCO X3 Pro (crDroid 12.13 / Android 16):

<div align="center">
  <img src="media/bakasu_susfs_proof.png" alt="BakaSU + SuSFS Proof" width="360" />
  <br /><br />
  <a href="https://github.com/fakfekrill-glitch/xiaomi_sm8150_kernel_e404_modified/releases/download/R3-SuSFS-v1.5.5/E404-BakaSU-SuSFS-MBanking-Proof.mp4">
    <img src="https://img.shields.io/badge/▶_Watch_Video_Proof-M--Banking_Working_&_Bypass-success?style=for-the-badge&logo=youtube" alt="Watch Proof Video" />
  </a>
  <p><i>Click badge above to play or download the video demonstration (.mp4)</i></p>
</div>

---

## Kernel Variants & Flashing Guide

Two flashable AnyKernel3 packages are provided:

| Variant | Recommended OS | Description |
|---|---|---|
| **`RE404-VAYU-ResukiSU-SuSFS-BPF.zip`** | **Android 15, 16, 17+** | Full eBPF support (`CONFIG_ANDROID_16_BPF=y`) for modern Android networking (`NetBpfLoad`, offload, tethering). |
| **`RE404-VAYU-ResukiSU-SuSFS-NON-BPF.zip`** | **Android 12, 13, 14, MIUI, HyperOS** | Legacy netd compatibility without Android 15/16+ BPF changes. |

### How to Flash
1. Reboot to custom recovery (**OrangeFox Recovery** or **TWRP** recommended).
2. *(Optional)* Back up your current `boot` partition.
3. Flash the matching zip variant for your ROM.
4. Reboot to system.
5. Install the **ReSukiSU / BakaSU Manager** app if not already installed.

### Post-Flash Verification (Terminal / Root Shell)
```sh
e404
cat /sys/kernel/mm/lru_gen/enabled /sys/kernel/mm/lru_gen/min_ttl_ms /sys/module/wakeup/parameters/enable_wakelock_blocker
# Expected:
# 0x0001
# 0
# Y
```

---

## Building From Source

Requires an existing `AnyKernel3` directory and toolchain (e.g., `toolchains/neutron-clang`) alongside the cloned kernel directory.

```bash
# Clone the repository
git clone https://github.com/fakfekrill-glitch/xiaomi_sm8150_kernel_e404_modified -b main-susfs kernel
cd kernel

# BPF variant (Android 15, 16, 17+):
./compile.sh vaybpf sus bpf neutron

# Non-BPF variant (Android 12, 13, 14, MIUI, HyperOS):
./compile.sh vayu sus neutron
```

---

## Credits & Acknowledgments
- [@deutereium](https://github.com/deutereium) for the E404 kernel source and Android 15–17 backports
- [Baka-SU / ReSukiSU Team](https://github.com/Baka-SU)
- [simonpunk](https://gitlab.com/simonpunk/susfs4ksu) for SuSFS
- [tiann](https://github.com/tiann) for KernelSU
- [osm0sis](https://github.com/osm0sis) for AnyKernel3
- [dakkshesh07](https://github.com/dakkshesh07) for Neutron Clang
- Yu Zhao & Linux MM developers for Multi-Gen LRU (MGLRU)
- **Dalu Raziq Hidayatullah** ([@fakfekrill-glitch](https://github.com/fakfekrill-glitch)) for porting, non-GKI 4.14 fixes, tuning, and maintenance

---
**License**: [GPL-2.0](LICENSE)
