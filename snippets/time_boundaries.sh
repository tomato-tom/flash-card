#!/bin/bash
# 期間計算


get_period() {
    local period="$1"

    case $period in
        today)
            # 今日の 00:00:00 〜 23:59:59
            start_boundary=$(date -d '00:00:00' '+%Y-%m-%d %H:%M:%S')
            end_boundary=$(date -d '23:59:59' '+%Y-%m-%d %H:%M:%S')
            period_name="Today"
            ;;
        week)
            # 7日前の 00:00:00 〜 今日の 23:59:59
            start_boundary=$(date -d '7 days ago 00:00:00' '+%Y-%m-%d %H:%M:%S')
            end_boundary=$(date -d '23:59:59' '+%Y-%m-%d %H:%M:%S')
            period_name="This Week"
            ;;
        month)
            # 今月1日の 00:00:00
            start_boundary=$(date -d "$(date +%Y-%m-01) 00:00:00" '+%Y-%m-%d %H:%M:%S')
            # 翌月1日の 00:00:00 から1秒戻した瞬間 = 今月最終日の 23:59:59
            end_boundary=$(date -d "$(date +%Y-%m-01) +1 month -1 second" '+%Y-%m-%d %H:%M:%S')
            period_name="This Month"
            ;;
        custom)
            # 指定日付の 00:00:00 〜 23:59:59
            shift
            local start="$1"
            local end="$2"

            start_boundary=$(date -d "$start 00:00:00" '+%Y-%m-%d %H:%M:%S')
            end_boundary=$(date -d "$end 23:59:59" '+%Y-%m-%d %H:%M:%S')
            period_name="Custom"
            ;;
        all|*)
            start_boundary="null"
            end_boundary="null"
            period_name="All Time"
            ;;
    esac
}


get_period
echo "name: $period_name"
echo "start: $start_boundary"
echo "end: $end_boundary"
echo

get_period custom 2026-01-15 2026-02-23
echo "name: $period_name"
echo "start: $start_boundary"
echo "end: $end_boundary"
echo

