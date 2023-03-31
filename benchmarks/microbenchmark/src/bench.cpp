//
// system includes
//
#include <atomic>
#include <cassert>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <string>
#include <chrono>
#include <sys/mman.h>
#include <thread> 
#include <tuple>
#include <errno.h>
#include <string.h>
#include <sys/sysinfo.h>
#include <stdio.h>
#include <stdlib.h>

//
// deps
//
#include "../../../implementations/mmap_thread_private/test/thread_private_mmap.h"
#include "tbb/enumerable_thread_specific.h"

//
// other includes
//
#include "helper.hpp"
#include "cxxopts.hpp"

//
// namespaces
//
using namespace std;

//
// passed arguments
//
bool dummy;
string device;
size_t file_size_kb;
size_t process_count;
size_t process_id;
size_t round_nr;
size_t round_length_ms;
size_t io_thread_count;
size_t io_thread_io_size_kb;
bool add_random_access_after_io;
size_t compute_thread_count;
float compute_thread_computeload_factor;
size_t mixed_thread_count;
size_t mixed_thread_io_size_kb;
bool add_random_access_after_compute;
float mixed_thread_computeload_factor;
float mixed_thread_computeload_factor_randomization; // TODO
bool madvise_dontneed_whole_file;
bool madvise_dontneed_for_random_acceses;
bool do_periodically_madvise_dontneed_whole_file;
size_t periodically_madvise_dontneed_whole_file_period_ms;
string mapping_type_complete_file; // "shared" "private" "thread_private"
string mapping_type_small_io; // "shared" "private" "thread_private"
// todo: complete file mapping per thread (on off, implementation)
string fastmap_device;
bool fastmap_enabled;
size_t random_access_mode; /* 0=read 1=write 2=read_and_write */
size_t single_access_mode; /* 0=read 1=write 2=read_and_write */
bool single_access_offset_randomized;
bool monitor;
bool memintensive_compute_operations;
size_t compute_thread_memintense_pages;



//
// forward definitions
//
void print_params();
void prepare_on_main_thread();
void spawn_threads();
void main_thread();
void stop_threads();
void print_results(size_t round);
void print_final_results();

//
// private globals
//
int fd;
char* mapping;
tbb::enumerable_thread_specific<atomic<size_t>> io_thread_io_counts;
tbb::enumerable_thread_specific<atomic<size_t>> compute_thread_compute_counts;
tbb::enumerable_thread_specific<atomic<size_t>> mixed_thread_io_counts;
tbb::enumerable_thread_specific<atomic<size_t>> mixed_thread_compute_counts;
ssize_t last_tlb_shootdowns;
struct tlbdetails last_tlb_details;
atomic<bool> do_exit;
ulong mapping_type_complete_file_bits;
ulong mapping_type_small_io_bits;

ulong sum_io_thread_io_counts = 0;
ulong sum_compute_thread_compute_counts = 0;
ulong sum_mixed_thread_io_counts = 0;
ulong sum_mixed_thread_compute_counts = 0;
ulong sum_tlb_shootdowns = 0;

char **memintensive_compute_data;
size_t memintensive_compute_size;


