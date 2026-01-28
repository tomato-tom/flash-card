#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"
SESSION_DIR="$PROJECT_ROOT/data/typing"

# Get all JSON files
JSON_FILES=("$SESSION_DIR"/*.json)
session_count=${#JSON_FILES[@]}

# Check if files exist
if [ $session_count -eq 0 ] || [ ! -f "${JSON_FILES[0]}" ]; then
    exit 1
fi

# Calculate statistics
jq -s '
  # Flatten all games from all sessions
  [.[] | .games[]] as $games |
  
  # Get only correct games
  ($games | map(select(.input == .word))) as $correct_games |
  
  # Basic statistics
  ($games | length) as $total |
  ($correct_games | length) as $correct |
  
  # Time-related statistics
  ($correct_games | map(.time_taken) | add // 0) as $total_time |
  ($correct_games | map(.input | length) | add // 0) as $total_chars |
  
  # Calculations
  (if $total > 0 then ($correct * 100 / $total) else 0 end) as $accuracy |
  (if $total_time > 0 then $total_chars / $total_time else 0 end) as $avg_speed |
  
  # Output object
  {
    total_games: $total,
    correct_games: $correct,
    accuracy_percent: $accuracy,
    total_time_seconds: $total_time,
    avg_speed_cps: $avg_speed,
    # Keep raw data for potential period-based statistics
    raw_games: $games,
    raw_correct_games: $correct_games
  }
' "${JSON_FILES[@]}" 2>/dev/null | jq -r --arg sc "$session_count" '
  def round2: (.*100 | floor)/100;
  
  "=== Typing Game Statistics ===",
  "",
  "  Sessions: \($sc)",
  "  Total Games: \(.total_games)",
  "  Correct Answers: \(.correct_games)",
  "  Accuracy: \(.accuracy_percent | floor)%",
  "  Total Time: \(.total_time_seconds | floor) seconds",
  "  CPS (Chars Per Second): \(.avg_speed_cps | round2)"
'

# Error checking
if [ $? -ne 0 ]; then
    echo "Error: Failed to process data"
    exit 1
fi
