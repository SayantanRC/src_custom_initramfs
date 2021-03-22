## Setup directories
Clone this repository in your home directory and move to [Gathering binaries](#gathering-binaries). Or follow the below steps to manually setup the directory structure.  
To manually create the directories: Use the below commands.  
```
mkdir ~/src_custom_initramfs
mkdir -p ~/src_custom_initramfs/{dev,etc,mnt/root,proc,root,sbin,secure,sys,tmp,usr/bin,usr/lib,usr/lib64}
```
Create the following symlinks.  
```
cd ~/src_custom_initramfs
ln -s usr/bin .
ln -s usr/lib .
ln -s usr/lib64 .
```

## Gathering binaries
The following binaries are recommended to be added. You may add more (or less) depending on your needs.  
`bash, mkdir, ls, tail, grep, cut, awk, mount, umount, insmod, lsmod, modprobe, switch_root`  
To find the location of the binary, in terminal, type `type <binary-name>` or `which <binary-name>`. Example: `which modprobe` gives output `/usr/bin/modprobe`  
We need to copy each of them in the respective directories. In the above example of modprobe, the command would be `cp -p /usr/bin/modprobe usr/bin/modprobe`.  
### AUTOMATION!
```
cd ~/src_custom_initramfs

while read -r bin_path
do
  init_bin_path=${bin_path:1}
  cp -pv $bin_path $init_bin_path
done < <(which {bash,mkdir,ls,tail,grep,cut,awk,mount,umount,insmod,modprobe,lsmod,switch_root})
```

## Gathering library dependencies
Each of the above binaries have one or several library dependencies. Example:  
`ldd /usr/bin/modprobe` gives output:  

>	linux-vdso.so.1 (0x00007ffee9f24000)  
>	libzstd.so.1 => /usr/lib/libzstd.so.1 (0x00007f947c7d4000)  
>	liblzma.so.5 => /usr/lib/liblzma.so.5 (0x00007f947c7ac000)  
>	libz.so.1 => /usr/lib/libz.so.1 (0x00007f947c792000)  
>	libcrypto.so.1.1 => /usr/lib/libcrypto.so.1.1 (0x00007f947c4b4000)  
>	libc.so.6 => /usr/lib/libc.so.6 (0x00007f947c2e7000)  
>	libpthread.so.0 => /usr/lib/libpthread.so.0 (0x00007f947c2c6000)  
>	libdl.so.2 => /usr/lib/libdl.so.2 (0x00007f947c2bd000)  
>	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x00007f947c8f7000)  

All these dependencies are to be added individually for all the binaries. Example
`cp -p /usr/lib/libzstd.so.1 usr/lib/libzstd.so.1` and so on.  
<b>IMPORTANT:</b> The first library `linux-vdso.so.1` is provided by the kernel and is not needed to be copied.
### AUTOMATION!
```
cd ~/src_custom_initramfs

while read -r bin_path
do
  while read -r dependency
  do
    lib_path=$(echo $dependency | cut -d ' ' -f3)
    init_lib_path=${lib_path:1}
    cp -npv $lib_path $init_lib_path
    # -n flag: no-clobber - do NOT overwrite an existing file
  done < <(ldd $bin_path | tail -n +2)
done < <(which {bash,mkdir,ls,tail,grep,cut,awk,mount,umount,insmod,modprobe,lsmod,switch_root})
```

## Check if `chroot` works
At this point you should be able to chroot into you initramfs directory.
```
cd ~/src_custom_initramfs

sudo chroot . usr/bin/bash
```

## Gathering modprobe modules
We will add the following modprobe modules along with their dependencies.  
`ext4, ntfs, loop`
Module files and their dependencies can be seen via the command `modprobe --show-depends <module-name>`. For example, `modprobe --show-depends ext4` gives result:
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/fs/jbd2/jbd2.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/fs/mbcache.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/lib/crc16.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/arch/x86/crypto/crc32c-intel.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/crypto/crc32c_generic.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/fs/ext4/ext4.ko.xz  

