# Create a custom initramfs
## Setup directories
Clone this repository in the home directory 
```
cd ~
git clone https://github.com/SayantanRC/src_custom_initramfs.git
```
and move to [Gathering binaries](#gathering-binaries). Or follow the below steps to manually setup the directory structure.  
#### To manually create the directories, use the below commands.  
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
`bash, mkdir, ls, cat, tail, grep, cut, awk, ntfs-3g, mount, umount, insmod, lsmod, modprobe, switch_root, blkid, ntfsfix`  
To find the location of the binary, in terminal, type `type <binary-name>` or `which <binary-name>`. Example: `which modprobe` gives output `/usr/bin/modprobe`  
We need to copy each of them in the respective directories. In the above example of modprobe, the command would be `cp -p /usr/bin/modprobe usr/bin/modprobe`.  
### AUTOMATION!
```
cd ~/src_custom_initramfs  
./1.gather_binaries.sh  
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
./2.gather_libraries.sh  
```

## Check if `chroot` works
At this point we should be able to chroot into our initramfs directory.
```
cd ~/src_custom_initramfs

sudo chroot . usr/bin/bash
```

## Gathering modprobe modules
We will add the following modprobe modules along with their dependencies.  
`ext4, fuse, loop, ahci, libahci`  
Module files and their dependencies can be seen via the command `modprobe --show-depends <module-name>`. For example, `modprobe --show-depends ext4` gives result:
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/fs/jbd2/jbd2.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/fs/mbcache.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/lib/crc16.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/arch/x86/crypto/crc32c-intel.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/crypto/crc32c_generic.ko.xz  
> insmod /lib/modules/5.11.6-1-MANJARO/kernel/fs/ext4/ext4.ko.xz  

Note that some modules like `ahci` and `libahci` may be internal modules and not available in the current kernel. These modules are related to disk drives (SATA drives). They are located at:
```
/lib/modules/<kernel_version>/kernel/drivers/ata/libahci.ko
/lib/modules/<kernel_version>/kernel/drivers/ata/ahci.ko
```

If we want to make an initramfs for this kernel, we can go ahead and copy these files. Syntax will be something like `mkdir -p lib/modules/5.11.6-1-MANJARO/kernel/fs/jbd2; cp -pv /lib/modules/5.11.6-1-MANJARO/kernel/fs/jbd2/jbd2.ko.xz lib/modules/5.11.6-1-MANJARO/kernel/fs/jbd2/jbd2.ko.xz` for each of the modules.  
If however, we need to get the modules for a different kernel, we will need to copy from that kernel modules (various cases arise here like copying from an OS on a USB, copying from a backup img file etc).  
### AUTOMATION!

##### Find path for variable `module_source_path`

<b>The path specified by this variable must exist.</b>  
The variable `module_source_path` can refer to a custom location, ending with a kernel release, just one level above the 'kernel' directory. Example, a system can have 2 linux kernels installed, say 5.11 and 5.4. Then the `module_source_path` can be any of the following:
> "/lib/modules/5.4"  
> "/lib/modules/5.11"  

It can also be set to an external source, say we have mounted a live USB, then `module_source_path` can also be set as `/run/media/<user>/arch_root/lib/modules/5.9.6-arch1-1`; where `/run/media/<user>/arch_root` is the mount point.  
The value must end with a kernel-release similar to ouput of `uname -r`. It cannot take values like:  

> "/lib/modules"  
> "/lib/modules/5.11/kernel"  
> "/lib/modules/5.4/build"  

etc.  
```
cd ~/src_custom_initramfs  
./3.gather_mods.sh  
```
Enter the path you found out previously.  

##### Some explanation of the script
This script checks the presence of `.ko` modules and `.ko.xz` modules and copies them accordingly. It also lists the copied modules in a file named `module_list.txt`.  
The variable `init_mod_dir_name` can be set as any string like "IceCream", "MyInit" anything; but in the final `init` script, `insmod` will need to refer to the proper file paths. Example, if the value is set as "MojoJojo", in `init` script, insmod will need to be used as: <pre>insmod /lib/modules/<b>MojoJojo</b>/kernel/fs/ext4/ext4.ko.xz</pre>  
If we are using the `init` file from this repository as a template, along with `module_list.txt` (check the next section), then we do not need to worry about inserting the modules as it will be done for automatically.  

## Create the `module_list.txt` file
If the above [automation](#automation-2) is used, then this file is already created. If not, we need to manually create this file under the initramfs root.  
```
cd ~/src_custom_initramfs
vim module_list.txt
```
Contents of the file will be something like:
> /lib/modules/generic/kernel/fs/jbd2/jbd2.ko.xz  
> /lib/modules/generic/kernel/fs/mbcache.ko.xz  
> /lib/modules/generic/kernel/lib/crc16.ko.xz  
> /lib/modules/generic/kernel/arch/x86/crypto/crc32c-intel.ko.xz  
> /lib/modules/generic/kernel/crypto/crc32c_generic.ko.xz  
> /lib/modules/generic/kernel/fs/ext4/ext4.ko.xz  
> /lib/modules/generic/kernel/fs/fuse/fuse.ko.xz  
> /lib/modules/generic/kernel/drivers/block/loop.ko.xz  


## Finally create the init script
Create a file named as `init` in the root of the initramfs, i.e. at `~/src_custom_initramfs/init`  
How to write an init script can be found in various online resources. A template is given in this repository, feel free to use it.

## Specific use case - booting an img file.
The expected menuentry is (can be set under `/etc/grub.d/40_custom`):
```
menuentry "Arch IMG" {
        img_part=/dev/sda7
        img_path=/arch.img
        search --no-floppy --set=root --file $img_path
        loopback loop $img_path
        linux (loop)/boot/vmlinuz-linux img_part=$img_part img_path=$img_path
        initrd (loop)/boot/my_initramfs.igz
}
```
Here we will use the commandline arguments to set the root as the image because GRUB cannot directly boot from an img file.  
The `init` script will look like this:  
```
#!/usr/bin/bash

mount -t devtmpfs  devtmpfs  /dev
mount -t proc      proc      /proc
mount -t sysfs     sysfs     /sys
mount -t tmpfs     tmpfs     /tmp

# insert modules
while read -r mod_path
do
  insmod $mod_path
done < module_list.txt


# commandline arguments
args=$(cat /proc/cmdline)

# do your thing here, finally mount the boot location to /mnt/root

# first argument value is "(loop)/boot/vmlinuz-linux" we don't need that.
# Our arguments start from second token.
arg_part=$(echo $args | awk '{print $2}')
arg_path=$(echo $args | awk '{print $3}')

img_part=$(echo $arg_part | cut -d '=' -f2)
img_path=$(echo $arg_path | cut -d '=' -f2)

echo ""
echo "Partition: $img_part"
echo "IMG path: $img_path"

echo ""
echo "All devices:"
ls /dev

echo ""
echo "Kernel version:"
uname -a

# check if ntfs partition, if yes, use ntfsfix
part_type="$(blkid $img_part | awk -F 'TYPE' '{print $2}' | awk -F '[ ="]' '{print $3}')"
printf "\nPartition type (blkid): $part_type\n\n"
if [[ "$part_type" == "ntfs" ]]; then
  printf "Checking and fixing NTFS...\n\n"
  ntfsfix -d $img_part
  echo ""
fi

echo "Mounting partition..."
mkdir /img_partition
if [[ "$part_type" == "ntfs" ]]; then
  echo "Mounting with ntfs-3g..."
  ntfs-3g $img_part /img_partition
else
  mount -o rw $img_part /img_partition
fi

echo "Mounting IMG as loop..."
mount -o rw,loop,sync /img_partition/$img_path /mnt/root




# clean up
umount /proc
umount /sys

# Boot
printf "\nBooting...\n\n"
exec switch_root /mnt/root /sbin/init
```

#### Important
In the above scenario, some more modifications are to be done before booting.  
1. The img file needs to be mounted as read-write and the `etc/fstab` entries need to be changed. UUID of the / partition must be same as the UUID of the actual img file. This can be found by the command `blkid <path_to_arch.img_file>`  
2. Also in most cases, the modules from the current distro will not work on this `arch.img` file. The img file needs to be mounted, and in the [AUTOMATION section of "Gathering modprobe modules"](#automation-2), the variable `module_source_path` needs to point to the modules of this img mount point (say "/run/media/$USER/arch_root/lib/modules/5.9.6/")

## Make the `init` file executable
This is very important and is often missed. Hence added under a seperate heading.
```
cd ~/src_custom_initramfs
chmod +x init
```

## Compile the initramfs
The compiled output should not reside inside the initramfs directory.
```
cd ~/src_custom_initramfs
./4.compile.sh
```
A new `my_initramfs.igz` file is created one directory level above. In this case, directly under home.  
Now this `my_initramfs.igz` file can be placed in the target device's boot directory and called from `initrd` of Grub.
