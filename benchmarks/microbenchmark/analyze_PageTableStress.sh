#!/bin/bash

echo $(basename $(pwd))
cd case-PageTableStress


DEVICE="nullblk"
#DEVICE="optane"

CFs="0.5 1 2 3 4 8"
#CFs="0.5 1 2 4 8"
PGs="16 64 128 256 512 1024 4096 16385"

#THREADS="1 2 4 8 12 24 36 48 72 96"
#THREADS="1 2 4 8 12 24 36 48"
THREADS="1 2 3 4 5 6 7 8 9 10"

#THREAD_MAX="96"
THREAD_MAX="10"

TAIL="200"

echo "t$TAIL" "threadmax$THREAD_MAX"
echo ""

calc () {
    cat $1 | grep -w $2 | tail -n $TAIL | awk '{print $NF}' | awk '{s+=$1}END{print s/NR}' RS="\n"
}

get_first () {
    echo $1 | awk '{print $1}'
}


for VAR in "compute_thread_compute_count" "tlb_shootdowns"; do
for MODE in "shared" "shared_thread_private"; do

    if [[ "${MODE}" == "shared" ]]; then
        echo -n TPMM=0
    else
         echo -n TPMM=1
    fi  
    echo ", $MODE, $VAR"


    do_table () {

        echo -n "- "
        for CF in $CFs; do
            echo -n "CF=$CF "
        done

        echo ""

    

        for PG in $PGs; do
            echo -n "PG=$PG "
            for CF in $CFs; do
                echo -n "$(calc $(get_first *DEV-${DEVICE}*${THREAD_MAX}COMPUTE*IO${MODE}_R*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
            done
            echo ""
        done

    }
    do_table | column -t
    echo ""
done
done


for MODE in "shared" "shared_thread_private"; do

    if [[ "${MODE}" == "shared" ]]; then
        echo -n TPMM=0
    else
         echo -n TPMM=1
    fi  
    echo ", $MODE, no memory access in computes."


    do_table () {

        for CF in $CFs; do
            echo -n "CF=$CF "
        done

        echo ""

        for CF in $CFs; do

            echo -n "$(calc *DEV-${DEVICE}*${THREAD_MAX}COMPUTE*IO${MODE}_R*MEMINTCOMP-false*_CF-${CF}*log compute_thread_compute_count) "

        done
        echo ""
    }
    do_table | column -t
    echo ""
done



PG=128
VAR="compute_thread_compute_count"
VAR2="tlb_shootdowns"
for CF in "1" "2"; do
    echo "CF=$CF, PG=128, shared read, scalability"

    do_table () {
        echo threads TPMM-0_$VAR TPMM-1_$VAR TPMM-0_$VAR2 TPMM-1_$VAR2
        for THREAD in $THREADS; do
            echo -n "$THREAD "
            echo -n "$(calc $(get_first *DEV-${DEVICE}*-${THREAD}COMPUTE*IOshared_R*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
            echo -n "$(calc $(get_first *DEV-${DEVICE}*-${THREAD}COMPUTE*IOshared_thread_private_R*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
            echo -n "$(calc $(get_first *DEV-${DEVICE}*-${THREAD}COMPUTE*IOshared_R*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR2) "
            echo -n "$(calc $(get_first *DEV-${DEVICE}*-${THREAD}COMPUTE*IOshared_thread_private_R*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR2) "
            echo ""
        done

    }
    do_table | column -t
    echo ""
done


PG=128
CF=2

for CF in "1" "2"; do
    echo "CF=$CF, PG=128, mode comparison"

    do_table () {
        echo TPMM shared_read_COM private_read_COM shared_write_COM shared_read_TLB private_read_TLB shared_write_TLB

        echo -n "0 "
        for VAR in "compute_thread_compute_count" "tlb_shootdowns"; do
            echo -n "$(calc $(get_first *DEV-${DEVICE}*${THREAD_MAX}COMPUTE*IOshared*RANDOM-0*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
            echo -n "$(calc $(get_first *DEV-${DEVICE}*${THREAD_MAX}COMPUTE*IOprivate*RANDOM-0*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
            echo -n "$(calc $(get_first *DEV-${DEVICE}*${THREAD_MAX}COMPUTE*IOshared*RANDOM-1*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
        done
        echo ""
        echo -n "1 "
        for VAR in "compute_thread_compute_count" "tlb_shootdowns"; do
            echo -n "$(calc $(get_first *DEV-${DEVICE}*${THREAD_MAX}COMPUTE*IOshared_thread_private*RANDOM-0*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
            echo -n "$(calc $(get_first *DEV-${DEVICE}*${THREAD_MAX}COMPUTE*IOthread_private*RANDOM-0*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
            echo -n "$(calc $(get_first *DEV-${DEVICE}*${THREAD_MAX}COMPUTE*IOshared_thread_private*RANDOM-1*MEMINTCOMP-true*_CF-${CF}_PG-${PG}*log) $VAR) "
        done
        echo ""
    }
    do_table | column -t


    echo ""
done

