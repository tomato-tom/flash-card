#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <command>" >&2
    exit 1
fi

CMD="$1"

LANG=C man "$CMD" 2>/dev/null | \
awk '
BEGIN { buffer = "" }
/^[A-Z][A-Z ]*$/ || !NF {
    if (buffer != "") { printf "%s ", buffer; buffer = "" }
    next
}
/^[[:space:]]/ && NF {
    line = $0
    gsub(/^[ \t]+/, "", line)
    if (buffer != "") {
        if (buffer ~ /[a-z]-$/) {
            sub(/-$/, "", buffer)
            buffer = buffer line
        } else {
            buffer = buffer " " line
        }
    } else {
        buffer = line
    }
    if (buffer !~ /[a-z]-$/) {
        printf "%s ", buffer
        buffer = ""
    }
}
END {
    if (buffer != "") printf "%s ", buffer
    printf "\n"
}' | \
tr -s ' ' | \
sed 's/\([^.]\+\.\)/\1\n/g' | \
grep '\.$' | \
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
# --- 変数名（小文字を含まない1単語目）を削除 ---
awk '
{
    first = $1
    rest = $0
    sub(/^[^[:space:]]+[[:space:]]+/, "", rest)
    if (length(first) > 0 && tolower(first) != first && rest ~ /^[A-Z]/) {
        print rest
    } else {
        print $0
    }
}' | \
awk 'NF >= 2 && /^[A-Z]/ && length($0) >= 15' | \
# --- 重複除去 ---
awk '!seen[$0]++'
