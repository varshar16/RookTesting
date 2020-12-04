#!/bin/bash -e

# if lvs true then proceed
if [[ "$(sudo lvs)" ]]; then
        echo "Formatting in progress"
        sudo lvremove vg_nvme -y
        # Get nvme name
        device_name="$(sudo lsblk -f | awk '/nvme/ {print $1}')"
        echo "$device_name is the device name, proceeding to remove fs"
        sudo wipefs -a /dev/$device_name
        if [[ !"$(sudo lsblk -f | awk '/nvme/ {print $2}')" ]]; then
                echo "Successful!!"
        else
                echo "Erasing fs failed"
        fi
else
        echo "No, device to reformat"
fi
