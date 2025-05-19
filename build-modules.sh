#!/bin/bash
set -euo pipefail

cleanup() {
    if mountpoint -q /mnt; then
        sudo umount /mnt
    fi
}
trap cleanup EXIT

echo "Building ./modules/ floppy folder..."

rm -rf ./modules
kernel_version=$(make -s -C linux-5.17.2 kernelrelease)
INSTALL_MOD_PATH=$(pwd)/modules make -C linux-5.17.2 modules_install
mv "modules/lib/modules/${kernel_version}" modules/
rmdir modules/lib/modules modules/lib
rm modules/${kernel_version}/{source,build}
find modules/ -type f -name "*.ko" -exec strip --strip-debug {} \;
du -sh ./modules

echo "Creating modules.img..."

# Optional first argument sets the image size in 1K blocks (default 1440)
SIZE="${1:-1440}"

# Usage helper
if [[ "$SIZE" == "-h" || "$SIZE" == "--help" ]]; then
    echo "Usage: $0 [size_in_kb]"
    echo "Creates modules.img using the specified size (default 1440 KB)."
    exit 0
fi

# Basic sanity check
if ! [[ "$SIZE" =~ ^[0-9]+$ && "$SIZE" -gt 0 ]]; then
    echo "Error: size must be a positive integer" >&2
    exit 1
fi

# Warn if modules will not fit into the requested image
MODULES_SIZE=$(du -sk modules | cut -f1)
if [ "$MODULES_SIZE" -gt "$SIZE" ]; then
    echo "Warning: modules folder (${MODULES_SIZE} KB) exceeds image size ${SIZE} KB" >&2
fi

dd if=/dev/zero of=modules.img bs=1k count="${SIZE}"

mkfs.vfat -F 12 modules.img
sudo mount -oloop modules.img /mnt
sudo cp -R modules/* /mnt/
sudo chown root:root /mnt/*
df -h /mnt
sudo umount /mnt

