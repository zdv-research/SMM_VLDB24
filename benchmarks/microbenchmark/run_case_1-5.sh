#!/bin/bash

source run_env.sh

set_run_name () {
    run_name="DEV-${TARGET_DEVICE}"
    run_name="${run_name}_${io_thread_count}IO-${compute_thread_count}COMPUTE-${mixed_thread_count}MIXED"
    run_name="${run_name}_SMALLIO${mapping_type_small_io}"
    if [[ "${single_access_offset_randomized}" == "true" ]]; then run_name="${run_name}-RND"; fi
    run_name="${run_name}_SINGLE-${single_access_mode}"
    if [[ "${fastmap_enabled}" == "true" ]]; then run_name="${run_name}-FASTMAP"; fi
}

add_random_access_after_io="false"
add_random_access_after_compute="false"

for TARGET_DEVICE in "nullblk" "pmem"; do
#for TARGET_DEVICE in "optane" "ssd" "nullblk"; do

    #for mapping_type_small_io in "private" "shared" "thread_private" "shared_thread_private"; do 
    for mapping_type_small_io in "shared" "shared_thread_private"; do 
        mapping_type_complete_file=$mapping_type_small_io

        for single_access_mode in "0" "1"; do 

            #for fastmap_enabled in "false" "true"; do 
            for fastmap_enabled in $OPTIONS_FASTMAP; do 

                single_access_offset_randomized="false"

                if [[ "$mapping_type_small_io" == "thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                if [[ "$mapping_type_small_io" == "shared_thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi

                #
                # Case 1: n IO workers
                #
                case_name="case-1"
                compute_thread_count="0"; mixed_thread_count="0"

                for i in $H_CORES; do
                    io_thread_count="$i"
                    set_run_name
                    run
                done


                #
                # Case 2: 1 IO worker, n compute workers
                #
                case_name="case-2"
                io_thread_count="1"; mixed_thread_count="0"


                for i in $H_CORES_INKL_0; do
                    compute_thread_count="$i"
                    set_run_name
                    run
                done


                #
                # Case 3: n IO workers, 1 compute workers
                #
                case_name="case-3"
                compute_thread_count="1"; mixed_thread_count="0"


                for i in $H_CORES_INKL_0; do
                    io_thread_count="$i"
                    set_run_name
                    run
                done


                #
                # Case 5: n mixed workers
                #
                case_name="case-5"
                compute_thread_count="0"; io_thread_count="0"


                for i in $H_CORES; do
                    mixed_thread_count="$i"
                    set_run_name
                    run
                done

            done
        done
    done
done

for TARGET_DEVICE in "nullblk"; do
    for mapping_type_small_io in "shared" "shared_thread_private"; do 
        mapping_type_complete_file=$mapping_type_small_io

        for single_access_mode in "0"; do 

            #for fastmap_enabled in "false" "true"; do 
            for fastmap_enabled in $OPTIONS_FASTMAP; do 


                single_access_offset_randomized="false"

                if [[ "$mapping_type_small_io" == "thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                if [[ "$mapping_type_small_io" == "shared_thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi

                #
                # Case 4: n IO workers, n compute workers
                #
                case_name="case-4"; mixed_thread_count="0"


                for i in $H_CORES; do 
                    for j in $H_CORES; do
                        io_thread_count="$i"
                        compute_thread_count="$j"
                        set_run_name
                        run
                    done
                done

            done
        done
    done
done

for TARGET_DEVICE in "nullblk" "pmem" "ssd"; do
#for TARGET_DEVICE in "optane" "ssd" "nullblk"; do

    for mapping_type_small_io in "private" "shared" "thread_private" "shared_thread_private"; do 
        mapping_type_complete_file=$mapping_type_small_io

        for single_access_mode in "0" "1"; do 

            #for fastmap_enabled in "false" "true"; do 
            for fastmap_enabled in $OPTIONS_FASTMAP; do 

                single_access_offset_randomized="false"

                if [[ "$mapping_type_small_io" == "thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                if [[ "$mapping_type_small_io" == "shared_thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi

                #
                # Case B1: single_access_offset_randomized
                #
                case_name="case-b1-single_access_offset_randomized"
                single_access_offset_randomized="true"

                CORES="10"
                if [[ "$(hostname)" == *"epyc"* ]]; then
                    CORES="48 96"
                fi
                if [[ "$(hostname)" == *"cala"* ]]; then
                    CORES="48 96"
                fi

                for i in ${CORES}; do
                    compute_thread_count="0"; mixed_thread_count="0"; io_thread_count="$i"; set_run_name; run
                    compute_thread_count="$i"; mixed_thread_count="0"; io_thread_count="1"; set_run_name; run
                    compute_thread_count="0"; mixed_thread_count="$i"; io_thread_count="0"; set_run_name; run
                done
            done
        done
    done
done