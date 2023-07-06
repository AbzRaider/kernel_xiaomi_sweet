#!/bin/bash
#
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="AbzRaider-KERNEL-SWEET-$(date '+%Y%m%d-%H%M').zip"
DEFCONFIG="sweet_user_defconfig"

export PATH="${PWD}/clang/bin:${PATH}:${PWD}/clang/bin:${PATH}:${PWD}/clang/bin:${PATH}"
if ! [ -d "clang" ]; then
	echo "clang-proton not found! Cloning to clang..."
	if ! git clone --depth=1 https://gitlab.com/LeCmnGend/proton-clang.git clang; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee error.log - Image.gz dtbo.img

kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/qcom/xiaomi-sdmmagpie.dtb"
dtbo="out/arch/arm64/boot/sweet-sdmmagpie-overlay.dtbo"

 git clone https://github.com/AbzRaider/AnyKernel33.git -b sweet AnyKernel		
	
	cp $kernel $dtbo AnyKernel
	cp $dtb AnyKernel/dtb
	rm -f *zip
	cd AnyKernel || exit
	rm -rf out/arch/arm64/boot
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	rm -rf AnyKernel
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	curl --upload-file "$ZIPNAME" https://free.keep.sh
	echo
else
	echo -e "\nCompilation failed!"
fi
