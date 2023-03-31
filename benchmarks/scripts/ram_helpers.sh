#!/bin/bash


if [[ "$(hostname)" == *"pbar"* ]]; then
    ram_block_bin="/home/fred_root/TLB/tlb_shootdown/benchmarks/tool_alloc/block_memory_kb.bin"
else
    ram_block_bin="/home/fred/TLB/tlb_shootdown/benchmarks/tool_alloc/block_memory_kb.bin"
fi



block_ram () {
    sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    _block_ram_kb=$1
    if (( _block_ram_kb > 0 )); then
        sleep 3
        if [[ "$(hostname)" == *"epyc"* ]]; then
            numactl --cpunodebind 0 $ram_block_bin $((_block_ram_kb/2)) &
            ram_block_pid_0=$!
            numactl --cpunodebind 1 $ram_block_bin $((_block_ram_kb/2)) &
            ram_block_pid_1=$!
        elif [[ "$(hostname)" == *"cala"* ]]; then
            numactl --cpunodebind 0 $ram_block_bin $((_block_ram_kb/4)) &
            ram_block_pid_0=$!
            numactl --cpunodebind 1 $ram_block_bin $((_block_ram_kb/4)) &
            ram_block_pid_1=$!
            numactl --cpunodebind 2 $ram_block_bin $((_block_ram_kb/4)) &
            ram_block_pid_2=$!
            numactl --cpunodebind 3 $ram_block_bin $((_block_ram_kb/4)) &
            ram_block_pid_3=$!
            # $ram_block_bin $((_block_ram_kb/8)) &
            # ram_block_pid_4=$!
            # $ram_block_bin $((_block_ram_kb/8)) &
            # ram_block_pid_5=$!
            # $ram_block_bin $((_block_ram_kb/8)) &
            # ram_block_pid_6=$!
            # $ram_block_bin $((_block_ram_kb/8)) &
            # ram_block_pid_7=$!
        else
            $ram_block_bin $_block_ram_kb &
            ram_block_pid=$!
        fi
        if [[ "$(hostname)" == *"pbar"* ]]; then
            sleep 50
        else
            sleep 60
        fi
        
        sudo sync
        sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    fi
}

block_ram_gb () {
    _gb=$1
    block_ram $((_gb*1024*1024))
}

block_ram_up_to_gb () {
    sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sync

    _block_ram_to_gb=$1
    if (( _block_ram_to_gb > 0 )); then
        sleep 5

        _total_ram_kb=$(grep MemFree /proc/meminfo | tr -d -c 0-9)
        _block_ram_kb=$((_total_ram_kb-(_block_ram_to_gb*1024*1024)))

        block_ram $_block_ram_kb
    fi
}

free_blocked_ram () {
    _block_ram_kb=$1
    if (( _block_ram_kb > 0 )); then
        if [[ "$(hostname)" == *"epyc"* ]]; then
            kill $ram_block_pid_0; kill $ram_block_pid_1
        elif [[ "$(hostname)" == *"cala"* ]]; then
            kill $ram_block_pid_0; kill $ram_block_pid_1; kill $ram_block_pid_2; kill $ram_block_pid_3
            # kill $ram_block_pid_4; kill $ram_block_pid_5; kill $ram_block_pid_6; kill $ram_block_pid_7
        else
            kill $ram_block_pid
        fi
    fi
    sleep 13
}

hard_wipe_ram () {
    echo Wiping Ram..
    sudo runuser -l fred -c 'tail /dev/zero'
}