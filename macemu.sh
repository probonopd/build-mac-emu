#!/bin/sh -e -x

cat /etc/os-release # Debian GNU/Linux 12 (bookworm)
cat /etc/rpi-issue # Raspberry Pi reference 2024-11-19

sudo apt-get -y update
sudo apt-get -y install git unzip libgmp-dev libmpfr-dev libsdl2-dev autoconf checkinstall

git clone https://github.com/kanjitalk755/macemu.git
cd macemu
git checkout 6ddff7b

cd BasiliskII/src/Unix
./autogen.sh --prefix=/usr
make -j$(nproc)
# sudo make install
sudo checkinstall --pkgname=basiliskii-custom --pkgversion=$(date +%Y%m%d) --backup=no --install=no --default
cd -

cd SheepShaver/src/Unix
./autogen.sh --prefix=/usr
make -j$(nproc)
# sudo make install
sudo checkinstall --pkgname=sheepshaver-custom --pkgversion=$(date +%Y%m%d) --backup=no --install=no --default
cd -
