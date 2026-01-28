#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"

run() {
  local command="$1"
  if [ "$command" = t ]; then
    $PROJECT_ROOT/typing.sh
    $PROJECT_ROOT/typing_stats.sh
  elif [ "$command" = f ]; then
    $PROJECT_ROOT/flash_card.sh
    $PROJECT_ROOT/flash_card_stats.sh
  fi
}

: 他のブランチは？
#git_update() {
#    local message="${@:-update}"
#    if grep '* dev' >/dev/null; then
#        git add .
#        git commit -m "$message"
#        git push local dev
#    fi
#
#    : 何か引数？
#    if [ : ]; then
#        git switch main &&
#        git merge dev &&
#        git push local main &&
#        git push github main &&
#        git switch dev
#    fi
#}
#
#alias gu="git_update"

