#!/bin/bash
set -euo pipefail

if [ ! -e ./linux-5.17.2.tar.xz ] ; then
    echo "Fetching Linux..."
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.17.2.tar.xz
fi

if [ ! -e ./linux-5.17.2 ] ; then
    echo "Extracting Linux..."
    tar xf ./linux-5.17.2.tar.xz
    cp config-5.17.2tiny ./linux-5.17.2/.config
    
    cd ./linux-5.17.2
    
    echo "Patching Linux..."
    patch usr/gen_initramfs.sh < ../linux/patches/gen_initramfs.sh.patch
    # TODO: Other patches necessary? They do save some space...

    ARCH=x86 CROSS_COMPILE=i486-buildroot-linux-uclibc- make olddefconfig
else
    cd ./linux-5.17.2
fi

echo "Creating initramfs file structure..."
sudo rm -rf initrd
mkdir -p initrd/{bin,dev/pts,etc/init.d,lib/modules,mnt,proc,root,run,sys}
cp ../linux/{fstab,group,inittab,passwd} initrd/etc

make -C ../preinit
cp ../preinit/init initrd/init

echo "Calling sudo to create initramfs's /dev/console..."
sudo mknod initrd/dev/console c 5 1

echo "Building Linux..."
ARCH=x86 CROSS_COMPILE=i486-buildroot-linux-uclibc- make -j8

echo "Calling sudo to copy bzImage to the floppy folder..."
bzImage_path=arch/x86/boot/bzImage
size_bytes=$(stat -c%s "$bzImage_path")
echo "Kernel size: $size_bytes bytes"
if [ "$size_bytes" -gt 737280 ]; then
    echo "Warning: bzImage exceeds 720KB. Consider enabling LZMA compression and trimming built-ins."
fi
sudo cp "$bzImage_path" ../floppy/boot/bzImage