int main(int argc, char **argv)
{
    cxxopts::Options options("MMAP TLB microbenchmark", "performance impact of multiple i/o and compute threads.");
    options.add_options()
        ("dummy", "Early outs with all results as 1. To test further result parsing.", cxxopts::value<bool>()->default_value("false"))
        ("device", "e.g. /dev/nullb1", cxxopts::value<string>()->default_value("/dev/nullb1"))
        ("file_size_kb", "Size of the mmaped file in KB.", cxxopts::value<size_t>()->default_value("1024"))
        ("process_count", "Overall process number.", cxxopts::value<size_t>()->default_value("1"))
        ("process_id", "ID of this process.", cxxopts::value<size_t>()->default_value("0"))
        ("round_nr", "Number of measurements to take.", cxxopts::value<size_t>()->default_value("100"))
        ("round_length_ms", "Time in [ms] between each measurement.", cxxopts::value<size_t>()->default_value("1000"))
        ("io_thread_count", "I/O thread count.", cxxopts::value<size_t>()->default_value("2"))
        ("io_thread_io_size_kb", "I/O size in KB for I/O thread.", cxxopts::value<size_t>()->default_value("4"))
        ("compute_thread_count", "Compute thread count.", cxxopts::value<size_t>()->default_value("2"))
        ("compute_thread_computeload_factor", "Scales the default work amount.", cxxopts::value<float>()->default_value("1.0"))
        ("mixed_thread_count", "Mixed thread count.", cxxopts::value<size_t>()->default_value("0"))
        ("mixed_thread_io_size_kb", "I/O size in KB for mixed thread.", cxxopts::value<size_t>()->default_value("4"))
        ("mixed_thread_computeload_factor", "Scales the default work amount of the compute part.", cxxopts::value<float>()->default_value("1.0"))
        ("mixed_thread_computeload_factor_randomization", "Adds +- randomization*factor to the factor each time. To bring threads ot of sync.", cxxopts::value<float>()->default_value("0.0"))
        ("add_random_access_after_io", "This should lead to aditional page faults.", cxxopts::value<bool>()->default_value("false"))
        ("add_random_access_after_compute", "This should lead to aditional page faults.", cxxopts::value<bool>()->default_value("false"))
        ("madvise_dontneed_whole_file", "Do single madvise MADV_DONTNEED for whole file after inital mmap.", cxxopts::value<bool>()->default_value("false"))
        ("madvise_dontneed_for_random_acceses", "Do madvise MADV_DONTNEED after every random access for only the acceded data range", cxxopts::value<bool>()->default_value("false"))
        ("do_periodically_madvise_dontneed_whole_file", "Do madvise MADV_DONTNEED for whole file repeatedly.", cxxopts::value<bool>()->default_value("false"))
        ("periodically_madvise_dontneed_whole_file_period_ms", "Repeatedly madvise MADV_DONTNEED period time in [ms]", cxxopts::value<size_t>()->default_value("10000"))
        ("mapping_type_complete_file", "private, shared or thread_private", cxxopts::value<string>()->default_value("shared"))
        ("mapping_type_small_io", "private, shared or thread_private", cxxopts::value<string>()->default_value("shared"))
        ("fastmap_device", "FastMap device", cxxopts::value<string>()->default_value("/dev/dmap/dmap1"))
        ("fastmap_enabled", "true or false", cxxopts::value<bool>()->default_value("false"))
        ("random_access_mode", "0=read 1=write 2=read_write", cxxopts::value<size_t>()->default_value("0"))
        ("single_access_mode", "0=read 1=write 2=read_write", cxxopts::value<size_t>()->default_value("0"))
        ("single_access_offset_randomized", "true or false", cxxopts::value<bool>()->default_value("false"))
        ("memintensive_compute_operations", "true or false", cxxopts::value<bool>()->default_value("false"))
        ("compute_thread_memintense_pages", "default=128", cxxopts::value<size_t>()->default_value("128"))
        ("monitor", "monitor mode, true or false", cxxopts::value<bool>()->default_value("false"))
        ("h,help", "Print usage")
    ;
    auto parse_result = options.parse(argc, argv);

    if (parse_result.count("help"))
    {
        std::cout << options.help() << std::endl;
        exit(0);
    }

    dummy = parse_result["dummy"].as<bool>();
    device = parse_result["device"].as<string>();
    file_size_kb = parse_result["file_size_kb"].as<size_t>();
    process_count = parse_result["process_count"].as<size_t>();
    process_id = parse_result["process_id"].as<size_t>();
    round_nr = parse_result["round_nr"].as<size_t>();
    round_length_ms = parse_result["round_length_ms"].as<size_t>();
    io_thread_count = parse_result["io_thread_count"].as<size_t>();
    io_thread_io_size_kb = parse_result["io_thread_io_size_kb"].as<size_t>();
    compute_thread_count = parse_result["compute_thread_count"].as<size_t>();
    compute_thread_computeload_factor = parse_result["compute_thread_computeload_factor"].as<float>();
    mixed_thread_count = parse_result["mixed_thread_count"].as<size_t>();
    mixed_thread_io_size_kb = parse_result["mixed_thread_io_size_kb"].as<size_t>();
    mixed_thread_computeload_factor = parse_result["mixed_thread_computeload_factor"].as<float>();
    mixed_thread_computeload_factor_randomization = parse_result["mixed_thread_computeload_factor_randomization"].as<float>();
    add_random_access_after_io = parse_result["add_random_access_after_io"].as<bool>();
    add_random_access_after_compute = parse_result["add_random_access_after_compute"].as<bool>();   
    madvise_dontneed_whole_file = parse_result["madvise_dontneed_whole_file"].as<bool>();   
    madvise_dontneed_for_random_acceses = parse_result["madvise_dontneed_for_random_acceses"].as<bool>();   
    do_periodically_madvise_dontneed_whole_file = parse_result["do_periodically_madvise_dontneed_whole_file"].as<bool>();   
    periodically_madvise_dontneed_whole_file_period_ms = parse_result["periodically_madvise_dontneed_whole_file_period_ms"].as<size_t>();   
    mapping_type_complete_file = parse_result["mapping_type_complete_file"].as<string>(); 
    mapping_type_small_io = parse_result["mapping_type_small_io"].as<string>(); 
    fastmap_device = parse_result["fastmap_device"].as<string>(); 
    fastmap_enabled = parse_result["fastmap_enabled"].as<bool>(); 
    random_access_mode = parse_result["random_access_mode"].as<size_t>();   
    single_access_mode = parse_result["single_access_mode"].as<size_t>(); 
    single_access_offset_randomized = parse_result["single_access_offset_randomized"].as<bool>(); 
    memintensive_compute_operations = parse_result["memintensive_compute_operations"].as<bool>(); 
    compute_thread_memintense_pages = parse_result["compute_thread_memintense_pages"].as<size_t>(); 
    monitor = parse_result["monitor"].as<bool>(); 

    if (!monitor) {
        cout << "BENCHMARK START" << endl;
        prepare_on_main_thread();
    }

    last_tlb_shootdowns = get_tlb_shootdowns();
    last_tlb_details = get_tlb_details();

    if (!monitor) {
        
        print_params();

        if (dummy)
        {
            for (size_t i = 0; i < round_nr; i++) print_results(i);
        }
        else
        {
            spawn_threads();
            main_thread();
            stop_threads();
            print_final_results();
        }

    } else {
        round_length_ms = 1000;
        round_nr = 999999;
        main_thread();
    }

    cout << "BENCHMARK FINISH" << endl << endl;
    
    return 0;
}

