#!/bin/bash
# usage
# source run.sh
# run f/t

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"

# アプリ実行と統計
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

# ローカルでHTMLファイル閲覧用
alias http-start='cd $PROJECT_ROOT/docs && python3 -m http.server 8080 >/dev/null &'
alias http-stop='pkill -f "python3 -m http.server 8080"'

git_diff() {
    case "$1" in
        # gd → ステージされていない変更
        "")
            git diff
            ;;
        # gd s → ステージ済みの変更（index vs HEAD）
        s)
            git diff --cached
            ;;
        # gd 1 → 最後のコミットとの差分（HEAD vs HEAD~1）
        [0-9]*)
            git diff "HEAD~$1"
            ;;
        # gd main → 現在のブランチと指定ブランチの差分
        *)
            if git rev-parse --verify "$1" >/dev/null 2>&1; then
                git diff "$1"
            else
                echo "❓ Unknown argument or branch: $1" >&2
                echo "Usage: gd [branch|commit|--cached|s]" >&2
                return 1
            fi
            ;;
    esac
}

# git_update [target_branch] [message]
# eg. git_update main "Add files"
git_update() {
    local target_branch=""
    local message=""

    if [ "$1" = main ] || [ "$1" = dev ]; then
        target_branch="$1"
        shift
    fi
    message="${*:-update}"

    current_branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$current_branch" ]; then
        echo "❌ Not in a Git repository." >&2
        return 1
    fi

    # 変更があるか確認（ステージ前＋ステージ後）
    if git diff --quiet && git diff --cached --quiet; then
        echo "ℹ️ No changes to commit." >&2
        return 0
    fi

    # -- push --
    # main -> local + github
    # dev -> local
    # feature* -> local
    #
    # -- merge --
    # feature* -> dev -> main
    cd "$PROJECT_ROOT"
    if [ "$current_branch" = dev ]; then
        # on dev
        git add .
        git commit -m "$message"
        git push local dev

        if [ "$target_branch" = main ]; then
            # merge: dev -> main
            git switch main &&
            git merge dev &&
            git push local main &&
            git push github main &&
            git switch dev
        fi
    elif [ "$current_branch" = main ]; then
        # on main
        git merge dev &&
        git push local main &&
        git push github main &&
        git switch dev
    else
        # feature*など
        git add .
        git commit -m "$message"
        git push local "$current_branch"

        if [ "$target_branch" = dev ]; then
            # merge: feature* -> dev
            git switch dev &&
            git merge "$current_branch" &&
            git push local dev &&
            git switch "$current_branch"
        fi
    fi
    cd -
}

alias gu="git_update"
alias gl="git log --oneline"
alias gd="git_diff"

