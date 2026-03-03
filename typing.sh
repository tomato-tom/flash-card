#!/bin/bash
# Typing game
# 使い方
# ./typing.sh            - デフォルトの "man bash" よりコンテンツ抽出
# SOURCE=ls ./typing.sh  - "man ls" より

# 設定
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"
: ${SOURCE:="bash"}

# ログ用変数
SESSION_ID="session_$(date +%Y%m%d_%H%M%S)"
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
START_SEC=$(date +%s)
SESSION_DIR="$PROJECT_ROOT/data/typing"
JSON_FILE="$SESSION_DIR/$SESSION_ID.json"
LEVEL=""

# TTS
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

    # man2typing.sh
    if [[ ! -x "$PROJECT_ROOT/snippets/man2typing.sh" ]]; then
        echo "Error: ./snippets/man2typing.sh not found or not executable"
        exit 1
    fi

    for rec in "${recs[@]}"; do
        if ! command -v "$rec" &> /dev/null; then
            SPEECH=false
        fi
    done
}


# データ用のjsonファイル作成
create_json() {
    mkdir -p "$SESSION_DIR"
    jq -n --arg sid "$SESSION_ID" \
        --arg st "$START_TIME" \
        --arg src "$SOURCE" \
        --arg lv "$LEVEL" '{
           session_id: $sid,
           start_time: $st,
           source: $src,
           level: $lv,
           games: [] 
       }' > "$JSON_FILE"
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

# TUI風に難易度選択
select_menu() {
    local options=("easy" "medium" "hard" "quit")
    local selected=0
    local key

    tput civis
    tput sc
    
    while true; do
        tput rc
        tput ed
        echo "menu:"
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
                [ "${options[$selected]}" = "quit" ] && exit 0 ||
                    LEVEL="${options[$selected]}"
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
    local max_char
    local min_char

    # 各レベルの文字長さ
    case $LEVEL in
        easy) max_char=90; min_char=15 ;;
        medium) max_char=60; min_char=15 ;;
        hard) max_char=90; min_char=30 ;;
    esac

    # フレーズのリスト取得: man2typing.sh を利用
    mapfile -t word_list < <(
        "$PROJECT_ROOT/snippets/man2typing.sh" "$SOURCE" 2>/dev/null |
            grep -E "^.{$min_char,$max_char}$" |
            sort -u | shuf -n 300
    )

    # レベルeasyは単語のみ、フレーズから抽出
    max_char=15; min_char=5 ;
    if [[ "$LEVEL" == "easy" ]]; then
        local word_min=5
        local word_max=15
        
        mapfile -t word_list < <(
            printf '%s\n' "${word_list[@]}" |
                tr ' ' '\n' |
                grep -E "^[[:alpha:]]{$word_min,$word_max}$" |
                sort -u | shuf -n 300
        )
    fi
}

# クリーンアップ
cleanup() {
    [ -f "$SPEECH_FILE" ] && rm -f "$SPEECH_FILE"
    [ -f "${JSON_FILE}.tmp" ] && rm -f "${JSON_FILE}.tmp"
    tput cnorm
}

trap cleanup EXIT INT TERM

# main
select_menu
create_json
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

    # 各レベルの制限時間
    case $LEVEL in
        easy) time=8 ;;
        medium) time=5 ;;
        hard) time=3 ;;
    esac

    start_time=$(date +%s.%N)
    wait_time=$((text_length * time / 10))
    read -t $wait_time -r input

    end_time=$(date +%s.%N)
    echo
    tput civis

    [ "$input" == "q" ] && break

    if [ "$input" == "$text" ]; then
        echo "✓ Correct!"
    else
        echo "✗ Failed"
    fi

    # CPS計算
    time_taken=$(echo "$end_time - $start_time" | bc 2>/dev/null)
    speed=$(echo "scale=2; ${#input} / $time_taken" | bc 2>/dev/null)
    printf "%.2f c/s\n" "${speed}"
    log_game "$text" "$input" "${time_taken}"

    echo "Enter to next game"
    read -s input
    [ "$input" == "q" ] && break
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

