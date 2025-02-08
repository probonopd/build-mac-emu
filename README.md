# build-mac-emu

Build Mac emulators on Raspberry Pi OS

## Build on GitHub Actions

Currently broken, any help appreciated

## Build on real hardware

1. Download [2024-11-19-raspios-bookworm-armhf-lite.img.xz](http://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf-lite.img.xz)
2. Write it to a microSD card using the Raspberry Pi Imager. Apply custom settings for username and password so that you can log in over ssh
3. Create a file `ssh` on the microSD card so you can log in over ssh
4.  ```
    sudo apt-get update
    sudo apt-get -y install git
    git clone https://github.com/probonopd/build-mac-emu
    cd build-mac-emu
    sh -ex run.sh```
