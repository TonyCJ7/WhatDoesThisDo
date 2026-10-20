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

# 7. interactive: install, arrows, back, typed folder, jump from the summary, then write
new_repo "$TMP/four"
(cd "$TMP/four" && printf '\n\n\033[B\033[B\033[A\nb\n\n\033[B\ndocs/refs\n\n2\033[B\n\n' | WDTD_STDIN_KEYS=1 ${SH:-sh} "$SCRIPT" > "$TMP/four.out" 2>&1) || fail "interactive run exited with an error: $(tail -3 "$TMP/four.out")"
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

# 9. uninstall in project scope removes what install wrote and keeps everything else
new_repo "$TMP/six"
printf '# My rules\n\nKeep them.\n' > "$TMP/six/CLAUDE.md"
(cd "$TMP/six" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null)
out=$(cd "$TMP/six/src" && ${SH:-sh} "$SCRIPT" --uninstall --scope project)
echo "$out" | grep -q 'Removed' || fail "uninstall did not report what it removed"
[ ! -e "$TMP/six/.claude" ] || fail "uninstall left the skill folder"
[ ! -e "$TMP/six/.cursor" ] || fail "uninstall left the cursor rule"
grep -q 'Keep them.' "$TMP/six/CLAUDE.md" || fail "uninstall lost the rest of CLAUDE.md"
! grep -q 'whatdoesthisdo:start' "$TMP/six/CLAUDE.md" || fail "uninstall left the rule block"
[ -f "$TMP/six/docs/whatdoesthisdo/references/README.md" ] || fail "uninstall removed the references folder"
echo "$out" | grep -q 'User Rules' && fail "project uninstall mentioned the pasted Cursor rule"

# 10. a CLAUDE.md that held only the block is deleted, and a second uninstall finds nothing
new_repo "$TMP/seven"
(cd "$TMP/seven" && ${SH:-sh} "$SCRIPT" --agent claude --scope project --yes > /dev/null)
(cd "$TMP/seven" && ${SH:-sh} "$SCRIPT" --uninstall --scope project > /dev/null)
[ ! -e "$TMP/seven/CLAUDE.md" ] || fail "empty CLAUDE.md not deleted"
out=$(cd "$TMP/seven" && ${SH:-sh} "$SCRIPT" --uninstall --scope project) || fail "uninstall with nothing installed failed"
echo "$out" | grep -q 'Nothing from WhatDoesThisDo' || fail "uninstall with nothing installed did not say so"

# 11. uninstall in global scope removes under HOME and reminds about the pasted Cursor rule
(cd "$TMP/seven" && ${SH:-sh} "$SCRIPT" --agent both --scope global --yes > /dev/null)
out=$(cd "$TMP/seven" && ${SH:-sh} "$SCRIPT" --uninstall --scope global)
[ ! -e "$HOME/.claude/skills/whatdoesthisdo" ] || fail "global uninstall left the skill"
[ ! -e "$HOME/.claude/CLAUDE.md" ] || fail "global uninstall left the CLAUDE.md block"
[ -d "$HOME/.claude" ] || fail "global uninstall removed ~/.claude itself"
echo "$out" | grep -q 'User Rules' || fail "global uninstall did not mention the pasted Cursor rule"

# 12. interactive uninstall: down to Uninstall, project scope, confirm on the summary
new_repo "$TMP/eight"
(cd "$TMP/eight" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null)
(cd "$TMP/eight" && printf '\n\033[B\n\n\n' | WDTD_STDIN_KEYS=1 ${SH:-sh} "$SCRIPT" > "$TMP/eight.out" 2>&1) || fail "interactive uninstall exited with an error: $(tail -3 "$TMP/eight.out")"
grep -q 'Uninstalled' "$TMP/eight.out" || fail "interactive uninstall: no success message"
[ ! -e "$TMP/eight/.claude" ] || fail "interactive uninstall left the skill folder"
[ ! -e "$TMP/eight/CLAUDE.md" ] || fail "interactive uninstall left CLAUDE.md"

# 13. interactive uninstall with nothing installed: enter does nothing, q leaves
new_repo "$TMP/nine"
out=$(cd "$TMP/nine" && printf '\n\033[B\n\n\nq' | WDTD_STDIN_KEYS=1 ${SH:-sh} "$SCRIPT" 2>&1) || fail "interactive empty uninstall exited with an error"
echo "$out" | grep -q 'nothing removed' || fail "interactive empty uninstall did not say nothing removed"

# 14. cursor-only install and uninstall: no CLAUDE.md ever, our rule file goes, other rule files stay
new_repo "$TMP/ten"
mkdir -p "$TMP/ten/.cursor/rules"
printf 'mine\n' > "$TMP/ten/.cursor/rules/mine.mdc"
(cd "$TMP/ten" && ${SH:-sh} "$SCRIPT" --agent cursor --scope project --yes > /dev/null)
(cd "$TMP/ten" && ${SH:-sh} "$SCRIPT" --uninstall --scope project > /dev/null)
[ ! -e "$TMP/ten/CLAUDE.md" ] || fail "cursor-only uninstall created CLAUDE.md"
[ ! -e "$TMP/ten/.cursor/rules/whatdoesthisdo.mdc" ] || fail "cursor-only uninstall left our rule"
[ -f "$TMP/ten/.cursor/rules/mine.mdc" ] || fail "uninstall removed another rule file"
[ ! -e "$TMP/ten/.claude" ] || fail "cursor-only uninstall left the skill folder"

