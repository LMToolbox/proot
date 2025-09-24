git clone https://github.com/proot-me/proot
cd proot

make -C src loader.elf loader-m32.elf build.h
make -C src proot care

mkdir -p dist
mv src/proot dist/proot-$arch
mv src/loader.elf dist/loader-$arch.elf
mv src/loader-m32.elf dist/loader-m32-$arch.elf
mv src/care dist/care-$arch
