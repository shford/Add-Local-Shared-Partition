#!/bin/bash

#author  :  Hampton Ford
#notes   :  Should only have to run once, but probably won't cause errors if run multiple times.
#purpose :  Essentially share a partition locally b/w various linux OS's and/or versions.
#        :    --likely works best across Debian only systems. If in doubt give a shot.

#license :  As specified by the MIT license included in the repo, this program is provided as is without any gurantees."
#        :  Redistribute and modify as you see fit so long as you include the original source of the author. 


# the partition to mount and add fstab entry for
PARTITION=""  #ex: /dev/sda6

# the mount point
TARGET_MOUNT_DIR=/mnt/localFileShare/

# the target soft link that'll point to the mount point
TARGET_SOFT_LINK=/home/$(logname)/


#=======================================================================================================
### Introductory Prompt ###
#=======================================================================================================
echo "This program will mount a parition, add an fstab entry so that it automatically remounts on boot, " 
echo "and create a symlink to the mount directory in ${TARGET_SOFT_LINK}. Please feel free to customize "
echo "this program to better suite your needs."
echo
echo "Major Run Conditions:"
echo "  1) That this program's tty was opened from a non-root account corresponding to the desired user's '/home/' directory."
echo "  2) Run as sudo."
echo "  3) Partition in question is not currently mounted." #I decided not to forcibly unmount the partition since someone could have important file transfers or something 
echo
echo "Disclaimer: This script was tested thoroughly on Ubuntu 20.04.1 but it was designed for convenience to be run on a trusted system, not for bullet-proof security."
echo
read -p "Hit ^Ctrl+C to exit or press enter to continue: " pause  
echo

#=======================================================================================================
### Check Conditions ###
#=======================================================================================================
# install tools to get the UUID
apt install -y libblkid1 > /dev/null 2>&1;
apt install -y grep > /dev/null 2>&1;

# ensure root privilege
if [[ $(id -u) -ne 0 ]]; then
   echo "Error: This script must be run as root..." 
   exit 1
fi

# ensure PARTITION is valid (invalid cases: null, doesn't exist in /dev/, or user did not confirm)
PARTITION_VALID=true
(ls /dev/ | grep ${PARTITION}) > /dev/null 2>&1

while [[ (-z ${PARTITION} || !("${?}" -ne 0)) && (PARTITION_VALID) ]]; do
	blkid | cat -n
	read -p "Enter the number of your corresponding partition: " PARTITION_NUMBER;
	PARTITION=$(blkid | cat -n | grep "   ${PARTITION_NUMBER}" | sed 's/://g' | sed 's/^[^\t]*/ /g' | sed 's/^\s*//g' | cut -d ' ' -f 1)

	# verify entry
	read -p "Is ${PARTITION} correct? Enter y or n: " PARTITION_VALID
	if [[ "${PARTITION_VALID}" == "y" || "${PARTITION_VALID}" == "Y" || "${PARTITION_VALID}" == "Yes" || "${PARTITION_VALID}" == "YES" ]]; then
		PARTITION_VALID=false
	else

		PARTITION_VALID=true
	fi
	(ls /dev/ | grep ${PARTITION}) > /dev/null 2>&1
done

# exit if device is already mounted
$(grep -qs "${PARTITION}" /proc/mounts)
if [[ "${?}" == 0 ]]; then
	echo "Error: ${PARTITION} is already mounted. Unmount partition and try again."
	exit 1
fi

#=======================================================================================================
### Mount Partition ###
#=======================================================================================================
# check if mount exists
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

# create mount directory
echo "Creating mount point..."
mkdir ${TARGET_MOUNT_DIR}

# mount partition to localShare and exit if mount failed
echo "Mounting partition..."
mount -w ${PARTITION} ${TARGET_MOUNT_DIR}
if [[ "${?}" -ne 0 ]]; then
	echo "Error: Failed to mount ${PARTITION} to ${TARGET_MOUNT_DIR}"; exit 1
fi

# create soft link
echo "Creating soft link..."
ln -s ${TARGET_MOUNT_DIR} ${TARGET_SOFT_LINK}

#=======================================================================================================
### Add fstab Entry ###
#=======================================================================================================
# get UUID
UUID=$(blkid | grep -i ${PARTITION} | cut -d ' ' -f 3)

# prevent duplicate fstab entries
if [[ $(grep ${UUID} /etc/fstab) -ne 0 ]]; then
	# add entry
	echo "# Add fstab entry for ${PARTITION} via mountScript.sh" >> /etc/fstab
	echo "${UUID}    ${TARGET_MOUNT_DIR}   auto    rw,user,auto    0    0" >> /etc/fstab
fi

#=======================================================================================================
### Take Ownership of Drive ###
#=======================================================================================================
# common cases for yes 
echo "Would you like to take ownership of all files at on parition ${PARTITION}?"
echo "Enter y if: "
echo "  1) You want to be able to modify/delete existing files/folders and create/modify/delete new files/folders as well. Entering y will run:"
echo "   \"sudo chown -R $(logname):$(logname) ${TARGET_MOUNT_DIR}\""
# common cases for no
echo "Enter n if: "
echo "  1) You'd prefer to individually modify file permisions. (Use the below command upon completion of this script.)"
echo "   \"sudo chown $(logname):$(logname) ${TARGET_MOUNT_DIR}/<some_file_of_your_choosing>\" without the <>."
echo "  2) You don't want to tamper with existing files but still be able to create/modify/delete new files. (Use the below command upon completion of this script.)"
echo "   \"sudo chown $(logname):$(logname) ${TARGET_MOUNT_DIR}/\""
read -p "Enter y to take ownership or n to finish the script without modifying files: " TAKE_OWNERSHIP;
echo
if [[ !("${TAKE_OWNERSHIP}" == "y" || "${TAKE_OWNERSHIP}" == "Y" || "${TAKE_OWNERSHIP}" == "Yes" || "${TAKE_OWNERSHIP}" == "YES" || "${TAKE_OWNERSHIP}" == "Continue") ]]; then
	echo "Finishing script..."; exit 0
else
	echo "Taking ownership..."
	chown $(logname):$(logname) ${TARGET_MOUNT_DIR}
	exit 0
fi