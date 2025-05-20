#!/bin/bash
set -euo pipefail

# Usage: ./build-floppy.sh [SIZE]
# SIZE is the image size in kilobytes (defaults to 1440). The size can also be
# specified with the FLOPPY_SIZE environment variable. Example:
#   FLOPPY_SIZE=720 ./build-floppy.sh

SIZE=${FLOPPY_SIZE:-${1:-1440}}

cleanup() {
    if mountpoint -q /mnt/dev; then
        sudo umount /mnt/dev
        sudo rmdir /mnt/dev
    fi
    if mountpoint -q /mnt; then
        sudo umount /mnt
    fi
}
trap cleanup EXIT

# Create the floppy image. 1440 creates a 1.44MB image while 720 creates a
# 720KB image.

dd if=/dev/zero of=floppy.img bs=1k count="$SIZE"
# The -T floppy option tunes parameters for small images
mkfs.ext2 -b 1024 -i 65536 -I 128 -m 0 -r 0 -T floppy -d floppy floppy.img

sudo mount floppy.img /mnt -oloop
sudo mkdir /mnt/dev
sudo mount devtmpfs /mnt/dev -t devtmpfs

sudo chown -R root:root /mnt/*
sudo lilo -v -g -b /dev/loop0 -r /mnt -C /boot/lilo.conf

sudo umount /mnt/dev
sudo rmdir /mnt/dev
df -h /mnt
sudo umount /mnt

