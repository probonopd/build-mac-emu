#!/bin/sh -e -x

cat /etc/os-release # Debian GNU/Linux 12 (bookworm)
cat /etc/rpi-issue # Raspberry Pi reference 2024-11-19

sudo apt-get -y update
sudo apt-get -y install git unzip libgmp-dev libmpfr-dev libsdl2-dev autoconf patchelf

git clone https://github.com/kanjitalk755/macemu.git
cd macemu
git checkout 6ddff7b

cd BasiliskII/src/Unix
./autogen.sh --prefix=/usr
make -j$(nproc)
sudo make install
make DESTDIR=app install
mkdir -p app/usr/lib
ldd app/usr/bin/*  | grep "=>" | cut -d " " -f 3 | xargs -I {} cp {} app/usr/lib/
find app/usr/bin/ -type f -exec patchelf --add-rpath '$ORIGIN/../lib' {} \;
( cd app/ ; zip -r ../BasiliskII.zip * )
mount | grep "on /boot/firmware" && sudo cp *.zip /boot/firmware/
cd -

cd SheepShaver/src/Unix
./autogen.sh --prefix=/usr
make -j$(nproc)
sudo make install
make DESTDIR=app install
strip app/usr/bin/*
mkdir -p app/usr/lib
ldd app/usr/bin/*  | grep "=>" | cut -d " " -f 3 | xargs -I {} cp {} app/usr/lib/
find app/usr/bin/ -type f -exec patchelf --add-rpath '$ORIGIN/../lib' {} \;
( cd app/ ; zip -r ../SheepShaver.zip * )
mount | grep "on /boot/firmware" && sudo cp *.zip /boot/firmware/
cd -

# NOTE: If this fails to build, run qemu.sh first. Possibly some dependency from there needs to be installed
