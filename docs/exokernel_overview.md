# Minimizing Linux into an Exokernel Approach

This document summarizes how the existing `linux-486` build could be stripped down to a minimal exokernel-style core. It also reviews the current patches and highlights which portions of the kernel might be shifted entirely to user space.

## 1. Candidate Subsystems for User Space

The tiny kernel configuration (`config-5.17.2tiny`) already disables networking and many device classes. Lines 623--634 show that networking and PCI support are compiled out, leaving only basic driver hooks and devtmpfs for device node creation:
```
623  # CONFIG_NET is not set
630  CONFIG_HAVE_PCI=y
631  # CONFIG_PCI is not set
638  CONFIG_DEVTMPFS=y
639  CONFIG_DEVTMPFS_MOUNT=y
```
Moving additional functionality to user space can focus on:
- **Input**: Basic input support is enabled (lines 788--803). Only mouse/joystick event interfaces are modules, so input handling could be delegated to a user-level daemon.
- **Filesystem modules**: Only ext2 is compiled in (line 1230). Filesystems such as FAT, ISO9660, or others can be provided as FUSE modules in user space.
- **Block/Char drivers**: With devtmpfs enabled (lines 638--640) device nodes can be populated by a minimal early user process instead of compiled-in drivers.
- **System services**: Serial console and early printk remain built in (lines 861--868), but higher-level TTY management (getty, login) can live entirely in user space using Busybox utilities.

## 2. Review of Kernel Patches

Several patches under `linux/patches/` remove complex startup logic to save memory:
- `init.c.patch` comments out the trampoline page table setup and TLB flush used during real-mode transition. The patched lines replace the original code with comments, effectively stripping this path:
```
-       write_cr3(real_mode_header->trampoline_pgd);
-       __flush_tlb_all();
+//     write_cr3(real_mode_header->trampoline_pgd);
+//     __flush_tlb_all();
```
- `rmpiggy.S.patch` removes the embedded real-mode binary (`realmode.bin`) from the kernel image:
```
-       .incbin "arch/x86/realmode/rm/realmode.bin"
+//     .incbin "arch/x86/realmode/rm/realmode.bin"
```
- `initramfs.c.patch` introduces a helper (`do_unpack_to_rootfs`) allowing decompression into an allocated buffer. This reduces stack usage when unpacking the initramfs:
```
-static char * __init unpack_to_rootfs(char *buf, unsigned long len)
+static char * __init do_unpack_to_rootfs(char *buf, unsigned long len, char *output)
```
- `bugs.c.patch` places most Spectre/MDS mitigation routines behind `CONFIG_M486` guards, meaning they are omitted in this tiny build. This substantially cuts code paths executed during boot.

Overall these patches remove memory-intensive startup steps and unnecessary mitigations for a minimal 486 environment.

## 3. Responsibilities Remaining in the Kernel

A Linux-based exokernel would retain only primitives necessary for isolation and hardware multiplexing:
- **Process management and scheduling**
- **Memory management** (paging, basic MMU setup)
- **A simple block I/O layer** for the root filesystem and module loading
- **Interrupt/exception handling** and a minimal set of device drivers (console, floppy, perhaps IDE/SCSI if required)

All higher-level services—network stacks, complex filesystems, device enumeration, and user interaction—can run as user programs. Busybox can supply init, shell, and common utilities. Device drivers could be implemented as user-level servers using `/dev` nodes created by devtmpfs.

User processes would interact with the kernel using standard syscalls. Busybox-based init scripts (e.g., `linux/rcS`) would mount the root filesystem, start udev or a custom device manager, and launch user-space drivers.

## 4. Space-Efficient Libraries and Microkernel Techniques

The build already uses `uClibc` for a small C library, but alternatives such as **musl** offer smaller static binaries and may simplify maintenance. Using Busybox for core utilities keeps the userland compact.

Microkernel ideas can be applied by running drivers as separate processes and using message passing or ioctl-based communication with the kernel. Projects like **LKL** (Linux Kernel Library) demonstrate compiling portions of the kernel into user space while preserving the Linux API. Another option is leveraging **FUSE** for filesystems so that only a minimal VFS layer remains in kernel space.

## 5. Interaction with Busybox

Busybox acts as the initial user space and provides `init`, a shell, and essential commands. It would mount devtmpfs (automatically populated by the kernel) and start any user-level driver daemons. Because the kernel omits networking and most filesystems, Busybox-based tooling focuses on process management and file maintenance in a RAM-backed environment.

## Conclusion

By trimming kernel features to the bare essentials and offloading drivers and services to user space, the `linux-486` environment can approach an exokernel design while keeping Linux API compatibility through Busybox and uClibc (or musl). The provided patches already demonstrate removing memory-heavy startup paths and mitigations, further suggesting how the kernel can be simplified for legacy hardware.

