#include <linux/module.h>     /* Needed by all modules */
#include <linux/kernel.h>     /* Needed for KERN_INFO */
#include <linux/init.h>       /* Needed for the macros */
  
///< The license type -- this affects runtime behavior
MODULE_LICENSE("GPL");
  
///< The author -- visible when you use modinfo
MODULE_AUTHOR("Fred S");
  
///< The description -- see modinfo
MODULE_DESCRIPTION("TPMM cleaner");
  
///< The version of the module
MODULE_VERSION("0.1");

#include "../../../../tpmm/tpmm.h"

int init_module(void)
{
#if defined CONFIG_USE_TPMM_PAGE_FAULT_MARK || defined CONFIG_USE_TPMM_ALLOC_FLUSH_CHECK
	TPMM_PRINT("TPMM-CLEAN: start cleaning\n");

	size_t i;
	for (i = 0; i < nr_tpmm_data_blocks; i++) {
		memset(tpmm_data_blocks_starts[i], 0, tpmm_data_blocks_lengths[i]);
		TPMM_PRINT("TPMM:   cleaned %lu bytes at %p \n", tpmm_data_blocks_lengths[i], tpmm_data_blocks_starts[i]);
	}

	TPMM_PRINT("TPMM-CLEAN: done cleaning\n");

#endif

	return 0;
}

void cleanup_module(void)
{
	TPMM_PRINT("TPMM-CLEAN: quit\n");
}