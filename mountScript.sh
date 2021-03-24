#!/bin/bash

#author  :  Hampton Ford
#notes   :  Meant to automate setup after fresh install.
#purpose :  Mount a partition of shared user files (I don't recommend config files) files. Add static entry in fstab.
#        :  Then create a soft link to the mount point in $TARGET_SOFT_LINK.

PARTITION=""
TARGET_MOUNT_DIR=/mnt/localFileShare/
TARGET_SOFT_LINK=/home/$(logname)/

# todo
# add fstab entry

#=======================================================================================================
### Check Conditions ###
#=======================================================================================================
echo "This program will mount a parition, add an fstab entry so that it automatically remounts on boot, and create a symlink to the mount directory."
echo
echo "Run Conditions:"
echo "  1) Fill in your desired device partition."
echo "  2) Run with super user privileges."
echo "  3) That this program's tty was opened from a non-root account for the targeted directory (or modify the TARGET_SOFT_LINK parameter to your desired destination)."
echo "  4) That the partition is not already mounted."
echo
echo "Disclaimer: This script was tested thoroughly on 5.8.0-45-generic #51~20.04.1-Ubuntu but it was designed for convenience to be run on a trusted system, not for bullet-proof security."
echo "It provided as is without any gurantees."
echo
read -p "Hit ^Ctrl+C to exit or press enter to continue: " throwawayvar  
echo

#ensure root privilege
if [[ $(id -u) -ne 0 ]]; then
   echo "Error: This script must be run as root..." 
   exit 1
fi

#ensure parition is filled out (DOES NOT CHECK VALIDITY OF ENTRY)
if [[ -z ${PARTITION} ]]; then
	echo "Error: Fill out PARTITION=\"\" with your target partition by replacing \"\"."
	echo "  If you don't know which parition you're looking for, I recommend using gparted. Install with:"
	echo "    sudo apt install gparted"
	exit 1
fi

#=======================================================================================================
### Mount Partition ###
#=======================================================================================================
#check if mount exists
if [[ -d ${TARGET_MOUNT_DIR} ]]; then
	echo "The target mount point \"${TARGET_MOUNT_DIR}\" already exists."
	echo
	echo "CAUTION: Overwriting will delete all data stored at ${TARGET_MOUNT_DIR}."
	read -p "Enter y to overwrite or n to exit: " CONTINUE
	if [[ !("${CONTINUE}" == "y" || "${CONTINUE}" == "Y" || "${CONTINUE}" == "Yes" || "${CONTINUE}" == "YES" || "${CONTINUE}" == "Continue") ]]; then
		echo "Aborting script..."; exit 1
	else
		rm -rf ${TARGET_MOUNT_DIR}
	fi
fi

#create mount directory
echo "Creating mount point..."
mkdir ${TARGET_MOUNT_DIR}

#mount partition to localShare and exit if mount failed
echo "Mounting partition..."
mount -w /dev/${PARTITION} ${TARGET_MOUNT_DIR}
if [[ "${?}" -ne 0 ]]; then
	echo "Error: Failed to mount /dev/${PARTITION} to ${TARGET_MOUNT_DIR}"; exit 1
fi

#create soft link
echo "Creating soft link..."
ln -s ${TARGET_MOUNT_DIR} ${TARGET_SOFT_LINK}

#=======================================================================================================
### Add fstab Entry ###
#=======================================================================================================

#=======================================================================================================
### Take Ownership of Drive ###
#=======================================================================================================
#common cases for yes 
echo "Would you like to take ownership of all files at on parition ${PARTITION}?"
echo "Enter y if: "
echo "  1) You want to be able to modify/delete existing files/folders and create/modify/delete new files/folders as well. Entering y will run:"
echo "   \"sudo chown -R $(logname):$(logname) ${TARGET_MOUNT_DIR}\""
#common cases for no
echo "Enter n if: "
echo "  1) You'd prefer to individually modify file permisions. (Use the below command upon completion of this script.)"
echo "   \"sudo chown $(logname):$(logname) ${TARGET_MOUNT_DIR}/<some_file_of_your_choosing>\" without the <>."
echo "  2) You don't want to tamper with existing files but still be able to create/modify/delete new files. (Use the below command upon completion of this script.)"
echo "   \"sudo chown $(logname):$(logname) ${TARGET_MOUNT_DIR}/\""
read -p "Enter y to TAKE OWNERSHIP or n to finish the script without modifying files: " TAKE_OWNERSHIP;
echo
if [[ !("${TAKE_OWNERSHIP}" == "y" || "${TAKE_OWNERSHIP}" == "Y" || "${TAKE_OWNERSHIP}" == "Yes" || "${TAKE_OWNERSHIP}" == "YES" || "${TAKE_OWNERSHIP}" == "Continue") ]]; then
	echo "Finishing script..."; exit 0
else
	echo "Taking ownership..."
	chown $(logname):$(logname) ${TARGET_MOUNT_DIR}
	exit 0
fi