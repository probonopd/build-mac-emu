# build-mac-emu

Build Mac emulators on Raspberry Pi OS

## Build on GitHub Actions

Currently broken, any help appreciated

## Build on real hardware

It is recommended to use a Raspberry Pi 5 or Raspberry Pi 500 to speed up the build process significantly. The built software should then also run on other 64-bit Raspberry Pi models.

1. Download [2024-11-19-raspios-bookworm-armhf-lite.img.xz](http://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf-lite.img.xz)
2. Write it to a microSD card using the Raspberry Pi Imager. Apply custom settings for username and password so that you can log in over ssh
3. Create a file `ssh` on the microSD card so you can log in over ssh
4. Log into the Raspberry Pi over ssh so that you can copy and paste the following
5.  ```
    sudo apt-get update
    sudo apt-get -y install git
    git clone https://github.com/probonopd/build-mac-emu
    cd build-mac-emu
    sh -ex run.sh
    ```
