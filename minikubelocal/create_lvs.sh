#!/bin/bash -e

lsblk -f
sudo pvcreate /dev/vda3
sudo vgcreate vg_test  /dev/vda3
sudo lvcreate -L 5G -n lv0 vg_test
#sudo lvcreate -l 100%FREE -n lv0 vg_test

echo "Done, your lv is"
sudo lvscan
