#!/bin/bash
set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly SESSION_DIR="$PROJECT_ROOT/data/typing"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# 定数・グローバル変数
# ============================================================================
declare PERIOD="all"
declare START_ARG="" END_ARG=""
declare -a TARGET_FILES=()
declare START_BOUNDARY="null" END_BOUNDARY="null"
declare PERIOD_NAME=""

# ============================================================================
# ユーティリティ関数
# ============================================================================
log_error() { echo "Error: $*" >&2; }
log_fatal() { log_error "$*"; exit 1; }

# ============================================================================
# 引数解析
# ============================================================================
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Show typing game statistics for different time periods.

Period options (mutually exclusive):
  -l, --latest    Show statistics for the most recent session
  -t, --today     Show statistics for today (00:00 to 23:59)
  -w, --week      Show statistics for the last 7 days
  -m, --month     Show statistics for the current month
  -a, --all       Show statistics for all time (default)

Custom range options (must be used together):
  --start YYYY-MM-DD   Start date (inclusive, from 00:00:00)
  --end YYYY-MM-DD     End date (inclusive, until 23:59:59)

Examples:
  $0 --today
  $0 --start 2026-01-24 --end 2026-02-23
  $0          # Same as --all
EOF
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--latest) PERIOD="latest"; shift ;;
            -t|--today) PERIOD="today"; shift ;;
            -w|--week) PERIOD="week"; shift ;;
            -m|--month) PERIOD="month"; shift ;;
            -a|--all) PERIOD="all"; shift ;;
            --start) START_ARG="$2"; shift 2 ;;
            --end) END_ARG="$2"; shift 2 ;;
            -h|--help) show_help ;;
            *) log_fatal "Unknown option: $1" ;;
        esac
    done
}

# ============================================================================
# 日付・ファイル処理
# ============================================================================
validate_custom_range() {
    [[ -z "$START_ARG" || -z "$END_ARG" ]] && \
        log_fatal "--start and --end must be specified together"
    
    for label in "start" "end"; do
        local val="${label == start ? $START_ARG : $END_ARG}"
        date -d "$val" >/dev/null 2>&1 || \
            log_fatal "Invalid $label date format: '$val' (expected YYYY-MM-DD)"
    done
    
    local start_epoch end_epoch
    start_epoch=$(date -d "$START_ARG" +%s)
    end_epoch=$(date -d "$END_ARG" +%s)
    [[ $start_epoch -gt $end_epoch ]] && \
        log_fatal "Start date must be before or equal to end date"
}

compute_boundaries() {
    case $PERIOD in
        latest) 
            PERIOD_NAME="Latest Session"
            return 0  # latest はファイル取得時に処理
            ;;
        today)
            START_BOUNDARY="$(date -d '00:00:00' '+%Y-%m-%d %H:%M:%S')"
            END_BOUNDARY="$(date -d '23:59:59' '+%Y-%m-%d %H:%M:%S')"
            PERIOD_NAME="Today"
            ;;
        week)
            START_BOUNDARY="$(date -d '7 days ago 00:00:00' '+%Y-%m-%d %H:%M:%S')"
            END_BOUNDARY="$(date -d '23:59:59' '+%Y-%m-%d %H:%M:%S')"
            PERIOD_NAME="This Week"
            ;;
        month)
            local first_day; first_day="$(date +%Y-%m-01)"
            START_BOUNDARY="$(date -d "$first_day 00:00:00" '+%Y-%m-%d %H:%M:%S')"
            END_BOUNDARY="$(date -d "$first_day +1 month -1 second" '+%Y-%m-%d %H:%M:%S')"
            PERIOD_NAME="This Month"
            ;;
        custom)
            START_BOUNDARY="${START_ARG} 00:00:00"
            END_BOUNDARY="${END_ARG} 23:59:59"
            PERIOD_NAME="Custom Range: $START_ARG to $END_ARG"
            ;;
        all)
            START_BOUNDARY="null"
            END_BOUNDARY="null"
            PERIOD_NAME="All Time"
            ;;
    esac
}

