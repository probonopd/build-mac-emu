#!/bin/sh -e -x

cat /etc/os-release # Debian GNU/Linux 12 (bookworm)
cat /etc/rpi-issue # Raspberry Pi reference 2024-11-19

sudo apt-get -y update
sudo apt-get -y install git unzip libsdl2-dev cmake patchelf

git clone https://github.com/mihaip/previous
cd previous
git checkout d5b8125
mkdir -p build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make -j$(nproc)
sudo make install
sudo make DESTDIR=app install # sudo needed here, why?
mkdir -p app/usr/lib
ldd app/usr/bin/*  | grep "=>" | cut -d " " -f 3 | xargs -I {} cp {} app/usr/lib/
find app/usr/bin/ -type f -exec patchelf --add-rpath '$ORIGIN/../lib' {} \;
( cd app/ ; zip -r ../previous.zip * )
mount | grep "on /boot/firmware" && sudo cp *.zip /boot/firmware/
cd -

# FIXME: Disable X11 and Wayland, how?

# wget https://winworldpc.com/download/45e2809d-53c2-b753-3e11-c3a4c2a90f70/from/c39ac2af-c381-c2bf-1b25-11c3a4e284a2
# sudo apt install 7zip
# 7zr x c39ac2af-c381-c2bf-1b25-11c3a4e284a2
# previous ./Nextstep\ 1.0\ HD\ Image\ With\ Previous/NS10_1GB.dd
# Only a black screen with a cursor, why?
# How to specify ROM and disk?
