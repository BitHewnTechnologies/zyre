#!/usr/bin/env bash
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################

if [ ! -f $PWD/raspbian_lite_latest.zip ]; then
    wget --connect-timeout=10 https://downloads.raspberrypi.org/raspbian_lite_latest -O raspbian_lite_latest.zip
fi

RASPBIAN_IMG=$(unzip -Z1 raspbian_lite_latest.zip)
if [ ! -f $PWD/$RASPBIAN_IMG ]; then
    unzip raspbian_lite_latest.zip
fi

if [ ! -f $PWD/raspbian_zyre.img ]; then

# Allocate disk space for extended image
truncate -s 1536M raspbian_zyre.img

# Begin partitioning disk image.
# Creating two partitions:
# BOOT = 100 MB
# ROOT = 1536 MB
fdisk raspbian_zyre.img <<EOF
o
n
p
1

+100M

t
c
n
p
2


w
EOF

# Create a loop device and mount the extended image's partitions
export LOOPDEV_EX="$(losetup --show --find raspbian_zyre.img)"

# Use sudo kpartx to create partitions in /dev/mapper
kpartx -av $LOOPDEV_EX
dmsetup --noudevsync mknodes

# Create partition names to mount
export BOOTPARTION_EX=$(echo $LOOPDEV_EX | sed 's|'/dev'/|'/dev/mapper/'|')p1
export ROOTPARTION_EX=$(echo $LOOPDEV_EX | sed 's|'/dev'/|'/dev/mapper/'|')p2

# Create file systems for the partitions
mkfs.vfat $BOOTPARTION_EX
mkfs.ext4 $ROOTPARTION_EX

# Create a loop device and mount the original image's partitions
export LOOPDEV_ORIG="$(losetup --show --find $RASPBIAN_IMG)"

# Use sudo kpartx to create partitions in /dev/mapper
kpartx -av $LOOPDEV_ORIG
dmsetup --noudevsync mknodes

# Create partition names to mount
export BOOTPARTION_ORIG=$(echo $LOOPDEV_ORIG | sed 's|'/dev'/|'/dev/mapper/'|')p1
export ROOTPARTION_ORIG=$(echo $LOOPDEV_ORIG | sed 's|'/dev'/|'/dev/mapper/'|')p2

# Copy data from original image to extended image
dd if=$BOOTPARTION_ORIG of=$BOOTPARTION_EX bs=64K conv=noerror,sync
dd if=$ROOTPARTION_ORIG of=$ROOTPARTION_EX bs=64K conv=noerror,sync

# Remove loop devices for original image
dmsetup clear $BOOTPARTION_ORIG
dmsetup clear $ROOTPARTION_ORIG
dmsetup remove $BOOTPARTION_ORIG
dmsetup remove $ROOTPARTION_ORIG
losetup -d $LOOPDEV_ORIG
fi

# Try to mount extended image
if [ -z "$(mount|grep raspbian-boot)" ] && [ -z "$(mount|grep raspbian-root)" ]; then

    # Create a loop device and mount the disk image
    export LOOPDEV_EX="$(losetup --show --find ./raspbian_zyre.img)"

    # Use sudo kpartx to create partitions in /dev/mapper
    kpartx -av $LOOPDEV_EX
    dmsetup --noudevsync mknodes

    # Create partition names to mount
    export BOOTPARTION_EX=$(echo $LOOPDEV_EX | sed 's|'/dev'/|'/dev/mapper/'|')p1
    export ROOTPARTION_EX=$(echo $LOOPDEV_EX | sed 's|'/dev'/|'/dev/mapper/'|')p2

    # Make sure mount points exist and are clean
    mkdir -p raspbian-boot
    mkdir -p raspbian-root
    rm -rf raspbian-boot/*
    rm -rf raspbian-root/*

    # Mount partitions
    mount $BOOTPARTION_EX -t vfat raspbian-boot
    mount $ROOTPARTION_EX -t ext4 raspbian-root
else
    echo "Image already mounted!"
fi

################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################
