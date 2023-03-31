#ifndef _TPMM_H
#define _TPMM_H

#include <linux/types.h>
#include <linux/mmzone.h>
#include <linux/memblock.h>
#include <linux/cred.h>
#include <linux/cpumask.h>
#include <linux/version.h>
#include <asm/pgtable.h>

#if LINUX_VERSION_CODE <= KERNEL_VERSION(4,15,0)
#include <linux/bootmem.h>              
#endif

/*
    -----------------------------------
    DEBUG
    -----------------------------------
*/

#define TPMM_PRINT(m, ...) printk(KERN_INFO m, ##__VA_ARGS__);

#ifdef CONFIG_TPMM_DEBUG_ENABLED

#define TPMM_DEBUG(m, ...) printk(KERN_ERR m, ##__VA_ARGS__);
#define TPMM_DEBUG_IF(condition, m, ...) if (condition) {printk(KERN_ERR m, ##__VA_ARGS__);}

#else

#define TPMM_DEBUG(m, ...) do {} while(0)
#define TPMM_DEBUG_IF(condition, m, ...) do {} while(0)

#endif

//#ifdef CONFIG_USE_TPMM_SEC_AND_KSWAPD
#if defined CONFIG_USE_TPMM_PAGE_FAULT_MARK || defined CONFIG_USE_TPMM_ALLOC_FLUSH_CHECK || defined CONFIG_USE_TPMM_KSWAPD_TLB_SKIP

/*
    -----------------------------------
    CONSTANTS ABD GLOBALS
    -----------------------------------
*/

#define TPMM_FLAG_IS_TPMM_PAGE                  (1 << 0)
#define TPMM_FLAG_FORCE_SHOOTDOWN_ON_ALLOCATION (1 << 1)
#define TPMM_FLAG_LOG_ONLY                      (1 << 2)

#define TPMM_ID_MODE_PID                (1 << 0)
#define TPMM_ID_MODE_PARENT_PID         (1 << 1)
#define TPMM_ID_MODE_UID                (1 << 2)
#define TPMM_ID_MODE                    TPMM_ID_MODE_UID

extern unsigned long tpmm_tlb_flush_counter;
extern unsigned long reverted_pages;

extern size_t nr_tpmm_data_blocks;
extern size_t tpmm_data_blocks_lengths[64];
extern struct tpmm_page_data* tpmm_data_blocks_starts[64];

extern int after_bootmem;


/*
    -----------------------------------
    TYPES
    -----------------------------------
*/

struct tpmm_page_data {
    u8 flags;
    u8 unused[3];
    u32 id;
    u64 counter;

    /* Current sizes only for simplicity. Can be sized down to 64 bit total:
       22 bits id
       32 bits counter
       3 to 10 bits flags
    */

};


/*
    -----------------------------------
    HELPERS
    -----------------------------------
*/

static inline unsigned int tpmm_current_id (unsigned int mode) {
    return current_uid().val; // TODO: check mode (preprocessor)
};
static inline void tpmm_set_flag (struct tpmm_page_data* tpd, char mask, char value) {
    tpd->flags |= (value & mask);
};
static inline void tpmm_set_flag_true (struct tpmm_page_data* tpd, char mask) {
    tpmm_set_flag(tpd, mask, 255);
};
static inline void tpmm_set_flag_false (struct tpmm_page_data* tpd, char mask) {
    tpmm_set_flag(tpd, mask, 0);
};
static inline bool tpmm_read_flag (struct tpmm_page_data* tpd, char mask) {
    return tpd->flags & mask;
};


/*  
    -----------------------------------
    Implementation
    -----------------------------------
*/

