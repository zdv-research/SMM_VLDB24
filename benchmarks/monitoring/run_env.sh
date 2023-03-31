#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "Sudo required."
    exit 1
fi

############
## INCLUDES
############
source ../scripts/ram_helpers.sh
source ../scripts/cores_helper.sh

############
## PREPARE SERVER STUFF
############
sudo bash -c "echo 1 >/proc/sys/vm/overcommit_memory"
sudo systemctl stop docker.service
sudo systemctl stop containerd.service

############
## PRIVATE VARS
############
_now=$(date +%F-%H-%M-%S)
now="${now:-$_now}"
bench_bin="../microbenchmark/bin/bench"
results_dir="results_current"
current_kernel=$(uname -r)

############
## VARS and BASIC CONFIG
############
benchmark_name="$(hostname)_$current_kernel"
get_info_before_after="true"
enable_bench_monitor="true"
restrict_ram_to_gb=0

############
## RUN FUNCTION
############
run () {
    if [[ "$(early_out)" == "1" ]]; then
        echo Early out: $run_name
        return 0
    fi

    echo " "
    echo $run_name
    
    
    run_before_each

    sleep 1

    write_params

    sudo insmod /lib/modules/$(uname -r)/kernel/drivers/misc/tpmmclean.ko; sudo rmmod tpmmclean
    sudo sync
    sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    sleep 3

    # LOWER RAM
    # block_ram_up_to_gb $restrict_ram_to_gb

    # RUN BENCH MONITOR
    if [[ "${enable_bench_monitor}" == "true" ]]; then
        $bench_bin --monitor | tee $output_dir/$output_file.monitor.txt &
        bench_pid=$!
    fi

    # GET STATS BEFORE
    save_stats $output_dir/$output_file.stats-begin.txt
    cat /proc/vmstat >> $output_dir/$output_file.vmstat-begin.txt
    cat /proc/meminfo >> $output_dir/$output_file.meminfo-begin.txt

    # RUN
    run_core

    # GET STATS AFTER
    save_stats $output_dir/$output_file.stats-end.txt
    diff_stats $output_dir/$output_file.stats-begin.txt $output_dir/$output_file.stats-end.txt $output_dir/$output_file.stats-diff.txt
    cat /proc/vmstat >> $output_dir/$output_file.vmstat-end.txt
    cat /proc/meminfo >> $output_dir/$output_file.meminfo-end.txt

    # END BENCH MONITOR
    if [[ "${enable_bench_monitor}" == "true" ]]; then
        kill $bench_pid
    fi

    # END LOWER RAM
    # free_blocked_ram $restrict_ram_to_gb

    sleep 2

    run_after_each

    sudo sync
    sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    sleep 3

}

run_before_each () {
    return 0
}
run_after_each () {
    return 0
}

early_out () {
    echo 0
}

############
## helper
############
set_output_file () {
    current_now=$(date +%F-%H-%M-%S)
    output_file="${run_name}_${current_now}"
}
create_output_dir () {
    output_dir="${results_dir}/${app_name}/${benchmark_name}_${now}"
    mkdir -p $output_dir
}

save_stats () {
    cat /proc/vmstat | grep nr_tlb_ >> $1
}
diff_stat () {
    x=$(grep -iw $1 $2 | awk '{print $2}')
    y=$(grep -iw $1 $3 | awk '{print $2}')
    echo $1 $((y-x))
}
diff_stats () {
    diff_stat nr_tlb_remote_flush $1 $2 >> $3
    diff_stat nr_tlb_remote_flush_received $1 $2 >> $3
    diff_stat nr_tlb_local_flush_all $1 $2 >> $3
    diff_stat nr_tlb_local_flush_one $1 $2 >> $3
}

clean_params () {
    unset $(compgen -v "BPARAM_")
}
clean_params

write_params () {
    printenv | grep -i "BPARAM_" >> $output_dir/$output_file.params.txt
}

############
## SETUP
############
app_name="${app_name:-$"default"}"
run_name="rundefault"
run_cmd="sleep 1"
create_output_dir
set_output_file
