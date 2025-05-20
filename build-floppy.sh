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
# The -T floppy option tunes parameters for small image
SIZE="${1:-1440}"
if [[ "$SIZE" != "1440" && "$SIZE" != "720" ]]; then
    echo "Usage: $0 [720|1440]" >&2
    exit 1
fi

if [[ "$SIZE" == "720" ]]; then
    COUNT=720
    LILO_CONF="floppy/boot/lilo.conf.720k"
else
    COUNT=1440
    LILO_CONF="floppy/boot/lilo.conf"
fi

dd if=/dev/zero of=floppy.img bs=1k count=$COUNT

mkfs.ext2 -b 1024 -i 65536 -I 128 -m 0 -r 0 -T floppy -d floppy floppy.img

sudo mount floppy.img /mnt -oloop
sudo mkdir /mnt/dev
sudo mount devtmpfs /mnt/dev -t devtmpfs

sudo cp "$LILO_CONF" /mnt/boot/lilo.conf
sudo chown -R root:root /mnt/*
sudo lilo -v -g -b /dev/loop0 -r /mnt -C "$lilo_conf"

sudo umount /mnt/dev
sudo rmdir /mnt/dev
df -h /mnt
sudo umount /mnt

