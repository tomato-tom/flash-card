#!/bin/bash
# テストデータ生成スクリプト

create_test_data() {
    cat > test_data.json << 'EOF'
{
  "games": [
    {
      "timestamp": "2026-01-15 10:30:00",
      "word": "yesterday1",
      "input": "yesterday1",
      "time_taken": 3.5
    },
    {
      "timestamp": "2026-01-15 14:45:00",
      "word": "yesterday2",
      "input": "yesterday2",
      "time_taken": 4.2
    },
    {
      "timestamp": "2026-01-16 09:15:00",
      "word": "two_days_ago",
      "input": "two_days_ago",
      "time_taken": 5.1
    },
    {
      "timestamp": "2026-01-16 16:20:00",
      "word": "two_days_ago2",
      "input": "two_days_ago2_wrong",
      "time_taken": 6.3
    },
    {
      "timestamp": "2026-01-17 11:30:00",
      "word": "last_week1",
      "input": "last_week1",
      "time_taken": 3.8
    },
    {
      "timestamp": "2026-01-10 13:45:00",
      "word": "last_week2",
      "input": "last_week2",
      "time_taken": 4.5
    },
    {
      "timestamp": "2026-01-05 08:00:00",
      "word": "early_this_month",
      "input": "early_this_month",
      "time_taken": 7.2
    },
    {
      "timestamp": "2025-12-28 15:30:00",
      "word": "last_month",
      "input": "last_month",
      "time_taken": 5.9
    },
    {
      "timestamp": "2025-12-15 10:00:00",
      "word": "last_month2",
      "input": "last_month2_wrong",
      "time_taken": 8.1
    },
    {
      "timestamp": "2025-11-20 14:00:00",
      "word": "two_months_ago",
      "input": "two_months_ago",
      "time_taken": 6.7
    },
    {
      "timestamp": "$(date '+%Y-%m-%d') 09:00:00",
      "word": "today1",
      "input": "today1",
      "time_taken": 3.2
    },
    {
      "timestamp": "$(date '+%Y-%m-%d') 14:30:00",
      "word": "today2",
      "input": "today2_wrong",
      "time_taken": 4.8
    },
    {
      "timestamp": "$(date '+%Y-%m-%d') 16:45:00",
      "word": "today3",
      "input": "today3",
      "time_taken": 2.9
    }
  ]
}
EOF

    # 日付を実際の値に置換
    local today=$(date '+%Y-%m-%d')
    local this_week=$(date '+%Y-%W')
    local this_month=$(date '+%Y-%m')
    
    # 先月のデータ
    local last_month=$(date -d "last month" '+%Y-%m')
    local last_month_date=$(date -d "last month" '+%Y-%m-%d')
    
    # 先週のデータ
    local last_week_date=$(date -d "last week" '+%Y-%m-%d')
    
    sed -i \
        -e "s|\$(date '+%Y-%m-%d')|$today|g" \
        -e "s|2026-01-15|$(date -d '3 days ago' '+%Y-%m-%d')|g" \
        -e "s|2026-01-16|$(date -d '2 days ago' '+%Y-%m-%d')|g" \
        -e "s|2026-01-17|$last_week_date|g" \
        -e "s|2026-01-10|$last_week_date|g" \
        -e "s|2026-01-05|$today|g" \
        -e "s|2025-12-28|$last_month_date|g" \
        -e "s|2025-12-15|$last_month_date|g" \
        -e "s|2025-11-20|$(date -d '2 months ago' '+%Y-%m-%d')|g" \
        test_data.json
    
    echo "テストデータを作成しました: test_data.json"
    echo "今日の日付: $today"
    echo "今月: $this_month"
}

# 既存のデータをテストデータで上書きする場合
if [ "$1" = "--overwrite" ]; then
    create_test_data
    cp test_data.json data.json
    echo "data.json をテストデータで上書きしました"
else
    create_test_data
    echo ""
    echo "元の data.json は保持されます"
    echo "テスト用: cp test_data.json data.json"
    echo "元に戻す: cp backup.json data.json (必要に応じてバックアップを取ってください)"
fi
