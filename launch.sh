#!/bin/sh
datestamp=$(date '+%Y%m%d%H%M%S')
mkdir -p ./results
cat targets.json | ./vegeta attack -format="json" -duration=3s rate=500 | tee ./results/results-$datestamp.bin | ./vegeta plot > ./results/vegeta-plot-$datestamp.html
cat ./results/results-$datestamp.bin | ./vegeta report > ./results/report-$datestamp.txt
