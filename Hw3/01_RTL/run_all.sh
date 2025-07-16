#!/bin/bash
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
do
    echo "---------- Testing pattern $i ----------"
    ./01_run tb$i 10.0
done