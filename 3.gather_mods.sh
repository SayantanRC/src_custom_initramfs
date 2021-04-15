#!/bin/bash

echo "Enter module_source_path"
read module_source_path
echo "Entered: $module_source_path"
echo

init_mod_dir_name="generic"

mods=(`cat mod.list`)
mod_list_file="module_list.txt"

cat /dev/null > $mod_list_file

for mod in ${mods[@]}; do
  while read -r actual_mod_path
  do
  
    after_kernel_path=$(echo $actual_mod_path | cut -d '/' -f5-)
    after_kernel_dir=$(echo ${after_kernel_path%/*})
    
    actual_mod_file=$(echo ${after_kernel_path##*/})
    actual_mod_name=$(echo ${actual_mod_file%%.*})
    
    init_mod_dir="lib/modules/$init_mod_dir_name/$after_kernel_dir"
    
    mkdir -p $init_mod_dir
    
    ko_path="${module_source_path}/${after_kernel_dir}/${actual_mod_name}.ko"
    xz_path="${module_source_path}/${after_kernel_dir}/${actual_mod_name}.ko.xz"
    
    init_mod_path=""
    if [[ -e "$ko_path" ]]; then
      init_mod_path="${init_mod_dir}/${actual_mod_name}.ko"
      cp -npv $ko_path $init_mod_path
    elif [[ -e "$xz_path" ]]; then
      init_mod_path="${init_mod_dir}/${actual_mod_name}.ko.xz"
      cp -np $xz_path $init_mod_path && echo "Copied: $actual_mod_name" || echo "FAILED: $actual_mod_name"
    else
      echo "Module $actual_mod_name not found in source path"
    fi
    
    if [[ -n "$init_mod_path" ]]; then
      echo "/${init_mod_path}" >> $mod_list_file
    fi
    
  done < <(modprobe --show-depends $mod | cut -d ' ' -f2)
done
