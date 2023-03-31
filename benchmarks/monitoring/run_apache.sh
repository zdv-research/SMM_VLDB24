#!/bin/bash

app_name="apache"
source ../scripts/kill_background.sh; sleep 1
source run_env.sh

echo never > /sys/kernel/mm/transparent_hugepage/enabled

TLB_DIR="/home/fred/TLB"

enable_bench_monitor="false"

export BPARAM_app="$app_name"
export BPARAM_kernel=$(uname -r)
export BPARAM_tpmm=0
export BPARAM_fastmap=0
export BPARAM_threads=10
export BPARAM_producer_threads=6
export BPARAM_producer_duration=30
export BPARAM_numaseperate=1
export BPARAM_taskset_even=0

early_out () {
    # if fastmap (because fastmap not working)
    if [[ "$BPARAM_fastmap" == "1" ]]; then
        echo 1
    fi

    # if tpmm and not tpmm kernel (mmap/munmap tpmm works in contrast to kswapd-tpmm without sec implementatiion)
    if [[ "$BPARAM_tpmm" == "1" ]]; then
        if [[ "$(uname -r)" != *"tpmm"* ]]; then
            echo 1
        fi
    fi

    echo 0
}

run_before_each () {
    return 0
}

run_core () {

    if [[ "${BPARAM_tpmm}" == "1" ]]; then
        APACHE_DIR="${TLB_DIR}/httpd_install_tpmm"
    else
        APACHE_DIR="${TLB_DIR}/httpd_install"
    fi

    cp -f ${TLB_DIR}/tlb_shootdown/benchmarks/apache/httpd.conf ${APACHE_DIR}/conf/httpd.conf
    cp -f ${TLB_DIR}/tlb_shootdown/benchmarks/apache/httpd-mpm.conf ${APACHE_DIR}/conf/extra/httpd-mpm.conf

    APACHE_CMD="${APACHE_DIR}/bin/apachectl -f ${APACHE_DIR}/conf/httpd.conf"
    WRK_BIN="${TLB_DIR}/wrk/wrk"

    #CALA no 1 1,2 1,2,3
    #EPYC no 1

    if [[ "$(hostname)" == *"epyc"* ]]; then
        NUMA_BIND="1"
    elif [[ "$(hostname)" == *"cala"* ]]; then
        NUMA_BIND="1,2,3"
    else
        NUMA_BIND="0"
    fi

    TASKSET_CMD="taskset -c 0-$((BPARAM_threads-1))"
    if [[ "${BPARAM_taskset_even}" == "1" ]]; then
        TASKSET_CMD="taskset -c $(get_even_binding_cpus $BPARAM_threads)"
    fi
    if [[ "${BPARAM_taskset_even}" == "x" ]]; then
        TASKSET_CMD=""
    fi
    if [[ "${BPARAM_threads}" == "0" ]]; then
        TASKSET_CMD=""
    fi

    NUMA_CMD=""
    if [[ "${BPARAM_numaseperate}" == "1" ]]; then
        NUMA_CMD="numactl --cpunodebind=${NUMA_BIND}"
    fi

    APACHE_CMD="${NUMA_CMD} ${TASKSET_CMD} ${APACHE_CMD}"

    # if [[ "${BPARAM_numaseperate}" != "0" ]]; then
    #     if [[ "${BPARAM_threads}" != "0" ]]; then
    #         APACHE_CMD="numactl --cpunodebind=${NUMA_BIND} taskset -c $(get_even_binding_cpus $BPARAM_threads) ${APACHE_CMD}"
    #     else
    #         APACHE_CMD="numactl --cpunodebind=${NUMA_BIND} ${APACHE_CMD}"
    #     fi
    # else
    #     if [[ "${BPARAM_threads}" != "0" ]]; then
    #         APACHE_CMD="taskset -c $(get_even_binding_cpus $BPARAM_threads) ${APACHE_CMD}"
    #     else
    #         APACHE_CMD="${APACHE_CMD}"
    #     fi
    # fi
   
    $APACHE_CMD

    sleep 1

    numactl --cpunodebind=0 $WRK_BIN -c 400 -t $BPARAM_producer_threads -d ${BPARAM_producer_duration}s http://127.0.0.1:80 | tee $output_dir/$output_file.log.txt

}

run_after_each () {
    $APACHE_DIR/bin/apachectl -k stop
    pkill -f "httpd"
}

set_and_run () {
    run_name="DURATION-${BPARAM_producer_duration}_PRODTHREADS-${BPARAM_producer_threads}_THREADS-${BPARAM_threads}_TPMM-${BPARAM_tpmm}_FASTMAP_${BPARAM_fastmap}"
    run_name="${run_name}_NUMASEPERATE-${BPARAM_numaseperate}"
    run_name="${run_name}_TSeven-${BPARAM_taskset_even}"
    set_output_file
    run
}

ITERATIONS=3

for BPARAM_producer_threads in "12" "6"; do

for BPARAM_taskset_even in "1"; do

for BPARAM_numaseperate in "0"; do

    for BPARAM_tpmm in "0" "1"; do

        # Looking for best BPARAM_producer_threads
        # for BPARAM_producer_threads in "1" "2" "3" "4" "5" "6" "7" "8"; do
        #     for BPARAM_threads in "0" "1" "5" "10" "20"; do
        #         set_and_run
        #     done
        # done

        # for((i=0;i<5;i++)); do
        #     for BPARAM_producer_threads in "6"; do
        #         for BPARAM_threads in "0"; do
        #             set_and_run
        #         done
        #     done
        # done

        for((i=0;i<ITERATIONS;i++)); do
            #
                for BPARAM_threads in $H_CORES; do
                #for BPARAM_threads in $H_CORES_INKL_0; do
                #for BPARAM_threads in "1" "4" "12" "24" "48" "96"; do
                    set_and_run
                done
            #done
        done
    done
done
done
done


