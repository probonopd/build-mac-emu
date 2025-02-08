#!/bin/sh

# sh -ex qemu.sh
sh -ex macemu.sh

# Only contonue if we are runnning on real hardware
mount | grep "on /boot/firmware" || exit 0

cd ~
wget "https://github.com/adamhope/rpi-basilisk2-sdl2-nox/raw/refs/heads/main/Quadra800.ROM" -O ROM
wget "https://github.com/mihaip/infinite-mac/raw/refs/heads/main/Images/Mac%20OS%207.6%20HD.dsk" -O system.img
echo "disk system.img" > ~/.config/BasiliskII/prefs
echo "frameskip 0" >> ~/.config/BasiliskII/prefs
app/usr/bin/BasiliskII
