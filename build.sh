#!/bin/bash
export KBUILD_BUILD_USER=mianyuan
export KBUILD_BUILD_HOST=travis
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"

OUT_DIR=${HOME}
COMPILE_DATE=$(date +"%Y%m%d")

# clone Clang and Anykernl3
git clone https://github.com/kdrag0n/proton-clang.git ${OUT_DIR}/clang --depth=1
git clone https://github.com/Amy07i/AnyKernel3 ${OUT_DIR}/AnyKernel3 --depth=1

# Compile
export PATH="${OUT_DIR}/clang/bin:${OUT_DIR}/clang/aarch64-linux-gnu/bin/:${OUT_DIR}/clang/arm-linux-gnueabi/bin:$PATH"
cd ${OUT_DIR}/kernel
make O=./out clean
make O=./out mrproper
export KBUILD_DIFFCONFIG=poplar_dsds_diffconfig
make O=out ARCH=arm64 msmcortex-perf_defconfig
make -j${KJOBS} O=out ARCH=arm64 CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-

# package
cp ${OUT_DIR}/kernel/out/arch/arm64/boot/Image.gz-dtb ${OUT_DIR}/AnyKernel3
mkdir -p ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/
cp ${OUT_DIR}/kernel/out/drivers/staging/qcacld-3.0/wlan.ko ${OUT_DIR}/AnyKernel3/modules/vendor/lib/modules/qca_cld3_wlan.ko
cd ${OUT_DIR}/AnyKernel3
mkdir -p ${OUT_DIR}/upload
rm -rf ${OUT_DIR}/upload/*
zip -r ${OUT_DIR}/upload/PureKernel-XZ1-Dual-${COMPILE_DATE}.zip *
