#!/bin/bash
cycle=$1
for i in 0 1 2 3 4
do
    echo "---------- Testing pattern $i ----------"
    ./03_run tb$i $cycle | tee rtl_pr_$i.log
done