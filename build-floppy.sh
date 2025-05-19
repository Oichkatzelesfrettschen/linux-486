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

size=${1:-1440}

if [ "$size" = "720" ]; then
    lilo_conf=/boot/lilo_720.conf
else
    lilo_conf=/boot/lilo.conf
fi

dd if=/dev/zero of=floppy.img bs=1k count=$size
mkfs.ext2 -b 1024 -i 65536 -I 128 -m 0 -r 0 -T floppy -d floppy floppy.img

sudo mount floppy.img /mnt -oloop
sudo mkdir /mnt/dev
sudo mount devtmpfs /mnt/dev -t devtmpfs

sudo chown -R root:root /mnt/*
sudo lilo -v -g -b /dev/loop0 -r /mnt -C "$lilo_conf"

sudo umount /mnt/dev
sudo rmdir /mnt/dev
df -h /mnt
sudo umount /mnt

