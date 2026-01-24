#!/bin/bash
# Typing game

# JSONファイル
JSON_FILE="typing_data.json"
WORD="man"
#WORD="command"
SPEECH=true
SESSION_ID=${SESSION_ID:-$$}

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

# 英語読み上げ
speech() {
    local text="$@"
    local tmp="/tmp/say_${SESSION_ID}.mp3"
    gtts-cli "$text" --output "$tmp"
    ffplay -autoexit -nodisp -loglevel quiet "$tmp" > /dev/null 2>&1
    [ -f "$tmp" ] && rm "$tmp"

    sleep 3
}

# クリーンアップ
trap 'rm -f /tmp/say_*.mp3; tput cnorm' EXIT INT TERM

# 単語セット読み込み
if [ $WORD = "man" ]; then
    word_list=($(
        man bash | col -bx | tr -c '[:alnum:]' '\n' | grep -E '^[a-zA-Z]{4,}$' |
        sort | uniq -i | shuf -n 300
    ))
elif [ $WORD = "command" ]; then
    MAX_CHAR=15  # 最大文字数、引数でオプションに?
    word_list=($(ls /usr/bin | grep -E "^.{1,$MAX_CHAR}$"))
    word_list+=($(ls /usr/sbin | grep -E "^.{1,$MAX_CHAR}$"))
    echo "${word_list[@]}" | tr ' ' '\n' | shuf -n 300
fi

echo "words: ${#word_list[@]}"
echo -ne "\n\033[1;35mPress ANY KEY to start...\033[0m\r"
read -rsn1
tput ed

echo "Start typing game..."
echo "q to stop"
tput sc
tput civis

sleep 0.3

while :; do
    tput rc
    tput ed

    index=$((RANDOM % ${#word_list[@]}))
    text="${word_list[$index]}"
    [ "$SPEECH" = true ] && speech "$text" &
    echo -n "Type it: "
    echo -e "\033[0;32m$text\033[0m"
    echo
    echo -en "\033[38;5;87m> \033[0m"
    tput cnorm

    # 表示から認識までのタイムラグ
    # 要調整
    #sleep 0.4

    start_time=$(date +%s.%N)
    read -t 8 -r input || { echo "Timeout..."; exit 1; }
    end_time=$(date +%s.%N)
    echo
    tput civis

    if [ "$input" == "q" ]; then
        break
    fi

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
    sleep 0.8
done

