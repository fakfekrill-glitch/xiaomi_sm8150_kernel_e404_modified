#!/usr/bin/env bash
# E404 Kernel Compile Script !
# Put a fucking credit if you use something from here !

# Set kernel source directory and base directory to place tools
KERNEL_DIR="$PWD"
cd ..
BASE_DIR="$PWD"
cd "$KERNEL_DIR"

set -eo pipefail
trap 'errorbuild' INT TERM ERR

AK3_DIR="$BASE_DIR/AnyKernel3"
[[ ! -d "$AK3_DIR" ]] && echo "!! Please Provide AnyKernel3 !!" && exit 1

# Parse command line arguments
TYPE="BPF"
TC="Unknown-Clang"
TARGET=""
DEFCONFIG=""

case "$*" in
    *st*)
        git checkout main
        TYPE="STABLE" ;;
    *dev*) TYPE="DEV" ;;
    *sus*) 
        git checkout main-susfs
        TYPE="SUSFS" 
        ;;
esac

case "$*" in

    *gf*)
        export PATH="$BASE_DIR/toolchains/gf-clang/bin:$PATH"
        TC="vayu-Gf-Clang"
        ;;
    *aosp*)
        export PATH="$BASE_DIR/toolchains/aosp-clang/bin:$PATH"
        TC="AOSP-Clang"
        ;;
    *neutron*)
        export PATH="$BASE_DIR/toolchains/neutron-clang/bin:$PATH"
        TC="Neutron-Clang"
        ;;
    *llvm*)
        export PATH="$BASE_DIR/toolchains/llvm-clang/bin:$PATH"
        TC="LLVM-Clang"
        ;;
    *lilium*)
        export PATH="$BASE_DIR/toolchains/lilium-clang/bin:$PATH"
        TC="Lilium-Clang"
        ;;
    *eva*)
        GCC64_DIR="$BASE_DIR/toolchains/gcc/gcc-arm64/bin/"
        GCC32_DIR="$BASE_DIR/toolchains/gcc/gcc-arm/bin/"
        export PATH="$GCC64_DIR:$GCC32_DIR:/usr/bin:$PATH"
        TC="EVA"
        ;;
    *gcc*)
        GCC64_DIR="$BASE_DIR/toolchains/gcc/gcc-14.2.0-nolibc/aarch64-linux/bin"
        GCC32_DIR="$BASE_DIR/toolchains/gcc/gcc-14.2.0-nolibc/arm-linux-gnueabi/bin"
        export PATH="$GCC64_DIR:$GCC32_DIR:$PATH"
        TC="GCC"
        ;;
    *)
        if [[ -d "$BASE_DIR/toolchains/llvm-clang" ]]; then
            export PATH="$BASE_DIR/toolchains/llvm-clang/bin:$PATH"
            TC="LLVM-Clang"
        elif [[ -d "$BASE_DIR/toolchains/lilium-clang" ]]; then
            export PATH="$BASE_DIR/toolchains/lilium-clang/bin:$PATH"
            TC="Lilium-Clang"
        elif [[ -d "$BASE_DIR/toolchains/gf-clang" ]]; then
            export PATH="$BASE_DIR/toolchains/gf-clang/bin:$PATH"
            TC="vayu-Gf-Clang"
        elif [[ -d "$BASE_DIR/toolchains/aosp-clang" ]]; then
            export PATH="$BASE_DIR/toolchains/aosp-clang/bin:$PATH"
            TC="AOSP-Clang"
        elif [[ -d "$BASE_DIR/toolchains/neutron-clang" ]]; then
            export PATH="$BASE_DIR/toolchains/neutron-clang/bin:$PATH"
            TC="Neutron-Clang"
        else
            echo "-- !! Please provide a toolchain !! --"
            exit 1
        fi
        ;;
esac

# Device selection using arrays
    declare -A DEVICE_MAP=(
        ["vayu"]="VAYU:vayu_defconfig"
        ["debug"]="DEBUG:vayu-debug_defconfig"
        ["vaybpf"]="VAYBPF:vayu-bpf_defconfig"
    )

for arg in "$@"; do
    if [[ -n "${DEVICE_MAP[$arg]}" ]]; then
        IFS=':' read -r TARGET DEFCONFIG <<< "${DEVICE_MAP[$arg]}"
        sed -i "/devicename=/c\devicename=vayu" "$AK3_DIR/anykernel.sh"
        break
    fi
done

[[ ! "$TARGET" ]] && echo "-- !! Please set build device target !! --" && exit 1

# Set kernel image paths
K_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image"
K_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
K_DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb.img"

# Telegram configuration - Load from external file
TELEGRAM_CONFIG="$BASE_DIR/kernel_build"
if [[ -f "$TELEGRAM_CONFIG" ]]; then
    source "$TELEGRAM_CONFIG"
    export TOKEN="$TELEGRAM_TOKEN"
    export CHATID="$TELEGRAM_CHATID"
