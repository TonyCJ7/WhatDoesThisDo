#!/bin/sh
# WhatDoesThisDo agent setup for macOS.
# Run from a clone:  sh setup/setup-macos.sh
# Or remotely:       sh -c "$(curl -fsSL https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/setup/setup-macos.sh)"
set -eu

RAW_URL="https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/agent"
DEFAULT_FOLDER="docs/whatdoesthisdo/references"
AGENT=""
SCOPE=""
FOLDER=""
YES=0

usage() {
  cat <<USAGE
Sets up the WhatDoesThisDo documentation skill and rule for Claude Code and Cursor.

Options (asked interactively when omitted):
  --agent claude|cursor|both   which agent follows the rule
  --scope project|global       this repository, or every project on this machine
  --folder <path>              references folder relative to the repository root
  --yes                        accept the defaults and write without asking
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --folder) FOLDER="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

ask() {
  if [ "$YES" = 1 ]; then
    printf '%s' "$2"
    return
  fi

  printf '%s [%s]: ' "$1" "$2" >&2

  if [ -r /dev/tty ]; then
    read -r answer < /dev/tty
  else
    read -r answer
  fi

  printf '%s' "${answer:-$2}"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)

if [ -n "$script_dir" ] && [ -f "$script_dir/../agent/skill/SKILL.md" ]; then
  SRC=$(cd "$script_dir/../agent" && pwd)
else
  SRC="$TMP/agent"
  mkdir -p "$SRC/skill"

  for file in skill/SKILL.md rule-block.md cursor-rule.mdc; do
    curl -fsSL "$RAW_URL/$file" -o "$SRC/$file" || { echo "could not download $file" >&2; exit 1; }
  done
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)

[ -n "$AGENT" ] || AGENT=$(ask "Agent to set up (claude, cursor, both)" both)
[ -n "$SCOPE" ] || SCOPE=$(ask "Scope (project, global)" project)

case "$AGENT" in claude|cursor|both) ;; *) echo "agent must be claude, cursor or both" >&2; exit 2 ;; esac
case "$SCOPE" in project|global) ;; *) echo "scope must be project or global" >&2; exit 2 ;; esac

if [ "$SCOPE" = project ] && [ -z "$ROOT" ]; then
  echo "not inside a git repository; run from your project or use --scope global" >&2
  exit 1
fi

[ -n "$FOLDER" ] || FOLDER=$(ask "References folder, relative to the repository root" "$DEFAULT_FOLDER")
FOLDER=${FOLDER%/}

if [ "$SCOPE" = project ]; then
  BASE="$ROOT"
else
  BASE="$HOME"
fi

substitute() {
  sed "s#$DEFAULT_FOLDER#$FOLDER#g" "$1"
}

strip_block() {
  awk '
    /<!-- whatdoesthisdo:start -->/ { skip = 1 }
    !skip { lines[++n] = $0; if ($0 != "") last = n }
    /<!-- whatdoesthisdo:end -->/ { skip = 0 }
    END { for (i = 1; i <= last; i++) print lines[i] }
  ' "$1"
}

write_block() {
  block=$(substitute "$SRC/rule-block.md")
  kept=""

  if [ -f "$1" ]; then
    kept=$(strip_block "$1")
  fi

  mkdir -p "$(dirname "$1")"

  if [ -n "$kept" ]; then
    printf '%s\n\n%s\n' "$kept" "$block" > "$1"
  else
    printf '%s\n' "$block" > "$1"
  fi
}

SKILL_TARGET="$BASE/.claude/skills/whatdoesthisdo/SKILL.md"
plan="  $SKILL_TARGET"

if [ "$AGENT" != cursor ]; then
  if [ "$SCOPE" = project ]; then
    CLAUDE_MD="$ROOT/CLAUDE.md"
  else
    CLAUDE_MD="$HOME/.claude/CLAUDE.md"
  fi

  plan="$plan
  $CLAUDE_MD  (rule block between <!-- whatdoesthisdo --> markers)"
fi

if [ "$AGENT" != claude ] && [ "$SCOPE" = project ]; then
  CURSOR_RULE="$ROOT/.cursor/rules/whatdoesthisdo.mdc"
  plan="$plan
  $CURSOR_RULE"
fi

if [ "$SCOPE" = project ]; then
  plan="$plan
  $ROOT/$FOLDER/README.md  (only if missing)"
fi

echo "Files to write:"
echo "$plan"

if [ "$YES" != 1 ]; then
  answer=$(ask "Continue? (y, n)" y)
  case "$answer" in y|Y|yes) ;; *) echo "nothing written"; exit 0 ;; esac
fi

mkdir -p "$(dirname "$SKILL_TARGET")"
substitute "$SRC/skill/SKILL.md" > "$SKILL_TARGET"

if [ "$AGENT" != cursor ]; then
  write_block "$CLAUDE_MD"
fi

if [ "$AGENT" != claude ] && [ "$SCOPE" = project ]; then
  mkdir -p "$(dirname "$CURSOR_RULE")"
  substitute "$SRC/cursor-rule.mdc" > "$CURSOR_RULE"
fi

if [ "$SCOPE" = project ] && [ ! -f "$ROOT/$FOLDER/README.md" ]; then
  mkdir -p "$ROOT/$FOLDER"
  printf '# Reference pages\n\nMarkdown pages read by the WhatDoesThisDo extension. One page per source file, at the same path as the file with a `.md` extension,\none entry per function or constant. The `whatdoesthisdo` skill describes the format.\n' > "$ROOT/$FOLDER/README.md"
fi

echo "Done."

if [ "$AGENT" != claude ] && [ "$SCOPE" = global ]; then
  echo
  echo "Cursor has no global rules file. Paste this into Cursor Settings > Rules > User Rules:"
  echo
  substitute "$SRC/cursor-rule.mdc" | awk 'f && NF { print } /^---$/ { c++; if (c == 2) f = 1 }'
fi
