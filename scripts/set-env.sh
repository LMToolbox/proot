export TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64
export TARGET=$ARCH-linux-android
export API=24

mkdir -p ${PWD}/install
export PREFIX=$(realpath ${PWD}/install)

export AR=$TOOLCHAIN/bin/llvm-ar
export CC="$TOOLCHAIN/bin/clang --target=$TARGET$API"
export AS=$CC
export CXX="$TOOLCHAIN/bin/clang++ --target=$TARGET$API"
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