else
    echo "-- Warning: Telegram config file not found at $TELEGRAM_CONFIG --"
    echo "-- Telegram notifications will be disabled --"
    export TOKEN=""
    export CHATID=""
fi

# Define dummy notification functions if not defined by TELEGRAM_CONFIG
if ! declare -f send_msg >/dev/null 2>&1; then
    send_msg() { :; }
fi
if ! declare -f send_file >/dev/null 2>&1; then
    send_file() { :; }
fi

# Build environment
export ARCH="arm64"
export SUBARCH="arm64"
export TZ="Asia/Jakarta"

# Clean previous builds
# rm -rf ../*RE404*.zip

# Function definitions
build_msg() {
    local BRANCH=$(git rev-parse --abbrev-ref HEAD)
    local COMMIT=$(git log -1 --pretty=format:'%s')
    local MSG=$(cat <<EOF
<b>Build Triggered !</b>
<code>Device : $TARGET</code>
<code>Branch : $BRANCH</code>
<code>ToolCh : $TC</code>
<b>Commit :</b>
<code>$COMMIT</code>
EOF
)
    send_msg "$MSG"
}

success_msg() {
    local MSG=$(cat <<EOF
<b>Build Success !</b>
<code>Date : $(date +"%d %b %Y, %H:%M:%S")</code>
<code>Time : $(($TIME_END / 60))m $(($TIME_END % 60))s</code>
EOF
)
    send_msg "$MSG"
}

