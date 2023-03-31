#include <string>
#include <vector>
#include <random>
#include <sstream>

#include "../../../implementations/mmap_thread_private/test/thread_private_mmap.h"
#include <sys/mman.h>

using namespace std;

std::vector<std::string> split(std::string const &input) { 
    std::istringstream buffer(input);
    std::vector<std::string> ret((std::istream_iterator<std::string>(buffer)), 
                                 std::istream_iterator<std::string>());
    return ret;
}

uint64_t get_tlb_shootdowns()
{
    std::ifstream irq_stats("/proc/interrupts");
    assert(!!irq_stats);

    for (std::string line; std::getline(irq_stats, line);)
    {
        if (line.find("TLB") != std::string::npos)
        {
            std::vector<std::string> strs = split(line);
            uint64_t count = 0;
            for (size_t i = 0; i < strs.size(); i++)
            {
                std::stringstream ss(strs[i]);
                uint64_t c;
                ss >> c;
                count += c;
            }
            return count;
        }
    }
    return 0;
}

struct tlbdetails {
    uint64_t nr_tlb_remote_flush;
    uint64_t nr_tlb_remote_flush_received;
    uint64_t nr_tlb_local_flush_all;
    uint64_t nr_tlb_local_flush_one;
};

struct tlbdetails get_tlb_details()
{
    std::ifstream irq_stats("/proc/vmstat");
    assert(!!irq_stats);

    struct tlbdetails _tlb_details;

    for (std::string line; std::getline(irq_stats, line);)
    {
        if (line.find("nr_tlb_remote_flush") != std::string::npos)
        {
            {
                std::vector<std::string> strs = split(line);
                std::stringstream ss(strs[1]); ss >> _tlb_details.nr_tlb_remote_flush;
            }

            std::getline(irq_stats, line);
            {
                std::vector<std::string> strs = split(line);
                std::stringstream ss(strs[1]); ss >> _tlb_details.nr_tlb_remote_flush_received;
            }

            std::getline(irq_stats, line);
            {
                std::vector<std::string> strs = split(line);
                std::stringstream ss(strs[1]); ss >> _tlb_details.nr_tlb_local_flush_all;
            }

            std::getline(irq_stats, line);
            {
                std::vector<std::string> strs = split(line);
                std::stringstream ss(strs[1]); ss >> _tlb_details.nr_tlb_local_flush_one;
            }

            return _tlb_details;
        }
    }
    return tlbdetails();
}



class Rand
{
public:
    std::random_device rd;
    std::mt19937 gen;
    std::uniform_int_distribution<uint64_t> rnd;
    Rand(uint64_t max) : rd{}, rnd{0, max}, gen{rd()} {}
};

ulong mapping_string_to_bitmask(string mapping) {
    if (mapping == "shared")
        return MAP_SHARED;
    if (mapping == "thread_private")
        return MAP_PRIVATE | MAP_SMM;
    if (mapping == "shared_thread_private")
        return MAP_SHARED | MAP_SMM;
    return MAP_PRIVATE;
}