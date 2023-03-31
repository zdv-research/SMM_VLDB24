#!/bin/bash

source run_env.sh

#
# Case MappingTypeComparison
#

case_name="case-MappingTypeComparison"

set_run_name () {
    run_name="${io_thread_count}IO-${compute_thread_count}COMPUTE-${mixed_thread_count}MIXED"
    run_name="${run_name}_SMALLIO${mapping_type_small_io}"
    run_name="${run_name}_SINGLE-${single_access_mode}"
}

io_thread_count=1; compute_thread_count=10; mixed_thread_count=0
add_random_access_after_io="false"
add_random_access_after_compute="false"

single_access_mode="0"
single_access_offset_randomized="false"

for mapping_type_small_io in "private" "shared" "thread_private" "shared_thread_private"; do
    for single_access_mode in "0" "1"; do 
        set_run_name; run
    done
done

hard_wipe_ram