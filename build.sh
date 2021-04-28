#!/bin/bash
export KBUILD_BUILD_USER=mianyuan
export KBUILD_BUILD_HOST=travis
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"

OUT_DIR=${HOME}
COMPILE_DATE=$(date +"%Y%m%d")
CLANG_URL="https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-7284624.git"
GCC_URL="https://github.com/arter97/arm64-gcc.git"
GCC32_URL="https://github.com/arter97/arm32-gcc.git"
DEFCONFIG=poplar_dsds_diffconfig

# clone Clang and Anykernl3
git clone ${CLANG_URL} ${OUT_DIR}/clang --depth=1
git clone ${GCC_URL} ${OUT_DIR}/gcc --depth=1
git clone ${GCC32_URL} ${OUT_DIR}/gcc32 --depth=1
git clone https://github.com/Amy07i/AnyKernel3 ${OUT_DIR}/AnyKernel3 --depth=1

# Compile
export PATH="${OUT_DIR}/clang/bin:${OUT_DIR}/gcc/bin/:${OUT_DIR}/gcc32/bin:$PATH"
cd ${OUT_DIR}/kernel
make O=./out clean
make O=./out mrproper
export KBUILD_DIFFCONFIG=${DEFCONFIG}
make O=out ARCH=arm64 msmcortex-perf_defconfig
make -j${KJOBS} O=out ARCH=arm64 CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-elf- CROSS_COMPILE_ARM32=arm-eabi-

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
zip -r ${OUT_DIR}/upload/PureKernel-XZ1-Dual-EAS-${COMPILE_DATE}.zip *
