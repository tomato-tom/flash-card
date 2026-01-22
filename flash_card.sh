#!/bin/bash
# 英単語フラッシュカード (JSON対応版)

SPEECH=true  # 読み上げスイッチ
VOCAB_JSON="card/contents.json"

# jqの存在確認
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed."
    exit 1
fi

if [ ! -f "$VOCAB_JSON" ]; then
    echo "Error: $VOCAB_JSON not found."
    exit 1
fi

# 英語読み上げ関数
speech() {
    local text="$@"
    local tmp="/tmp/say.mp3"
    local speed="${SPEED:-1.0}"
    gtts-cli "$text" --output "$tmp"
    ffplay -autoexit -nodisp -loglevel quiet -af "atempo=$speed" "$tmp"
    [ -f "$tmp" ] && rm "$tmp"
}

source frame.sh
tput civis
echo "    === Flash Card (JSON Mode) ==="
read frame_row frame_col < <(get_pos)

easy=0
medium=0
hard=0

while true; do
    # priorityを考慮してランダムに1件抽出 (priorityが高いほど出やすい簡易ロジック)
    # 複雑な統計保存は今後の拡張とし、今は全データからランダムに1つ取得
    RAW_DATA=$(jq -c '.content | .[]' "$VOCAB_JSON" | shuf -n 1)
    
    if [ -z "$RAW_DATA" ]; then
        break
    fi
    
    english=$(echo "$RAW_DATA" | jq -r '.english')
    japanese=$(echo "$RAW_DATA" | jq -r '.japanese')
    card_id=$(echo "$RAW_DATA" | jq -r '."card-id"')

    # フレーム更新
    tput cup $frame_row $frame_col
    tput ed
    create_frame 1 3 9 45
    tput sc

    # 英語表示 & 読み上げ
    english_line=3
    english_color="\033[38;5;87m"
    [ "$SPEECH" = true ] && speech "$english" &

    write_at $english_line center "$english" "$english_color"
    tput rc
    tput ed

    echo "[$card_id] Any key to show answer (q:quit)"
    read -n 1 -t 3 -s input
    [ "$input" = "q" ] && break

    # 日本語表示
    japanese_line=6
    japanese_color="\033[0;32m"
    write_at $japanese_line center "$japanese" "$japanese_color"
    
    tput rc
    tput ed
    echo "e:Easy / m:Medium / h:Hard / q:Quit"
    
    read -n 1 -s input
    case "$input" in
        q) break ;;
        e) ((easy++)) ;;
        m) ((medium++)) ;;
        h) ((hard++)) ;;
        *) ((easy++)) ;; # デフォルト
    esac

    sleep 0.3
done

tput rc
tput ed

total=$((easy + medium + hard))
echo "Finished!"
echo "Total: $total | Easy: $easy | Medium: $medium | Hard: $hard"
tput cnorm
