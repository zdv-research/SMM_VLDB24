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
echo never > /sys/kernel/mm/transparent_hugepage/enabled

############
## PRIVATE VARS
############
_now=$(date +%F-%H-%M-%S)
now="${now:-$_now}"
bin="./bin/bench"
results_dir="results_current"
current_kernel=$(uname -r)

############
## VARS and BASIC CONFIG
############
dummy="false"
benchmark_name="$(hostname)_$current_kernel"
#benchmark_name="zbar.5.15.12.tpmm"
hwthread_number=$(nproc)
core_number="$((hwthread_number/2))" 
#device="/home/fred/misc/reserve_rand"
#device="/home/fred/misc/reserve_zero"
# device="/dev/nullb1"
# file_size_kb="1992294400" # 1024=1MB   1048576=1GB   104857600=100GB   1992294400=1.9TB 19922944000=19TB
device="/dev/sdb"
file_size_kb="604857600" # 1024=1MB   1048576=1GB   104857600=100GB   1992294400=1.9TB 19922944000=19TB
round_nr="20"
round_length_ms="500"
io_thread_io_size_kb="4"
mixed_thread_io_size_kb="4"
compute_thread_computeload_factor="1.0"
mixed_thread_computeload_factor="1.0"
madvise_dontneed_whole_file="false"
madvise_dontneed_for_random_acceses="false"
do_periodically_madvise_dontneed_whole_file="false"
periodically_madvise_dontneed_whole_file_period_ms="10000"
mapping_type_complete_file="shared"
mapping_type_small_io="shared"
fastmap_device="/dev/dmap/dmap1"
fastmap_enabled="false"
single_access_mode="0"
random_access_mode="0"
single_access_offset_randomized="false"
memintensive_compute_operations="false"
compute_thread_memintense_pages="128"


############
## AUTO_OPTIONS
############
# if [[ "${current_kernel}" == *"fastmap"* ]]; then
# if [[ "${current_kernel}" == *"4.14.262"* ]]; then
#     OPTIONS_FASTMAP="false true"
# else
#     OPTIONS_FASTMAP="false"
# fi
OPTIONS_FASTMAP="false"

TARGET_DEVICE="nullblk"

