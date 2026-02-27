# stats_filter.jq
# 期間フィルタ用ヘルパー
def filter_period(start; end):
  if start == "null" then .
  else map(select(.timestamp >= start and .timestamp <= end))
  end;

# 丸めヘルパー
def round2: (.*100 | floor)/100;

# メイン処理
[.[] as $session | $session.games[] as $game | 
 $game + {session_id: $session.session_id, source: $session.source, level: $session.level}] as $all |

filter_period($start; $end) as $games |
($games | map(select(.input == .word))) as $correct_games |

($games | length) as $total |
($correct_games | length) as $correct |
($correct_games | map(.time_taken) | add // 0) as $total_time |
($correct_games | map(.input | length) | add // 0) as $total_chars |

(if $total > 0 then ($correct * 100 / $total) else 0 end) as $accuracy |
(if $total_time > 0 then ($total_chars / $total_time) else 0 end) as $avg_speed |

{
  session_count: ($games | map(.session_id) | unique | length),
  total_games: $total,
  correct_games: $correct,
  accuracy_percent: $accuracy,
  total_time_seconds: $total_time,
  avg_speed_cps: $avg_speed,
  sources: ($games | map(.source) | unique | join(", ")),
  levels: ($games | map(.level) | unique | join(", "))
}
