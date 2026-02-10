#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel 2>/dev/null || pwd)"
SESSION_DIR="$PROJECT_ROOT/data/typing"

# Help message
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

# Parse options
period="all"
start_arg=""
end_arg=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--latest) period="latest"; shift ;;
        -t|--today) period="today"; shift ;;
        -w|--week) period="week"; shift ;;
        -m|--month) period="month"; shift ;;
        -a|--all) period="all"; shift ;;
        --start) start_arg="$2"; shift 2 ;;
        --end) end_arg="$2"; shift 2 ;;
        -h|--help) show_help ;;
        *) echo "Unknown option: $1" >&2; show_help ;;
    esac
done

# Custom range validation and mutual exclusion
if [[ -n "$start_arg" || -n "$end_arg" ]]; then
    # Cannot combine with period options
    if [[ "$period" != "all" ]]; then
        echo "Error: Cannot combine period options (--today, --week, etc.) with --start/--end" >&2
        exit 1
    fi
    # Both required
    if [[ -z "$start_arg" || -z "$end_arg" ]]; then
        echo "Error: --start and --end must be specified together" >&2
        exit 1
    fi
    # Validate date format (YYYY-MM-DD)
    if ! date -d "$start_arg" >/dev/null 2>&1; then
        echo "Error: Invalid start date format: '$start_arg' (expected YYYY-MM-DD)" >&2
        exit 1
    fi
    if ! date -d "$end_arg" >/dev/null 2>&1; then
        echo "Error: Invalid end date format: '$end_arg' (expected YYYY-MM-DD)" >&2
        exit 1
    fi
    # Check start <= end
    start_epoch=$(date -d "$start_arg" +%s)
    end_epoch=$(date -d "$end_arg" +%s)
    if [[ $start_epoch -gt $end_epoch ]]; then
        echo "Error: Start date must be before or equal to end date" >&2
        exit 1
    fi
    period="custom"
fi

# Handle latest session separately (no date filtering)
if [[ "$period" == "latest" ]]; then
    session_file=$(ls -t "$SESSION_DIR"/*.json 2>/dev/null | head -n 1)
    if [[ -z "$session_file" || ! -f "$session_file" ]]; then
        echo "Error: No session files found in $SESSION_DIR" >&2
        exit 1
    fi
    session_files=("$session_file")
    start_boundary="null"
    end_boundary="null"
    period_name="Latest Session"
else
    # Get all session files safely
    shopt -s nullglob 2>/dev/null || true
    session_files=("$SESSION_DIR"/*.json)
    shopt -u nullglob 2>/dev/null || true

    if [[ ${#session_files[@]} -eq 0 || ! -f "${session_files[0]}" ]]; then
        echo "Error: No session files found in $SESSION_DIR" >&2
        exit 1
    fi

    # Compute time boundaries
    case $period in
        today)
            start_boundary=$(date -d '00:00:00' '+%Y-%m-%d %H:%M:%S')
            end_boundary=$(date -d '23:59:59' '+%Y-%m-%d %H:%M:%S')
            period_name="Today"
            ;;
        week)
            start_boundary=$(date -d '7 days ago 00:00:00' '+%Y-%m-%d %H:%M:%S')
            end_boundary=$(date -d '23:59:59' '+%Y-%m-%d %H:%M:%S')
            period_name="This Week"
            ;;
        month)
            start_boundary=$(date -d "$(date +%Y-%m-01) 00:00:00" '+%Y-%m-%d %H:%M:%S')
            end_boundary=$(date -d "$(date +%Y-%m-01) +1 month -1 second" '+%Y-%m-%d %H:%M:%S')
            period_name="This Month"
            ;;
        custom)
            start_boundary="${start_arg} 00:00:00"
            end_boundary="${end_arg} 23:59:59"
            period_name="Custom Range: $start_arg to $end_arg"
            ;;
        all)
            start_boundary="null"
            end_boundary="null"
            period_name="All Time"
            ;;
    esac

    # Final boundary validation (should not fail on Linux with GNU date)
    if [[ "$period" != "all" && ( -z "$start_boundary" || -z "$end_boundary" ) ]]; then
        echo "Error: Failed to compute date boundaries (requires GNU date)" >&2
        exit 1
    fi
fi

# Process sessions with jq
jq -s --arg start "$start_boundary" --arg end "$end_boundary" '
  # Add session_id to each game and flatten
  [ 
    .[] as $session | 
    $session.games[] as $game | 
    $game + {session_id: $session.session_id}
  ] as $all_games |

  # Filter games by timestamp period (skip if boundaries are "null")
  (if ($start == "null") then 
     $all_games 
   else 
     $all_games | map(select(.timestamp >= $start and .timestamp <= $end)) 
   end) as $games |

  # Correct games (exact matches)
  ($games | map(select(.input == .word))) as $correct_games |

  # Basic counts
  ($games | length) as $total |
  ($correct_games | length) as $correct |

  # Time/chars from correct games only
  ($correct_games | map(.time_taken) | add // 0) as $total_time |
  ($correct_games | map(.input | length) | add // 0) as $total_chars |

  # Derived statistics
  (if $total > 0 then ($correct * 100 / $total) else 0 end) as $accuracy |
  (if $total_time > 0 then $total_chars / $total_time else 0 end) as $avg_speed |

  # Distinct sessions contributing to this period
  ($games | map(.session_id) | unique | length) as $session_count |

  {
    session_count: $session_count,
    total_games: $total,
    correct_games: $correct,
    accuracy_percent: $accuracy,
    total_time_seconds: $total_time,
    avg_speed_cps: $avg_speed
  }
' "${session_files[@]}" 2>/dev/null | jq -r --arg period "$period_name" '
  def round2: (.*100 | floor)/100;
  "=== Typing Game Statistics (\($period)) ===",
  "",
  "  Sessions: \(.session_count)",
  "  Total Games: \(.total_games)",
  "  Correct Answers: \(.correct_games)",
  "  Accuracy: \(.accuracy_percent | floor)%",
  "  Total Time: \(.total_time_seconds | floor) seconds",
  "  CPS (Chars Per Second): \(.avg_speed_cps | round2)",
  ""
' || { echo "Error: Failed to process session data" >&2; exit 1; }
