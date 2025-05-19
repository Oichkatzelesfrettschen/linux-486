# linux-486

This repo provides the files necessary to build a modern Linux-based "operating system" for old i486 systems with at least 8MB of RAM. Build scripts for all components of the system are provided. An i486-linux toolchain is also built, enabling you to compile other programs for use with the system.

The generated boot floppy disk provides you with a Busybox system that is kept entirely in memory. uClibc's shared library files are also loaded into memory, allowing other programs to save on memory (as opposed to using static binaries).

A second floppy containing additional kernel modules can also be generated. Both floppies are ext2 formatted.

## Build requirements

* building tools (make, gcc, linux kernel's requirements, etc.)
* bash
* wget
* tar, xz, bzip2
* Around **6GB** of available disk space

## Build steps

Run the build scripts in this order:

1. `build-toolchain.sh` (after this script, add ~/i486-linux/bin to your PATH)
2. `build-linux.sh`
3. `build-busybox.sh`
4. `build-floppy.sh`
5. `build-modules.sh`

On my machine (Ryzen 1700x, 16GB RAM), building the toolchain takes around ten minutes; building Linux takes around a minute, and the remaining steps take less than a minute each.

After successful execution of all scripts, you should have `floppy.img` (boot image) and `modules.img` (modules). By default these are sized for a 1.44M disk. Pass `720` as the first argument to `build-floppy.sh` and `build-modules.sh` to create 720K images instead.

## Booting the system

The system requires an i486 or better processor, a 3.5" floppy drive, and at least 8MB of RAM (8320K for QEMU).

Notes:

* Current Linux is v5.17.2. Older Linux (v2.x) uses less RAM for the kernel, and may be added later as a build option. Newer Linux (v6.x) appears to require well over 8MB of RAM to boot, so targeting newer kernels will be unlikely.
* Once the system is booted, the boot floppy can be removed.
* root's password is `toor`.
* Mount the modules floppy to `/lib/modules`; then, use `modprobe` for loading and unloading.

### Kernel compression

This build now uses **LZO** compression for the kernel image. LZO decompresses much faster than the previous LZMA setting but produces a `bzImage` around **1.1&nbsp;MB** with the supplied configuration. This easily fits on a 1.44M floppy but is too large for a 720K disk. For 720K targets, enable LZMA compression (`CONFIG_KERNEL_LZMA=y`) and disable unnecessary built‑ins so the final image stays under 720K.
