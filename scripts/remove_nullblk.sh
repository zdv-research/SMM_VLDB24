cd /sys/kernel/config/
cd nullb/
cd nullb1; 

echo 0 > power;

cd ..

rmdir nullb1

rmmod null_blk