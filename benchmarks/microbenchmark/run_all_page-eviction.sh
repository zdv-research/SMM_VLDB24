#!/bin/bash


source ../scripts/kill_background.sh; sleep 1
source ../scripts/ram_helpers.sh

#216
#block_ram_gb 200
if [[ "$(hostname)" != *"zbar"* && "$(hostname)" != *"pbar"* ]]; then block_ram_up_to_gb 36; fi
if [[ "$(hostname)" == *"pbar"* ]]; then block_ram_up_to_gb 17; fi
if [[ "$(hostname)" == *"zbar"* ]]; then block_ram_up_to_gb 10; fi
source run_case_PageTableStress.sh
free_blocked_ram 216



