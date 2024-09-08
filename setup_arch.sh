#!/bin/bash


CYAN='\033[1;96m'

# CONFIGS
# Note: Leave root to 0 if you want to partition rest to root
#       Remove ucode if you're using amd
disk_device="/dev/sda"
time_zone="Europe/Istanbul"
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
mkfs.btrfs $part_3
mkswap $part_2
mkfs.fat -F32 $part_1


# Mount File System
mount $part_3 /mnt
btrfs sub cr /mnt/@
btrfs sub cr /mnt/@home
btrfs sub cr /mnt/@snapshots
btrfs sub cr /mnt/@var_log
btrfs sub cr /mnt/@pkg

umount /mnt
mount -o subvol=@,compress=zstd,commit=120,nodiscard,space_cache=v2,ssd,noatime $part_3 /mnt
mount --mkdir -o subvol=@home,compress=zstd,commit=120,nodiscard,space_cache=v2,ssd,noatime $part_3 /mnt/home
mount --mkdir -o subvol=@snapshots,compress=zstd,commit=120,nodiscard,space_cache=v2,ssd,noatime $part_3 /mnt/.snapshots
mount --mkdir -o subvol=@var_log,compress=zstd,commit=120,nodiscard,space_cache=v2,ssd,noatime $part_3 /mnt/var/log
mount --mkdir -o subvol=@pkg,compress=zstd,commit=120,nodiscard,space_cache=v2,ssd,noatime $part_3 /mnt/var/cache/pacman/pkg

mount --mkdir $part_1 /mnt/boot
swapon $part_2

# Update Mirrorlist
reflector --latest 20 --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install packages to /mnt
pacstrap -K /mnt base linux linux-firmware base-devel linux-headers $ucode sof-firmware networkmanager nano sudo man-db man-pages texinfo btrfs-progs
# pacstrap -K /mnt base linux linux-firmware base-devel linux-headers sof-firmware networkmanager nano sudo man-db man-pages texinfo


# Generate fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

mkdir -p /mnt/script
cp systemd-boot-config /mnt/script/

# Chroot
arch-chroot /mnt ./setup_arch_post.sh $part_3

printf ${CYAN}"Pre Installation is finished\n."