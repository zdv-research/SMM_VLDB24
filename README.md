# SMM - Scoped Memory Mappings

This repository serves as the artifact for the Submission of "Towards Zero-TLB Shootdowns using Scoped Memory Mappings" to VLDB 2024.

Next to the data and instructions provided here, we can give access to a fully prepared machine upon request.

During development SMM had the project name TPMM (thread private mmap), which is still present in many places like variable names and comments.
Nevertheless, the flag passed to mmap by the user to enable a mapping for SMM, is `MAP_SMM`

A small amount of the features (like page migration or kswap bitmask optimization) are still experimental and are not fully available in this version.

## Kernel building

The code implementing SMM into the Linux Kernel is divided into two parts.
1. A kernel-version independent part placed at `implementations/mmap_thread_private/tpmm/tpmm.h`
2. Kernel-version specific implementations tightly coupled with the memory internals, directly implemented in the kernel source code.

We provide a kernel version 5.15.12 with SMM implemented at `implementations/mmap_thread_private/linux-5.15.12/`.
The config we used is `implementations/mmap_thread_private/configs/config-5.15.12`

As SMM adds various config parameters, build is most easily achieved by our build script at `/home/fred/repos/tlb_shootdown/implementations/mmap_thread_private/make_kernels.sh`

The default scope configuraration set at kernel compilation is *application wide*, covering all the threads of the app using SMM.

## Usage

After booting a SMM enabled kernel, a SMM enabled mapping is simply created by passing the `MAP_SMM` flag to the `mmap()` call. 

Example:
```c
#define MAP_SMM 0x40000000

int fd = open("/dev/sda", O_RDWR);
mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_SMM, fd, 0);
```

## Benchmarks

Within the paper, nullblk was used for several measurements. It is set up at `/dev/nullb1` using `scripzs/create_nullblk.sh`.

To reproduce our pmem setup, its `ndctl` namespace has to configured to `fsdax`.

### Microbenchmarks
`benchmarks/microbenchmark/src` contains the source of the microbenchmark suite. Cmake build is provided at `benchmarks/microbenchmark`.

Running the compiled executable, following parameters con be configured:

        --device            target device path. type: string. default: /dev/nullb1
        --file_size_kb      Size of the mmaped file in KB. type: size_t. default: 1024
        --round_nr          Number of measurements to take. type: size_t. default: 100
        --round_length_ms   Time in [ms] between each measurement. type^: size_t. default: 1000
        --io_thread_count   I/O thread count. type: size_t. default: 2
        --io_thread_io_size_kb  I/O size in KB for I/O thread. type: size_t. default: 4
        --compute_thread_count  Compute thread count. type: size_t. default: 2
        --compute_thread_computeload_factor Scales the default work amount. type: float. default: 1.0
        --mixed_thread_count    Mixed thread count. type: size_t. default: 0
        --mixed_thread_io_size_kb   I/O size in KB for mixed thread. type: size_t. default: 4
        --mixed_thread_computeload_factor   Scales the default work amount of the compute part. type: float. default: 1.0
        --mixed_thread_computeload_factor_randomization Adds +- randomization*factor to the factor each time. To bring threads ot of sync. type: float. default: 0.0
        --add_random_access_after_io    This should lead to aditional page faults. type: bool. default: false
        --add_random_access_after_compute   This should lead to aditional page faults. type: bool. --default: false
        --madvise_dontneed_whole_file   Do single madvise MADV_DONTNEED for whole file after inital mmap. type: bool. default: false
        --madvise_dontneed_for_random_acceses   Do madvise MADV_DONTNEED after every random access for only the acceded data range. type: bool. default: false
        --do_periodically_madvise_dontneed_whole_file   Do madvise MADV_DONTNEED for whole file --repeatedly. type: bool. default: false
        --periodically_madvise_dontneed_whole_file_period_ms    Repeatedly madvise MADV_DONTNEED period in [ms]. type: size_t. default: 10000
        --mapping_type_complete_file    private, shared or thread_private. type: string. default: shared
        --mapping_type_small_io private, shared or thread_private. type: string. default: shared
        --random_access_mode    0=read 1=write 2=read_write. type: size_t. default: 0
        --single_access_mode    0=read 1=write 2=read_write. type: size_t. default: 0
        --single_access_offset_randomized   type: bool. default: false
        --memintensive_compute_operations   type: bool. default: false
        --compute_thread_memintense_pages   type: size_t. default: 128
        --monitor                           print monitoring outputs. type: bool. default: false

It might be easier to use the execution scripts we created for our setup (`benchmarks/microbenchmark/run_case_*.sh`). They configure the benchmark binary for all the presented cases. Be aware, that manual adjustments to that scripts have to be made to suit the specific execution environment (e.g. changing absolute pathes to devices, binaries or working directories).

To convert the output of the execution scripts into a sumary, `benchmarks/microbenchmark/analyze*.sh` can be used.

### Apache benchmark
To use SMM, Apache has to be build from source code (https://httpd.apache.org/download.cgi) with the `MAP_SMM` flag added to the mmap call in `srclib/apr/mmap/unix/mmap.c` line 133 (version 2.4.53).

```c
./srclib/apr/mmap/unix/mmap.c:132: #define MAP_SMM 0x40000000
./srclib/apr/mmap/unix/mmap.c:133: mm = mmap(NULL, size, native_flags, MAP_SHARED | MAP_SMM, file->filedes, offset);
```

The benchmark is performed by executing wrk (https://github.com/wg/wrk).

The benchmarks can be run manually or by using the `benchmarks/monitoring/run_apache.sh` script for the same configurations as used within the paper. Be aware, that manual adjustments to the script have to be made to suit the specific execution environment (e.g. changing absolute pathes to devices, binaries or working directories).


### YCSB Benchmark
We have been using YCSB-cpp (https://github.com/ls4154/YCSB-cpp), included in `third_party/YCSB-cpp`. The used libraries for leveldb and lmdb can be also found in the `third_party`directory. For both, we provide a *tpmm version, using the DB mmaps with the `MAP_SMM` flag.

The benchmarks can be run manually or by using the `benchmarks/monitoring/run_leveldb.sh` and `benchmarks/monitoring/run_lmdb.sh` scripts for the same configurations as used within the paper. Be aware, that manual adjustments to that scripts have to be made to suit the specific execution environment (e.g. changing absolute pathes to devices, binaries or working directories).
