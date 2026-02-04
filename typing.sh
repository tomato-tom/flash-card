#!/bin/bash
# Typing game

# 設定
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"

# ログ用変数
SESSION_ID="session_$(date +%Y%m%d_%H%M%S)"
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
START_SEC=$(date +%s)

SPEECH_FILE="/dev/shm/say_${SESSION_ID}.mp3"
SPEECH=true

# 依存チェック
check_dependencies() {
    local deps=("jq" "bc" "tput")
    local recs=("gtts-cli" "ffplay")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing[*]}"
        exit 1
    fi

    for rec in "${recs[@]}"; do
        if ! command -v "$rec" &> /dev/null; then
            SPEECH=false
        fi
    done
}

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
    gtts-cli "$text" --output "$SPEECH_FILE"
    ffplay -autoexit -nodisp -loglevel quiet "$SPEECH_FILE" > /dev/null 2>&1
    [ -f "$SPEECH_FILE" ] && rm "$SPEECH_FILE"
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

# FIXME - WORDもsentenceから取得すれば単語がとぎれないか
# PC内からコンテンツ読み込み
load_content() {
    local max_char_sentence=$(tput cols)
    local max_char_word=15
    local min_char_word=4
    local pattern="^[a-zA-Z]{$min_char_word,$max_char_word}$"

    # 単語セット読み込み
    if [[ "$WORD" == man-sentence-* ]]; then
        # 文モード: man2typing.sh を利用
        mapfile -t word_list < <(
            ./snippets/man2typing.sh "${WORD#man-sentence-}" 2>/dev/null |
                grep -E "^.{15,$max_char_sentence}$" |
                shuf -n 200
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
cleanup() {
    [ -f "$SPEECH_FILE" ] && rm -f "$SPEECH_FILE"
    [ -f "${JSON_FILE}.tmp" ] && rm -f "${JSON_FILE}.tmp"
    tput cnorm
}

trap cleanup EXIT INT TERM

select_word_set

# データ用のjsonファイル作成
SESSION_DIR="$PROJECT_ROOT/data/typing"
mkdir -p "$SESSION_DIR"
JSON_FILE="$SESSION_DIR/$SESSION_ID.json"
jq -n --arg sid "$SESSION_ID" \
    --arg st "$START_TIME" \
    --arg ct "$WORD" '{
       session_id: $sid,
       start_time: $st,
       content: $ct,
       games: [] 
   }' > "$JSON_FILE"
    
load_content
echo "words: ${#word_list[@]}"
echo -ne "\n\033[1;35mPress ANY KEY to start...\033[0m\r"
read -rsn1
tput ed

echo "Start typing game..."
echo "q to stop"
tput sc
tput civis

while :; do
    tput rc
    tput ed

    index=$((RANDOM % ${#word_list[@]}))
    text="${word_list[$index]}"
    text_length="$(echo -n $text | wc -c)"
    [ "$SPEECH" = true ] && speech "$text" &

    echo "Type it: "
    echo
    echo "$text"
    echo
    echo
    echo -en "\033[38;5;87m> \033[0m"
    tput cnorm

    start_time=$(date +%s.%N)
    base_time=$((text_length * 5 / 10))
    wait_time=$((base_time < 5 ? 5 : (base_time > 60 ? 60 : base_time)))
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
    read -s -t 0.8
done

# 終了処理: ログ更新
END_TIME=$(date "+%Y-%m-%d %H:%M:%S")
DURATION=$(( $(date +%s) - START_SEC ))

echo "Saving session..."
# セッション終了データ書き込み
jq --arg et "$END_TIME" \
    --arg dur "$DURATION" \
    '. + {
       end_time: $et,
       duration_seconds: ($dur|tonumber)
    }' "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"

[ -f "${JSON_FILE}.tmp" ] && rm -f "${JSON_FILE}.tmp"
echo "Session saved: $JSON_FILE"

