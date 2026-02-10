#!/bin/bash
period=${1:-7}    # デフォルト7日
count=${2:-3}     # デフォルト3期間

for i in $(seq 0 $((count - 1))); do
    end=$(date -d "$((i * period)) days ago" '+%Y-%m-%d')
    start=$(date -d "$((i * period + period - 1)) days ago" '+%Y-%m-%d')
    echo "$start to $end"
    ./typing_stats.sh --start "$start" --end "$end" | grep -E '(Sessions|Total Games|Accuracy)'
done