/*
    Define some specialized TLB shootdown functions next to the default try_to_unmap_flush()
*/
void arch_tlbbatch_flush(struct arch_tlbflush_unmap_batch *batch); // forward declaration
static inline void try_to_unmap_flush_tpmm_skip(void)
{
	struct tlbflush_unmap_batch *tlb_ubc = &current->tlb_ubc;

    tlb_ubc->arch.cpumask = CPU_MASK_NONE;

	tlb_ubc->flush_required = false;
	tlb_ubc->writable = false;
}
static inline void try_to_unmap_flush_tpmm_mask(struct cpumask _cpumask)
{
	struct tlbflush_unmap_batch *tlb_ubc = &current->tlb_ubc;

	if (!tlb_ubc->flush_required)
		return;

	tlb_ubc->arch.cpumask = _cpumask;

	arch_tlbbatch_flush(&tlb_ubc->arch);
	tlb_ubc->flush_required = false;
	tlb_ubc->writable = false;

	tpmm_tlb_flush_counter++;
}


/*
    Here, we create space to store TPMM data per page.
*/
#define LONG_ALIGN(x) (((x)+(sizeof(long))-1)&~((sizeof(long))-1))
#if LINUX_VERSION_CODE <= KERNEL_VERSION(4,15,0)
phys_addr_t memblock_alloc_try_nid(phys_addr_t size, phys_addr_t align, int nid); // forward declaration
#else
static inline void *memblock_alloc_node(phys_addr_t size, phys_addr_t align, int nid); // forward declaration
#endif
static inline void tpmm_init_zone (struct zone *zone, unsigned int order) {

#ifdef CONFIG_USE_TPMM_PMEM
    gfp_t flags;
#endif

    int nid;
    unsigned long size = zone->spanned_pages;       // total number of pages

    unsigned long tpmm_size = (size) >> (order);    // number of elements needed in this order
    tpmm_size = tpmm_size * sizeof(struct tpmm_page_data); // total byte size
    tpmm_size = LONG_ALIGN(tpmm_size+1);

#ifdef CONFIG_NUMA
	nid = zone->node;
#else
	nid = 0;
#endif

    TPMM_PRINT("TPMM: want to allocate %lu bytes\n", tpmm_size);
    TPMM_PRINT("TPMM:   spanned %lu, present %lu \n", zone->spanned_pages, zone->present_pages);
    TPMM_PRINT("TPMM:   nid %d, zone_idx %ld \n", nid, zone_idx(zone));
        
    if (size != 0) {
#if LINUX_VERSION_CODE <= KERNEL_VERSION(4,15,0)
		//zone->free_area[order].tpmm = 
		//	(struct tpmm_page_data *) memblock_alloc_try_nid((phys_addr_t) tpmm_size, (phys_addr_t) sizeof(long), nid);
        // static inline void * __init memblock_virt_alloc_node(
		// 				phys_addr_t size, int nid)
        zone->free_area[order].tpmm = 
			(struct tpmm_page_data *) memblock_virt_alloc_node((phys_addr_t) tpmm_size, nid);                    
#else

#ifdef CONFIG_USE_TPMM_PMEM
        if (!after_bootmem) {
#endif
            zone->free_area[order].tpmm = 
                (struct tpmm_page_data *) memblock_alloc_node((phys_addr_t) tpmm_size, (phys_addr_t) sizeof(long), nid);
#ifdef CONFIG_USE_TPMM_PMEM
        } else {
            TPMM_PRINT("TPMM:   allocating after bootmem.\n");
            flags = GFP_KERNEL | __GFP_ZERO | __GFP_NOWARN;
            zone->free_area[order].tpmm = 
                alloc_pages_exact_nid(nid, tpmm_size, flags);
        }
#endif


#endif

        TPMM_PRINT("TPMM:   allocated %lu bytes at %p \n", tpmm_size, zone->free_area[order].tpmm);

        tpmm_data_blocks_starts[nr_tpmm_data_blocks] = zone->free_area[order].tpmm;
        tpmm_data_blocks_lengths[nr_tpmm_data_blocks] = tpmm_size;
        nr_tpmm_data_blocks++;

    }

    // memblock allocated memory should be initialized to zero
};


