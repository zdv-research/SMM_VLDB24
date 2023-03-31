#!/bin/bash

echo $(basename $(pwd))

echo ""

DEV=nullblk
THREADS="1 2 4 8 12 24 36 48 72 96"
MAX_THREAD="96"
#THREADS="1 2 3 4 5 6 7 8 9 10"
#MAX_THREAD="10"

list_files () {
    FILES=$(ls -1tr **/${1}.log)
    for i in $FILES; do
        f="${i%.*}"
        echo $f
    done
}


get_from_diff () {
    # nr_tlb_remote_flush, nr_tlb_remote_flush_received
    # nr_tlb_local_flush_all, nr_tlb_local_flush_one
    for i in ${@:2}; do
        grep -w $1 $i*diff* | awk '{printf $NF "\n"}'
    done
}

get_from_sum () {
    # sum_io_thread_io_counts, sum_compute_thread_compute_counts
    # sum_mixed_thread_io_counts, sum_mixed_thread_compute_counts
    for i in ${@:2}; do
        grep -w $1 $i*log* | awk '{printf $NF/1000 "\n"}'
    done
}



case_0 () {
    FILES=$(list_files "*case-0_0IO-*COMPUTE-0MIXED_*")
    
    RESULTS=$(get_from_sum "sum_compute_thread_compute_counts" $FILES)
    TABLE=$(paste <(echo THREADS $THREADS | tr " " "\n") <(echo -e "compute/s\n$RESULTS"))

    RESULTS=$(get_from_diff "nr_tlb_remote_flush_received" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "tlb-rec\n$RESULTS"))

    echo -e "$TABLE" | column -t
}

case_1 () {
    mapping_type=$1
    rw=$2

    FILES=$(list_files "*case-1_DEV-${DEV}_*IO-0COMPUTE-0MIXED_SMALLIO${mapping_type}_SINGLE-${rw}_*")
    
    RESULTS=$(get_from_sum "sum_io_thread_io_counts" $FILES)
    TABLE=$(paste <(echo THREADS $THREADS | tr " " "\n") <(echo -e "io/s\n$RESULTS"))

    RESULTS=$(get_from_diff "nr_tlb_remote_flush_received" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "tlb-rec\n$RESULTS"))

    echo -e "$TABLE" | column -t
}

case_2 () {
    mapping_type=$1
    rw=$2

    FILES=$(list_files "*case-2_DEV-${DEV}_1IO-*COMPUTE-0MIXED_SMALLIO${mapping_type}_SINGLE-${rw}_*")
    
    RESULTS=$(get_from_sum "sum_compute_thread_compute_counts" $FILES)
    TABLE=$(paste <(echo comTHREADS "0" $THREADS | tr " " "\n") <(echo -e "compute/s\n$RESULTS"))

    RESULTS=$(get_from_sum "sum_io_thread_io_counts" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "io/s\n$RESULTS"))

    RESULTS=$(get_from_diff "nr_tlb_remote_flush_received" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "tlb-rec\n$RESULTS"))

    echo -e "$TABLE" | column -t
}

case_3 () {
    mapping_type=$1
    rw=$2

    FILES=$(list_files "*case-3_DEV-${DEV}_*IO-1COMPUTE-0MIXED_SMALLIO${mapping_type}_SINGLE-${rw}_*")
    
    RESULTS=$(get_from_sum "sum_compute_thread_compute_counts" $FILES)
    TABLE=$(paste <(echo ioTHREADS "0" $THREADS | tr " " "\n") <(echo -e "compute/s\n$RESULTS"))

    RESULTS=$(get_from_sum "sum_io_thread_io_counts" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "io/s\n$RESULTS"))

    RESULTS=$(get_from_diff "nr_tlb_remote_flush_received" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "tlb-rec\n$RESULTS"))

    echo -e "$TABLE" | column -t
}

case_5 () {
    mapping_type=$1
    rw=$2

    FILES=$(list_files "*case-5_DEV-${DEV}_0IO-0COMPUTE-*MIXED_SMALLIO${mapping_type}_SINGLE-${rw}_*")
    
    RESULTS=$(get_from_sum "sum_mixed_thread_io_counts" $FILES)
    TABLE=$(paste <(echo THREADS $THREADS | tr " " "\n") <(echo -e "compute/s\n$RESULTS"))

    RESULTS=$(get_from_sum "sum_mixed_thread_compute_counts" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "io/s\n$RESULTS"))

    RESULTS=$(get_from_diff "nr_tlb_remote_flush_received" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "tlb-rec\n$RESULTS"))

    echo -e "$TABLE" | column -t
}

case_4 () {
    mapping_type=$1
    rw=$2


    echo "tlb-rec"
    TABLE=$(echo "|TCOM.TIO- "$THREADS | tr " " "\n")
    for IOt in $THREADS; do
        FILES=$(list_files "*case-4_DEV-${DEV}_${IOt}IO-*COMPUTE-*MIXED_SMALLIO${mapping_type}_SINGLE-${rw}_*")
        RESULTS=$(get_from_diff "nr_tlb_remote_flush_received" $FILES)
        TABLE=$(paste <(echo "$TABLE") <(echo -e "$IOt\n$RESULTS"))
    done
    echo -e "$TABLE" | column -t

    echo ""; echo "io/s"
    TABLE=$(echo "|TCOM.TIO- "$THREADS | tr " " "\n")
    for IOt in $THREADS; do
        FILES=$(list_files "*case-4_DEV-${DEV}_${IOt}IO-*COMPUTE-*MIXED_SMALLIO${mapping_type}_SINGLE-${rw}_*")
        RESULTS=$(get_from_sum "sum_io_thread_io_counts" $FILES)
        TABLE=$(paste <(echo "$TABLE") <(echo -e "$IOt\n$RESULTS"))
    done
    echo -e "$TABLE" | column -t

    echo ""; echo "compute/s"
    TABLE=$(echo "|TCOM.TIO- "$THREADS | tr " " "\n")
    for IOt in $THREADS; do
        FILES=$(list_files "*case-4_DEV-${DEV}_${IOt}IO-*COMPUTE-*MIXED_SMALLIO${mapping_type}_SINGLE-${rw}_*")
        RESULTS=$(get_from_sum "sum_compute_thread_compute_counts" $FILES)
        TABLE=$(paste <(echo "$TABLE") <(echo -e "$IOt\n$RESULTS"))
    done
    echo -e "$TABLE" | column -t
}

