#!/bin/bash


CYAN='\033[1;96m'

# CONFIGS
# Note: Leave root to 0 if you want to partition rest to root
#       Remove ucode if you're using amd
disk_device="/dev/sda"
time_zone="Europe/Zurich"
boot_size="+1G"
swap_size="+4G"
root_size="0"
host_name="archlinux"
user_name="han"
root_pass="NONE"
user_pass="NONE"
ucode="intel-ucode"
discard_grain=$(lsblk -ndo DISC-GRAN)

# Partition naming
part_1="${disk_device}1"
part_2="${disk_device}2"
part_3="${disk_device}3"

# Set timedatectl
timedatectl set-ntp true
timedatectl set-timezone $time_zone


# Parition Drive

# Layout:
# 1 GB - Boot /dev/sda1
# 4 GB - Swap /dev/sda2
# Rest - Root /dev/sda3
sgdisk --zap-all $disk_device
sgdisk --new=1:0:$boot_size --typecode=1:EF00 $disk_device
sgdisk --new=2:0:$swap_size --typecode=2:8200 $disk_device
sgdisk --new=3:0:$root_size --typecode=3:8300 $disk_device


# Format Partitions
mkfs.ext4 $part_3
mkswap $part_2
mkfs.fat -F32 $part_1


# Mount File System
mount $part_3 /mnt
mount --mkdir $part_1 /mnt/boot
swapon $part_2

# Update Mirrorlist
reflector --latest 20 --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install packages to /mnt
#pacstrap -K /mnt base linux linux-firmware base-devel linux-headers $ucode sof-firmware networkmanager nano sudo man-db man-pages texinfo
pacstrap -K /mnt base linux linux-firmware base-devel linux-headers sof-firmware networkmanager nano sudo man-db man-pages texinfo


# Generate fstab
genfstab -U -p /mnt >> /mnt/etc/fstab


# Chroot
arch-chroot /mnt

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

# Systemd-boot Setup
bootctl install
cp systemd-boot-config/loader.conf /boot/loader/loader.conf
cp systemd-boot-config/arch.conf /boot/loader/entries/arch.conf
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value ${part_3}) rw" >> /boot/loader/entries/arch.conf

# Enable NetworkManager
systemctl enable NetworkManager.service

printf ${CYAN}"Pre Installation is finished\n"