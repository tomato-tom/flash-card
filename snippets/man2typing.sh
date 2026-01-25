#!/bin/bash

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
    buffer = ""
    in_section = 0
}

# セクションヘッダー判定
/^[A-Z][A-Z ]*$/ {
    gsub(/^[ \t]+|[ \t]+$/, "")
    current = $0
    in_section = (current in allowed)
    next
}

# 対象セクション外 or 空行
!in_section || !NF {
    if (buffer != "") {
        # バッファ出力（行末ハイフン処理済み）
        printf "%s ", buffer
        buffer = ""
    }
    next
}

# 対象セクション内の本文行
in_section && NF {
    line = $0
    gsub(/^[ \t]+/, "", line)  # 行頭インデント削除

    if (buffer != "") {
        # 前の行が行末ハイフンで終わっていたか？
        if (buffer ~ /[a-z]-$/) {
            # 行末の "-" を削除し、次の単語と直接結合
            sub(/-$/, "", buffer)
            buffer = buffer line
        } else {
            # 普通にスペースで連結
            buffer = buffer " " line
        }
    } else {
        buffer = line
    }

    # 行末が [a-z]- で終わっていなければ、即出力
    if (buffer !~ /[a-z]-$/) {
        printf "%s ", buffer
        buffer = ""
    }
}

END {
    if (buffer != "") {
        # 最終行が未出力なら出力（末尾ハイフンはそのまま残すが稀）
        printf "%s ", buffer
    }
    printf "\n"
}' | \
tr -s ' ' | \
sed 's/\([^.]\+\.\)/\1\n/g' | \
grep '\.$' | \
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
awk 'NF >= 2 && /^[A-Z]/ && length($0) >= 15' | \
awk '!seen[$0]++'
