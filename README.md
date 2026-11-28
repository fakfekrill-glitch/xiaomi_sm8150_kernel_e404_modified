# E404 Custom Kernel for POCO X3 Pro (`vayu` / `bhima`)
Linux `4.14.356` (reporting `4.19.404R`) with ReSukiSU (BakaSU `v4.2.0-rc3`), SuSFS `v1.5.5`, Multi-Gen LRU (MGLRU), Frame Aware Scaling (FAS), and unrestricted 6A Turbo Charge to 100%.

![Device](https://img.shields.io/badge/Device-POCO%20X3%20Pro%20(vayu%2Fbhima)-blue)
![SoC](https://img.shields.io/badge/SoC-Snapdragon%20860%20(SM8150--AC)-orange)
![Kernel](https://img.shields.io/badge/Kernel-4.14.356%20(4.19.404R)-green)
![Compiler](https://img.shields.io/badge/Compiler-Neutron%20Clang%2024%20(ThinLTO)-red)
![Android](https://img.shields.io/badge/Android-12%20to%2017%2B%20(Tested%20on%20crDroid%2012.13)-purple)
![Root](https://img.shields.io/badge/Root-BakaSU%20%2B%20SuSFS%20v1.5.5-red)

---

## Maintainer and Contact
- Maintained and modified by Dalu Raziq Hidayatullah ([@fakfekrill-glitch](https://github.com/fakfekrill-glitch))
- Base E404 kernel source by [@deutereium](https://github.com/deutereium) ([xiaomi_sm8150_kernel_e404](https://github.com/deutereium/xiaomi_sm8150_kernel_e404))

[![Telegram](https://img.shields.io/badge/Telegram-@PushyAja-blue?logo=telegram)](https://t.me/PushyAja)
[![Instagram](https://img.shields.io/badge/Instagram-dalu.hidayatullah-E4405F?logo=instagram)](https://instagram.com/dalu.hidayatullah)
[![Discord](https://img.shields.io/badge/Discord-pushygamertag27-5865F2?logo=discord)](https://discord.com)

- Telegram: [@PushyAja](https://t.me/PushyAja)
- Instagram: [@dalu.hidayatullah](https://instagram.com/dalu.hidayatullah)
- Discord: `pushygamertag27`

---

## Device and OS Compatibility

| Item | Details |
|---|---|
| Supported devices | Xiaomi POCO X3 Pro (`vayu` global, `bhima` India) |
| SoC | Qualcomm Snapdragon 860 (`SM8150-AC`) |
| Upstream base | Linux `4.14.356` (`UTS_RELEASE="4.19.404R"` via `scripts/POST-GEN.sh`) |
| Compiler toolchain | Neutron Clang `24.0.0` + Neutron LLD `24.0.0` with `CONFIG_LTO_CLANG_THIN=y` |
| BPF build (`vayu-bpf_defconfig`) | Android 15, 16, and 17+ AOSP ROMs (verified on crDroid 12.13 / Android 16) |
| Non-BPF build (`vayu_defconfig`) | Android 12, 13, 14 AOSP ROMs, MIUI 12.5/13/14, and HyperOS |

Repository branch layout:
- `main-susfs`: primary development and release branch used by `compile.sh` when passing `sus`
- `beta-mglru`: tracks `main-susfs` across MGLRU, charging, and FAS releases
- `main`: default branch synced at each release tag via `--no-ff` merge from `beta-mglru`

---

## Known Features

### 1. Upstream Base, Modern Android Backports, and Debloat
- Backports Linux `5.15` Android Binder IPC, the `clone3()` syscall, and `bpf_atomic` instructions required by Android 15 to 17+ ART and `NetBpfLoad`.
- Backports Linux `5.10` RCU and `5.10` ZRAM subsystems onto `4.14.356`, paired with `scripts/POST-GEN.sh` reporting kernel version `4.19.404R` to userspace.
- Fixes slow UI animations on HyperOS and removes the post-reboot 60Hz display refresh rate lock.
- Keeps multi-IR remote driver support, drops the 140 MHz Adreno GPU idle step, and disables Content Adaptive Backlight Control (CABC).
- Builds WireGuard natively into the kernel (`CONFIG_WIREGUARD=y`) and keeps `pstore` (`ramoops`) enabled for crash log capture.
- Disables unused `CONFIG_EDAC` and `CONFIG_QCOM_DLOAD_MODE` error-dump subsystems while compiling both BPF and Non-BPF defconfigs with zero compiler warnings.

### 2. Multi-Gen LRU (MGLRU) and Memory Management
- Enables Multi-Gen LRU (`CONFIG_LRU_GEN=y`, `CONFIG_LRU_GEN_ENABLED=y`) configured with 4 page generations (`MAX_NR_GENS = 4`) and 4 refault tiers (`MAX_NR_TIERS = 4`).
- Sets `lru_gen_min_ttl` to `0` ms by default so memory pressure triggers do not stall behind artificial age thresholds before OOM/LMK action.
- Fixes `vmpressure_global()` in `mm/vmpressure.c` to skip zero-scanned non-critical global events, stopping MGLRU aging and sorting passes from reporting false `pressure = 100` spikes to Simple LMK (`CONFIG_ANDROID_SIMPLE_LMK=y`, minfree `100`, timeout `200` ms).
- Fixes `lru_deactivate_file_fn()` so deactivated clean file pages remain tracked inside MGLRU generational lists rather than falling back to legacy LRU lists.
- Includes backport stability fixes in `mm/vmscan.c` and page-reclaim paths for `reclaim_state` initialization, `PG_active` bit-clear ordering, `p4d_entry` page-table traversal, IRQ-safe `mm_list->lock` locking, and fork/exec process list tracking.
- Sets ZSTD as the default ZRAM compressor (`CONFIG_ZRAM_DEF_COMP_ZSTD=y`) and overrides `page_cluster = 0` in `mm/swap.c` so ZRAM reads single requested pages instead of wasting cycles decompressing swap readahead windows.
- Sets default VM parameters to `vm_swappiness = 100` (`mm/vmscan.c`), `dirty_background_ratio = 5` (`mm/page-writeback.c`), and `sysctl_vfs_cache_pressure = 80` (`fs/dcache.c`).

### 3. CPU Scheduling, 120Hz Touch Boost (FAS), and IRQ Balancing
- Uses CASS (`CONFIG_SCHED_CASS=y`) with capacity-aware task placement, Task Utilization Clamping (`CONFIG_UCLAMP_TASK=y`, `CONFIG_UCLAMP_TASK_GROUP=y`, `CONFIG_UCLAMP_ASSIST=y` with 20 buckets), and `HZ = 250`.
- Tunes `schedutil` (`CONFIG_CPU_FREQ_GOV_SCHEDUTIL=y`) down to `rate_limit_us = 1000` (1 ms) in `kernel/sched/cpufreq_schedutil.c` so frequency scaling responds within an 8.33 ms 120Hz frame budget.
- Drives refresh-rate-aware CPU touch and render boosting through Frame Aware Scaling (`CONFIG_SCHED_FAS=y` in `kernel/sched/fas.c`), which hooks both touchscreen input (`fas_input_boost_ms = 50`, `150` ms cooldown) and Adreno GPU command-batch completions (`fas_do_cmdbatch_boost()`, `50` to `200` ms adaptive window) without activating duplicate `cpu-boost` handlers (`# CONFIG_CPU_BOOST is not set`):
  - Above `90Hz` (120Hz mode): sets Little cluster (`0-3`) minimum floor to `1804800` kHz, Big cluster (`4-6`) to `940800` kHz during touch windows, and Prime core (`7`) to `1056000` kHz during touch windows.
  - At `75 to 90Hz`: sets Little cluster (`0-3`) floor to `1401600` kHz, and raises Big and Prime floors to `825600` kHz during touch windows.
  - At `60Hz` or lower: skips FAS boost to preserve idle battery life.
  - Continuous GPU `cmdbatch` frames keep only the Little cluster raised so gaming or scrolling does not lock Big or Prime cores high, while a single-active `fas_wq` (`max_active = 1`) prevents expiry races between touch and frame boost states.
- Enables `CONFIG_DEVFREQ_BOOST=y` for DDR and LLCC memory bus scaling (`3879` MHz boost frequency, `58` ms input boost window, `1000` ms wake boost window).
- Enables `CONFIG_IRQ_SBALANCE=y` (`10000` ms polling interval, `1024` interrupt threshold) while excluding CPUs `3`, `6`, and `7` (`CONFIG_SBALANCE_EXCLUDE_CPUS="3,6,7"`).

### 4. Fast Charging (Unrestricted 6A Turbo Charge), Aftermarket Chargers, and Battery Profiles
- Enables `/sys/kernel/fast_charge/force_fast_charge = 1` by default in `drivers/power/supply/qcom/fast-charge.c`, locking `FCC` to `6,000,000 uA` (6A) and clearing limiting voters (`THERMAL_DAEMON_VOTER`, `RESTRICT_CHG_VOTER`, `SLOWLY_CHARGING_VOTER`, `BATT_VERIFY_VOTER`, `STEP_CHG_VOTER`, `CLASSA_QC_FCC_VOTER`, `BQ_TAPER_FCC_VOTER`).
- Leaves `USB_ICL` free of `vote_override` (`fast-charge.c`) so PM8150B retains hardware APSD detection, QC3 500 mA pulse negotiation, and 50 mA main-charger shutdown during Charge Pump operation without collapsing VBUS.
- Keeps both Charge Pump controllers (`cp_qc30` and `pd_policy_manager`) active up to `HIGH_CAPACITY_TRH = 100`% SOC and `4450 mV` (`BATT_MAX_CHG_VOLT = 4450`, `mi,qc3-bat-volt-max`, `mi,qc3-ffc-bat-volt-max`, `mi,pd-ffc-bat-volt-max`, and `mi,pd-non-ffc-bat-volt-max` in `vayu-sm8150.dtsi`), eliminating early 90% to 95% SOC or 4320 mV drops back to the slower PMIC charger.
- Adds adaptive fast-ramp Charge Pump tuning:
  - `cp_qc30.c` cuts initial post-HVDCP3 start delay to `1500 ms` (down from 3 seconds), uses `80 ms` pre-ramp voltage stepping, and runs `200 ms` active current loop ticks below target current with tighter hysteresis (`ibus_minus = 300`, `ibat_minus = 450` above 29% SOC).
  - `pd_policy_manager.c` enters PPS at `150 ms` polling and boosts in up to `40 mV` steps every `250 ms` below target current, settling back to `500 ms` near peak current or CV taper.
- Fixes third-party charger and cable compatibility:
  - Fixes a multi-APDO latch bug in `drivers/usb/pd/policy_engine.c` (`pps_weak_limit`) where a sub-18W first APDO throttled 30W+ PPS chargers (such as Anker bricks) down to 1.5A.
  - Adds wide-range 16V and 21V PPS APDO negotiation safely clamped to `APDO_MAX_VOLT = 11000` mV, and removes the 2.0A-to-1.5A PPS fallback.
  - Raises QC3 Class B limits to `6000` mA battery / `3000` mA bus with `11000` mV bus OVP alarm (`12000` to `13000` mV OVP fault) and `3500` mA bus OCP alarm (`3750` mA OCP fault) across `bq2597x` and `ln8000`, plus a relaxed `12.0V` Class B cable IR-drop threshold (`VOL_THR_FOR_QC_CLASS_AB`).
  - Raises legacy and third-party adapter/cable current ceilings to `2400 mA` (`DCP_CURRENT_UA`), `2000 mA` (`HVDCP2_CURRENT_UA`), `2000 mA` (`FLOAT_CHARGER_UA`, regulated dynamically by AICL), and `3000 mA` (`HVDCP_CURRENT_UA`).
  - Marks USB-PD adapters verified and activates FFC on connect without MIUI `batterysecret` (`pd_policy_manager.c`), reports `QUICK_CHARGE_TURBE` (`3`) on USB-PD and QC3 Class B (`smb5-lib.c`), and exposes the active `PD_VOTER` or `SW_ICL_MAX_VOTER` current limit on `usb/current_max` instead of `50 mA` during Charge Pump mode so AOSP ROMs such as crDroid display charging speed accurately.
- Supports switchable Fuel Gauge battery data profiles (`vayu-sm8150.dtsi`) and suppresses `ds28e16` auth failure `dmesg` spam on replacement aftermarket packs without OEM crypto ICs:
  - `0` (`batt_def`): OEM `5160 mAh` battery
  - `1` (`batt_6k`): `6000 mAh` custom battery profile (default)
  - `2` (`batt_65k`): `6500 mAh` custom battery profile (`fg-gen4-batterydata-vayu-6500mah.dtsi`)

### 5. Networking, Storage, and Wake Behavior
- Sets `bbrplus` (`net/ipv4/tcp_bbrplus.c`) as default TCP congestion control alongside `bbr` and `westwood`, paired with Fair Queue packet scheduling (`CONFIG_NET_SCH_FQ=y`, `CONFIG_DEFAULT_NET_SCH="fq"`, `fq_codel` included).
- Enables TCP Fast Open (`TFO_CLIENT_ENABLE | TFO_SERVER_ENABLE` in `net/ipv4/tcp_ipv4.c`) and sets `sysctl_tcp_slow_start_after_idle = 0` (`net/ipv4/tcp_output.c`).
- Enables F2FS transparent compression (`CONFIG_F2FS_FS_COMPRESSION=y`) supporting `LZO`, `LZ4`, and `ZSTD` (`CONFIG_F2FS_FS_ZSTD=y`) adapted to the kernel 4.14 zstd API, with Qualcomm UFS inline hardware encryption active (`CONFIG_SCSI_UFS_QCOM=y`, `CONFIG_SCSI_UFS_CRYPTO_QTI=y`).
- Restores `drivers/base/power/wakeup.c` to stock E404 behavior (no Boeffla wakelock blocker) so push notifications, alarms, and Wi-Fi packets wake cleanly out of deep sleep without delay.

### 6. Root (`ReSukiSU`) and Stealth (`SuSFS v1.5.5`)
- Bundles ReSukiSU / BakaSU (`v4.2.0-rc3`) compiled in-tree (`CONFIG_KSU=y`) with `CONFIG_KSU_FEATURE_SULOG=y`, `CONFIG_KSU_FEATURE_ADBROOT=y`, and `CONFIG_KSU_LSM_SECURITY_HOOKS=y`.
- Integrates SuSFS `v1.5.5` with `SUS_PATH`, `SUS_MOUNT`, `SUS_KSTAT`, `SPOOF_UNAME`, `SPOOF_CMDLINE_OR_BOOTCONFIG`, `OPEN_REDIRECT`, `SUS_MAP`, and `HIDE_KSU_SUSFS_SYMBOLS`.
- Includes non-GKI 4.14 fixes for `sucompat` `faccessat` / `stat` user-pointer checks and converts stack-heavy buffers in `fs/susfs/` to heap allocations to avoid ThinLTO frame warnings.

### 7. Built-in `e404` CLI Fetch Tool (`scripts/e404`)
Flashing either AnyKernel3 zip attempts to install `e404` into `/data/adb/ksu/bin`, `/data/adb/magisk`, `/data/data/com.termux/files/usr/bin`, and `/data/local/tmp`. Running it outputs live system telemetry formatted safely for Android's 32-bit `mksh` integer arithmetic:
- Device model, codename, Android version, and `uname -r` kernel release
- CPU load percentage plus current Little / Big / Prime cluster clocks in MHz
- Adreno 640 clock frequency (MHz) and busy percentage
- RAM usage and ZRAM uncompressed vs. compressed memory usage
- Active Wi-Fi IPv4 address and MAC address
- Battery percentage, status, health, temperature, voltage, signed current (mA), and learned full vs. design capacity
- Live charging diagnostics (`Turbo`, `Flash`, `Fast`, or `Normal`, USB `real_type`, active adapter `ICL` in mA, and live wattage estimate `~W`, or `Unplugged` power draw)
- Feature status line: active TCP congestion control, `FastChg` (`6A`/`Stock`), `FAS` (`On`/`Off`), and MGLRU bitmask (`0x0001`)

---

## Runtime Tunables (`sysfs` and Kernel Cmdline)

### Boot Arguments (`e404_args=...`)
Parsed early in `drivers/misc/e404_attributes.c`:
- Battery profile: `batt_def` (`5160` mAh), `batt_6k` (`6000` mAh, default), `batt_65k` / `batt_6500` (`6500` mAh)
- Panel / DTBO / ROM selection: `dtbo_120`, `dtbo_130`, `dtbo_def`, `dtbo_oem`, `rom_aosp`, `rom_oem`, `rom_port`, `dtb_effcpu`, `dtb_def`, `ir0`, `ir1`, `lyb0`, `lyb1`, `lyb2`

### `sysfs` Controls

| Interface | Default | Purpose |
|---|---|---|
| `/sys/kernel/fast_charge/force_fast_charge` | `1` | Override `FCC` to `6,000,000 uA` (`1` enabled, `0` stock voting) |
| `/sys/kernel/mm/lru_gen/enabled` | `0x0001` | Read MGLRU capabilities or toggle (`y`/`n`/bitmask) |
| `/sys/kernel/mm/lru_gen/min_ttl_ms` | `0` | Minimum generation age threshold in milliseconds |
| `/sys/kernel/e404/fas` | `1` | Enable (`1`) or disable (`0`) FAS touch and cmdbatch CPU boosting |
| `/sys/kernel/e404/batt_profile` | `1` | Active Fuel Gauge profile index (`0`: 5160, `1`: 6000, `2`: 6500) |
| `/sys/kernel/e404/batt_capacity_mah` | `0` | Custom capacity override in mAh (`0` uses selected DTSI profile) |
| `/sys/kernel/e404/file_sync` | `1` | Toggle `fsync` behavior |
| `/sys/kernel/e404/kgsl_skip_zeroing` | `0` | Adreno KGSL pool zeroing skip toggle |

---

## Known Behavior, Limitations, and Notes

### Why MGLRU reports `0x0001` instead of `0x0007`
In `include/linux/mmzone.h` and `mm/vmscan.c`, bit `0` (`0x0001`) is `LRU_GEN_CORE`, bit `1` (`0x0002`) is `LRU_GEN_MM_WALK` (gated by `arch_has_hw_pte_young()`), and bit `2` (`0x0004`) is `LRU_GEN_NONLEAF_YOUNG` (gated by `CONFIG_ARCH_HAS_NONLEAF_PMD_YOUNG`). Because this `4.14.356` `arm64` backport leaves `arch_has_hw_pte_young()` as `false` and does not define `CONFIG_ARCH_HAS_NONLEAF_PMD_YOUNG`, MGLRU reports `0x0001` and runs full generational reclaim via `iterate_mm_list_nowalk()` and `lru_gen_look_around()`, avoiding bursty software accessed-bit page faults. This is normal for `4.14` arm64 and does not limit MGLRU operation.

### Unrestricted 6A Charge Pump behavior under heat
On QC3 (`cp_qc30.c`), kernel thermal-level throttling and JEITA Charge Pump cutoffs remain intentionally bypassed (`qc3_get_batt_current_thermal_level()` returns `0`, `qc3_disable_cp_by_jeita_status()` returns `false`) so boost charging stays continuous up to 100% SOC. Hardware OVP and OCP alarms remain active on `bq2597x` and `ln8000`, while `pd_policy_manager.c` still enforces `JEITA_WARM_THR = 450` (`45.0` °C) on USB-PD PPS. Monitor battery temperatures if gaming heavily while fast-charging in warm rooms.

### Running `e404` in MT Manager Terminal
Typing `e404` directly inside MT Manager Terminal often returns `not found` because `/data/local/tmp` and Termux directories sit outside MT Manager's default `$PATH`, and `/data/adb` (`0700 root:root`) blocks non-root traversal. Run it with root via `su -c /data/adb/ksu/bin/e404` (or `su -c sh /data/local/tmp/e404`). If neither file exists after flashing in recovery, `/data` was encrypted or unmounted during the flash; re-flash from a decrypted recovery session or an in-OS kernel flasher app.

### Block I/O scheduler default
Both defconfigs retain `CONFIG_DEFAULT_IOSCHED="cfq"` with `# CONFIG_SCSI_MQ_DEFAULT is not set` for compatibility across Android 12 to 17 ROMs, while `CONFIG_MQ_IOSCHED_KYBER=y` and `CONFIG_MQ_IOSCHED_DEADLINE=y` remain built in.

---

## Verification Proof (BakaSU, SuSFS, and Banking Apps)

Captured on POCO X3 Pro (`crDroid 12.13` / Android 16) running BakaSU `v4.2.0-rc3` and SuSFS `v1.5.5`:

<div align="center">
  <img src="media/bakasu_susfs_proof.png" alt="BakaSU + SuSFS Proof" width="360" />
  <br /><br />
  <a href="https://github.com/fakfekrill-glitch/xiaomi_sm8150_kernel_e404_modified/releases/download/R3-SuSFS-v1.5.5/E404-BakaSU-SuSFS-MBanking-Proof.mp4">
    <img src="https://img.shields.io/badge/▶_Watch_Video_Proof-M--Banking_Working_&_Bypass-success?style=for-the-badge&logo=youtube" alt="Watch Proof Video" />
  </a>
  <p><i>Click the badge above to play or download the video demonstration (.mp4)</i></p>
</div>

---

## Kernel Variants and Flashing Guide

| Variant | Recommended OS | Details |
|---|---|---|
| `RE404-VAYU-ResukiSU-SuSFS-BPF.zip` | Android 15, 16, 17+ | Enables `CONFIG_ANDROID_16_BPF=y` for modern Android networking (`NetBpfLoad`, offload, tethering). |
| `RE404-VAYU-ResukiSU-SuSFS-NON-BPF.zip` | Android 12, 13, 14, MIUI, HyperOS | Standard `netd` compatibility without Android 15/16+ BPF changes. |

### How to Flash
1. Reboot to custom recovery (OrangeFox Recovery or TWRP recommended; decrypt `/data` if you want `e404` CLI installed automatically during flash).
2. Back up your current `boot` partition if needed.
3. Flash the zip matching your ROM.
4. Reboot to system.
5. Install the ReSukiSU / BakaSU Manager app if not already present.

### Post-Flash Verification (Termux or MT Manager Root Shell)
```sh
# In Termux:
e404

# In MT Manager Terminal (or any root shell where /data/adb/ksu/bin is outside $PATH):
su -c /data/adb/ksu/bin/e404

# Verify MGLRU, FAS, and Force 6A Fast Charge states:
su -c "cat /sys/kernel/mm/lru_gen/enabled /sys/kernel/mm/lru_gen/min_ttl_ms /sys/kernel/fast_charge/force_fast_charge /sys/kernel/e404/fas"
# Expected output:
# 0x0001
# 0
# 1
# 1
```

---

## Building From Source

Place `AnyKernel3` and the compiler toolchain (`toolchains/neutron-clang`) in the parent directory alongside the cloned kernel directory.

```bash
# Clone the repository
git clone https://github.com/fakfekrill-glitch/xiaomi_sm8150_kernel_e404_modified -b main-susfs kernel
cd kernel

# Start interactive build menu for BPF variant (choose 1: Export Defconfig, 2: Start Build):
./compile.sh sus vaybpf neutron

# Start interactive build menu for Non-BPF variant (choose 1: Export Defconfig, 2: Start Build):
./compile.sh sus vayu neutron
```

---

## Credits and Acknowledgments
- [@deutereium](https://github.com/deutereium) for the E404 kernel source, FAS, and Android 15 to 17 backports
- [Baka-SU / ReSukiSU Team](https://github.com/Baka-SU)
- [simonpunk](https://gitlab.com/simonpunk/susfs4ksu) for SuSFS
- [tiann](https://github.com/tiann) for KernelSU
- [osm0sis](https://github.com/osm0sis) for AnyKernel3
- [dakkshesh07](https://github.com/dakkshesh07) for Neutron Clang
- Yu Zhao and Linux MM contributors for Multi-Gen LRU (MGLRU)
- Dalu Raziq Hidayatullah ([@fakfekrill-glitch](https://github.com/fakfekrill-glitch)) for porting, non-GKI 4.14 fixes, charging and FAS tuning, and maintenance

---
License: [GPL-2.0](LICENSE)
