#!/bin/bash
# 英単語フラッシュカード (Session Log & Priority Update 版)

SPEECH=true
VOCAB_JSON="card/contents.json"
SESSION_DIR="data/sessions"
mkdir -p "$SESSION_DIR"

# 依存チェック
for cmd in jq bc gtts-cli ffplay; do
    if ! command -v $cmd &> /dev/null; then echo "Error: $cmd is not installed."; exit 1; fi
done

# ログ用変数
SESSION_ID="sess_$(date +%Y%m%d_%H%M%S)"
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
START_SEC=$(date +%s)
TMP_LOG=$(mktemp)

# 英語読み上げ
speech() {
    local text="$@"
    local tmp="/tmp/say_${SESSION_ID}.mp3"
    gtts-cli "$text" --output "$tmp"
    ffplay -autoexit -nodisp -loglevel quiet "$tmp"
    [ -f "$tmp" ] && rm "$tmp"
}

source frame.sh
tput civis
read frame_row frame_col < <(get_pos)

easy_c=0; medium_c=0; hard_c=0

while true; do
    # priorityに基づく重み付け抽出
    RAW_DATA=$(jq -c '.content[]' "$VOCAB_JSON" | awk -F: '{
        split($0, a, "\"priority\":"); split(a[2], b, ","); 
        p=b[1]*10; for(i=0; i<p; i++) print $0 
    }' | shuf -n 1)
    
    [ -z "$RAW_DATA" ] && break
    
    english=$(echo "$RAW_DATA" | jq -r '.english')
    japanese=$(echo "$RAW_DATA" | jq -r '.japanese')
    card_id=$(echo "$RAW_DATA" | jq -r '."card-id"')
    curr_p=$(echo "$RAW_DATA" | jq -r '.priority')

    # 画面描画
    tput cup $frame_row $frame_col; tput ed
    create_frame 1 3 9 45
    tput sc
    [ "$SPEECH" = true ] && speech "$english" &
    write_at 3 center "$english" "\033[38;5;87m"
    
    tput rc; tput ed
    echo "[$card_id] Any key to answer (q:quit)"
    read -n 1 -t 5 -s input
    [ "$input" = "q" ] && break

    write_at 6 center "$japanese" "\033[0;32m"
    tput rc; tput ed
    echo "e:Easy(x0.7) / m:Med(x1.2) / h:Hard(x1.5) / q:Quit"
    
    read -n 1 -s input
    case "$input" in
        q) break ;;
        e) rate=0.7; eval="easy";   ((easy_c++)) ;;
        h) rate=1.5; eval="hard";   ((hard_c++)) ;;
        *) rate=1.2; eval="medium"; ((medium_c++)) ;;
    esac

    # 新しいPriority計算 (0.5〜3.0の範囲に制限)
    new_p=$(echo "$curr_p * $rate" | bc -l | xargs printf "%.2f")
    if (( $(echo "$new_p < 0.5" | bc -l) )); then new_p="0.50"; fi
    if (( $(echo "$new_p > 3.0" | bc -l) )); then new_p="3.00"; fi

    # 一時ログ保存
    echo "$card_id|$english|$eval|$curr_p|$new_p|$(date '+%Y-%m-%d %H:%M:%S')" >> "$TMP_LOG"
    sleep 0.3
done

# --- 終了処理: ログ生成 & Master更新 ---
END_TIME=$(date "+%Y-%m-%d %H:%M:%S")
DURATION=$(( $(date +%s) - START_SEC ))

if [ -s "$TMP_LOG" ]; then
    echo "Saving session..."
    
    # 1. セッションJSON生成
    jq -n --arg sid "$SESSION_ID" --arg st "$START_TIME" --arg et "$END_TIME" \
       --arg dur "$DURATION" --arg cid "c01" \
       --arg ec "$easy_c" --arg mc "$medium_c" --arg hc "$hard_c" \
       '{session_id: $sid, start_time: $st, end_time: $et, duration_seconds: ($dur|tonumber), cards_reviewed: (($ec|tonumber)+($mc|tonumber)+($hc|tonumber)), "contents-id": $cid, cards: [], summary: {easy: ($ec|tonumber), medium: ($mc|tonumber), hard: ($hc|tonumber)}}' > "$SESSION_DIR/$(date +%Y-%m-%d).json"

    # カード詳細をJSONに追加
    while IFS='|' read -r id eng ev cp np tm; do
        jq --arg id "$id" --arg tm "$tm" --arg eng "$eng" --arg ev "$ev" --arg cp "$cp" --arg np "$np" \
           '.cards += [{card_id: $id, time: $tm, text: $eng, self_evaluation: $ev, current_priority: ($cp|tonumber), new_priority: ($np|tonumber)}]' \
           "$SESSION_DIR/$(date +%Y-%m-%d).json" > "$SESSION_DIR/tmp.json" && mv "$SESSION_DIR/tmp.json" "$SESSION_DIR/$(date +%Y-%m-%d).json"

        # 2. Master JSON (contents.json) の更新
        jq --arg id "$id" --arg np "$np" --arg today "$(date +%Y-%m-%d)" \
           '(.content[] | select(."card-id" == $id)) |= (.priority = ($np|tonumber) | .last_reviewed = $today | .review_count += 1)' \
           "$VOCAB_JSON" > "${VOCAB_JSON}.tmp" && mv "${VOCAB_JSON}.tmp" "$VOCAB_JSON"
    done < "$TMP_LOG"
fi

rm -f "$TMP_LOG"
tput cnorm
echo "Done! Session logged to $SESSION_DIR"
