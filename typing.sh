#!/bin/bash
# Typing game

# JSONファイル
JSON_FILE="typing_data.json"
SPEECH=true
SESSION_ID=${SESSION_ID:-$$}

# データ用のjsonファイルを初期化
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

# 読み上げ
speech() {
    local text="$@"
    local tmp="/tmp/say_${SESSION_ID}.mp3"
    gtts-cli "$text" --output "$tmp"
    ffplay -autoexit -nodisp -loglevel quiet "$tmp" > /dev/null 2>&1
    [ -f "$tmp" ] && rm "$tmp"

    sleep 3
}

# TUI風に単語セットを選択
select_word_set() {
    local options=("man-bash" "man-ip-link" "command" "man-sentence-bash" "quit")
    local selected=0
    local key

    tput civis
    tput sc
    
    while true; do
        tput rc
        tput ed
        echo "セットを選択:"
        echo
        
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo "→ ${options[$i]}"
            else
                echo "  ${options[$i]}"
            fi
        done
        
        read -rsn1 key
        case "$key" in
            k) ((selected > 0)) && ((selected--)) ;;  # k で上
            j) ((selected < ${#options[@]}-1)) && ((selected++)) ;; # j で下
            $'\x1b')
                read -rsn2 key
                case "$key" in
                    '[A') ((selected > 0)) && ((selected--)) ;;  # ↑
                    '[B') ((selected < ${#options[@]}-1)) && ((selected++)) ;; # ↓
                esac
                ;;
            '') # Enter
                WORD="${options[$selected]}"
                [ "$WORD" = "quit" ] && exit 0
                break
                ;;
        esac
    done
    
    tput cnorm
    tput rc
    tput ed
}

# PC内からコンテンツ読み込み
load_content() {
    local max_char=15
    local min_char=4
    local pattern="^[a-zA-Z]{$min_char,$max_char}$"

    local options=("man-bash" "man-ip-link" "command" "man-sentence-bash" "quit")
    # 単語セット読み込み
    if [[ "$WORD" == man-sentence-* ]]; then
        # 文モード: man2typing.sh を利用
        mapfile -t word_list < <(
            ./snippets/man2typing.sh "${WORD#man-sentence-}" 2>/dev/null | shuf -n 200
        )
    elif [[ "$WORD" == man-* ]]; then
        word_list=($(
            man "${WORD#man-}" 2>/dev/null |
            col -bx | tr -c '[:alnum:]' '\n' | grep -E "$pattern" |
            sort | uniq -i | shuf -n 300
        ))
    elif [ $WORD = "command" ]; then
        word_list=($(ls /usr/bin | grep -E "$pattern"))
        word_list+=($(ls /usr/sbin | grep -E "$pattern"))
        word_list=($(
            printf '%s\n' "${word_list[@]}" | shuf -n 300
        ))
    fi
}

# クリーンアップ
trap 'rm -f /tmp/say_*.mp3; tput cnorm' EXIT INT TERM

select_word_set
load_content
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
    text_length="$(echo -n $text | wc -c)"
    [ "$SPEECH" = true ] && speech "$text" &

    echo -n "Type it: "
    echo -e "\033[0;32m$text\033[0m"
    echo
    echo -en "\033[38;5;87m> \033[0m"
    tput cnorm

    start_time=$(date +%s.%N)
    base_time=$((text_length * 6 / 10))
    wait_time=$((base_time < 5 ? 5 : (base_time > 45 ? 45 : base_time)))
    read -t $wait_time -r input || true
    end_time=$(date +%s.%N)
    echo
    tput civis

    [ "$input" == "q" ] && break

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

