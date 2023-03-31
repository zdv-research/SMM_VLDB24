#!/bin/bash

H_MOUNTS_DIR="/home/fred/mounts"

mkdir -p $H_MOUNTS_DIR

h_mount_ram_real_fs () {

    mkdir -p $H_MOUNTS_DIR/ramdisks
    mount -t ramfs ramfs $H_MOUNTS_DIR/ramdisks

    GBSIZE="$1"
    
    if [[ "$(hostname)" == *"epyc"* ]]; then
        numactl --cpunodebind 0 dd if=/dev/zero of=$H_MOUNTS_DIR/ramdisks/ext4.image bs=1G count=1
        for((i=1;i<GBSIZE;i++)); do
            echo bind $((i%2))
            numactl --cpunodebind $((i%2)) dd if=/dev/zero of=$H_MOUNTS_DIR/ramdisks/ext4.image bs=1G count=1 oflag=append conv=notrunc
        done
    elif [[ "$(hostname)" == *"cala"* ]]; then
        numactl --cpunodebind 0 dd if=/dev/zero of=$H_MOUNTS_DIR/ramdisks/ext4.image bs=1G count=1
        for((i=1;i<GBSIZE;i++)); do
            echo bind $((i%4))
            numactl --cpunodebind $((i%4)) dd if=/dev/zero of=$H_MOUNTS_DIR/ramdisks/ext4.image bs=1G count=1 oflag=append conv=notrunc
        done
    else
        dd if=/dev/zero of=$H_MOUNTS_DIR/ramdisks/ext4.image bs=1G count=$1
    fi

    mkfs.ext4 $H_MOUNTS_DIR/ramdisks/ext4.image
    mkdir -p $H_MOUNTS_DIR/ext4ramdisk
    mount -o loop $H_MOUNTS_DIR/ramdisks/ext4.image $H_MOUNTS_DIR/ext4ramdisk

}

h_mount_optanessd () {
    mkfs.ext4 -F /dev/nvme3n1p1
    mkdir -p $H_MOUNTS_DIR/ext4optane
    mount /dev/nvme3n1p1 $H_MOUNTS_DIR/ext4optane
}

h_mount_nvme_cala () {
    mkfs.ext4 -F /dev/nvme0n1p1
    mkdir -p $H_MOUNTS_DIR/ext4nvme
    mount /dev/nvme0n1p1 $H_MOUNTS_DIR/ext4nvme
}

h_mount_ssd_epyc () {
    mkdir -p $H_MOUNTS_DIR/ext4ssd
}



h_unmount_all () {
    umount -f $H_MOUNTS_DIR/ext4ramdisk
    if [[ "$(hostname)" == *"cala"* ]]; then umount -f $H_MOUNTS_DIR/ext4optane; fi
    if [[ "$(hostname)" == *"cala"* ]]; then umount -f $H_MOUNTS_DIR/ext4nvme; fi
    sleep 1
    rm -rf $H_MOUNTS_DIR/ext4ramdisk
    rm -rf $H_MOUNTS_DIR/ramdisks/*
    if [[ "$(hostname)" == *"cala"* ]]; then rm -rf $H_MOUNTS_DIR/ext4optane; fi
    if [[ "$(hostname)" == *"cala"* ]]; then rm -rf $H_MOUNTS_DIR/ext4nvme; fi
    if [[ "$(hostname)" == *"epyc"* ]]; then rm -rf $H_MOUNTS_DIR/ext4ssd; fi
    sleep 1
    umount -f $H_MOUNTS_DIR/ramdisks
    rm -rf $H_MOUNTS_DIR/ramdisks


}

if [[ "$1" == "m" ]]; then
    h_mount_ram_real_fs 100
    if [[ "$(hostname)" == *"cala"* ]]; then h_mount_optanessd; fi
    if [[ "$(hostname)" == *"cala"* ]]; then h_mount_nvme_cala; fi
    if [[ "$(hostname)" == *"epyc"* ]]; then h_mount_ssd_epyc; fi
fi

if [[ "$1" == "optane" ]]; then
    if [[ "$(hostname)" == *"cala"* ]]; then h_mount_optanessd; fi
fi

if [[ "$1" == "nvme" ]]; then
    if [[ "$(hostname)" == *"cala"* ]]; then h_mount_nvme_cala; fi
fi

if [[ "$1" == "u" ]]; then
    h_unmount_all
fi