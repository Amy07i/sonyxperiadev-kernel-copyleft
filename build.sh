#!/bin/bash
export KBUILD_BUILD_USER=mianyuan
export KBUILD_BUILD_HOST=travis
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"

OUT_DIR=${HOME}
COMPILE_DATE=$(date +"%Y%m%d")
CLANG_URL="https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-7284624.git"
GCC_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu.tar.xz?revision=972019b5-912f-4ae6-864a-f61f570e2e7e&la=en&hash=B8618949E6095C87E4C9FFA1648CAA67D4997D88"
GCC="gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu"
GCC32_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz?revision=d0b90559-3960-4e4b-9297-7ddbc3e52783&la=en&hash=985078B758BC782BC338DB947347107FBCF8EF6B"
GCC32="gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf"
DEFCONFIG=poplar_dsds_diffconfig
LOCAL_VERSION="r3.2"

# clone Clang and Anykernl3
git clone ${CLANG_URL} ${OUT_DIR}/clang --depth=1
wget ${GCC_URL} -P ${OUT_DIR}
wget ${GCC32_URL} -P ${OUT_DIR}
tar Jxvf ${OUT_DIR}/*gnu.tar* -C ${OUT_DIR}/
tar Jxvf ${OUT_DIR}/*gnueabihf.tar* -C ${OUT_DIR}/
git clone https://github.com/Amy07i/AnyKernel3 ${OUT_DIR}/AnyKernel3 --depth=1

# Compile
export LOCALVERSION="-${LOCAL_VERSION}"
export PATH="${OUT_DIR}/clang/bin:${OUT_DIR}/${GCC}/bin/:${OUT_DIR}/${GCC32}/bin:$PATH"
cd ${OUT_DIR}/kernel
make O=./out clean
make O=./out mrproper
export KBUILD_DIFFCONFIG=${DEFCONFIG}
make O=out ARCH=arm64 msmcortex-perf_defconfig
make -j${KJOBS} O=out ARCH=arm64 CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-none-linux-gnu- CROSS_COMPILE_ARM32=arm-none-linux-gnueabihf-

# package
cd ${OUT_DIR}/AnyKernel3
cp ${OUT_DIR}/kernel/out/arch/arm64/boot/Image.gz-dtb ${OUT_DIR}/AnyKernel3
mkdir -p ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/
cp ${OUT_DIR}/kernel/out/drivers/input/misc/bu520x1nvx.ko ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/bu520x1nvx.ko
cp ${OUT_DIR}/kernel/out/drivers/input/misc/fpc1145_platform.ko ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/fpc1145_platform.ko
cp ${OUT_DIR}/kernel/out/drivers/misc/ldo_vibrator.ko ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/ldo_vibrator.ko
cp ${OUT_DIR}/kernel/out/drivers/misc/pn553.ko ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/nxp_pn553_nfc.ko
cp ${OUT_DIR}/kernel/out/drivers/staging/qcacld-3.0/wlan.ko ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/qca_cld3_wlan.ko
cp ${OUT_DIR}/kernel/out/drivers/misc/sim_detect.ko ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/sim_detect.ko

mkdir -p ${OUT_DIR}/upload
rm -rf ${OUT_DIR}/upload/*
zip -r ${OUT_DIR}/upload/PureKernel-XZ1-Dual-EAS-${LOCAL_VERSION}-${COMPILE_DATE}.zip *
