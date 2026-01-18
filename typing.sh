#!/bin/bash
# Typing game

tput sc

# JSONファイル
JSON_FILE="data.json"

if [ ! -f "$JSON_FILE" ] || [ ! -s "$JSON_FILE" ]; then
    echo '{"games":[]}' > "$JSON_FILE"
fi

# ゲーム結果を追加
log_game() {
    local word="$1"
    local input="$2"
    local time_taken="$3"
    
    # 新しいゲームデータ
    jq --arg timestamp "$(date '+%Y-%m-%d %H:%M:%S')" \
       --arg word "$word" \
       --arg input "$input" \
       --argjson time_taken "$time_taken" \
       '.games += [{
           timestamp: $timestamp,
           word: $word
           input: $input,
           time_taken: $time_taken
       }]' "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"
}


word_list=($(ls /usr/bin | grep -E '^[a-zA-Z0-9_-]+$'))
word_list+=($(ls /usr/sbin | grep -E '^[a-zA-Z0-9_-]+$'))
echo "words: ${#word_list[@]}"
echo -e "\n\033[1;35mPress ANY KEY to start...\033[0m"
read -rsn1

echo "Start typing game..."
echo "Ctrl-c to stop"
sleep 0.8

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
        correct=0
    else
        echo "✗ Failed"
        correct=1
    fi

    time_taken=$(echo "$end_time - $start_time" 2>/dev/null | bc)
    speed=$(echo "scale=2; ${#input} / $time_taken" | bc 2>/dev/null)
    printf "%.2f c/s\n" "${speed}"

    log_game "$text" "$input" "${time_taken}"
    sleep 0.7
done

