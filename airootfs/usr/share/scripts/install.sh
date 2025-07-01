#!/bin/bash

# Tails1154 Linux Installer using KDialog

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    if command -v kdialog >/dev/null; then
        kdialog --error "This installer must be run as root. Please try again with 'sudo'."
    else
        echo "This installer must be run as root. Please try again with 'sudo'."
    fi
    exit 1
fi

# Check for kdialog
if ! command -v kdialog >/dev/null; then
    echo "kdialog not found. Installing required packages..."
    pacman -Sy --noconfirm kdialog
    if [ $? -ne 0 ]; then
        echo "Failed to install kdialog. Please install it manually first."
        exit 1
    fi
fi

# Welcome message
kdialog --title "Tails1154 Linux Installer" --msgbox "Welcome to the Tails1154 Linux installer.\n\nThis will guide you through installing Tails1154 Linux (based on Arch Linux) with KDE Plasma desktop."

# Verify internet connection
if ! ping -c 3 archlinux.org >/dev/null 2>&1; then
    kdialog --error "No internet connection detected. Please connect to the internet before proceeding."
    exit 1
fi

# Update keyring first to avoid package installation failures
pacman -Sy --noconfirm archlinux-keyring

# Select disk for installation
DISKS=()
while IFS= read -r line; do
    DISKS+=("$(echo "$line" | awk '{print $1}")" "$(echo "$line" | awk '{print $2}")")
done < <(lsblk -d -n -o NAME,SIZE | grep -v "loop")

DISK=$(kdialog --title "Select Installation Disk" --combobox "Choose the disk to install Tails1154 Linux on:" "${DISKS[@]}")
if [ $? -ne 0 ]; then
    kdialog --error "Installation cancelled."
    exit 1
fi
DISK="/dev/${DISK}"

# Partitioning options
PART_OPTION=$(kdialog --title "Partitioning" --menu "Choose partitioning option:" \
    "1" "Automatic (entire disk, UEFI)" \
    "2" "Manual (using cfdisk)" \
    "3" "Use existing partitions")

case $PART_OPTION in
    1)
        # Automatic partitioning
        if ! parted -s "$DISK" mklabel gpt; then
            kdialog --error "Failed to create GPT partition table."
            exit 1
        fi
        
        if ! parted -s "$DISK" mkpart primary fat32 1MiB 513MiB; then
            kdialog --error "Failed to create EFI partition."
            exit 1
        fi
        parted -s "$DISK" set 1 esp on
        
        if ! parted -s "$DISK" mkpart primary linux-swap 513MiB 4.5GiB; then
            kdialog --error "Failed to create swap partition."
            exit 1
        fi
        
        if ! parted -s "$DISK" mkpart primary ext4 4.5GiB 100%; then
            kdialog --error "Failed to create root partition."
            exit 1
        fi
        
        EFI_PART="${DISK}1"
        SWAP_PART="${DISK}2"
        ROOT_PART="${DISK}3"
        
        if ! mkfs.fat -F32 "$EFI_PART"; then
            kdialog --error "Failed to format EFI partition."
            exit 1
        fi
        
        if ! mkswap "$SWAP_PART"; then
            kdialog --error "Failed to create swap space."
            exit 1
        fi
        
        if ! mkfs.ext4 -F "$ROOT_PART"; then
            kdialog --error "Failed to format root partition."
            exit 1
        fi
        
        if ! swapon "$SWAP_PART"; then
            kdialog --error "Failed to enable swap."
            exit 1
        fi
        
        if ! mount "$ROOT_PART" /mnt; then
            kdialog --error "Failed to mount root partition."
            exit 1
        fi
        
        if ! mount --mkdir "$EFI_PART" /mnt/boot; then
            kdialog --error "Failed to mount EFI partition."
            exit 1
        fi
        ;;
    2)
        # Manual partitioning
        cfdisk "$DISK"
        kdialog --msgbox "After partitioning in cfdisk, please specify your partitions:"
        
        EFI_PART=$(kdialog --title "EFI Partition" --inputbox "Enter EFI system partition (e.g., /dev/sda1):")
        SWAP_PART=$(kdialog --title "Swap Partition" --inputbox "Enter swap partition (e.g., /dev/sda2):")
        ROOT_PART=$(kdialog --title "Root Partition" --inputbox "Enter root partition (e.g., /dev/sda3):")
        
        if ! mkfs.fat -F32 "$EFI_PART"; then
            kdialog --error "Failed to format EFI partition."
            exit 1
        fi
        
        if ! mkswap "$SWAP_PART"; then
            kdialog --error "Failed to create swap space."
            exit 1
        fi
        
        if ! mkfs.ext4 -F "$ROOT_PART"; then
            kdialog --error "Failed to format root partition."
            exit 1
        fi
        
        if ! swapon "$SWAP_PART"; then
            kdialog --error "Failed to enable swap."
            exit 1
        fi
        
        if ! mount "$ROOT_PART" /mnt; then
            kdialog --error "Failed to mount root partition."
            exit 1
        fi
        
        if ! mount --mkdir "$EFI_PART" /mnt/boot; then
            kdialog --error "Failed to mount EFI partition."
            exit 1
        fi
        ;;
    3)
        # Use existing partitions
        EFI_PART=$(kdialog --title "EFI Partition" --inputbox "Enter existing EFI system partition (e.g., /dev/sda1):")
        SWAP_PART=$(kdialog --title "Swap Partition" --inputbox "Enter existing swap partition (e.g., /dev/sda2):")
        ROOT_PART=$(kdialog --title "Root Partition" --inputbox "Enter existing root partition (e.g., /dev/sda3):")
        
        if ! swapon "$SWAP_PART"; then
            kdialog --error "Failed to enable swap."
            exit 1
        fi
        
        if ! mount "$ROOT_PART" /mnt; then
            kdialog --error "Failed to mount root partition."
            exit 1
        fi
        
        if ! mount --mkdir "$EFI_PART" /mnt/boot; then
            kdialog --error "Failed to mount EFI partition."
            exit 1
        fi
        ;;
    *)
        kdialog --error "Installation cancelled."
        exit 1
        ;;
