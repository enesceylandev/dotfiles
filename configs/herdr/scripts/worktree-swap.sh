#!/usr/bin/env bash
set -uo pipefail

DRY_RUN=0
FORCE=0
for a in "$@"; do
    case "$a" in
        --dry-run) DRY_RUN=1 ;;
        --force) FORCE=1 ;;
        --help|-h)
            cat <<EOF
worktree-swap — promote the focused worktree into the main checkout and
turn the current main branch into a sibling worktree.

Usage: worktree-swap.sh [--dry-run] [--force]

Flow: stash WIP (worktree + main) -> herdr worktree remove (closes the
worktree workspace, frees the branch) -> main checks out the promoted
branch -> restore its WIP into main -> herdr worktree create for the old
main branch at <repo>-<branch> -> restore main WIP into it -> focus main.

Stashes are tagged with a unique mark and never dropped on failure, so a
botched swap is always recoverable from the stash list.

  --dry-run  Print every action without executing the destructive ones.
  --force    Pass --force to herdr worktree remove (kills agents running
             in the promoted worktree's workspace).
EOF
            exit 0
            ;;
    esac
done

HERDR_BIN="${HERDR_BIN:-herdr}"
LOG_FILE="${LOG_FILE:-$HOME/.config/herdr/worktree-swap.log}"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

log() { echo "[$(date '+%H:%M:%S')] $*" >>"$LOG_FILE" 2>/dev/null || true; }
say() { echo "worktree-swap: $*"; log "$*"; }
err() { say "ERROR: $*"; exit 1; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        say "DRY-RUN: $*"
    else
        say "RUN: $*"
        "$@" || err "command failed ($*)"
    fi
}

jpane() { printf '%s' "$PANE_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin)["result"]["pane"]; print(d[sys.argv[1]])' "$1"; }

PANE_JSON="$("$HERDR_BIN" pane current)" || err "herdr pane current failed (not in a herdr session?)"
CWD="$(jpane cwd)"
FOCUSED_WS="$(jpane workspace_id)"

cd "$CWD" 2>/dev/null || err "cannot cd to focused pane path ($CWD)"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || err "focused pane is not inside a git work tree"

WT_PATH="$(git rev-parse --show-toplevel)"
GIT_COMMON="$(git rev-parse --git-common-dir)"
GIT_COMMON="$(cd "$GIT_COMMON" && pwd)"
MAIN_ROOT="$(dirname "$GIT_COMMON")"

[ "$WT_PATH" = "$MAIN_ROOT" ] && err "focused pane is in the main repo, not a worktree. Open/focus a worktree workspace first."

WT_BRANCH="$(git branch --show-current)"
[ -z "$WT_BRANCH" ] && err "worktree is in detached HEAD; checkout a branch first"
MAIN_BRANCH="$(cd "$MAIN_ROOT" && git branch --show-current)"
[ -z "$MAIN_BRANCH" ] && err "main is in detached HEAD; checkout a branch first"
[ "$WT_BRANCH" = "$MAIN_BRANCH" ] && err "main and worktree are on the same branch ($WT_BRANCH); nothing to swap"

BRANCH_SLUG="$(printf '%s' "$MAIN_BRANCH" | tr '/' '-')"
NEW_WT="$(dirname "$MAIN_ROOT")/$(basename "$MAIN_ROOT")-$BRANCH_SLUG"
[ -e "$NEW_WT" ] && err "target worktree path already exists: $NEW_WT"

WS_JSON="$("$HERDR_BIN" workspace list)" || err "herdr workspace list failed"
PARSED="$(printf '%s' "$WS_JSON" | python3 -c '
import json, sys
d = json.load(sys.stdin)
wss = d["result"]["workspaces"]
def wid(path, linked):
    for w in wss:
        wt = w.get("worktree") or {}
        if wt.get("checkout_path") == path and bool(wt.get("is_linked_worktree")) == linked:
            return w["workspace_id"]
    return ""
print(wid(sys.argv[1], True), wid(sys.argv[2], False))
' "$WT_PATH" "$MAIN_ROOT")"
TARGET_WS_ID="$(printf '%s' "$PARSED" | awk '{print $1}')"
MAIN_WS_ID="$(printf '%s' "$PARSED" | awk '{print $2}')"

[ -z "$TARGET_WS_ID" ] && err "no open herdr workspace for worktree $WT_PATH. Open it first: herdr worktree open"
[ -z "$MAIN_WS_ID" ] && err "no open herdr workspace for main repo $MAIN_ROOT"

MARK="wtswap-$(date +%s)-$$"

stash_if_dirty() {
    local where="$1" msg="$2"
    if ! (cd "$where" && git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]); then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "DRY-RUN: would stash WIP in $where ($msg)"
        else
            (cd "$where" && git stash push -u -m "$msg") >/dev/null 2>&1 || err "failed to stash WIP in $where"
            say "stashed WIP in $where ($msg)"
        fi
        return 0
    fi
    return 1
}

pop_by_mark() {
    local where="$1" msg="$2" ref
    if [ "$DRY_RUN" -eq 1 ]; then
        say "DRY-RUN: would pop $msg into $where"
        return 0
    fi
    ref="$(cd "$where" && git stash list | grep -F -- "$msg" | head -1 | cut -d: -f1)"
    [ -z "$ref" ] && { say "WARN: stash $msg not found; skipping pop"; return 0; }
    (cd "$where" && git stash pop "$ref") || err "failed to pop stash $msg in $where"
    say "popped $msg into $where"
}

STASHED_Y=0
STASHED_X=0
stash_if_dirty "$WT_PATH" "${MARK}-y" && STASHED_Y=1
stash_if_dirty "$MAIN_ROOT" "${MARK}-x" && STASHED_X=1

say "promote: $WT_BRANCH  (worktree $WT_PATH, ws $TARGET_WS_ID)"
say "demote:  $MAIN_BRANCH -> $NEW_WT"

if [ "$FORCE" -eq 1 ]; then
    run "$HERDR_BIN" worktree remove --workspace "$TARGET_WS_ID" --force
else
    run "$HERDR_BIN" worktree remove --workspace "$TARGET_WS_ID"
fi

run git -C "$MAIN_ROOT" checkout "$WT_BRANCH"
[ "$STASHED_Y" -eq 1 ] && pop_by_mark "$MAIN_ROOT" "${MARK}-y"

run "$HERDR_BIN" worktree create --path "$NEW_WT" --branch "$MAIN_BRANCH" --cwd "$MAIN_ROOT" --no-focus
[ "$STASHED_X" -eq 1 ] && pop_by_mark "$NEW_WT" "${MARK}-x"

if [ "$DRY_RUN" -eq 0 ]; then
    "$HERDR_BIN" workspace focus "$MAIN_WS_ID" 2>/dev/null || true
fi

say "DONE: main=$WT_BRANCH | worktree=$NEW_WT ($MAIN_BRANCH)"
