#!/usr/bin/env bash
set -uo pipefail

PANE_ID="${1:-}"
TMUX_BIN="${TMUX_BIN:-tmux}"

err() {
    "$TMUX_BIN" display-message -d 8000 "worktree-swap: $*"
    echo "worktree-swap error: $*" >&2
    exit 1
}

if [ -n "$PANE_ID" ]; then
    CWD="$("$TMUX_BIN" display-message -p -t "$PANE_ID" '#{pane_current_path}')"
else
    CWD="$PWD"
fi

cd "$CWD" 2>/dev/null || err "cannot cd to focused pane path ($CWD)"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || err "not inside a git work tree"

WT_PATH="$(git rev-parse --show-toplevel)"
GIT_COMMON="$(git rev-parse --git-common-dir)"
GIT_COMMON="$(cd "$GIT_COMMON" && pwd)"
MAIN_ROOT="$(dirname "$GIT_COMMON")"

[ "$WT_PATH" = "$MAIN_ROOT" ] && err "focused pane is in main repo, not a worktree. Navigate to a worktree pane first."

WT_BRANCH="$(git branch --show-current)"
[ -z "$WT_BRANCH" ] && err "worktree is in detached HEAD; checkout a branch first"

MAIN_BRANCH="$(cd "$MAIN_ROOT" && git branch --show-current)"
[ -z "$MAIN_BRANCH" ] && err "main is in detached HEAD; checkout a branch first"
[ "$WT_BRANCH" = "$MAIN_BRANCH" ] && err "main and worktree are on the same branch ($WT_BRANCH); nothing to swap"

BRANCH_SLUG="$(printf '%s' "$MAIN_BRANCH" | tr '/' '-')"
NEW_WT="$(dirname "$MAIN_ROOT")/$(basename "$MAIN_ROOT")-$BRANCH_SLUG"
[ -e "$NEW_WT" ] && err "target worktree path already exists: $NEW_WT"

MARK="wtswap-$(date +%s)-$$"

stash_if_dirty() {
    local where="$1" msg="$2"
    if ! (cd "$where" && git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]); then
        (cd "$where" && git stash push -u -m "$msg") >/dev/null 2>&1 || err "failed to stash in $where"
        return 0
    fi
    return 1
}

pop_by_mark() {
    local where="$1" msg="$2" ref
    ref="$(cd "$where" && git stash list | grep -F -- "$msg" | head -1 | cut -d: -f1)"
    [ -z "$ref" ] && return 1
    (cd "$where" && git stash pop "$ref") || err "failed to pop stash $msg in $where"
}

STASHED_Y=0
STASHED_X=0
stash_if_dirty "$WT_PATH" "${MARK}-y" && STASHED_Y=1
stash_if_dirty "$MAIN_ROOT" "${MARK}-x" && STASHED_X=1

git worktree unlock "$WT_PATH" 2>/dev/null || true
git worktree remove "$WT_PATH" || err "failed to remove worktree $WT_PATH (close editors/terminals in it and retry). Stashes left: y=$STASHED_Y x=$STASHED_X"

(cd "$MAIN_ROOT" && git checkout "$WT_BRANCH") || err "failed to checkout $WT_BRANCH in main. Stashes: y=$STASHED_Y x=$STASHED_X"

[ "$STASHED_Y" -eq 1 ] && pop_by_mark "$MAIN_ROOT" "${MARK}-y"

git worktree add "$NEW_WT" "$MAIN_BRANCH" || err "failed to create worktree at $NEW_WT. y-stash already in main; x-stash still safe: x=$STASHED_X"

[ "$STASHED_X" -eq 1 ] && pop_by_mark "$NEW_WT" "${MARK}-x"

if [ -n "$PANE_ID" ]; then
    "$TMUX_BIN" send-keys -t "$PANE_ID" "cd '$MAIN_ROOT'" Enter
fi

"$TMUX_BIN" display-message -d 4000 "swapped: main=$WT_BRANCH | worktree=$NEW_WT ($MAIN_BRANCH)"
