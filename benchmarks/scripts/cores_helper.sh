#!/bin/bash

H_CORES_FROM_2="2 3 4 5 6 7 8 9 10"
H_CORES_MAX="10"

if [[ "$(hostname)" == *"epyc"* ]]; then
    H_CORES_FROM_2="2 4 8 12 24 36 48"
    H_CORES_MAX="48"
fi

if [[ "$(hostname)" == *"cala"* ]]; then
    H_CORES_FROM_2="2 4 8 12 24 36 48 72 96"
    H_CORES_MAX="96"
fi

H_CORES="1 $H_CORES_FROM_2"
H_CORES_INKL_0="0 $H_CORES"

# # TEMP
# H_CORES="48"
# H_CORES_INKL_0="48"

get_even_binding_cpus () {
    L_THREADS=$1

   
    if [[ "$(hostname)" == *"epyc"* ]]; then
        L_THREADS_P=$((L_THREADS/2))
        # NUMA node(s):          2
        # NUMA node0 CPU(s):     0-23,48-71
        # NUMA node1 CPU(s):     24-47,72-95
        if [[ "${L_THREADS}" == "1" ]]; then
            echo "0-0"
        else
            echo "0-$((L_THREADS_P-1)),24-$((24+L_THREADS_P-1))"
        fi
    elif [[ "$(hostname)" == *"cala"* ]]; then
        L_THREADS_P=$((L_THREADS/4))
        # NUMA node(s):          4
        # NUMA node0 CPU(s):     0-23,96-119
        # NUMA node1 CPU(s):     24-47,120-143
        # NUMA node2 CPU(s):     48-71,144-167
        # NUMA node3 CPU(s):     72-95,168-191
        if [[ "${L_THREADS}" == "1" ]]; then
            echo "0-0"
        elif [[ "${L_THREADS}" == "2" ]]; then
            echo "0-0,24-24"
        elif [[ "${L_THREADS}" == "3" ]]; then
            echo "0-0,24-24,48-28"
        else
            echo "0-$((L_THREADS_P-1)),24-$((24+L_THREADS_P-1)),48-$((48+L_THREADS_P-1)),72-$((72+L_THREADS_P-1))"
        fi
    else
        echo 0-$((L_THREADS-1))
    fi
}