void print_params()
{
    cout << "parameter device " << device << endl;
    cout << "parameter file_size_kb " << file_size_kb << endl;
    cout << "parameter process_count " << process_count << endl;
    cout << "parameter process_id " << process_id << endl;
    cout << "parameter round_nr " << round_nr << endl;
    cout << "parameter round_length_ms " << round_length_ms << endl;
    cout << "parameter io_thread_count " << io_thread_count << endl;
    cout << "parameter io_thread_io_size_kb " << io_thread_io_size_kb << endl;
    cout << "parameter compute_thread_count " << compute_thread_count << endl;
    cout << "parameter compute_thread_computeload_factor " << compute_thread_computeload_factor << endl;
    cout << "parameter mixed_thread_count " << mixed_thread_count << endl;
    cout << "parameter mixed_thread_io_size_kb " << mixed_thread_io_size_kb << endl;
    cout << "parameter mixed_thread_computeload_factor " << mixed_thread_computeload_factor << endl;
    cout << "parameter mixed_thread_computeload_factor_randomization " << mixed_thread_computeload_factor_randomization << endl;
    cout << "parameter add_random_access_after_io " << add_random_access_after_io << endl;  
    cout << "parameter add_random_access_after_compute " << add_random_access_after_compute << endl;   
    cout << "parameter madvise_dontneed_whole_file " << madvise_dontneed_whole_file << endl;  
    cout << "parameter madvise_dontneed_for_random_acceses " << madvise_dontneed_for_random_acceses << endl;  
    cout << "parameter do_periodically_madvise_dontneed_whole_file " << do_periodically_madvise_dontneed_whole_file << endl;  
    cout << "parameter periodically_madvise_dontneed_whole_file_period_ms " << periodically_madvise_dontneed_whole_file_period_ms << endl; 
    cout << "parameter mapping_type_complete_file " << mapping_type_complete_file << endl;  
    cout << "parameter mapping_type_small_io " << mapping_type_small_io << endl;   
    cout << "parameter fastmap_device " << fastmap_device << endl;  
    cout << "parameter fastmap_enabled " << fastmap_enabled << endl;  
    cout << "parameter single_access_offset_randomized " << single_access_offset_randomized << endl;  
    cout << "parameter memintensive_compute_operations " << memintensive_compute_operations << endl;  
    cout << "parameter compute_thread_memintense_pages " << compute_thread_memintense_pages << endl;  
    
    if (random_access_mode == 0)
        cout << "parameter random_access_mode " << "read" << endl;
    else if (random_access_mode == 1)
        cout << "parameter random_access_mode " << "write" << endl;
    else
        cout << "parameter random_access_mode " << "read_write" << endl;

    if (single_access_mode == 0)
        cout << "parameter single_access_mode " << "read" << endl;
    else if (single_access_mode == 1)
        cout << "parameter single_access_mode " << "write" << endl;
    else
        cout << "parameter single_access_mode " << "read_write" << endl;
}


