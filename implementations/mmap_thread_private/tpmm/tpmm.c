unsigned long tpmm_tlb_flush_counter = 0;
unsigned long reverted_pages = 0;

size_t nr_tpmm_data_blocks = 0;
EXPORT_SYMBOL(nr_tpmm_data_blocks);
size_t tpmm_data_blocks_lengths[64];
EXPORT_SYMBOL(tpmm_data_blocks_lengths);
struct tpmm_page_data* tpmm_data_blocks_starts[64];
EXPORT_SYMBOL(tpmm_data_blocks_starts);

#ifdef CONFIG_USE_TPMM_FINE_CPUBITMASKS
struct cpumask cpumask[NR_CPUS] = {{0}};
#endif /* CONFIG_USE_TPMM_FINE_CPUBITMASKS */