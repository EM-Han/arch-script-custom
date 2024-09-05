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

cp setup_arch_chroot.sh /mnt/
cp systemd-boot-config /mnt/

# Chroot
arch-chroot /mnt

printf ${CYAN}"Pre Installation is finished\nPlease run second script.\n"