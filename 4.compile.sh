#!/bin/bash

find . | cpio -H newc -o > ../my_initramfs.cpio
cat ../my_initramfs.cpio | gzip > ../my_initramfs.igz
rm ../my_initramfs.cpio
