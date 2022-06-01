#!/usr/bin/env bash

ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime || error_exit "Error: Could not set localtime."
hwclock --systohc

# Synchronize system clock across network
systemctl enable systemd-timesyncd # untested

#echo -e "en_US.UTF-8 UTF-8\nhu_HU.UTF-8 UTF-8" > /etc/locale.gen # untested
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#hu_HU.UTF-8 UTF-8/hu_HU.UTF-8 UTF-8/g' /etc/locale.gen # for LC_TIME
locale-gen
echo -e "LANG=en_US.UTF-8\nLC_TIME=hu_HU.UTF-8" > /etc/locale.conf
echo KEYMAP=hu > /etc/vconsole.conf
echo testarch > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\ttestarch.localdomain\ttestarch" > /etc/hosts
#systemctl enable NetworkManager