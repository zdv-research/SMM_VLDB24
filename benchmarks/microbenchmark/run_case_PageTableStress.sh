#!/bin/bash

source run_env.sh

#
# Case PageTableStress: Random accesses after compute and IO, both for IO, compute, IO and compute and mixed
#

case_name="case-PageTableStress"

round_nr="400"
if [[ "$(hostname)" == *"pbar"* ]]; then
    round_nr="800"
fi

round_length_ms="500"
periodically_madvise_dontneed_whole_file_period_ms="10000"

set_run_name () {
    run_name="DEV-${TARGET_DEVICE}"
    run_name="${run_name}_${io_thread_count}IO-${compute_thread_count}COMPUTE-${mixed_thread_count}MIXED"
    run_name="${run_name}-AccIO${add_random_access_after_io}-AccCom${add_random_access_after_compute}"
    run_name="${run_name}-madviseDN${madvise_DN_mode}"
    # run_name="${run_name}_SMALLIO${mapping_type_small_io}"
    # run_name="${run_name}_BIGIO${mapping_type_complete_file}"
    run_name="${run_name}_IO${mapping_type_complete_file}"
    run_name="${run_name}_RANDOM-${random_access_mode}"
    run_name="${run_name}_MEMINTCOMP-${memintensive_compute_operations}"
    run_name="${run_name}_CF-${compute_thread_computeload_factor}"
    run_name="${run_name}_PG-${compute_thread_memintense_pages}"
    if [[ "${fastmap_enabled}" == "true" ]]; then run_name="${run_name}-FASTMAP"; fi
}

# run () {
#     echo $run_name
# }

#for TARGET_DEVICE in "nullblk" "ssd" "optane"; do
#for TARGET_DEVICE in "pmem" "nullblk" "ssd" ; do
#for TARGET_DEVICE in "nullblk" "optane" "ssd" ; do

if [[ "$(hostname)" == *"pbar"* ]]; then
    RUN_PG_CF_MATRIX=0
    RUN_PG_CF_MATRIX_DEVICES=""
    RUN_PG_CF_SELECTED=1
    RUN_PG_CF_SELECTED_DEVICES="pmem nullblk ssd"
    RUN_SCALABILITY=0
    RUN_SCALABILITY_DEVICES=""
    RUN_ACCESS_MODES=1
    RUN_ACCESS_MODES_DEVICES="pmem nullblk ssd"
elif [[ "$(hostname)" == *"cala"* ]]; then
    RUN_PG_CF_MATRIX=0
    RUN_PG_CF_MATRIX_DEVICES="optane nullblk ssd"
    RUN_PG_CF_SELECTED=1
    RUN_PG_CF_SELECTED_DEVICES="optane nullblk ssd"
    RUN_SCALABILITY=1
    RUN_SCALABILITY_DEVICES="optane nullblk"
    RUN_ACCESS_MODES=1
    RUN_ACCESS_MODES_DEVICES="optane nullblk ssd"
else
    RUN_PG_CF_MATRIX=0
    RUN_PG_CF_MATRIX_DEVICES=""
    RUN_PG_CF_SELECTED=0
    RUN_PG_CF_SELECTED_DEVICES=""
    RUN_SCALABILITY=0
    RUN_SCALABILITY_DEVICES=""
    RUN_ACCESS_MODES=0
    RUN_ACCESS_MODES_DEVICES=""
fi

