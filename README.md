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
`mkdir, ls, tail, grep, cut, awk, mount, umount, insmod, modprobe, switch_root`  
To find the location of the binary, in terminal, type `type <binary-name>` or `which <binary-name>`. Example: `which modprobe` gives output `/usr/bin/modprobe`  
We need to copy each of them in the respective directories. In the above example of modprobe, the command would be `cp -p /usr/bin/modprobe usr/bin/modprobe`.  
### AUTOMATION!
```
cd ~/src_custom_initramfs
while read -r bin_path
do
  init_bin_path=${bin_path:1}
  cp -v $bin_path $init_bin_path
done < <(which {mkdir,ls,tail,grep,cut,awk,mount,umount,insmod,modprobe,switch_root})
```
