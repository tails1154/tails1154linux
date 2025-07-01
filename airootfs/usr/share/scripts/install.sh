#!/bin/bash


kdialog --progressbar "Syncing the date and time" 0 --title "Tails1154 Linux Setup"
timedatectl
killall kdialog # idk how to use dbus lol. tell me how if you want

DISKS=$(fdisk -l)

kdialog --msgbox "Disks: $DISKS" --title "Tails1154 Linux Setup"

getblockdev() {
	DISK=$(kdialog --input "Enter your Disk block device." --title "Tails1154 Linux Setup")
} # First time with bash functions, don't judge me lol



getblockdev


ls /dev/$DISK

while [ $? != 0 ]; do
	kdialog --error "Invalid block device. ls returned non 0 status code $?" --title "Tails1154 Linux Setup"
	getblockdev
done





kdialog --warningcontinuecancel "We will DESTROY all data on $DISK!!! Are you sure you want to continue?" --title "Tails1154 Linux Setup" && kdialog --warningcontinuecancel "FINAL WARNING! Delete all data on $DISK?" --title "Tails1154 Linux Setup"
if [ $? != 0 ]; do
	kdialog --sorry "Install canceled."
	exit 1
done


SWAP_SIZE=$(kdialog --input "Enter swap size (Eg: 8G)" --title "Tails1154 Linux Setup")

# Unmount partitions and disable swap
umount -R /mnt 2>/dev/null
swapoff -a

# Partition the disk with fdisk
echo -e "g\nn\n1\n\n+512M\nt\n1\nn\n2\n\n+${SWAP_SIZE}\nt\n2\n19\nn\n3\n\n\nw" | fdisk "$DISK"


DISKS=$(fdisk -l)
EFIBLOCKDEV=$(kdialog --inputbox "Choose the efi partition from the list of disks. It should be your disk followed by the number 1. $DISKS" --title "Tails1154 Linux Setup")
SWAPBLOCKDEV=$(kdialog --inputbox "Choose the Swap partition from the list of disks. It should be your disk followed by the number 2. $DISKS" --title "Tails1154 Linux Setup")
ROOTBLOCKDEV=$(kdialog --inputbox "Choose the root partition from the list of disks. It should be your disk followed by the number 3. $DISKS" --title "Tails1154 Linux Setup")


kdialog --progressbar "Formatting partitions" 0 --title "Tails1154 Linux Setup"
# Format partitions
mkfs.fat -F32 "${DISK}$EFIBLOCKDEV"    # EFI (FAT32)
mkswap "${DISK}$SWAPBLOCKDEV"           # Swap
mkfs.ext4 "${DISK}$ROOTBLOCKDEV"        # Root (ext4)
killall kdialog
kdialog --progressbar "Mounting partitions" 0 --title "Tails1154 Linux Setup"
# Mount partitions
mount "${DISK}3" /mnt
mount --mkdir "${DISK}1" /mnt/boot
swapon "${DISK}2"
killall kdialog




kdialog --msgbox "That's all the info we need right now.\n\nAbout to setup base system." --title "Tails1154 Linux Setup"