# 15. a global CLAUDE.md keeps your own content around the block
printf '# Mine\n\nStay.\n' > "$HOME/.claude/CLAUDE.md"
(cd "$TMP/ten" && ${SH:-sh} "$SCRIPT" --agent claude --scope global --yes > /dev/null)
(cd "$TMP/ten" && ${SH:-sh} "$SCRIPT" --uninstall --scope global > /dev/null)
grep -q 'Stay.' "$HOME/.claude/CLAUDE.md" || fail "global uninstall lost your own CLAUDE.md content"
! grep -q 'whatdoesthisdo:start' "$HOME/.claude/CLAUDE.md" || fail "global uninstall left the block"
rm -f "$HOME/.claude/CLAUDE.md"

# 16. uninstall touches nothing else in the project, and a reinstall after it works
new_repo "$TMP/eleven"
(cd "$TMP/eleven" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null)
printf 'x\n' > "$TMP/eleven/extra.txt"
(cd "$TMP/eleven" && ${SH:-sh} "$SCRIPT" --uninstall --scope project > /dev/null)
[ -f "$TMP/eleven/extra.txt" ] || fail "uninstall removed a file it did not write"
[ -f "$TMP/eleven/src/a.ts" ] || fail "uninstall removed a source file"
(cd "$TMP/eleven" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null)
[ -f "$TMP/eleven/.claude/skills/whatdoesthisdo/SKILL.md" ] || fail "reinstall did not write the skill"
grep -q 'whatdoesthisdo:start' "$TMP/eleven/CLAUDE.md" || fail "reinstall did not write the block"
[ -f "$TMP/eleven/.cursor/rules/whatdoesthisdo.mdc" ] || fail "reinstall did not write the cursor rule"

# 18. uninstall in project scope outside a repository stops with an error
if (cd "$TMP/norepo" && ${SH:-sh} "$SCRIPT" --uninstall --scope project > /dev/null 2>&1); then
  fail "uninstall outside a repo did not fail"
fi

# 19. interactive: from the install summary, 1 switches to Uninstall, 2 revisits the scope, enter removes
new_repo "$TMP/twelve"
(cd "$TMP/twelve" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null)
(cd "$TMP/twelve" && printf '\n\n\n\n\n1\033[B\n\n2\n\n' | WDTD_STDIN_KEYS=1 ${SH:-sh} "$SCRIPT" > "$TMP/twelve.out" 2>&1) || fail "mode switch run exited with an error: $(tail -3 "$TMP/twelve.out")"
grep -q 'Uninstalled' "$TMP/twelve.out" || fail "mode switch: no uninstall success message"
[ ! -e "$TMP/twelve/.claude" ] || fail "mode switch: skill folder not removed"

# 20. interactive: q on an uninstall summary that lists files removes nothing
(cd "$TMP/twelve" && ${SH:-sh} "$SCRIPT" --agent both --scope project --yes > /dev/null)
out=$(cd "$TMP/twelve" && printf '\n\033[B\n\nq' | WDTD_STDIN_KEYS=1 ${SH:-sh} "$SCRIPT" 2>&1) || fail "quit on uninstall summary exited with an error"
echo "$out" | grep -q 'nothing removed' || fail "quit on uninstall summary did not say nothing removed"
[ -f "$TMP/twelve/.claude/skills/whatdoesthisdo/SKILL.md" ] || fail "quit on uninstall summary removed the skill"

# 21. interactive install: global scope, back from the folder screen, jump keys 3 and 4
new_repo "$TMP/thirteen"
(cd "$TMP/thirteen" && printf '\n\n\n\033[B\nb\n\n3\n4\n\n' | WDTD_STDIN_KEYS=1 ${SH:-sh} "$SCRIPT" > "$TMP/thirteen.out" 2>&1) || fail "global interactive run exited with an error: $(tail -3 "$TMP/thirteen.out")"
[ -f "$HOME/.claude/skills/whatdoesthisdo/SKILL.md" ] || fail "interactive global: skill not written under HOME"
[ ! -e "$TMP/thirteen/.claude" ] || fail "interactive global: skill written in the project"
grep -q 'User Rules' "$TMP/thirteen.out" || fail "interactive global: paste instruction missing"
(cd "$TMP/thirteen" && ${SH:-sh} "$SCRIPT" --uninstall --scope global > /dev/null)

# 22. --help prints the options and an unknown option fails
${SH:-sh} "$SCRIPT" --help | grep -q 'Options:' || fail "--help did not print the options"
if ${SH:-sh} "$SCRIPT" --bogus > /dev/null 2>&1; then fail "unknown option did not fail"; fi

echo "setup tests passed: $(basename "$SCRIPT")"
