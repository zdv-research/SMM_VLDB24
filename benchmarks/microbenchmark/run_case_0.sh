#!/bin/bash

source run_env.sh

#
# Case 0: n compute workers (baseline)
#

case_name="case-0"


io_thread_count="0"
mixed_thread_count="0"
add_random_access_after_io="false"
add_random_access_after_compute="false"


for i in $H_CORES; do
    compute_thread_count="$i"
    run_name="${io_thread_count}IO-${compute_thread_count}COMPUTE-${mixed_thread_count}MIXED"
    run
done