size_t sum_up_and_reset_enumerable_thread_specific(tbb::enumerable_thread_specific<atomic<size_t>> &enumerable_thread_specific)
{
    size_t result = 0;
    for (auto& x : enumerable_thread_specific)
        result += x.exchange(0);
    return result;
}

void print_results (size_t round)
{
    cout << endl;

    ssize_t tlb_shootdowns = get_tlb_shootdowns();
    ssize_t tlb_shootdowns_since_last = tlb_shootdowns - last_tlb_shootdowns;
    cout << "result " << round << " tlb_shootdowns " << tlb_shootdowns_since_last << endl;
    last_tlb_shootdowns = tlb_shootdowns;
    sum_tlb_shootdowns += tlb_shootdowns_since_last;

    if (io_thread_count != 0)
    {
        size_t io_thread_io_count = dummy == true ? 1 : sum_up_and_reset_enumerable_thread_specific(io_thread_io_counts);
        cout << "result " << round << " io_thread_io_count " << io_thread_io_count << endl;
        sum_io_thread_io_counts += io_thread_io_count;
    }

    if (compute_thread_count != 0)
    {
        size_t compute_thread_compute_count = dummy == true ? 1 : sum_up_and_reset_enumerable_thread_specific(compute_thread_compute_counts);
        cout << "result " << round << " compute_thread_compute_count " << compute_thread_compute_count << endl;
        sum_compute_thread_compute_counts += compute_thread_compute_count;
    }

    if (mixed_thread_count != 0)
    {
        size_t mixed_thread_io_count = dummy == true ? 1 : sum_up_and_reset_enumerable_thread_specific(mixed_thread_io_counts);
        cout << "result " << round << " mixed_thread_io_count " << mixed_thread_io_count << endl;
        sum_mixed_thread_io_counts += mixed_thread_io_count;

        size_t mixed_thread_compute_count = dummy == true ? 1 : sum_up_and_reset_enumerable_thread_specific(mixed_thread_compute_counts);
        cout << "result " << round << " mixed_thread_compute_count " << mixed_thread_compute_count << endl;
        sum_mixed_thread_compute_counts += mixed_thread_compute_count;
    }


    struct sysinfo sys_info;
    sysinfo(&sys_info);
    cout << "RAM " << round << " total=" << sys_info.totalram << " free=" << sys_info.freeram << " shared=" << sys_info.sharedram << " buffer=" << sys_info.bufferram << endl;

    struct tlbdetails tlb_details = get_tlb_details();
    cout << "TLB " << round 
        << " nr_tlb_remote_flush=" << tlb_details.nr_tlb_remote_flush 
        << " nr_tlb_remote_flush_received=" << tlb_details.nr_tlb_remote_flush_received 
        << " nr_tlb_local_flush_all=" << tlb_details.nr_tlb_local_flush_all 
        << " nr_tlb_local_flush_one=" << tlb_details.nr_tlb_local_flush_one 
        << endl;

    cout << "TLBDIFF " << round 
        << " nr_tlb_remote_flush=" << tlb_details.nr_tlb_remote_flush - last_tlb_details.nr_tlb_remote_flush
        << " nr_tlb_remote_flush_received=" << tlb_details.nr_tlb_remote_flush_received - last_tlb_details.nr_tlb_remote_flush_received
        << " nr_tlb_local_flush_all=" << tlb_details.nr_tlb_local_flush_all - last_tlb_details.nr_tlb_local_flush_all
        << " nr_tlb_local_flush_one=" << tlb_details.nr_tlb_local_flush_one - last_tlb_details.nr_tlb_local_flush_one
        << endl;

    last_tlb_details = tlb_details;
}

