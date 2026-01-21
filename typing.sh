#!/bin/bash
# Typing game


# JSONファイル
JSON_FILE="typing_data.json"

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
           word: $word,
           input: $input,
           time_taken: $time_taken
       }]' "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"
}


MAX_CHAR=6  # 最大文字数、引数でオプションに?
pattern="^.{1,$MAX_CHAR}$"

word_list=($(ls /usr/bin | grep -E "$pattern"))
word_list+=($(ls /usr/sbin | grep -E "$pattern"))
echo "words: ${#word_list[@]}"
echo -e "\n\033[1;35mPress ANY KEY to start...\033[0m"
read -rsn1

tput sc
tput civis

echo "Start typing game..."
echo "Ctrl-c to stop"
sleep 0.8

while :; do
    tput rc
    tput ed

    index=$((RANDOM % ${#word_list[@]}))
    text="${word_list[$index]}"
    echo -n "Type it: "
    echo -e "\033[0;32m$text\033[0m"
    echo
    echo -en "\033[38;5;87m> \033[0m"
    tput cnorm

    # 表示から認識までのタイムラグ
    # 要調整
    sleep 0.3

    start_time=$(date +%s.%N)
    read input
    end_time=$(date +%s.%N)
    echo
    tput civis

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
    sleep 0.8 # 次のカードまでのインターバル
done

