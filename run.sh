#!/bin/bash

run() {
  local command="$1"
  if [ "$command" = t ]; then
    ./typing.sh
    ./typing_stats.sh
  elif [ "$command" = f ]; then
    ./flash_card.sh
    ./flash_card_stats.sh
  fi
}
