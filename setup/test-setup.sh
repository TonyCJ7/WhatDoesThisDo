#!/bin/sh
# Usage: sh setup/test-setup.sh setup/setup-linux.sh   (SH=dash to use another shell)
set -eu

SCRIPT=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
AGENT_DIR=$(cd "$(dirname "$0")/../agent" && pwd)
TMP=$(mktemp -d)
export HOME="$TMP/home"
mkdir -p "$HOME"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
new_repo() { mkdir -p "$1/src" && git -C "$1" init -q && printf 'x\n' > "$1/src/a.ts"; }

# 1. project scope, both agents, from a subfolder, with an existing CLAUDE.md
new_repo "$TMP/one"
printf '# My rules\n\nKeep them.\n' > "$TMP/one/CLAUDE.md"
(cd "$TMP/one/src" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null)
[ -f "$TMP/one/.claude/skills/whatdoesthisdo/SKILL.md" ] || fail "skill not written"
cmp -s "$TMP/one/.claude/skills/whatdoesthisdo/SKILL.md" "$AGENT_DIR/skill/SKILL.md" || fail "skill differs from source"
grep -q '^# My rules' "$TMP/one/CLAUDE.md" || fail "existing CLAUDE.md content lost"
grep -q 'Keep them.' "$TMP/one/CLAUDE.md" || fail "existing CLAUDE.md body lost"
[ "$(grep -c 'whatdoesthisdo:start' "$TMP/one/CLAUDE.md")" = 1 ] || fail "block not written once"
[ -f "$TMP/one/.cursor/rules/whatdoesthisdo.mdc" ] || fail "cursor rule not written"
[ -f "$TMP/one/docs/whatdoesthisdo/references/README.md" ] || fail "references folder not created"

# 2. rerun changes nothing
before=$(cat "$TMP/one/CLAUDE.md" "$TMP/one/.cursor/rules/whatdoesthisdo.mdc" "$TMP/one/.claude/skills/whatdoesthisdo/SKILL.md")
(cd "$TMP/one" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null)
after=$(cat "$TMP/one/CLAUDE.md" "$TMP/one/.cursor/rules/whatdoesthisdo.mdc" "$TMP/one/.claude/skills/whatdoesthisdo/SKILL.md")
[ "$before" = "$after" ] || fail "second run changed files"
[ "$(grep -c 'whatdoesthisdo:start' "$TMP/one/CLAUDE.md")" = 1 ] || fail "block duplicated on rerun"

# 3. custom folder is substituted everywhere, and a bare CLAUDE.md gets no leading blank line
new_repo "$TMP/two"
(cd "$TMP/two" && ${SH:-sh} "$SCRIPT" --agent claude --scope project --folder docs/refs --yes > /dev/null)
grep -q 'docs/refs/' "$TMP/two/CLAUDE.md" || fail "folder not substituted in rule block"
grep -q 'docs/refs/' "$TMP/two/.claude/skills/whatdoesthisdo/SKILL.md" || fail "folder not substituted in skill"
[ -d "$TMP/two/docs/refs" ] || fail "custom references folder not created"
[ ! -e "$TMP/two/.cursor" ] || fail "cursor files written for claude only"
[ "$(head -c 1 "$TMP/two/CLAUDE.md")" = "<" ] || fail "new CLAUDE.md does not start with the block"

# 4. global scope writes under HOME, not the repo
new_repo "$TMP/three"
(cd "$TMP/three" && ${SH:-sh} "$SCRIPT" --agent claude --scope global --yes > /dev/null)
[ -f "$HOME/.claude/skills/whatdoesthisdo/SKILL.md" ] || fail "global skill not written"
grep -q 'whatdoesthisdo:start' "$HOME/.claude/CLAUDE.md" || fail "global CLAUDE.md block not written"
[ ! -e "$TMP/three/CLAUDE.md" ] || fail "project CLAUDE.md written in global scope"

# 5. cursor global writes the skill only and prints the rule to paste
out=$(cd "$TMP/three" && ${SH:-sh} "$SCRIPT" --agent cursor --scope global --yes)
echo "$out" | grep -q 'User Rules' || fail "cursor global did not print the paste instruction"
echo "$out" | grep -q 'read its entry' || fail "cursor global did not print the rule text"
[ ! -e "$HOME/.cursor" ] || fail "cursor global wrote a file"

# 6. project scope outside a repository stops with an error
mkdir -p "$TMP/norepo"
if (cd "$TMP/norepo" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null 2>&1); then
  fail "project scope outside a repo did not fail"
fi

# 7. interactive: arrows, back, typed folder, jump from the summary, then write
new_repo "$TMP/four"
(cd "$TMP/four" && printf '\n\033[B\033[B\033[A\nb\n\n\033[B\ndocs/refs\n\n1\033[B\n\n' | WDTD_STDIN_KEYS=1 ${SH:-sh} "$SCRIPT" > "$TMP/four.out" 2>&1) || fail "interactive run exited with an error: $(tail -3 "$TMP/four.out")"
[ -f "$TMP/four/.cursor/rules/whatdoesthisdo.mdc" ] || fail "interactive: agent changed from the summary to cursor was not applied"
[ ! -e "$TMP/four/CLAUDE.md" ] || fail "interactive: CLAUDE.md written although the final agent was cursor"
grep -q 'docs/refs/' "$TMP/four/.claude/skills/whatdoesthisdo/SKILL.md" || fail "interactive: typed folder not applied"
[ -f "$TMP/four/docs/refs/README.md" ] || fail "interactive: typed folder not created"
grep -q 'Set up' "$TMP/four.out" || fail "interactive: no success message"
grep -q 'Reload Window' "$TMP/four.out" || fail "interactive: no reload reminder"

# 8. interactive: q on the first screen writes nothing
new_repo "$TMP/five"
out=$(cd "$TMP/five" && printf 'q' | WDTD_STDIN_KEYS=1 ${SH:-sh} "$SCRIPT" 2>&1) || fail "quit exited with an error"
echo "$out" | grep -q 'nothing written' || fail "quit did not say nothing written"
[ ! -e "$TMP/five/.claude" ] || fail "quit wrote the skill"

echo "setup tests passed: $(basename "$SCRIPT")"