for TARGET_DEVICE in $RUN_PG_CF_MATRIX_DEVICES; do
if [[ "${RUN_PG_CF_MATRIX}" == "1" ]]; then
# for mapping_type_complete_file in "private" "shared" "thread_private" "shared_thread_private"; do 
for mapping_type_complete_file in "shared" "shared_thread_private"; do 
    mapping_type_small_io=$mapping_type_complete_file

    #for random_access_mode in "0" "1"; do 
    for random_access_mode in "0"; do 

        #for madvise_DN_mode in "none" "period" "beginning" "access"; do 
        for madvise_DN_mode in "none"; do 

            #for fastmap_enabled in "false" "true"; do 
            for fastmap_enabled in $OPTIONS_FASTMAP; do 

                if [[ "$random_access_mode" == "1" && "$mapping_type_complete_file" == "private" ]] ; then continue ;  fi
                if [[ "$random_access_mode" == "1" && "$mapping_type_complete_file" == "thread_private" ]] ; then continue ;  fi
                if [[ "$mapping_type_complete_file" == "thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                if [[ "$mapping_type_complete_file" == "shared_thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                
                # really? double check
                if [[ "$random_access_mode" == "1" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
            
                madvise_dontneed_whole_file="false"
                madvise_dontneed_for_random_acceses="false"
                do_periodically_madvise_dontneed_whole_file="false"

                if [[ "${madvise_DN_mode}" == "beginning" ]]; then madvise_dontneed_whole_file="true"; fi
                if [[ "${madvise_DN_mode}" == "access" ]]; then madvise_dontneed_for_random_acceses="true"; fi
                if [[ "${madvise_DN_mode}" == "period" ]]; then do_periodically_madvise_dontneed_whole_file="true"; fi
                

                # The higher, the larger the gap
                #for i in "48" "24"" "12" "6"; do

                for i in ${H_CORES_MAX}; do

                    # Interesting are 1->10
                    #for compute_thread_computeload_factor in "1" "5" "10" "50"; do 
                    #for compute_thread_computeload_factor in "1" "3" "5" "7" "9" "11" "13"; do
                    #for compute_thread_computeload_factor in "0.0625" "0.125" "0.25" "0.5" "1" "2" "4" "8"; do
                    for compute_thread_computeload_factor in "0.5" "1" "2" "3" "4" "8"; do

                        #for compute_thread_memintense_pages in "16" "64" "128" "256" "1024" "4096" "16385"; do
                        for compute_thread_memintense_pages in "16" "64" "128" "256" "512" "1024" "4096" "16385"; do

                            memintensive_compute_operations="true"
                            io_thread_count="0"; compute_thread_count="$i"; mixed_thread_count="0"
                            add_random_access_after_io="false"; add_random_access_after_compute="true"
                            set_run_name; run

                        done

                        memintensive_compute_operations="false"
                        io_thread_count="0"; compute_thread_count="$i"; mixed_thread_count="0"
                        add_random_access_after_io="false"; add_random_access_after_compute="true"
                        set_run_name; run

                    done


                done


                # memintensive_compute_operations="true"
                # io_thread_count="0"; compute_thread_count="$core_number"; mixed_thread_count="0"
                # add_random_access_after_io="false"; add_random_access_after_compute="true"
                # set_run_name; run

                # memintensive_compute_operations="false"
                # io_thread_count="0"; compute_thread_count="$core_number"; mixed_thread_count="0"
                # add_random_access_after_io="false"; add_random_access_after_compute="true"
                # set_run_name; run

                # TODO: loop over thread number
                # TODO: more time for lower thread count

                # io_thread_count="0"; compute_thread_count="$((core_number/2))"; mixed_thread_count="0"
                # add_random_access_after_io="false"; add_random_access_after_compute="true"
                # set_run_name; run
                # io_thread_count="0"; compute_thread_count="1"; mixed_thread_count="0"
                # add_random_access_after_io="false"; add_random_access_after_compute="true"
                # set_run_name; run

                
                # io_thread_count="1"; compute_thread_count="$((core_number-1))"; mixed_thread_count="0"
                # add_random_access_after_io="true"; add_random_access_after_compute="true"
                # set_run_name; run

                # # io_thread_count="1"; compute_thread_count="0"; mixed_thread_count="0";
                # # add_random_access_after_io="true"; add_random_access_after_compute="false"
                # # set_run_name; run
                # # io_thread_count="$core_number"; compute_thread_count="0"; mixed_thread_count="0";
                # # add_random_access_after_io="true"; add_random_access_after_compute="false"
                # # set_run_name; run

                # # io_thread_count="$((core_number/2))"; compute_thread_count="$((core_number/2))"; mixed_thread_count="0"
                # # add_random_access_after_io="true"; add_random_access_after_compute="true"
                # # set_run_name; run
                
            done
        done
    done
done
fi
done

for TARGET_DEVICE in $RUN_PG_CF_SELECTED_DEVICES; do
if [[ "${RUN_PG_CF_SELECTED}" == "1" ]]; then
for mapping_type_complete_file in "shared" "shared_thread_private"; do 
    mapping_type_small_io=$mapping_type_complete_file
    for random_access_mode in "0"; do 
        for madvise_DN_mode in "none"; do 
            for fastmap_enabled in $OPTIONS_FASTMAP; do 

                if [[ "$random_access_mode" == "1" && "$mapping_type_complete_file" == "private" ]] ; then continue ;  fi
                if [[ "$random_access_mode" == "1" && "$mapping_type_complete_file" == "thread_private" ]] ; then continue ;  fi
                if [[ "$mapping_type_complete_file" == "thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                if [[ "$mapping_type_complete_file" == "shared_thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                
                # really? double check
                if [[ "$random_access_mode" == "1" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
            
                madvise_dontneed_whole_file="false"
                madvise_dontneed_for_random_acceses="false"
                do_periodically_madvise_dontneed_whole_file="false"

                if [[ "${madvise_DN_mode}" == "beginning" ]]; then madvise_dontneed_whole_file="true"; fi
                if [[ "${madvise_DN_mode}" == "access" ]]; then madvise_dontneed_for_random_acceses="true"; fi
                if [[ "${madvise_DN_mode}" == "period" ]]; then do_periodically_madvise_dontneed_whole_file="true"; fi
                

                CORES="10"
                if [[ "$(hostname)" == *"epyc"* ]]; then
                    CORES="24 48 96"
                fi
                if [[ "$(hostname)" == *"cala"* ]]; then
                    CORES="48 96"
                fi

                for i in ${CORES}; do
                    for compute_thread_computeload_factor in "1" "0.5" "2" "3" "4"; do
                        for compute_thread_memintense_pages in "128"; do

                            memintensive_compute_operations="true"
                            io_thread_count="0"; compute_thread_count="$i"; mixed_thread_count="0"
                            add_random_access_after_io="false"; add_random_access_after_compute="true"
                            set_run_name; run

                        done

                        memintensive_compute_operations="false"
                        io_thread_count="0"; compute_thread_count="$i"; mixed_thread_count="0"
                        add_random_access_after_io="false"; add_random_access_after_compute="true"
                        set_run_name; run

                    done


                done


                # memintensive_compute_operations="true"
                # io_thread_count="0"; compute_thread_count="$core_number"; mixed_thread_count="0"
                # add_random_access_after_io="false"; add_random_access_after_compute="true"
                # set_run_name; run

                # memintensive_compute_operations="false"
                # io_thread_count="0"; compute_thread_count="$core_number"; mixed_thread_count="0"
                # add_random_access_after_io="false"; add_random_access_after_compute="true"
                # set_run_name; run

                # TODO: loop over thread number
                # TODO: more time for lower thread count

                # io_thread_count="0"; compute_thread_count="$((core_number/2))"; mixed_thread_count="0"
                # add_random_access_after_io="false"; add_random_access_after_compute="true"
                # set_run_name; run
                # io_thread_count="0"; compute_thread_count="1"; mixed_thread_count="0"
                # add_random_access_after_io="false"; add_random_access_after_compute="true"
                # set_run_name; run

                
                # io_thread_count="1"; compute_thread_count="$((core_number-1))"; mixed_thread_count="0"
                # add_random_access_after_io="true"; add_random_access_after_compute="true"
                # set_run_name; run

                # # io_thread_count="1"; compute_thread_count="0"; mixed_thread_count="0";
                # # add_random_access_after_io="true"; add_random_access_after_compute="false"
                # # set_run_name; run
                # # io_thread_count="$core_number"; compute_thread_count="0"; mixed_thread_count="0";
                # # add_random_access_after_io="true"; add_random_access_after_compute="false"
                # # set_run_name; run

                # # io_thread_count="$((core_number/2))"; compute_thread_count="$((core_number/2))"; mixed_thread_count="0"
                # # add_random_access_after_io="true"; add_random_access_after_compute="true"
                # # set_run_name; run
                
            done
        done
    done
done
fi
done

for TARGET_DEVICE in $RUN_SCALABILITY_DEVICES; do
if [[ "${RUN_SCALABILITY}" == "1" ]]; then
for mapping_type_complete_file in "shared" "shared_thread_private"; do 
    mapping_type_small_io=$mapping_type_complete_file

    for random_access_mode in "0"; do 

        for madvise_DN_mode in "none"; do 


            for fastmap_enabled in $OPTIONS_FASTMAP; do 

                if [[ "$random_access_mode" == "1" && "$mapping_type_complete_file" == "private" ]] ; then continue ;  fi
                if [[ "$random_access_mode" == "1" && "$mapping_type_complete_file" == "thread_private" ]] ; then continue ;  fi
                if [[ "$mapping_type_complete_file" == "thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                if [[ "$mapping_type_complete_file" == "shared_thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                
                if [[ "$random_access_mode" == "1" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
            
                madvise_dontneed_whole_file="false"
                madvise_dontneed_for_random_acceses="false"
                do_periodically_madvise_dontneed_whole_file="false"

                if [[ "${madvise_DN_mode}" == "beginning" ]]; then madvise_dontneed_whole_file="true"; fi
                if [[ "${madvise_DN_mode}" == "access" ]]; then madvise_dontneed_for_random_acceses="true"; fi
                if [[ "${madvise_DN_mode}" == "period" ]]; then do_periodically_madvise_dontneed_whole_file="true"; fi
                


                for i in ${H_CORES}; do

                    # DID ALREADY ABOVE
                    if [[ "$i" == "$H_CORES_MAX" ]] ; then continue ;  fi

                    for compute_thread_computeload_factor in "1" "2"; do

                        for compute_thread_memintense_pages in "128"; do

                            memintensive_compute_operations="true"
                            io_thread_count="0"; compute_thread_count="$i"; mixed_thread_count="0"
                            add_random_access_after_io="false"; add_random_access_after_compute="true"
                            set_run_name; run

                        done

                        memintensive_compute_operations="false"
                        io_thread_count="0"; compute_thread_count="$i"; mixed_thread_count="0"
                        add_random_access_after_io="false"; add_random_access_after_compute="true"
                        set_run_name; run

                    done

                done
                
            done
        done
    done
done
fi
done

for TARGET_DEVICE in $RUN_ACCESS_MODES_DEVICES; do
if [[ "${RUN_ACCESS_MODES}" == "1" ]]; then
for mapping_type_complete_file in "private" "shared" "thread_private" "shared_thread_private"; do 
    mapping_type_small_io=$mapping_type_complete_file

    for random_access_mode in "0" "1"; do 

        # DID ALREADY ABOVE
        if [[ "$random_access_mode" == "0" && "$mapping_type_complete_file" == "shared" ]] ; then continue ;  fi
        if [[ "$random_access_mode" == "0" && "$mapping_type_complete_file" == "shared_thread_private" ]] ; then continue ;  fi

        for madvise_DN_mode in "none"; do 


            for fastmap_enabled in $OPTIONS_FASTMAP; do 

                if [[ "$random_access_mode" == "1" && "$mapping_type_complete_file" == "private" ]] ; then continue ;  fi
                if [[ "$random_access_mode" == "1" && "$mapping_type_complete_file" == "thread_private" ]] ; then continue ;  fi
                if [[ "$mapping_type_complete_file" == "thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                if [[ "$mapping_type_complete_file" == "shared_thread_private" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
                
                if [[ "$random_access_mode" == "1" && "$fastmap_enabled" == "true" ]] ; then continue ;  fi
            
                madvise_dontneed_whole_file="false"
                madvise_dontneed_for_random_acceses="false"
                do_periodically_madvise_dontneed_whole_file="false"

                if [[ "${madvise_DN_mode}" == "beginning" ]]; then madvise_dontneed_whole_file="true"; fi
                if [[ "${madvise_DN_mode}" == "access" ]]; then madvise_dontneed_for_random_acceses="true"; fi
                if [[ "${madvise_DN_mode}" == "period" ]]; then do_periodically_madvise_dontneed_whole_file="true"; fi
                
                CORES="10"
                if [[ "$(hostname)" == *"epyc"* ]]; then
                    CORES="24 48 96"
                fi
                if [[ "$(hostname)" == *"cala"* ]]; then
                    CORES="48 96"
                fi

                for i in ${CORES}; do

                    for compute_thread_computeload_factor in "1" "2"; do

                        for compute_thread_memintense_pages in "128"; do

                            memintensive_compute_operations="true"
                            io_thread_count="0"; compute_thread_count="$i"; mixed_thread_count="0"
                            add_random_access_after_io="false"; add_random_access_after_compute="true"
                            set_run_name; run

                        done

                    done

                done
                
            done
        done
    done
done
fi
done

#done