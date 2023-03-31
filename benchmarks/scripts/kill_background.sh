#!/bin/bash
if [[ $UID != 0 ]]; then
    echo "Sudo required."
    exit 1
fi

pkill -f "bench --monitor"
pkill -f "limit_memory_to_gb"
pkill -f "block_memory_kb"
pkill -f "httpd"

sudo sync
sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
