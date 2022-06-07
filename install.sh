#!/usr/bin/env bash

# TODO
#   (1) "implement" SELinux - https://wiki.archlinux.org/index.php/SELinux

trap exit 1 ERR # Abort script if something in chroot or customize scripts throw and error

error_exit()
{
	echo "$(tput setab 1)$(tput setaf 7)$(tput bold)$1$(tput sgr0)" 1>&2
	exit 1
}

export -f error_exit # exporting erro finction to chroot function too

# PRE-INSTALLATION

# (1) Verify boot mode - List the efivars directory. If there's no error, then the system is booted in UEFI mode.
ls /sys/firmware/efi/efivars || error_exit "ERROR: Not booted in EFI mode."

# (2) Verify network connection
ping -q -c 1 -W 1 archlinux.org || error_exit "ERROR: No network connection."

# (3) Update the system clock
timedatectl set-ntp true || error_exit "ERROR: Could not update system clock."

# (4) Partition the disks - TODO - break up line into variable - user input?
wipefs -af /dev/sda || error_exit "ERROR: Could not delete existing partitions."
# LAPTOP
sgdisk -n 1:0:+300M -n 2:0:+8G -n 3:0:0 -t 1:ef00 -t 2:8200 -t 3:8300 -c 1:"EFI" -c 2:"SWAP" -c 3:"ROOT" -g /dev/sda || error_exit "ERROR: Could not create new partitions."

# (5) Format the partitions
grep -qs '/mnt ' /proc/mounts && umount -Rf /mnt # umount if previously mounted

mkfs.fat -F 32 /dev/sda1 || error_exit "ERROR: Failed to write fat32 to /dev/sda1"
mkfs.ext4 -F /dev/sda3 || error_exit "ERROR: Failed to write ext4 to /dev/sda3"

swapoff --all
mkswap /dev/sda2 || error_exit "ERROR: Could not create swap on /dev/sda2"
swapon /dev/sda2 || error_exit "ERROR: Could not load swap on /dev/sda2"

# (6) Mount the file systems
mount /dev/sda3 /mnt || error_exit "ERROR: Could not mount /dev/sda3 to /mnt"
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot || error_exit "ERROR: Could not mount /dev/sda1 to /mnt/boot"

# INSTALLATION

# (1) Select the mirrors
pacman -Sy wget --needed --noconfirm || error_exit "ERROR: Could not install wget"
wget "https://www.archlinux.org/mirrorlist/?country=HU" -O /etc/pacman.d/mirrorlist || error_exit "ERROR: Could not download mirrorlist."
sed -i '0,/#Server/s/#//' /etc/pacman.d/mirrorlist || error_exit "ERROR: Could not uncomment first mirror."

# (2) Install essential packages
pacstrap /mnt base base-devel linux linux-firmware || error_exit "ERROR: pacstrap failed" # try linux-hardened

# CONFIGURE THE SYSTEM

# (1) Fstab
genfstab -U /mnt >> /mnt/etc/fstab || error_exit "ERROR: Could not write fstab file to /mnt/etc/fstab."

# (2) Chroot & customization
#cp -r copy /mnt
#arch-chroot /mnt copy/chroot.sh || error_exit "ERROR: Chroot script failed."
#rm -rf /mnt/copy

cp chroot-script.sh /mnt/home
arch-chroot /mnt sh /home/chroot-script.sh
rm /mnt/home/chroot-script.sh

#arch-chroot /mnt passwd # untested

# Reboot
# Post-installation

# Set xorg keyboard to hu (also needed by lightdm)
# Normally created by running localectl (cannot run in chroot)
cp copy/00-keyboard.conf /mnt/etc/X11/xorg.conf.d

# DONE

umount -R /mnt
echo "$(tput setab 2)$(tput setaf 7)$(tput bold)Done. Install successfull.$(tput sgr0)"
#reboot
read -rp "Reboot into new system? [Y/n] " confirm && [[ ${confirm:-y} == [yY] ]] && reboot # TODO - add auto OK after a timer
