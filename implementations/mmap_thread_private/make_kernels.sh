

set_defaults () {
    # ./scripts/config --set-val CONFIG_USE_TPMM n
    # ./scripts/config --set-val CONFIG_USE_TPMM_SEC_AND_KSWAPD n
    ./scripts/config --set-val CONFIG_USE_TPMM_MUNMAP_TLB_SKIP n
    ./scripts/config --set-val CONFIG_USE_TPMM_PAGE_FAULT_MARK n
    ./scripts/config --set-val CONFIG_USE_TPMM_ALLOC_FLUSH_CHECK n
    ./scripts/config --set-val CONFIG_USE_TPMM_KSWAPD_TLB_SKIP n
    ./scripts/config --set-val CONFIG_USE_TPMM_KSWAPDTLB_BYPASS n
    ./scripts/config --set-val CONFIG_USE_TPMM_PMEM n
    ./scripts/config --set-val CONFIG_USE_TPMM_FINE_CPUBITMASKS n; 
    ./scripts/config --set-val CONFIG_USE_TPMM_MUNMAP_OWN_FLUSH n
    ./scripts/config --set-val CONFIG_TPMM_DEBUG_ENABLED n
    ./scripts/config --set-val CONFIG_DEBUG_INFO n; 
    ./scripts/config --set-val CONFIG_DEBUG_TLBFLUSH y

    ./scripts/config --set-val CONFIG_TPMM_MODULE_CLEAN m

    ./scripts/config --set-val CONFIG_NUMA_BALANCING_DEFAULT_ENABLED y
    ./scripts/config --set-val CONFIG_NUMA_BALANCING y
}

cd linux-5.15.12

# # The NOT ownflush hardened kernel
# sudo make clean; set_defaults
# ./scripts/config --set-val CONFIG_USE_TPMM_MUNMAP_TLB_SKIP y
# ./scripts/config --set-val CONFIG_USE_TPMM_PAGE_FAULT_MARK y
# ./scripts/config --set-val CONFIG_USE_TPMM_ALLOC_FLUSH_CHECK y
# ./scripts/config --set-val CONFIG_USE_TPMM_KSWAPD_TLB_SKIP y
# make oldconfig; grep TPMM .config; sleep 2; 
# make EXTRAVERSION='.tpmmmun.faultmark.allocflush.kswapd' -j 20;
# sudo make modules_install; sudo make install

# The ownflush hardened kernel
sudo make clean; set_defaults
./scripts/config --set-val CONFIG_USE_TPMM_MUNMAP_TLB_SKIP y
./scripts/config --set-val CONFIG_USE_TPMM_PAGE_FAULT_MARK y
./scripts/config --set-val CONFIG_USE_TPMM_ALLOC_FLUSH_CHECK y
./scripts/config --set-val CONFIG_USE_TPMM_KSWAPD_TLB_SKIP y
./scripts/config --set-val CONFIG_USE_TPMM_MUNMAP_OWN_FLUSH y
make oldconfig; grep TPMM .config; sleep 2; 
make EXTRAVERSION='.tpmmmun.faultmark.allocflush.kswapd.ownflush' -j 20;
sudo make modules_install; sudo make install

# # The mmap/munmap kernel
# sudo make clean; set_defaults
# ./scripts/config --set-val CONFIG_USE_TPMM_MUNMAP_TLB_SKIP y
# make oldconfig; grep TPMM .config; sleep 2; 
# make EXTRAVERSION='.tpmmmun' -j 20;
# sudo make modules_install; sudo make install

# # The kswapd kernel
# sudo make clean; set_defaults
# ./scripts/config --set-val CONFIG_USE_TPMM_PAGE_FAULT_MARK y
# ./scripts/config --set-val CONFIG_USE_TPMM_KSWAPD_TLB_SKIP y
# make oldconfig; grep TPMM .config; sleep 2; 
# make EXTRAVERSION='.tpmmmun.faultmark.kswapd' -j 20;
# sudo make modules_install; sudo make install

# # The vanilla kernel
# sudo make clean; set_defaults
# make oldconfig; grep TPMM .config; sleep 2; 
# make EXTRAVERSION='.vanilla' -j 20;
# sudo make modules_install; sudo make 

# # The pmem kernel
# sudo make clean; set_defaults
# ./scripts/config --set-val CONFIG_USE_TPMM_MUNMAP_TLB_SKIP y
# ./scripts/config --set-val CONFIG_USE_TPMM_PAGE_FAULT_MARK y
# ./scripts/config --set-val CONFIG_USE_TPMM_ALLOC_FLUSH_CHECK y
# ./scripts/config --set-val CONFIG_USE_TPMM_KSWAPD_TLB_SKIP y
# ./scripts/config --set-val CONFIG_USE_TPMM_PMEM y
# make oldconfig; grep TPMM .config; sleep 2; 
# make EXTRAVERSION='.tpmmmun.faultmark.allocflush.kswapd.pmem' -j 20;
# sudo make modules_install; sudo make install

# The pmem mmap/munmap kernel
# sudo make clean; set_defaults
# ./scripts/config --set-val CONFIG_USE_TPMM_MUNMAP_TLB_SKIP y
# ./scripts/config --set-val CONFIG_USE_TPMM_PMEM y
# make oldconfig; grep TPMM .config; sleep 2; 
# make EXTRAVERSION='.tpmmmun.pmem' -j 20;
# sudo make modules_install; sudo make install