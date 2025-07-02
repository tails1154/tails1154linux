#!/bin/bash


kdialog --progressbar "Syncing the date and time" 0 --title "Tails1154 Linux Setup"
timedatectl
killall kdialog_progress_helper # idk how to use dbus lol. tell me how if you want


kdialog --progressbar "Updating the keyring" 0 --title "Tails1154 Linux Setup"
pacman -Sy archlinux-keyring --noconfirm
#pacman -Sy arch-keyring # I have no idea what its called lol
killall kdialog_progress_helper
DISKS=$(fdisk -l)

kdialog --msgbox "Disks: $DISKS" --title "Tails1154 Linux Setup"

getblockdev() {
	DISK=$(kdialog --inputbox "Enter your Disk block device." --title "Tails1154 Linux Setup")
} # First time with bash functions, don't judge me lol



getblockdev


ls $DISK

while [ $? != 0 ]; do
	kdialog --error "Invalid block device. ls returned non 0 status code $?" --title "Tails1154 Linux Setup"
	getblockdev
done





kdialog --warningcontinuecancel "We will DESTROY all data on $DISK!!! Are you sure you want to continue?" --title "Tails1154 Linux Setup" && kdialog --warningcontinuecancel "FINAL WARNING! Delete all data on $DISK?" --title "Tails1154 Linux Setup"
if [ $? != 0 ]; then
	kdialog --sorry "Install canceled."
	exit 1
fi
kdialog --sorry "Install cannot be canceled past this point."
if [ "$1" != "--grub" ]; then	
	SWAP_SIZE=$(kdialog --inputbox "Enter swap size (Eg: 8G)" --title "Tails1154 Linux Setup")

	# Unmount partitions and disable swap
	umount -R /mnt 2>/dev/null
	swapoff -a

	# Partition the disk with fdisk
	#echo -e "g\nn\n1\n\n+512M\nt\n1\nn\n2\n\n+${SWAP_SIZE}\nt\n2\n19\nn\n3\n\n\nw" | fdisk "$DISK"
	kdialog --sorry "Please do manual partitioning using fdisk."
	fdisk $DISK
fi
DISKS=$(fdisk -l)
EFIBLOCKDEV=$(kdialog --inputbox "Choose the efi partition from the list of disks. It should be your disk followed by the number 1. $DISKS" --title "Tails1154 Linux Setup")
SWAPBLOCKDEV=$(kdialog --inputbox "Choose the Swap partition from the list of disks. It should be your disk followed by the number 2. $DISKS" --title "Tails1154 Linux Setup")
ROOTBLOCKDEV=$(kdialog --inputbox "Choose the root partition from the list of disks. It should be your disk followed by the number 3. $DISKS" --title "Tails1154 Linux Setup")

if [ "$1" != "--grub" ]; then
kdialog --progressbar "Formatting partitions" 0 --title "Tails1154 Linux Setup"
# Format partitions
mkfs.fat -F32 "${DISK}$EFIBLOCKDEV"    # EFI (FAT32)
mkswap "${DISK}$SWAPBLOCKDEV"           # Swap
mkfs.ext4 "${DISK}$ROOTBLOCKDEV"        # Root (ext4)
killall kdialog_progress_helper
# Mount partitions
fi
kdialog --progressbar "Mounting partitions" 0 --title "Tails1154 Linux Setup"
mount "${DISK}3" /mnt
mount --mkdir "${DISK}1" /mnt/boot
swapon "${DISK}2"
killall kdialog_progress_helper



if [ "$1" != "--grub" ]; then
kdialog --msgbox "That's all the info we need right now.\n\nAbout to setup base system." --title "Tails1154 Linux Setup"
kdialog --progressbar "Installing the base system" 0 --title "Tails1154 Linux Setup"
pacstrap -K /mnt base linux linux-firmware vi vim nano
killall kdialog_progress_helper
kdialog --progressbar "Installing programs" 0 --title "Tails1154 Linux Setup"
pacstrap /mnt  mkinitcpio mkinitcpio-archiso open-vm-tools openssh pv qemu-guest-agent syslinux virtualbox-guest-utils-nox plasma xorg-server xorg-xinit polkit nano vim vi kdialog firefox kde-applications flatpak vlc networkmanager man-db sudo pulseaudio sddm firefox
killall kdialog_progress_helper
TIMEZONE=$(kdialog --inputbox "Enter your timezone (eg America/Chicago)" --title "Tails1154 Linux Setup")
USERNAME=$(kdialog --inputbox "Enter your desired username" --title "Tails1154 Linux Setup")
kdialog --progressbar "Setting up the system" 0 --title "Tails1154 Linux Setup"
genfstab -U /mnt >> /mnt/etc/fstab
PASS=$(kdialog --password "Enter your desired password" --title "Tails1154 Linux Setup")
ROOTPASS=$(kdialog --password "Enter the desired root password" --title "Tails1154 Linux Setup"
arch-chroot /mnt /bin/sh -c "ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime ; hwclock --systohc ; locale-gen ; echo 'LANG=en_US.UTF-8' > /etc/locale.conf ; echo 'tailslinux' > /etc/hostname ; mkinitcpio -P ; useradd -m -G wheel $USERNAME ; echo '$PASS' | passwd $USERNAME --stdin ; echo '$ROOTPASS' | passwd root --stdin ; echo '$USERNAME ALL=(ALL:ALL) ALL' > /etc/sudoers.d/user.conf ; systemctl enable sddm ; systemctl enable NetworkManager ; echo 'Welcome to Tails1154 Linux!' > /etc/issue ; exit 0"
killall kdialog_progress_helper
fi
#kdialog --progressbar "Installing the grub package" 0 --title "Tails1154 Linux Setup"
#pacman -Sy grub efibootmgr --noconfirm # I know people will hate me doing this, but the packages cache is already out of date, and the ram most likely won't have enough space for upgrades if there are any.
#killall kdialog_progress_helper
kdialog --progressbar "Adding pacman keys" 0 --title "Tails1154 Linux Setup"
arch-chroot /mnt /bin/sh -c 'pacman -Sy arch-keyring --noconfirm ; pacman-key --init ; pacman-key --populate ; exit 0'
killall kdialog_progress_helper
kdialog --progressbar "Installing the grub bootloader" 0 --title "Tails1154 Linux Setup"
#kdialog --msgbox "$(fdisk -l)" --title "Tails1154 Linux Setup"
#DISK=$(kdialog --inputbox "Enter your block device one last time." --title "Tails1154 Linux Setup")
arch-chroot /mnt /bin/sh -c "pacman -Sy grub efibootmgr --noconfirm --needed ; grub-install --force $DISK ; exit 0"
killall kdialog_progress_helper
kdialog --progressbar "Unmounting file systems" 0 --title "Tails1154 Linux Setup"
umount /mnt
killall kdialog_progress_helper
kdialog --msgbox "Tails1154 Linux Setup has completed! You may now reboot into your new system! (in theory)"
kdialog --msgbox "Press OK or close this window to reboot."
reboot now


