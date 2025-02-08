#!/bin/sh -e -x

cat /etc/os-release # Debian GNU/Linux 12 (bookworm)
cat /etc/rpi-issue # Raspberry Pi reference 2024-11-19

sudo apt-get -y update
sudo apt-get -y install git checkinstall libsdl2-dev flex bison libepoxy-dev ninja-build 
wget "https://github.com/qemu/qemu/archive/refs/tags/v9.2.0.tar.gz"
tar xf v9.2.0.tar.gz
cd qemu-9.2.0/

mkdir -p build
cd build
../configure --prefix=/usr --target-list=m68k-softmmu,ppc-softmmu --enable-sdl --enable-alsa --enable-alsa --disable-oss --enable-opengl --enable-slirp # --static
make -j$(nproc)
make DESTDIR=app install
mkdir -p app/usr/lib
ldd app/usr/bin/*  | grep "=>" | cut -d " " -f 3 | xargs -I {} cp {} app/usr/lib/
find app/usr/bin/ -type f -exec patchelf --add-rpath '$ORIGIN/../lib' {} \;
( cd app/ ; zip -r ../qemu.zip * )
mount | grep "on /boot/firmware" && sudo cp *.zip /boot/firmware/

cd ../../
