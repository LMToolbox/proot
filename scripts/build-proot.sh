git clone https://github.com/proot-me/proot
cd proot

make -C src loader.elf build.h
make -C src proot care

mkdir -p dist
mv src/proot dist/proot-$ARCH
mv src/loader.elf dist/loader-$ARCH.elf
mv src/care dist/care-$ARCH
