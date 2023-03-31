#!/bin/bash

app_name="ycsb"
source ../scripts/kill_background.sh; sleep 1
source run_env.sh

TLB_DIR="/home/fred/TLB"
YCSB_DIR="$TLB_DIR/tlb_shootdown/third_party/YCSB-cpp"

export BPARAM_app="$app_name"
export BPARAM_kernel=$(uname -r)
export BPARAM_database="leveldb"
export BPARAM_size_Mop=6
export BPARAM_run_type="run" # load run
export BPARAM_workload="a"
#export BPARAM_database_path="$TLB_DIR/tmp/ycsb_DB"
export BPARAM_database_path="/home/fred/mounts/ext4ramdisk/ycsb_DB"
export BPARAM_tpmm=0
export BPARAM_fastmap=0
export BPARAM_threads=10
export BPARAM_limit_ram=10

restrict_ram_to_gb=$BPARAM_limit_ram


early_out () {
    # if fastmap and not fastmap kernel
    if [[ "$BPARAM_fastmap" == "1" ]]; then
        if [[ "$(uname -r)" != *"fastmap"* ]]; then
            echo 1
        fi
    fi
    
    # if tpmm and not tpmm.sec kernel
    if [[ "$BPARAM_tpmm" == "1" ]]; then
        if [[ "$(uname -r)" != *"tpmm.sec-and-kswapd"* ]]; then
            echo 1
        fi
    fi

    echo 0
}

run_before_each () {
   if [[ "${BPARAM_run_type}" == "load" ]]; then
       rm -rf ${BPARAM_database_path}_${BPARAM_database}
   fi
}

run_core () {
    YCSB_BIN=${YCSB_DIR}/ycsb_${BPARAM_database}

    if [[ "${BPARAM_tpmm}" == "1" ]]; then
        YCSB_BIN=${YCSB_BIN}_tpmm
    fi

    LIB_PATH=""
    if [[ "${BPARAM_database}" == "lmdb" ]]; then
        if [[ "${BPARAM_tpmm}" == "0" ]]; then
            LIB_PATH=$TLB_DIR/tlb_shootdown/third_party/lmdb/libraries/liblmdb
        else
            LIB_PATH=$TLB_DIR/tlb_shootdown/third_party/lmdb_tpmm/libraries/liblmdb
        fi
    fi
    #LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LIB_PATH numactl --cpunodebind=0 $YCSB_BIN -$BPARAM_run_type \

    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LIB_PATH taskset -c 0-$((BPARAM_threads-1)) $YCSB_BIN -$BPARAM_run_type \
        -db $BPARAM_database \
        -P $YCSB_DIR/workloads/workload$BPARAM_workload \
        -P $YCSB_DIR/$BPARAM_database/$BPARAM_database.properties \
        -s \
        -p status.interval=1 \
        -p leveldb.dbname=${BPARAM_database_path}_leveldb \
        -p lmdb.dbpath=${BPARAM_database_path}_lmdb \
        -p leveldb.compression=snappy \
        -p recordcount=$((1024*1024*BPARAM_size_Mop)) \
        -p operationcount=$((1024*1024*BPARAM_size_Mop)) \
        -threads $BPARAM_threads \
        | tee $output_dir/$output_file.log.txt

    sleep 1

# Options:
#   -load: run the loading phase of the workload
#   -t: run the transactions phase of the workload
#   -run: same as -t
#   -threads n: execute using n threads (default: 1)
#   -db dbname: specify the name of the DB to use (default: basic)
#   -P propertyfile: load properties from the given file. Multiple files can
#                    be specified, and will be processed in the order specified
#   -p name=value: specify a property to be passed to the DB and workloads
#                  multiple properties can be specified, and override any
#                  values in the propertyfile
#   -s: print status every 10 seconds (use status.interval prop to override)
}

set_and_run () {
    run_name="DB-${BPARAM_database}_MOP-${BPARAM_size_Mop}_RAM-${BPARAM_limit_ram}_TYPE-${BPARAM_run_type}_WORKLOAD-${BPARAM_workload}_THREADS-${BPARAM_threads}_TPMM-${BPARAM_tpmm}_FASTMAP_${BPARAM_fastmap}"
    set_output_file
    run
}

df -h >> $output_dir/$output_file.df.txt

# for BPARAM_tpmm in "0"; do
#     for BPARAM_threads in "48"; do

#     for BPARAM_size_Mop in "40"; do
#         BPARAM_database="lmdb";
#         BPARAM_run_type="load"; BPARAM_workload="a"; set_and_run
#     done

#     done
# done

for BPARAM_tpmm in "0" "1"; do
    #for BPARAM_threads in "48" "24" "12" "6"; do
    for BPARAM_threads in "48"; do

    for BPARAM_size_Mop in "20"; do
        BPARAM_database="lmdb";
        BPARAM_run_type="load"; BPARAM_workload="a"; set_and_run

        BPARAM_run_type="run"; BPARAM_workload="c"; set_and_run
        BPARAM_run_type="run"; BPARAM_workload="c"; set_and_run
        BPARAM_run_type="run"; BPARAM_workload="c"; set_and_run

        # BPARAM_run_type="run"; BPARAM_workload="a"; set_and_run
        # BPARAM_run_type="run"; BPARAM_workload="a"; set_and_run

        # BPARAM_run_type="run"; BPARAM_workload="b"; set_and_run
        # BPARAM_run_type="run"; BPARAM_workload="b"; set_and_run

    done

    done
done

hard_wipe_ram

# for BPARAM_threads in "10"; do
#     for BPARAM_tpmm in "0" "1"; do
#         BPARAM_database="lmdb";
#         BPARAM_run_type="load"; BPARAM_workload="a"; set_and_run
#         BPARAM_run_type="run"; BPARAM_workload="a"; set_and_run
#         BPARAM_run_type="run"; BPARAM_workload="b"; set_and_run

#         # BPARAM_database="leveldb";
#         # BPARAM_run_type="load"; BPARAM_workload="a"; set_and_run
#         # BPARAM_run_type="run"; BPARAM_workload="a"; set_and_run
#         # BPARAM_run_type="run"; BPARAM_workload="b"; set_and_run
#     done
# done





