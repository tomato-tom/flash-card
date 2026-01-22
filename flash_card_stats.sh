#!/bin/bash
# 学習統計表示スクリプト

SESSION_DIR="data/sessions"
VOCAB_JSON="card/contents.json"

if [ ! -d "$SESSION_DIR" ] || [ -z "$(ls -A "$SESSION_DIR")" ]; then
    echo "No session logs found."
    exit 1
fi

echo "=== Flash Card Learning Statistics ==="

# 1. 全体の進捗状況
total_cards=$(jq '.content | length' "$VOCAB_JSON")
reviewed_once=$(jq '[.content[] | select(.review_count > 0)] | length' "$VOCAB_JSON")
avg_priority=$(jq '[.content[].priority] | add / length' "$VOCAB_JSON")

echo "--- Overall Progress ---"
printf "Total Cards    : %d\n" "$total_cards"
printf "Reached Cards  : %d (%d%%)\n" "$reviewed_once" "$(( total_cards > 0 ? reviewed_once * 100 / total_cards : 0 ))"
printf "Average Priority: %.2f (Lower is better)\n" "$avg_priority"
echo

# 2. 直近5セッションのサマリー
echo "--- Recent 5 Sessions ---"
echo "DATE             | EASY | MED  | HARD | DUR(m) "
echo "-----------------+------+------+------+--------"

# ファイル名の sess_YYYYMMDD_HHMMSS を YYYY-MM-DD HH:MM に変換
ls "$SESSION_DIR"/sess_*.json 2>/dev/null | sort -r | head -n 5 | while read -r log; do
    filename=$(basename "$log" .json)
    
    # 文字列操作で整形 (sess_20260122_190043 -> 2026-01-22 19:00)
    raw_dt=${filename#sess_}
    formatted_date="${raw_dt:0:4}-${raw_dt:4:2}-${raw_dt:6:2} ${raw_dt:9:2}:${raw_dt:11:2}"
    
    easy=$(jq '.summary.easy' "$log")
    med=$(jq '.summary.medium' "$log")
    hard=$(jq '.summary.hard' "$log")
    dur=$(jq '.duration_seconds' "$log")
    
    printf "%-16s | %4d | %4d | %4d | %5.1f\n" \
           "$formatted_date" "$easy" "$med" "$hard" "$(echo "scale=1; $dur/60" | bc -l)"
done
echo

# 3. 苦手な単語トップ5
echo "--- Top 5 Weak Cards (Need Focus) ---"
jq -r '.content | sort_by(.priority) | reverse | .[:5] | .[] | "\(.priority)|\(.english)|\(.japanese)"' "$VOCAB_JSON" | \
while IFS='|' read -r prio eng jap; do
    # バー表示ロジック
    bar_len=$(echo "$prio / 1" | bc)
    bar=$(printf "%${bar_len}s" | tr ' ' '#')
    printf "[%-12s] %4.2f | %s\n" "$bar" "$prio" "$eng"
done

echo
echo "Keep it up!"
