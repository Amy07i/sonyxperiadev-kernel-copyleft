#!/bin/bash
export KBUILD_BUILD_USER=mianyuan
export KBUILD_BUILD_HOST=travis
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"

OUT_DIR=${HOME}
COMPILE_DATE=$(date +"%Y%m%d")

# clone gcc and Anykernl3
git clone --branch pie-release https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 ${OUT_DIR}/gcc --depth=1
git clone https://github.com/Amy07i/AnyKernel3 ${OUT_DIR}/AnyKernel3

# Compile
export PATH="${OUT_DIR}/gcc/bin:$PATH"
cd ${OUT_DIR}/kernel
make O=./out clean
make O=./out mrproper
export KBUILD_DIFFCONFIG=poplar_dsds_diffconfig
make O=out ARCH=arm64 msmcortex-perf_defconfig
make -j${KJOBS} O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-android-
if [ $? -ne 0 ]; then
		echo "build failed"
			exit 1
fi

# package
cd ${OUT_DIR}/AnyKernel3 
git reset --hard 9d8b7b3c932cd428e2209e6e28b819207cb7d1f5
cp ${OUT_DIR}/kernel/out/arch/arm64/boot/Image.gz-dtb ${OUT_DIR}/AnyKernel3
rm -rf ${OUT_DIR}/AnyKernel3/README.md LICENSE
mkdir -p ${OUT_DIR}/upload
rm -rf ${OUT_DIR}/upload/*
zip -r ${OUT_DIR}/upload/StockKernel-XZ1-Dual-UV-${COMPILE_DATE}.zip *
