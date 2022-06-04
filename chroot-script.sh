#!/usr/bin/env bash

# Set time zone
ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime || error_exit "Error: Could not set localtime."
hwclock --systohc

# Synchronize system clock across network
systemctl enable systemd-timesyncd # untested

# Localization
#echo -e "en_US.UTF-8 UTF-8\nhu_HU.UTF-8 UTF-8" > /etc/locale.gen # untested
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#hu_HU.UTF-8 UTF-8/hu_HU.UTF-8 UTF-8/g' /etc/locale.gen # for LC_TIME
locale-gen
echo -e "LANG=en_US.UTF-8\nLC_TIME=hu_HU.UTF-8" > /etc/locale.conf
echo KEYMAP=hu > /etc/vconsole.conf

# Network configuration
echo testarch > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\ttestarch.localdomain\ttestarch" > /etc/hosts
pacman -S networkmanager --needed --noconfirm || error_exit "Error: Could not install additional packages."
systemctl enable NetworkManager

# Initframs
mkinitcpio -P

# Root password
echo "root:$(date +%F | base64)" | chpasswd || error_exit "Error: Could not set new root password."

# Add new user
useradd -mG wheel vanderlyle || error_exit "Error: Could not create new user."
echo "vanderlyle:$(date +%F)" | chpasswd || error_exit "Error: Could not set password for new user."
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/1_allow_wheel_sudo_passwd || error_exit "Error: Could not add file to sudoers directory."

# Boot loader
# Failed to write EFI variable WORKAROUND: https://github.com/systemd/systemd/issues/13603#issuecomment-552246188
bootctl install --no-variables || error_exit "Error: Could not install 'bootctl'."
cp /usr/share/systemd/bootctl/arch.conf /boot/loader/entries/arch.conf
sed -i '0,/options/s/options.*/options root=PARTUUID='"$(blkid -s PARTUUID -o value /dev/sda3)"' rw quiet/' /boot/loader/entries/arch.conf
echo -e "timeout\tmenu-force\ndefault\tarch.conf\tmax\neditor\tno" > /boot/loader/loader.conf
pacman -S vi vim git wget curl --needed --noconfirm || error_exit "Error: Could not install additional packages."
