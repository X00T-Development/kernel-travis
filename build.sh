#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 -b HMP-fix $repo kernel
cd kernel
git clone --depth=1 -b 10.0.1 https://github.com/sujitroy/clang.git clang
git clone --depth=1 https://github.com/sujitroy/GCC-4.9.git -b arm64 stock
git clone --depth=1 https://github.com/sujitroy/GCC-4.9.git -b arm stock_32
git clone --depth=1 https://github.com/X00T-Development/AnyKernel3 -b master AnyKernel
echo "Done"
GCC="$(pwd)/aarch64-linux-android-"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/X00T_defconfig
PATH="${PWD}/clang/bin:${PWD}/stock/bin:${PWD}/stock_32/bin:${PATH}"
export ARCH=arm64
export KBUILD_BUILD_HOST=$myKernel
export KBUILD_BUILD_USER=Developer
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• kernel •</b>%0ABuild started on <code>travis CI/CD</code>%0AFor device <b>Asus Zenfone Max Pro M1 (X00T)</b>%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b> #Test"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Asus Zenfone Max Pro M1 (X00T)</b> | <b>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
   make O=out ARCH=arm64 X00T_defconfig
       make -j$(nproc --all) O=out \
                             ARCH=arm64 \
			     CROSS_COMPILE=aarch64-linux-android- \
			     CROSS_COMPILE_ARM32=arm-linux-androideabi-
   cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 ${myKernel}-${TANGGAL}.zip *
    cd .. 
}
# Main
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