void print_final_results() {
    cout << endl;
    cout << "END RESULTS" << endl;
    cout << "sum_io_thread_io_counts " << sum_io_thread_io_counts << endl;
    cout << "sum_compute_thread_compute_counts " << sum_compute_thread_compute_counts << endl;
    cout << "sum_mixed_thread_io_counts " << sum_mixed_thread_io_counts << endl;
    cout << "sum_mixed_thread_compute_counts " << sum_mixed_thread_compute_counts << endl;
    cout << "sum_tlb_shootdowns " << sum_tlb_shootdowns << endl;

}

void prepare_on_main_thread()
{
    mapping_type_complete_file_bits = mapping_string_to_bitmask(mapping_type_complete_file);
    mapping_type_small_io_bits = mapping_string_to_bitmask(mapping_type_small_io);

    if (fastmap_enabled) {
        fd = open(fastmap_device.c_str(), O_RDWR );
    } else {
        fd = open(device.c_str(), O_RDWR);
    }
    assert(fd != -1);

    mapping = (char*)mmap(nullptr, file_size_kb * 1024, PROT_READ | PROT_WRITE, mapping_type_complete_file_bits, fd, 0);
    if (mapping == MAP_FAILED) cout << errno << ": " << strerror(errno) << endl;
    assert(mapping != MAP_FAILED);
    int madvise_bits = MADV_RANDOM;
    if (madvise_dontneed_whole_file)
         madvise_bits = madvise_bits | MADV_DONTNEED;
    madvise(mapping, file_size_kb * 1024, madvise_bits);

    if (memintensive_compute_operations) {
        memintensive_compute_size = 1024*4 * compute_thread_memintense_pages;

        memintensive_compute_data = new char* [compute_thread_count];
        for (size_t i = 0; i < compute_thread_count; i++) {
            memintensive_compute_data[i] = (char*) aligned_alloc(64, memintensive_compute_size);
            for (size_t j = 0; j < memintensive_compute_size; j++) memintensive_compute_data[i][j] = j%255;
        }
    }

}

void main_thread()
{
    for (size_t i = 0; i < round_nr; i++)
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(round_length_ms));
        print_results(i);
    }
}

void do_single_io(Rand &rand, size_t size)
{
    uint64_t offset = 0;
    if (single_access_offset_randomized) {
        offset = rand.rnd(rand.gen);
        offset -= offset%4096;
    }
    char* pp = (char *)mmap(nullptr, size, PROT_READ | PROT_WRITE, mapping_type_small_io_bits | MAP_POPULATE, fd, offset);
    if (single_access_mode >= 1)
        pp[0] = 'a';
    munmap(pp, size);
}

void do_single_random_access(Rand &rand, int &sum)
{
    // read
    if (random_access_mode != 1) {
        uint64_t pos = rand.rnd(rand.gen);
        //cout << "pos read " << pos << endl;
        sum += mapping[pos];
        if (madvise_dontneed_for_random_acceses)
            madvise(mapping + pos, 1, MADV_DONTNEED);
    }

    // write
    if (random_access_mode >= 1) {
        uint64_t pos = rand.rnd(rand.gen);
        //cout << "pos write " << pos << endl;
        sum += 233;
        mapping[pos] = sum;
        if (madvise_dontneed_for_random_acceses)
            madvise(mapping + pos, 1, MADV_DONTNEED);
    }
}

