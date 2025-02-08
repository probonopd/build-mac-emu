#!/bin/sh -e -x

# apt-get wants to download
# http://raspbian.raspberrypi.com/raspbian/pool/main/g/git/git-man2.39.5-0%2bdeb12u1_all.deb
# but this results in 404 while
# http://raspbian.raspberrypi.com/raspbian/pool/main/g/git/git-man2.39.5-0+deb12u2_all.deb
# works. How can I make apt-get download from the latter rather than from the former?

mkdir -p /opt/deb
cd /opt/deb
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/g/git/git-man2.39.5-0+deb12u2_all.deb"
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/g/git/git_2.39.5-0+deb12u2_armhf.deb"
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/u/util-linux/uuid-dev_2.38.1-5+deb12u3_armhf.deb"
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/u/util-linux/libblkid-dev_2.38.1-5+deb12u3_armhf.deb"
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/g/glib2.0/libglib2.0-bin_2.74.6-2+deb12u5_armhf.deb"
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/g/glib2.0/libglib2.0-dev-bin_2.74.6-2+deb12u5_armhf.deb"
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/u/util-linux/libmount-dev_2.38.1-5+deb12u3_armhf.deb"
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/g/glib2.0/libglib2.0-dev_2.74.6-2+deb12u5_armhf.deb"
wget -q "http://raspbian.raspberrypi.com/raspbian/pool/main/s/systemd/libudev-dev_252.33-1~deb12u1+rpi1_armhf.deb"
dpkg-scanpackages . /dev/null | gzip -9 > Packages.gz
echo "deb [trusted=yes] file:///opt/deb ./" | sudo tee /etc/apt/sources.list.d/local.list
sudo tee /etc/apt/preferences.d/local.pref <<EOF
Package: *
Pin: origin ""
Pin-Priority: 1001
EOF
