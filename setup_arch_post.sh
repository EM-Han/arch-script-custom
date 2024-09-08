#!/bin/bash
time_zone="Europe/Istanbul"
host_name="archlinux"
user_name="han"
root_pass="NONE"
user_pass="NONE"
discard_grain=$(lsblk -ndo DISC-GRAN)

# Set timezone
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc --utc

# Set Localization
sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo $host_name > /etc/hostname 

# SSD only
if [ "$discard_grain" != "0B" ] && [ -n "$discard_grain" ]; then
    systemctl enable fstrim.timer
fi

# Set User
useradd -m -G wheel -s /bin/bash $user_name

# Password
echo -e "$root_pass\n$root_pass" | passwd
# User Pass
echo -e "$user_pass\n$user_pass" | passwd $user_name

# Edit sudoers
sed -i '$a\\nDefaults targetpw' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/Defaults:%wheel targetpw\n%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# sudo umount /boot
# sed -i '/\/boot/s/\(defaults\)\@<!\(defaults,[^,]*\)\@=/\2,fmask=0137,dmask=0027/g' /etc/fstab
# sudo mount /boot

# Systemd-boot Setup
# PLEASE MAKE SURE /dev/sda3 --> root
bootctl install
cp /script/systemd-boot-config/loader.conf /boot/loader/loader.conf
cp /script/systemd-boot-config/arch.conf /boot/loader/entries/arch.conf
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value $1) rw" >> /boot/loader/entries/arch.conf

# Enable NetworkManager
systemctl enable NetworkManager.service