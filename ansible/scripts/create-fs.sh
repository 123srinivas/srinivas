#!/bin/bash
var_file=lv_fs_mnt_owner.var.yml
echo $var_file

echo lv_fs_mnt_owner_create: >> $var_file

echo Please enter vg name:
read vgname
echo "  - vgname:" $vgname >> $var_file
echo "    create: true" >> $var_file

cat /dev/null > lv_file
echo how many file systems do you need to create?
read fs_number
create_number=1
while [ $create_number -le $fs_number ]
do
cat lv_block >> lv_file
create_number=$(( $create_number + 1 ))
done

vi lv_file

cat $var_file

