export MNAME=PBAR
sudo hwinfo --short >> ${MNAME}_hardware_hwinfo_short.txt
sudo hwinfo >> ${MNAME}_hardware_hwinfo.txt
sudo lscpu >> ${MNAME}_hardware_lscpu.txt
sudo dmidecode >> ${MNAME}_hardware_dmidecode.txt
cat /proc/meminfo >> ${MNAME}_hardware_meminfo.txt