/*
    Here, we need to mark pages, that were allocated using TPMM.
    Page is a order 0 page.
*/
static inline struct zone *page_zone(const struct page *page); // forward declaration
static inline void tpmm_on_page_fault (struct page *page) {

    unsigned long pfn = page_to_pfn(page);
    struct zone *zone = page_zone(page);
    unsigned long z_idx = pfn - zone->zone_start_pfn;
    
    struct tpmm_page_data tpd = {0};
    tpmm_set_flag_true(&tpd, TPMM_FLAG_IS_TPMM_PAGE);
    tpd.id = tpmm_current_id(TPMM_ID_MODE);
    tpd.counter = tpmm_tlb_flush_counter;

    zone->free_area[0].tpmm[z_idx] = tpd;

    TPMM_DEBUG("TPMM tpmm_on_page_fault page=%p \n", page);
}


/*
    Here on alloc we need to check, if the page was previously a tpmm page.
    If it was a tpmm page, we need a tlb shootdown if the tpmm page was from another id or if it is forced, AND if no other tlb shootdown occured (counter == saved counter).
*/
static inline void _tpmm_on_buddy_alloc (struct zone *zone, struct page *page, unsigned int order) {
    unsigned long pfn = page_to_pfn(page);
    unsigned long z_idx = pfn - zone->zone_start_pfn;

    struct tpmm_page_data zero_tpd = {0};

    struct tpmm_page_data *tpd = &(zone->free_area[0].tpmm[z_idx]);

    bool page_was_tpmm = tpmm_read_flag(tpd, TPMM_FLAG_IS_TPMM_PAGE);
    bool page_has_force_shootdown = tpmm_read_flag(tpd, TPMM_FLAG_FORCE_SHOOTDOWN_ON_ALLOCATION);

    

    if ( (page_was_tpmm && tpd->id != tpmm_current_id(TPMM_ID_MODE)) || page_has_force_shootdown) {

        TPMM_DEBUG("TPMM _tpmm_on_buddy_alloc page=%p \n", page);
        if (tpd->counter == tpmm_tlb_flush_counter)
            try_to_unmap_flush_tpmm_mask(CPU_MASK_ALL);

        *tpd = zero_tpd;
        reverted_pages++;
        if (reverted_pages % 262144 == 0) {
            TPMM_PRINT("TPMM: reverted %lu GB, flag=%d, id=%u, deleter=%u \n", 
            reverted_pages/262144, tpmm_read_flag(tpd, TPMM_FLAG_IS_TPMM_PAGE), tpd->id, (u32) tpmm_current_id(TPMM_ID_MODE));
        }
    }
}
static inline void tpmm_on_buddy_alloc (struct page *page, unsigned int order) {
    _tpmm_on_buddy_alloc(page_zone(page), page, order);
}


/*
    Bulk allocator allocs multiple order 0 pages. It first tries pcp lists, then falls back to __alloc_pages().
    As __alloc_pages() calls tpmm_on_buddy_alloc, we need to also handle the pcp allocations.
*/
static inline void tpmm_on_buddy_alloc_bulk_per_pcp_page (struct zone *zone, struct page *page) {
    _tpmm_on_buddy_alloc(zone, page, 0);
}


