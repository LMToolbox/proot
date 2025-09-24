git clone https://github.com/proot-me/proot
cd proot
git checkout 5f780cba57ce7ce557a389e1572e0d30026fcbca

make -C src loader.elf build.h
make -C src proot care

mkdir -p dist
mv src/proot dist/
mv src/loader.elf dist/
mv src/care dist/
