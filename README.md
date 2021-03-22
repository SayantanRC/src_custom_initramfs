## Setup directories
Clone this repository in the home directory and move to [Gathering binaries](#gathering-binaries). Or follow the below steps to manually setup the directory structure.  
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
The following binaries are recommended to be added. More (or less) binaries may be added as per requirement.  
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
  done < <(ldd $bin_path | tail -n +2)
done < <(which {bash,mkdir,ls,tail,grep,cut,awk,mount,umount,insmod,modprobe,lsmod,switch_root})
```
The -n flag in `cp`: no-clobber - do NOT overwrite an existing file.

## Check if `chroot` works
At this point we should be able to chroot into our initramfs directory.
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
If we want to make an initramfs for this kernel, we can go ahead and copy these files. Syntax will be something like `mkdir -p lib/modules/5.11.6-1-MANJARO/kernel/fs/jbd2; cp -pv lib/modules/5.11.6-1-MANJARO/kernel/fs/jbd2 lib/modules/5.11.6-1-MANJARO/kernel/fs/jbd2` for each of the modules.  
If however, we need to get the modules for a different kernel, we will need to copy from that kernel modules (various cases arise here like copying from an OS on a USB, copying from a backup img file etc).  
### AUTOMATION!
```
cd ~/src_custom_initramfs

module_source_path="/lib/modules/`uname -r`"
init_mod_dir_name="nokernel"

mods=(ext4 ntfs loop)
for mod in ${mods[@]}; do
  while read -r actual_mod_path
  do
    useful_path=$(echo $actual_mod_path | cut -d '/' -f5-)
    init_mod_dir="lib/modules/$init_mod_dir_name/$(echo ${useful_path%/*})"
    init_mod_file=$(echo ${useful_path##*/})
    mkdir -p $init_mod_dir
    cp -pv $module_source_path/$useful_path $init_mod_dir/$init_mod_file
  done < <(modprobe --show-depends $mod | cut -d ' ' -f2)
done
```
The variable `module_source_path` can refer to a custom location, just above the 'kernel' directory. Example, a system can have 2 linux kernels installed, say 5.11 and 5.4. Then the `module_source_path` can be any of the following:
> "/lib/modules/5.4"  
> "/lib/modules/5.11"  
but not something like  
> "/lib/modules"  
> "/lib/modules/5.11/kernel"  
> "/lib/modules/5.4/build"  
> etc.  
> The variable `init_mod_dir_name` can be set as any string like "IceCream", "MyInit" anything; but in the final `init` script, `insmod` will need to refer to the proper file paths. Example, if the value is set as "MojoJojo", in `init` script, insmod will need to be used as: <pre>insmod /lib/modules/<b>MojoJojo</b>/kernel/fs/ext4/ext4.ko</pre>
