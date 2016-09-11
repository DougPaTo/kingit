#!/bin/bash

function backupImg() {
	echo "capturing the used size of partition"
	usedSize=$(df | grep /dev/mmcblk0p2 | tr -s ' '| cut -d' ' -f3)

	echo "Working in the number to get it rouded up 15% of the used size"
	newSize=$(printf '%.*f\n' 0 $(echo $usedSize*1.15 | bc))

	echo "umounting the micro SD"
	sudo umount /dev/mmcblk0p*

	echo "Copying the image from SD Card"
	sudo pv -tpreb /dev/mmcblk0 | sudo dd of=imgpibkp.img bs=8M

	echo "Copying the value of Start of second partition that is almost all the time 131072"
	startPos=$(sudo fdisk -l imgpibkp.img | grep imgpibkp.img2 | tr -s ' ' | cut -d" " -f2)

	echo "Creating a lo setup to mount the img"
	sudo losetup /dev/loop0 imgpibkp.img -o $(($startPos*512))

	echo "Resizing partition to 15% more than the minimum size"
	sudo resize2fs -p /dev/loop0 $newSize"k"

	echo "umounting loop"
	sudo losetup -d /dev/loop0

	echo "Mounting the img completely"
	sudo losetup /dev/loop0 imgpibkp.img

	echo "Deleting the second partition and recreate it with the $startPos and $newSize values"
	echo "d
	2
	n
	p
	2
	$startPos
	"+"$newSize"k"
	w
	" | sudo fdisk /dev/loop0
	echo "Getting the value of end partition resized"
	valueEnd=$(sudo fdisk -l /dev/loop0 | grep /dev/loop0p2 | tr -s ' ' | cut -d" " -f3)

	echo "umounting loop"
	sudo losetup -d /dev/loop0

	echo "Truncating the image with the new parameters"
	sudo truncate -s $((($valueEnd+1)*512)) imgrafa-$(date +%F).img

	echo "Removing the temporary img"
	sudo rm imgpibkp.img
}

function restoreImg() {
        echo "umounting the micro SD"
        sudo umount /dev/mmcblk0p*

	echo "Deleting all partitions"
	sudo dd if=/dev/zero of=/dev/mmcblk0 bs=512 count=1 conv=notrunc

	echo "Copy the selected img back"
	sudo pv -tpreb $1 | sudo dd of=/dev/mmcblk0 bs=8M
}

if [ $# -eq 0 ]; then
	backupImg
else
	restoreImg $1
fi
