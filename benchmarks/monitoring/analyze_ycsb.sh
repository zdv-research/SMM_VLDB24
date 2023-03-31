#!/bin/bash

echo $(basename $(pwd))

echo ""

if [[ "$(ls -1 *log* | head -n1)" == *"_DEV-"* ]]; then
    HEADER="- - - - - - secs throughput nr_tlb_remote nr_tlb_remote_rec nr_tlb_local_all nr_tlb_local_one"
    TABLE=$(ls -1 *log* | column -t -s'_' | awk '{ print $1" "$2" "$3" "$4" "$7" "$8 }')
else
    HEADER="- - - - - secs throughput nr_tlb_remote nr_tlb_remote_rec nr_tlb_local_all nr_tlb_local_one"
    TABLE=$(ls -1 *log* | column -t -s'_' | awk '{ print $1" "$2" "$3" "$6" "$7 }')
fi


RUNTIMES=$(grep runtime *log*)
RUNTIMES_NO=$(grep -L runtime *log*  | awk '{printf $0 " -\n"}')
RUNTIMES=$( (echo -e "$RUNTIMES"; echo -e "$RUNTIMES_NO") | sort)
RUNTIMES=$(echo -e "$RUNTIMES" | column -t | awk '{printf $NF "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$RUNTIMES")) 

THROUGHPUT=$(grep throughput *log*)
THROUGHPUT_NO=$(grep -L runtime *log*  | awk '{printf $0 " -\n"}')
THROUGHPUT=$( (echo -e "$THROUGHPUT"; echo -e "$THROUGHPUT_NO") | sort)
THROUGHPUT=$(echo -e "$THROUGHPUT" | column -t | awk '{printf $NF "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$THROUGHPUT")) 

TLB_SEND=$(grep -w nr_tlb_remote_flush *diff* | column -t | awk '{printf $NF "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$TLB_SEND")) 

TLB_REC=$(grep -w nr_tlb_remote_flush_received *diff* | column -t | awk '{printf $NF "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$TLB_REC")) 

TLB_LOCAL_ALL=$(grep -w nr_tlb_local_flush_all *diff* | column -t | awk '{printf $NF "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$TLB_LOCAL_ALL")) 

TLB_LOCAL_ONE=$(grep -w nr_tlb_local_flush_one *diff* | column -t | awk '{printf $NF "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$TLB_LOCAL_ONE")) 

(echo -e "$HEADER"; echo -e "$TABLE") | column -t



#73.5761