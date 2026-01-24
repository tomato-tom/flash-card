#!/bin/bash

# Usage: ./man2typing.sh <command_name>
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <command>" >&2
    exit 1
fi

CMD="$1"

read -r -d '' ALLOWED_SECTIONS <<'EOF'
DESCRIPTION
OPTIONS
ARGUMENTS
INVOCATION
DEFINITIONS
PARAMETERS
EXPANSION
REDIRECTION
ALIASES
FUNCTIONS
ARITHMETIC EVALUATION
CONDITIONAL EXPRESSIONS
SIMPLE COMMAND EXPANSION
COMMAND EXECUTION
COMMAND EXECUTION ENVIRONMENT
ENVIRONMENT
EXIT STATUS
SIGNALS
JOB CONTROL
PROMPTING
READLINE
HISTORY
HISTORY EXPANSION
SHELL BUILTIN COMMANDS
SHELL COMPATIBILITY MODE
RESTRICTED SHELL
EOF

export ALLOWED_SECTIONS

LANG=C man "$CMD" 2>/dev/null | \
awk '
BEGIN {
    split(ENVIRON["ALLOWED_SECTIONS"], a, "\n")
    for (i in a) {
        gsub(/^[ \t]+|[ \t]+$/, "", a[i])
        if (a[i] != "") allowed[a[i]] = 1
    }
}
/^[A-Z]/ {
    gsub(/^[ \t]+|[ \t]+$/, "")
    current = $0
    capture = (current in allowed)
    next
}
capture && NF && /^[[:space:]]/ {
    gsub(/^[ \t]+/, "")
    printf "%s ", $0
    next
}
capture && NF && !/^[[:space:]]/ {
    printf "%s ", $0
    next
}
END { printf "\n" }
' | \
# --- 行またぎハイフンの除去 ---
# meta- も削除されてる FIX ME
sed 's/\([a-z]\)- \([a-z]\)/\1\2/g' | \
# --- 空白の正規化 ---
tr -s ' ' | \
# --- 文分割 ---
sed 's/\([^.]\+\.\)/\1\n/g' | \
# --- ピリオドで終わる行のみ ---
grep '\.$' | \
# --- 前後空白削除 ---
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
# --- 質量フィルタ ---
awk 'NF >= 2 && /^[A-Z]/ && length($0) >= 30 && length($0) <= 90' | \
# --- 重複除去（順序保持） ---
awk '!seen[$0]++'
