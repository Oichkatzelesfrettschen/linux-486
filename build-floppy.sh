#!/bin/bash
set -euo pipefail

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

dd if=/dev/zero of=floppy.img bs=1k count=1440
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

