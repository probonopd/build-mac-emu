#!/bin/sh -e -x

cat /etc/os-release # Debian GNU/Linux 12 (bookworm)
cat /etc/rpi-issue # Raspberry Pi reference 2024-11-19

git clone https://github.com/mihaip/minivmac
cd minivmac/
sh -ex build_example.sh

mv minivmac app/usr/bin/
ldd app/usr/bin/*  | grep "=>" | cut -d " " -f 3 | xargs -I {} cp {} app/usr/lib/
find app/usr/bin/ -type f -exec patchelf --add-rpath '$ORIGIN/../lib' {} \;
( cd app/ ; zip -r ../minivmac.zip * )
mount | grep "on /boot/firmware" && sudo cp *.zip /boot/firmware/

# wget -c "https://github.com/archtaurus/RetroPieBIOS/raw/master/BIOS/MacII.ROM"
# wget "https://github.com/mihaip/infinite-mac/raw/refs/heads/main/Images/System%206.0.8%20HD.dsk"
# ./app/usr/bin/minivmac System\ 6.0.8\ HD.dsk
