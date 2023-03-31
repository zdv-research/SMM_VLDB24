#!/bin/bash

echo $(basename $(pwd))

echo ""

for BPARAM_producer_threads in "6" "12"; do
for BPARAM_taskset_even in "1"; do
for BPARAM_numaseperate in "0"; do

echo BPARAM_producer_threads=$BPARAM_producer_threads


#FILES=$(ls -1 *PRODTHREADS-${BPARAM_producer_threads}*NUMASEPERATE-${BPARAM_numaseperate}*TSeven-${BPARAM_taskset_even}*log*)
#FILES_DIFF=$(ls -1 *PRODTHREADS-${BPARAM_producer_threads}*NUMASEPERATE-${BPARAM_numaseperate}*TSeven-${BPARAM_taskset_even}*diff*)

FILES=$(ls -1 *PRODTHREADS-${BPARAM_producer_threads}*log*)
FILES_DIFF=$(ls -1 *PRODTHREADS-${BPARAM_producer_threads}*diff*)


HEADER="- - Kreq/sec req/sec/T Latency nr_tlb_remote nr_tlb_remote_rec"
TABLE=$(echo -e "$FILES" | column -t -s'_' | awk '{ print $3" "$4  }')


RUNTIMES=$(grep "requests in" $FILES)
RUNTIMES=$(echo -e "$RUNTIMES" | column -t | awk '{printf $2/30000 "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$RUNTIMES")) 

RUNTIMES=$(grep "Req/Sec" $FILES)
RUNTIMES=$(echo -e "$RUNTIMES" | column -t | awk '{printf $3 "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$RUNTIMES")) 

RUNTIMES=$(grep "Latency" $FILES)
RUNTIMES=$(echo -e "$RUNTIMES" | column -t | awk '{printf $3 "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$RUNTIMES")) 

TLB_SEND=$(grep -w nr_tlb_remote_flush $FILES_DIFF | column -t | awk '{printf $NF "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$TLB_SEND")) 

TLB_REC=$(grep -w nr_tlb_remote_flush_received $FILES_DIFF | column -t | awk '{printf $NF "\n"}')
TABLE=$(paste -d' ' <(echo "$TABLE") <(echo "$TLB_REC")) 

WORDTOREMOVE="THREADS-"; TABLE=$(printf '%s\n' "${TABLE//$WORDTOREMOVE/}") 

TABLE=$(echo -e "$TABLE" | sort -n)
(echo -e "$HEADER"; echo -e "$TABLE" ) | column -t

echo ""
echo ""

done
done
done
