#!/bin/bash
# Typing game

tput sc

#word_list=($(ls /usr/bin | grep -E '^[a-zA-Z0-9_-]+$'))
word_list=($(ls /usr/sbin | grep -E '^[a-zA-Z0-9_-]+$'))
echo "words: ${#word_list[@]}"
echo

while :; do
    index=$((RANDOM % ${#word_list[@]}))
    text="${word_list[$index]}"

    tput rc
    tput ed

    echo -n "Type it: "
    echo -e "\033[0;32m$text\033[0m"
    echo
    echo -en "\033[38;5;87m> \033[0m"

    start_time=$(date +%s.%N)
    read input
    end_time=$(date +%s.%N)
    echo

    if [ "$input" == "$text" ]; then
        echo "✓ Correct!"
    else
        echo "✗ Failed"
    fi

    time_taken=$(echo "$end_time - $start_time" 2>/dev/null | bc)
    speed=$(echo "scale=2; ${#input} / $time_taken" | bc 2>/dev/null)
    printf "%.2f c/s\n" "${speed:-0}"

    sleep 0.7
done

