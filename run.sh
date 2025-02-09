#!/bin/sh

# sh -ex qemu.sh
sh -ex macemu.sh

# Only continue if we are runnning on real hardware
mount | grep "on /boot/firmware" || exit 0

echo " quiet fastboot" | sudo tee -a /boot/firmware/cmdline.txt

sudo apt-get -y install mdnsd

# NOTE: Disabling NetworkManager BRICKS sshd; how sad is that!
# Why can't we have a working network without Red Hat anymore?
# Worst, it draws in dbus...

for SERVICE in avahi-daemon bluetooth cron polkit systemd-journald systemd-timesyncd ModemManager
do
    sudo systemctl stop $SERVICE
    sudo systemctl disable $SERVICE
    # sudo systemctl mask $SERVICE
done

# See running services with
# systemctl list-units --type=service --state=running --no-pager --no-legend | awk '{printf "%s ", $1}'

################################################################################
# Start script as a static binary
################################################################################

sudo apt-get -y install golang
go build initmac.go
sudo mv initmac /sbin/initmac

sudo tee /etc/systemd/system/initmac.service <<\EOF
[Unit]
Description=Run initmac as early as possible
DefaultDependencies=no
Before=sysinit.target
After=local-fs.target
Wants=local-fs.target

[Service]
ExecStart=-/sbin/initmac
Type=simple
NoBlocking=true
ExecStopPost=/bin/systemctl poweroff

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable initmac.service
sudo systemctl start initmac.service

sudo systemctl disable getty@tty1
sudo systemctl stop getty@tty1

################################################################################
# Silence blinking cursor
################################################################################

sudo tee /etc/initramfs-tools/scripts/init-top/disable-cursor <<\EOF
#!/bin/sh
# Disable cursor in early initramfs

PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

# Hide cursor
/bin/echo -e "\e[?25l"
EOF

sudo chmod +x /etc/initramfs-tools/scripts/init-top/disable-cursor
sudo sed -i -e 's|^modules=|modules=most|g' /etc/initramfs-tools/initramfs.conf
sudo update-initramfs -u

################################################################################
# Virtual modem for vt100 terminal
# This can be accessed using a terminal program on the Modem port as vt100
################################################################################

sudo apt-get -y install socat

sudo tee /etc/systemd/system/socat-vmodem.service <<\EOF
[Unit]
Description=Socat Virtual Modem

[Service]
ExecStart=/usr/bin/socat PTY,echo=0,link=/tmp/vmodem exec:bash,pty,stderr,setsid
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable socat-vmodem.service
sudo systemctl start socat-vmodem.service

# wget https://download.macintoshgarden.org/apps/stuffit_expander_5.5.img
# wget https://macintoshgarden.org/sites/macintoshgarden.org/files/apps/Black_Night_CQII.sit