get_target_files() {
    shopt -s nullglob
    local -a all_files=("$SESSION_DIR"/*.json)
    shopt -u nullglob
    
    [[ ${#all_files[@]} -eq 0 ]] && log_fatal "No session files found in $SESSION_DIR"

    if [[ "$PERIOD" == "latest" ]]; then
        # 最新ファイル1件のみ取得（境界値は null で全件対象）
        TARGET_FILES=("$(ls -t "${all_files[@]}" | head -n1)")
    elif [[ "$PERIOD" == "custom" || "$PERIOD" == "all" ]]; then
        TARGET_FILES=("${all_files[@]}")
    else
        # 日付範囲でファイル名から簡易フィルタ（※session_id に日付が含まれる前提）
        # より厳密には jq で start_time をフィルタする方が安全
        for f in "${all_files[@]}"; do
            TARGET_FILES+=("$f")
        done
    fi
}

# ============================================================================
# jq 統計計算（統一処理）
# ============================================================================
# 外部ファイル stats_filter.jq を使う場合:
#   jq -s --arg start "$START_BOUNDARY" --arg end "$END_BOUNDARY" \
#      -f "$SCRIPT_DIR/stats_filter.jq" "${TARGET_FILES[@]}"
#
# 以下は inline 版（def で構造化）

calculate_stats() {
    local -n files_ref=$1
    local jq_filter
    jq_filter=$(cat <<'JQ_FILTER'
# 全ゲームをフラット化 + session メタ付与
[.[] as $session | $session.games[] as $game | $game + {session_id: $session.session_id, source: $session.source, level: $session.level}] as $all |

# 期間フィルタ（start/end が "null" 文字列の場合はスキップ）
(if ($start == "null") then $all 
 else $all | map(select(.timestamp >= $start and .timestamp <= $end)) 
 end) as $games |

# 正解ゲームの抽出
($games | map(select(.input == .word))) as $correct_games |

# 基本集計
($games | length) as $total |
($correct_games | length) as $correct |
($correct_games | map(.time_taken) | add // 0) as $total_time |
($correct_games | map(.input | length) | add // 0) as $total_chars |

# 派生指標
(if $total > 0 then ($correct * 100 / $total) else 0 end) as $accuracy |
(if $total_time > 0 then ($total_chars / $total_time) else 0 end) as $avg_speed |
($games | map(.session_id) | unique | length) as $session_count |
($games | map(.source) | unique | join(", ")) as $sources |
($games | map(.level) | unique | join(", ")) as $levels |

# 出力オブジェクト
{
  session_count: $session_count,
  total_games: $total,
  correct_games: $correct,
  accuracy_percent: $accuracy,
  total_time_seconds: $total_time,
  avg_speed_cps: $avg_speed,
  sources: $sources,
  levels: $levels
}
JQ_FILTER
)
    # jq 実行（エラーを隠さない）
    jq -s --arg start "$START_BOUNDARY" --arg end "$END_BOUNDARY" "$jq_filter" "${files_ref[@]}"
}

# ============================================================================
# 出力整形
# ============================================================================
format_output() {
    local period_name=$1
    jq -r --arg period "$period_name" '
      def round2: (.*100 | floor)/100;
      "=== Typing Game Statistics \($period) ===", "",
      "  Sessions: \(.session_count)",
      "  Sources: \(.sources)",
      "  Levels: \(.levels)",
      "  Total Games: \(.total_games)",
      "  Correct Answers: \(.correct_games)",
      "  Accuracy: \(.accuracy_percent | floor)%",
      "  Total Time: \(.total_time_seconds | floor) seconds",
      "  CPS (Chars Per Second): \(.avg_speed_cps | round2)",
      ""
    '
}

# ============================================================================
# メイン処理
# ============================================================================
main() {
    parse_arguments "$@"
    
    # カスタム範囲の検証
    if [[ -n "$START_ARG" || -n "$END_ARG" ]]; then
        [[ "$PERIOD" != "all" ]] && log_fatal "Cannot combine period options with --start/--end"
        validate_custom_range
        PERIOD="custom"
    fi
    
    compute_boundaries
    get_target_files
    
    # 統計計算 → 出力
    local stats
    if ! stats=$(calculate_stats TARGET_FILES); then
        log_fatal "jq processing failed: $stats"
    fi
    
    echo "$stats" | format_output "$PERIOD_NAME"
}

main "$@"
