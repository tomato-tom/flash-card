#!/bin/bash
JSON_FILE="data/typing_data.json"
#JSON_FILE="test_data.json"

# オプション解析
period="all"  # デフォルト: 全期間
if [ $# -gt 0 ]; then
    case "$1" in
        today|t) period="today" ;;
        weekly|week|w) period="weekly" ;;
        monthly|month|m) period="monthly" ;;
        all|a) period="all" ;;
        *) 
            echo "使い方: $0 [today|weekly|monthly|all]"
            echo "  today    - 今日の統計"
            echo "  weekly   - 今週の統計"
            echo "  monthly  - 今月の統計"
            echo "  all      - 全期間の統計（デフォルト）"
            exit 1
            ;;
    esac
fi

jq -r --arg period "$period" '
  # 現在日時
  (now | strflocaltime("%Y-%m-%d")) as $today |
  (now | strflocaltime("%Y-%m")) as $this_month |
  (now | strflocaltime("%Y-%W")) as $this_week |
  
  .games as $all_games |
  
  # 期間でフィルタリング
  $all_games |
  if $period == "today" then
    map(select(.timestamp | startswith($today)))
  elif $period == "weekly" then
    map(select(
      .timestamp | 
      split(" ")[0] | 
      strptime("%Y-%m-%d") | 
      strftime("%Y-%W") == $this_week
    ))
  elif $period == "monthly" then
    map(select(.timestamp | startswith($this_month)))
  else
    .
  end |
  
  # 統計計算
  . as $games |
  ($games | map(select(.input == .word))) as $correct_games |
  
  ($games | length) as $total_games |
  ($correct_games | length) as $correct_count |
  ($correct_games | map(.input | length) | add // 0) as $total_chars |
  ($correct_games | map(.time_taken) | add // 0) as $total_time |
  (if $total_time > 0 then $total_chars / $total_time else 0 end) as $chars_per_sec |
  
  # 出力
  "=== タイピング・ゲーム統計 (\(
    if $period == "today" then "今日"
    elif $period == "weekly" then "今週"
    elif $period == "monthly" then "今月"
    else "全期間"
  end)) ===",
  "",
  "ゲーム数: \($total_games)",
  "正解数: \($correct_count)",
  "正解率: \(if $total_games > 0 then (($correct_count * 100) / $total_games | floor) else 0 end)%",
  "総プレイ時間: \($total_time | round)秒",
  "平均速度: \($chars_per_sec * 100 | round / 100) c/s"
' "$JSON_FILE" 2>/dev/null