/*
    Here we take care, to properly pass tpmm information up to higher orders of buddy allocator, if pages merge.
*/
static inline void tpmm_on_page_merge (struct page *page, unsigned long pfn, unsigned long buddy_pfn, unsigned long combined_pfn) {
    struct zone *zone = page_zone(page);

    struct tpmm_page_data zero_tpd = {0};
    struct tpmm_page_data combined_tpd = zero_tpd;

    unsigned long page_z_idx = pfn - zone->zone_start_pfn;
    unsigned long buddy_z_idx = buddy_pfn - zone->zone_start_pfn;

    struct tpmm_page_data *page_tpd = &(zone->free_area[0].tpmm[page_z_idx]);
    struct tpmm_page_data *buddy_tpd = &(zone->free_area[0].tpmm[buddy_z_idx]);

    bool page_is_tpmm = tpmm_read_flag(page_tpd, TPMM_FLAG_IS_TPMM_PAGE);
    bool buddy_is_tpmm = tpmm_read_flag(buddy_tpd, TPMM_FLAG_IS_TPMM_PAGE);
    bool page_is_force = tpmm_read_flag(page_tpd, TPMM_FLAG_FORCE_SHOOTDOWN_ON_ALLOCATION);
    bool buddy_is_force = tpmm_read_flag(buddy_tpd, TPMM_FLAG_FORCE_SHOOTDOWN_ON_ALLOCATION);

    // We can early out, if the pages are no tpmm pages.
    if (!page_is_tpmm && !buddy_is_tpmm)
        return;

    // At least one of the pages is tpmm, so upper page has to be tpmm.
    
    tpmm_set_flag_true(&combined_tpd, TPMM_FLAG_IS_TPMM_PAGE);

    // If one of the lower pages is on force mode, combined has to be on force mode, too.
    if (page_is_force || buddy_is_force) {
        tpmm_set_flag_true(&combined_tpd, TPMM_FLAG_FORCE_SHOOTDOWN_ON_ALLOCATION);
        goto out;
    }

    // Lower pages are not on force mode. 
    // Upper page needs an id.
    // If lower pages have the same id, upper page can take it. Here, even if one of the pages is no tpmm, the resuting id would be correct, 
    if (page_tpd->id == buddy_tpd->id) {
        combined_tpd.id = page_tpd->id;
        goto out;
    } else {

        // if only one page tpmm?
        if (page_is_tpmm != buddy_is_tpmm) {
            if (page_is_tpmm) {
                combined_tpd.id = page_tpd->id;
                goto out;
            } else {
                combined_tpd.id = buddy_tpd->id;
                goto out;
            } 
        } 

        // Here, both must be tpmm pages. if both are tpmm, but have different id's, we need to force tlb on next allocation (of cource if not 'overcounted')
        tpmm_set_flag_true(&combined_tpd, TPMM_FLAG_FORCE_SHOOTDOWN_ON_ALLOCATION);
        goto out;
    }

out:

    // pass highest of both counters to combined page
    combined_tpd.counter = page_tpd->counter >= buddy_tpd->counter ? page_tpd->counter : buddy_tpd->counter;

    // clear lower ones
    *page_tpd = zero_tpd;
    *buddy_tpd = zero_tpd;

    // commit combined one
    zone->free_area[0].tpmm[combined_pfn - zone->zone_start_pfn] = combined_tpd;

}


/*
    If split is performed for an 'exact' allocation, a page of order(size) is allocated and split. TPMM is handled within this higher order allocation. Leftover pages are freed again to the buddy allocator.
    If split is performed for a pcp list refill, a page of an higher order is allocated and split. TPMM is handled within this higher order allocation.
*/
static inline void tpmm_on_page_split (struct page *page, size_t size) {
    // Nothing todo here.
}

#ifdef CONFIG_USE_TPMM_MIGRATION

static inline void tpmm_on_page_migration (struct page *old, struct page *new) {}

#endif /* CONFIG_USE_TPMM_MIGRATION */



#ifdef CONFIG_USE_TPMM_FINE_CPUBITMASKS

breaks

extern struct cpumask cpumask[NR_CPUS];

static inline void tpmm_cpu_fine_handling_on_allocation_tlb_flush () {}
static inline void tpmm_cpu_fine_handling_on_tpmm_deallocation () {}

#endif /* CONFIG_USE_TPMM_FINE_CPUBITMASKS */

#endif /* defined CONFIG_USE_TPMM_PAGE_FAULT_MARK || defined CONFIG_USE_TPMM_ALLOC_FLUSH_CHECK || defined CONFIG_USE_TPMM_KSWAPD_TLB_SKIP */

#endif /* _TPMM_H */