clearbuild() {
    if [[ "$1" == "all" ]]; then
        echo "-- Cleaning Out --"
        rm -rf out/*
    else
        rm -rf "$KERNEL_DIR/out/arch/arm64/boot"
    fi
}

zipbuild() {
    echo "-- Zipping Kernel --"
    cd "$AK3_DIR" || exit 1
    if [[ "$TARGET" == "VAYBPF" ]]; then
        ZIP_NAME="RE404-VAYU-ResukiSU-SuSFS-BPF.zip"
        cat << 'EOF' > banner
  ______ _  _    ___  _  _ 
 |  ____| || |  / _ \| || |
 | |__  | || |_| | | | || |_
 |  __| |__   _| | | |__   _|
 | |____   | | | |_| |  | |  
 |______|  |_|  \___/   |_|  
 ╔════════════════════════════════════════╗
 ║      >> E404 CYBERNETIC KERNEL <<      ║
 ║  • Target  : Android 15 / 16 / 17+     ║
 ║  • Core    : eBPF + ReSukiSU + SuSFS   ║
 ║  • Engine  : BBRplus FQ | Sched 120Hz  ║
 ║  • Device  : POCO X3 Pro (vayu/bhima)  ║
 ║  • Author  : Dalu Raziq Hidayatullah   ║
 ╚════════════════════════════════════════╝
EOF
    else
        ZIP_NAME="RE404-VAYU-ResukiSU-SuSFS-NON-BPF.zip"
        cat << 'EOF' > banner
  ______ _  _    ___  _  _ 
 |  ____| || |  / _ \| || |
 | |__  | || |_| | | | || |_
 |  __| |__   _| | | |__   _|
 | |____   | | | |_| |  | |  
 |______|  |_|  \___/   |_|  
 ╔════════════════════════════════════════╗
 ║      >> E404 CYBERNETIC KERNEL <<      ║
 ║  • Target  : Android 12 - 14 / HyperOS ║
 ║  • Core    : Non-BPF + ReSukiSU + SuSFS║
 ║  • Engine  : BBRplus FQ | Sched 120Hz  ║
 ║  • Device  : POCO X3 Pro (vayu/bhima)  ║
 ║  • Author  : Dalu Raziq Hidayatullah   ║
 ╚════════════════════════════════════════╝
EOF
    fi
    rm -f "$BASE_DIR/$ZIP_NAME"
    rm -f "$AK3_DIR"/*dtbo*
    zip -r9 "$BASE_DIR/$ZIP_NAME" META-INF/ tools/ anykernel.sh banner* Image dtb "${TARGET}"*-Image "${TARGET}"*-dtb
    cd "$KERNEL_DIR" || exit 1
}


setupbuild() {
    if [[ $TC == *Clang* ]]; then
        CC_CMD="clang"
        if command -v ccache >/dev/null 2>&1; then
            CC_CMD="ccache clang"
        fi
        BUILD_FLAGS=(
            CC="$CC_CMD"
            CROSS_COMPILE="aarch64-linux-gnu-"
            CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
            LLVM=1
            LLVM_IAS=1
            LD="ld.lld"
            AR="llvm-ar"
            NM="llvm-nm"
            OBJCOPY="llvm-objcopy"
            OBJDUMP="llvm-objdump"
            STRIP="llvm-strip"
        )
        
        # Export for defconfig (without ccache)
        export CC="clang"
        export CROSS_COMPILE="aarch64-linux-gnu-"
        export CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
        export LLVM=1
        export LLVM_IAS=1
        
    elif [[ $TC == "EVA" ]]; then
        BUILD_FLAGS=(
            CC="ccache aarch64-elf-gcc"
            CROSS_COMPILE="aarch64-elf-"
            CROSS_COMPILE_ARM32="arm-eabi-"
            LD="aarch64-elf-ld.lld"
            AR="llvm-ar"
            NM="llvm-nm"
            OBJCOPY="llvm-objcopy"
            OBJDUMP="llvm-objdump"
            OBJSIZE="llvm-size"
            STRIP="llvm-strip"
        )

        # Export for defconfig (without ccache)
        export CC="aarch64-elf-gcc"
        export CROSS_COMPILE="aarch64-elf-"
        export CROSS_COMPILE_COMPAT="arm-eabi-"
    else
        BUILD_FLAGS=(
            CC="ccache aarch64-linux-gcc"
            CROSS_COMPILE="aarch64-linux-"
            CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
        )

        # Export for defconfig (without ccache)
        export CC="aarch64-linux-gcc"
        export CROSS_COMPILE="aarch64-linux-"
        export CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
    fi
    #export KBUILD_BUILD_TIMESTAMP="$(date -d '1 year ago' '+%a %b %d %H:%M:%S %Z %Y')"
}

errorbuild() {
    echo "-- !! Kernel Build Error !! --"
    send_file "$BASE_DIR/compile.log"
    send_msg "<b>! Kernel Build Error !</b>"
    clearbuild
    exit 1
}

compilebuild() {    
    mkdir -p $KERNEL_DIR/out

    local make_flags=(-j"$(nproc)" O=out "${BUILD_FLAGS[@]}")
    
    if [[ $TC == *Clang* ]]; then
        echo "-- Compiling with Clang --"
        make "${make_flags[@]}" Image dtbs dtb.img || errorbuild
    else
        echo "-- Compiling with GCC --"
        make "${make_flags[@]}" Image dtbs dtb.img || errorbuild
    fi
}

makebuild() {
    # Config modifications
    export KBUILD_BUILD_USER="vyn"
    export KBUILD_BUILD_HOST="fedora"
    #sed -i '/CONFIG_KALLSYMS=/c\CONFIG_KALLSYMS=n' out/.config
    #sed -i '/CONFIG_KALLSYMS_BASE_RELATIVE=/c\CONFIG_KALLSYMS_BASE_RELATIVE=n' out/.config
    #sed -i '/CONFIG_KSU_SUSFS=/c\CONFIG_KSU_SUSFS=n' out/.config
    echo 0 > out/.version
   
    echo "-- Compiling Kernel --"
    export CCACHE_DIR="$BASE_DIR/ccache/.ccache_$TC"

    compilebuild
    # Show ccache stats after build
    if command -v ccache >/dev/null 2>&1; then
        echo "======== CCache Stats =========="
        ccache -p | grep cache_dir || true
        ccache -s || true
        echo "================================"
    fi

    echo "-- Copying files to AnyKernel3 --"
    rm -f "$AK3_DIR"/*Image "$AK3_DIR"/*dtb* "$AK3_DIR"/*dtbo*
    cp "$K_IMG" "$AK3_DIR/${TARGET}-Image"
    cp "$K_IMG" "$AK3_DIR/Image"
    cp "$K_DTB" "$AK3_DIR/${TARGET}-dtb"
    cp "$K_DTB" "$AK3_DIR/dtb"

}

setupbuild

# Main menu
while true; do
    echo ""
    echo " Menu "
    echo " ╔════════════════════════════════════╗"
    echo " ║ 1. Export Defconfig                ║"
    echo " ║ 2. Start Build                     ║"
    echo " ║ 3. Send File                       ║"
    echo " ║ 4. Repack Last Build               ║"
    echo " ║ f. Clean Out Directory             ║"
    echo " ║ fc. Clean Ccache                   ║"
    echo " ║ e. Exit                            ║"
    echo " ╚════════════════════════════════════╝"
    echo -n " Enter your choice : "
    read -r menu
    
    case "$menu" in
        1)
            make O=out "$DEFCONFIG"
            echo "-- Exported $DEFCONFIG to Out Dir --"
            ;;
        2)
            TIME_START="$(date +"%s")"
            rm -f "$BASE_DIR/compile.log"
            clearbuild
            makebuild 2>&1 | tee -a "$BASE_DIR/compile.log"
            zipbuild
            TIME_END=$(("$(date +"%s")" - "$TIME_START"))
            ;;
        3)
            echo "-- Sending to Telegram --"
            send_file "$BASE_DIR/$ZIP_NAME"
            ;;
        4)
            zipbuild
            send_file "$BASE_DIR/$ZIP_NAME"
            ;;
        f)
            clearbuild "all"
            ;;
        fc)
            rm -rf "$BASE_DIR/ccache"
            ;;
        e)
            exit 0
            ;;
        *)
            echo "-- !! Invalid option !! --"
            ;;
    esac
done