case_b1 () {
    mapping_type=$1
    rw=$2

    FILES=$(list_files "*case-b1-single_access_offset_randomized_DEV-${DEV}_1IO-${MAX_THREAD}COMPUTE-0MIXED_SMALLIO${mapping_type}-RND_SINGLE-${rw}_*")
    
    RESULTS=$(get_from_sum "sum_compute_thread_compute_counts" $FILES)
    TABLE=$(paste <(echo THREADS $MAX_THREAD | tr " " "\n") <(echo -e "compute/s\n$RESULTS"))

    RESULTS=$(get_from_sum "sum_io_thread_io_counts" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "io/s\n$RESULTS"))

    RESULTS=$(get_from_diff "nr_tlb_remote_flush_received" $FILES)
    TABLE=$(paste <(echo "$TABLE") <(echo -e "tlb-rec\n$RESULTS"))

    echo -e "$TABLE" | column -t
}

echo "-------------------------------------------------------"
echo "Case 0: n compute workers (baseline)"
case_0
echo ""

echo "-------------------------------------------------------"
echo "Case 1: n IO workers"
echo ""
echo "TPMM=0, shared, read"; case_1 shared 0
echo ""
echo "TPMM=1, shared, read"; case_1 shared_thread_private 0
echo ""
echo "TPMM=0, private, read"; case_1 private 0
echo ""
echo "TPMM=1, private, read"; case_1 thread_private 0
echo ""
echo "TPMM=0, shared, write"; case_1 shared 1
echo ""
echo "TPMM=1, shared, write"; case_1 shared_thread_private 1
echo ""
echo "TPMM=0, private, write"; case_1 private 1
echo ""
echo "TPMM=1, private, write"; case_1 thread_private 1
echo ""

echo "-------------------------------------------------------"
echo "Case 2: 1 IO worker, n compute workers"
echo ""
echo "TPMM=0, shared, read"; case_2 shared 0
echo ""
echo "TPMM=1, shared, read"; case_2 shared_thread_private 0
echo ""
echo "TPMM=0, private, read"; case_2 private 0
echo ""
echo "TPMM=1, private, read"; case_2 thread_private 0
echo ""
echo "TPMM=0, shared, write"; case_2 shared 1
echo ""
echo "TPMM=1, shared, write"; case_2 shared_thread_private 1
echo ""
echo "TPMM=0, private, write"; case_2 private 1
echo ""
echo "TPMM=1, private, write"; case_2 thread_private 1
echo ""

echo "-------------------------------------------------------"
echo "Case 3: n IO workers, 1 compute workers"
echo ""
echo "TPMM=0, shared, read"; case_3 shared 0
echo ""
echo "TPMM=1, shared, read"; case_3 shared_thread_private 0
echo ""
echo "TPMM=0, private, read"; case_3 private 0
echo ""
echo "TPMM=1, private, read"; case_3 thread_private 0
echo ""
echo "TPMM=0, shared, write"; case_3 shared 1
echo ""
echo "TPMM=1, shared, write"; case_3 shared_thread_private 1
echo ""
echo "TPMM=0, private, write"; case_3 private 1
echo ""
echo "TPMM=1, private, write"; case_3 thread_private 1
echo ""

echo "-------------------------------------------------------"
echo "Case 5: n mixed workers"
echo ""
echo "TPMM=0, shared, read"; case_5 shared 0
echo ""
echo "TPMM=1, shared, read"; case_5 shared_thread_private 0
echo ""
echo "TPMM=0, private, read"; case_5 private 0
echo ""
echo "TPMM=1, private, read"; case_5 thread_private 0
echo ""
echo "TPMM=0, shared, write"; case_5 shared 1
echo ""
echo "TPMM=1, shared, write"; case_5 shared_thread_private 1
echo ""
echo "TPMM=0, private, write"; case_5 private 1
echo ""
echo "TPMM=1, private, write"; case_5 thread_private 1
echo ""

echo "-------------------------------------------------------"
echo "Case 4: n IO workers, n compute workers"
echo ""
echo ""
echo "TPMM=0, shared, read"; case_4 shared 0
echo ""
echo "TPMM=1, shared, read"; case_4 shared_thread_private 0
echo ""

echo "-------------------------------------------------------"
echo "Case B1: random IO offsef"
echo ""
echo ""
echo "TPMM=0, shared, read"; case_b1 shared 0
echo ""
echo "TPMM=1, shared, read"; case_b1 shared_thread_private 0
echo ""
echo "TPMM=0, private, read"; case_b1 private 0
echo ""
echo "TPMM=1, private, read"; case_b1 thread_private 0
echo ""
echo "TPMM=0, shared, write"; case_b1 shared 1
echo ""
echo "TPMM=1, shared, write"; case_b1 shared_thread_private 1
echo ""
echo "TPMM=0, private, write"; case_b1 private 1
echo ""
echo "TPMM=1, private, write"; case_b1 thread_private 1
echo ""