
now=$(date +%F-%H-%M-%S)
output_dir="$(uname -r)_output_$now"
mkdir $output_dir

cwd=$(pwd)
parsec_dir="/home/fred/PARSEC/parsec-3.0"

ITERATIONS=20

cd $parsec_dir
source $parsec_dir/env.sh
cd $cwd


for bench in "blackscholes" "canneal" "fluidanimate" "streamcluster"; do
    echo "RUN $bench"
    for((i=0;i<ITERATIONS;i++)); do
        parsecmgmt -a run -p $bench -i simsmall >> $output_dir/out.$bench.txt
    done

    column1=$(for((i=0;i<ITERATIONS;i++)); do echo "$bench"; done)
    column2=$(grep real $output_dir/out.$bench.txt | awk '{printf $NF "\n"}')
    paste -d' ' <(echo "$column1") <(echo "$column2") | column -t | tee -a $output_dir/sum.txt
done