esac

# Install base system with progress dialog
DB=$(kdialog --title "Installing Base System" --progressbar "Installing base system..." 6)
qdbus $DB Set "" value 1

# Base system and essential packages
pacstrap /mnt base base-devel linux linux-firmware bash btrfs-progs dosfstools e2fsprogs exfatprogs f2fs-tools fuse2 gptfdisk ntfs-3g openssh sudo >/dev/null 2>&1
if [ $? -ne 0 ]; then
    kdialog --error "Failed to install base system."
    exit 1
fi
qdbus $DB Set "" value 2

# Generate fstab
if ! genfstab -U /mnt >> /mnt/etc/fstab; then
    kdialog --error "Failed to generate fstab."
    exit 1
fi
qdbus $DB Set "" value 3

# Chroot setup
arch-chroot /mnt <<EOF
# Timezone
TIMEZONE=\$(kdialog --title "Timezone" --inputbox "Enter timezone (Region/City):" "America/New_York")
ln -sf "/usr/share/zoneinfo/\$TIMEZONE" /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
HOSTNAME=\$(kdialog --title "Hostname" --inputbox "Enter hostname:" "tails1154")
echo "\$HOSTNAME" > /etc/hostname

# Root password
ROOT_PASS=\$(kdialog --title "Root Password" --password "Enter root password:")
echo "root:\$ROOT_PASS" | chpasswd

# Create user
USERNAME=\$(kdialog --title "User Account" --inputbox "Enter username for primary user:")
useradd -m -G wheel -s /bin/bash "\$USERNAME"
USER_PASS=\$(kdialog --title "User Password" --password "Enter password for \$USERNAME:")
echo "\$USERNAME:\$USER_PASS" | chpasswd

# Configure sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Bootloader
pacman -Sy --noconfirm grub efibootmgr >/dev/null 2>&1
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Tails1154 >/dev/null 2>&1
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
EOF
qdbus $DB Set "" value 4

# Install desktop environment and additional packages
arch-chroot /mnt <<EOF
# Install KDE Plasma and essential components
pacman -Sy --noconfirm \
    plasma-meta kde-applications-meta \
    xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xrdb \
    sddm sddm-kcm \
    networkmanager plasma-nm \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack \
    bluez bluez-utils bluedevil \
    cups print-manager \
    firefox \
    konsole dolphin kate \
    ark file-roller unzip p7zip \
    neofetch htop \
    git wget curl \
    ntfs-3g exfat-utils fuse \
    --needed >/dev/null 2>&1

# Enable services
systemctl enable sddm
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable sshd

# Configure auto-startx for root
echo "if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then" > /root/.bashrc
echo "    exec startx" >> /root/.bashrc
echo "fi" >> /root/.bashrc
EOF
qdbus $DB Set "" value 5

# Final configuration
arch-chroot /mnt <<EOF
# Update mkinitcpio
mkinitcpio -P

# Set up reflector for faster mirrors
pacman -Sy --noconfirm reflector >/dev/null 2>&1
reflector --country US --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Clean package cache
paccache -r
EOF
qdbus $DB Set "" value 6

# Close progress dialog
qdbus $DB close

# Installation complete
kdialog --title "Installation Complete" --msgbox "Tails1154 Linux installation is complete!\n\nPlease reboot and remove the installation media.\n\nUsername: $USERNAME\nHostname: $HOSTNAME"