############
## RUN FUNCTION
############
run () {
    device="/dev/nullb1"
    file_size_kb="1992294400" # 1024=1MB   1048576=1GB   104857600=100GB   1992294400=1.9TB 19922944000=19TB
        
    if [[ "${TARGET_DEVICE}" == "ssd" ]]; then
        if [[ "$(hostname)" == *"epyc"* ]]; then
            device="/dev/sdb"
            file_size_kb="604857600"
        elif [[ "$(hostname)" == *"cala"* ]]; then
            device="/dev/nvme0n1p1"
            file_size_kb="604857600"
        elif [[ "$(hostname)" == *"pbar"* ]]; then
            device="/dev/nvme1n1p2"
            file_size_kb="604857600"
        else
            echo "Early out for ${run_name}"
            return 0
        fi
    fi
    if [[ "${TARGET_DEVICE}" == "optane" ]]; then
        if [[ "$(hostname)" == *"cala"* ]]; then
            device="/dev/nvme3n1p1"
            file_size_kb="340000000" 
        else
            echo "Early out for ${run_name}"
            return 0
        fi
    fi
    if [[ "${TARGET_DEVICE}" == "pmem" ]]; then
        if [[ "$(hostname)" == *"pbar"* ]]; then
            device="/dev/pmem0"
            #file_size_kb="750000000" 
            # One dimm failed...
            file_size_kb="500000000" 
        else
            echo "Early out for ${run_name}"
            return 0
        fi
    fi

    set_output_file
    create_output_dir

    if [[ "$fastmap_enabled" == "true" ]] ; then 
        if (( (io_thread_count+mixed_thread_count) > 1 )); then 
            echo "Early out for ${run_name}"
            return 0
        fi
        if [[ "$add_random_access_after_compute" == "true" || "$add_random_access_after_io" == "true" ]]; then 
            if (( (io_thread_count+mixed_thread_count) >= 1 )); then 
                echo "Early out for ${run_name}"
                return 0
            fi
        fi
    fi

    echo Run \"${run_name}\" of benchmark \"${benchmark_name}\"

    sleep 1

    sudo insmod /lib/modules/$(uname -r)/kernel/drivers/misc/tpmmclean.ko; sudo rmmod tpmmclean
    sudo sync
    sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
    sleep 3

    # GET STATS BEFORE
    save_stats $output_dir/$output_file.stats-begin.txt

    # Folowing line not working, Fastmap cleares caches automatically
    # if [[ "$fastmap_enabled" == "true" ]] ; then sudo bash -c "echo 1 > /sys/class/dmap/0_buffer_state"; fi

    if [[ "$(hostname)" == *"cala"* || "$(hostname)" == *"epyc"* ]]; then
        THREADS=$((io_thread_count+compute_thread_count+mixed_thread_count))
        if (( THREADS > H_CORES_MAX )); then
            THREADS=$H_CORES_MAX
        fi
        echo THREADS $THREADS
        bin="taskset -c $(get_even_binding_cpus $THREADS) $bin"
    fi

    $bin \
    "--dummy=$dummy" \
    "--device=$device" \
    "--file_size_kb=$file_size_kb" \
    "--process_count=1" \
    "--process_id=0" \
    "--round_nr=$round_nr" \
    "--round_length_ms=$round_length_ms" \
    "--io_thread_count=$io_thread_count" \
    "--io_thread_io_size_kb=$io_thread_io_size_kb" \
    "--compute_thread_count=$compute_thread_count" \
    "--compute_thread_computeload_factor=$compute_thread_computeload_factor" \
    "--mixed_thread_count=$mixed_thread_count" \
    "--mixed_thread_io_size_kb=$mixed_thread_io_size_kb" \
    "--mixed_thread_computeload_factor=$mixed_thread_computeload_factor" \
    "--add_random_access_after_io=$add_random_access_after_io" \
    "--add_random_access_after_compute=$add_random_access_after_compute" \
    "--madvise_dontneed_whole_file=$madvise_dontneed_whole_file" \
    "--madvise_dontneed_for_random_acceses=$madvise_dontneed_for_random_acceses" \
    "--do_periodically_madvise_dontneed_whole_file=$do_periodically_madvise_dontneed_whole_file" \
    "--periodically_madvise_dontneed_whole_file_period_ms=$periodically_madvise_dontneed_whole_file_period_ms" \
    "--mapping_type_complete_file=$mapping_type_complete_file" \
    "--mapping_type_small_io=$mapping_type_small_io" \
    "--fastmap_device=$fastmap_device" \
    "--fastmap_enabled=$fastmap_enabled" \
    "--random_access_mode=$random_access_mode" \
    "--single_access_mode=$single_access_mode" \
    "--single_access_offset_randomized=$single_access_offset_randomized" \
    "--memintensive_compute_operations=$memintensive_compute_operations" \
    "--compute_thread_memintense_pages=$compute_thread_memintense_pages" \
    | tee "$output_dir/$output_file.log"

    # GET STATS AFTER
    save_stats $output_dir/$output_file.stats-end.txt
    diff_stats $output_dir/$output_file.stats-begin.txt $output_dir/$output_file.stats-end.txt $output_dir/$output_file.stats-diff.txt
    rm $output_dir/$output_file.stats-begin.txt $output_dir/$output_file.stats-end.txt
}
# run () {
#     echo Run \"${run_name}\" of benchmark \"${benchmark_name}\"
# }

############
## helper
############
set_output_file () {
    current_now=$(date +%F-%H-%M-%S)
    output_file="${benchmark_name}_${case_name}_${run_name}_${current_now}"
}
create_output_dir () {
    output_dir="${results_dir}/${benchmark_name}_${now}/${case_name}"
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


############
## SETUP
############
run_name="default"
case_name="casedefault"
set_output_file


set RUN_ENV_IS_SETUP