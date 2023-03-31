
modprobe null_blk

cd /sys/kernel/config/
cd nullb/

mkdir -p nullb1
cd nullb1; 

echo 0 > power;

echo 0 > zoned
echo 0 > completion_nsec
echo 2097152 > size # 200TB
echo 4096 > blocksize
echo 0 > memory_backed
echo 0 > irqmode
echo 10 > submit_queues

echo 1 > power;

chmod 777 /dev/nullb1

lsblk