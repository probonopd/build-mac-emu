#!/bin/sh

sh -ex qemu.sh
sh -ex macemu.sh

# Only continue if we are runnning on real hardware
mount | grep "on /boot/firmware" || exit 0

sudo apt-get -y install golang
go build initmac.go
sudo mv initmac /sbin/initmac

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<\EOF
[Service]
ExecStart=
ExecStart=-/path/to/initmac
Type=idle
EOF

sudo systemctl daemon-reload
sudo systemctl restart getty@tty1
