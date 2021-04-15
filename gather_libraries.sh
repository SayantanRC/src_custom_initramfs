#!/bin/bash

while read -r bin_path
do
  while read -r dependency
  do
    lib_path=$(echo $dependency | cut -d ' ' -f3)
    init_lib_path=${lib_path:1}
    cp -npv $lib_path $init_lib_path
  done < <(ldd $bin_path | tail -n +2)
done < <(which `cat binary.list`)