inline int fast_rand(int g_seed) { // https://stackoverflow.com/questions/26237419/faster-than-rand
    g_seed = (214013*g_seed+2531011);
    return (g_seed>>16)&0x7FFF;
}

void do_single_compute(float factor)
{
    for (size_t i = 0; i < 10000*factor; i++) 
    {
        __asm__ volatile("" : "+g" (i) : :);
    }
}

void do_single_memintensive_compute(size_t thread_id, int &sum, float factor)
{
    for (size_t i = 0; i < 10000*factor; i++) 
    {
        uint index = ((uint) fast_rand(sum)) % (memintensive_compute_size);
        sum += (int) (memintensive_compute_data[thread_id][index]);
    }
}

void io_thread(size_t id)
{
    auto &io_count = io_thread_io_counts.local();
    Rand rand(file_size_kb*1024 - io_thread_io_size_kb*1024);
    Rand rand2(file_size_kb*1024);
    int sum = 1;
    while (!do_exit)
    {
        for (size_t i = 0; i < 1000; i++)
        {
            do_single_io(rand, io_thread_io_size_kb*1024);
            io_count++;
            if (add_random_access_after_io) do_single_random_access(rand2, sum); 
        }
    }
    if (sum == 99) cout << "BINGO" << endl;
}

void compute_thread(size_t id)
{
    auto &compute_count = compute_thread_compute_counts.local();
    Rand rand(file_size_kb*1024);
    int sum = 1;
    while (!do_exit)
    {
        if (memintensive_compute_operations) {
            for (size_t i = 0; i < 1000; i++)
            {
                do_single_memintensive_compute(id, sum, compute_thread_computeload_factor);
                compute_count++;
                if (add_random_access_after_compute) do_single_random_access(rand, sum); 
            }
        } else {
            for (size_t i = 0; i < 1000; i++)
            {
                do_single_compute(compute_thread_computeload_factor);
                compute_count++;
                if (add_random_access_after_compute) do_single_random_access(rand, sum); 
            }
        }

    }
    if (sum == 999999999) cout << "BINGO" << endl;
}

void mixed_thread(size_t id)
{
    auto &io_count = mixed_thread_io_counts.local();
    auto &compute_count = mixed_thread_compute_counts.local();
    Rand rand(file_size_kb*1024);
    int sum = 1;
    while (!do_exit)
    {
        for (size_t i = 0; i < 1000; i++)
        {
            do_single_io(rand, mixed_thread_io_size_kb*1024);
            io_count++;
            if (add_random_access_after_io) do_single_random_access(rand, sum); 

            do_single_compute(mixed_thread_computeload_factor);
            compute_count++;
            if (add_random_access_after_compute) do_single_random_access(rand, sum); 
        }
    }
    if (sum == 99) cout << "BINGO" << endl;
}

void _madvise_dontneed_thread(size_t period_ms) {
    while (!do_exit)
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(period_ms));
        madvise(mapping, file_size_kb * 1024, MADV_DONTNEED);
    }
}

vector<thread> io_threads;
vector<thread> compute_threads;
vector<thread> mixed_threads;
vector<thread> other_threads;

void spawn_threads()
{
    for (size_t i = 0; i < io_thread_count; i++) io_threads.emplace_back(io_thread, i);
    for (size_t i = 0; i < compute_thread_count; i++) compute_threads.emplace_back(compute_thread, i);
    for (size_t i = 0; i < mixed_thread_count; i++) mixed_threads.emplace_back(mixed_thread, i);

    if (do_periodically_madvise_dontneed_whole_file)
        other_threads.emplace_back(_madvise_dontneed_thread, periodically_madvise_dontneed_whole_file_period_ms);
}

void stop_threads()
{
    do_exit = true;
    for (auto& t : io_threads) t.join();
    for (auto& t : compute_threads) t.join();
    for (auto& t : mixed_threads) t.join();
    for (auto& t : other_threads) t.join();
}