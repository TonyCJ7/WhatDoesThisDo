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

Without options the script asks on screen; arrow keys move, enter selects, b goes back, q quits.

Options:
  --agent claude|cursor|both   which agent follows the rule
  --scope project|global       this repository, or every project on this machine
  --folder <path>              references folder relative to the repository root
  --yes                        accept the defaults for anything not given and write without asking
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

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$(printf '\033[1m'); DIM=$(printf '\033[2m'); CYAN=$(printf '\033[36m'); GREEN=$(printf '\033[32m'); YELLOW=$(printf '\033[33m'); RESET=$(printf '\033[0m')
else
  BOLD=""; DIM=""; CYAN=""; GREEN=""; YELLOW=""; RESET=""
fi

TMP=$(mktemp -d)
KEYS=""
SAVED_STTY=""

cleanup() {
  if [ -n "$SAVED_STTY" ]; then
    stty "$SAVED_STTY" < "$KEYS" 2>/dev/null || true
  fi

  rm -rf "$TMP"
}

trap cleanup EXIT INT TERM

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

# ---------- keyboard ----------

open_keys() {
  if [ -n "${WDTD_STDIN_KEYS:-}" ]; then
    KEYS=stdin
  elif [ -t 0 ]; then
    KEYS=/dev/tty
  elif [ -r /dev/tty ]; then
    KEYS=/dev/tty
  else
    echo "no terminal to ask on; pass --agent, --scope, --folder and --yes" >&2
    exit 2
  fi

  if [ "$KEYS" != stdin ]; then
    SAVED_STTY=$(stty -g < "$KEYS")
    stty -icanon -echo min 1 time 0 < "$KEYS"
  fi
}

read_byte() {
  if [ "$KEYS" = stdin ]; then
    dd bs=1 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n'
  else
    dd bs=1 count=1 2>/dev/null < "$KEYS" | od -An -tx1 | tr -d ' \n'
  fi
}

read_key() {
  b=$(read_byte)

  case "$b" in
    1b)
      [ "$KEYS" = stdin ] || stty min 0 time 2 < "$KEYS"
      b2=$(read_byte)
      b3=""
      [ "$b2" = 5b ] && b3=$(read_byte)
      [ "$KEYS" = stdin ] || stty min 1 time 0 < "$KEYS"

      case "$b3" in
        41) echo up ;;
        42) echo down ;;
        44) echo back ;;
        *) echo other ;;
      esac
      ;;
    0a|0d) echo enter ;;
    6a) echo down ;;
    6b) echo up ;;
    62) echo back ;;
    71) echo quit ;;
    31) echo 1 ;;
    32) echo 2 ;;
    33) echo 3 ;;
    "") echo quit ;;
    *) echo other ;;
  esac
}

read_line() {
  if [ "$KEYS" = stdin ]; then
    read -r LINE || LINE=""
  else
    stty "$SAVED_STTY" < "$KEYS"
    read -r LINE < "$KEYS" || LINE=""
    stty -icanon -echo min 1 time 0 < "$KEYS"
  fi
}

clear_screen() {
  printf '\033[H\033[2J'
}

# ---------- screens ----------

header() {
  printf '%sWhatDoesThisDo setup%s  %s%s%s\n\n' "$BOLD" "$RESET" "$DIM" "$1" "$RESET"
}

draw_menu() {
  question=$1; current=$2; shift 2
  printf '%s\n\n' "$question"
  i=1

  for option in "$@"; do
    if [ "$i" = "$current" ]; then
      printf '  %s❯ %s%s\n' "$CYAN" "$option" "$RESET"
    else
      printf '    %s\n' "$option"
    fi

    i=$((i + 1))
  done

  printf '\n%s↑↓ move · enter select · b back · q quit%s\n' "$DIM" "$RESET"
}

# choose STEP QUESTION CURRENT OPTION... ; sets CHOICE to the index, "back" or "quit"
choose() {
  step=$1; question=$2; current=$3; shift 3
  count=$#

  while :; do
    clear_screen
    header "$step"
    draw_menu "$question" "$current" "$@"

    case "$(read_key)" in
      up) [ "$current" -gt 1 ] && current=$((current - 1)) ;;
      down) [ "$current" -lt "$count" ] && current=$((current + 1)) ;;
      enter) CHOICE=$current; return ;;
      back) CHOICE=back; return ;;
      quit) CHOICE=quit; return ;;
    esac
  done
}

agent_index() {
  case "$AGENT" in claude) echo 2 ;; cursor) echo 3 ;; *) echo 1 ;; esac
}

scope_index() {
  case "$SCOPE" in global) echo 2 ;; *) echo 1 ;; esac
}

screen_agent() {
  choose "step 1 of 3" "Which agent should follow the documentation rule?" "$(agent_index)" \
    "Both Claude Code and Cursor" "Claude Code" "Cursor"

  case "$CHOICE" in
    1) AGENT=both ;;
    2) AGENT=claude ;;
    3) AGENT=cursor ;;
  esac
}

screen_scope() {
  if [ -n "$ROOT" ]; then
    project_option="This project only          $ROOT"
  else
    project_option="This project only          (not inside a git repository)"
  fi

  while :; do
    choose "step 2 of 3" "Where should this apply?" "$(scope_index)" \
      "$project_option" "Everywhere for me          ~/.claude on this machine"

    case "$CHOICE" in
      1) [ -n "$ROOT" ] || continue; SCOPE=project; return ;;
      2) SCOPE=global; return ;;
      *) return ;;
    esac
  done
}

screen_folder() {
  [ -n "$FOLDER" ] || FOLDER=$DEFAULT_FOLDER

  while :; do
    choose "step 3 of 3" "Where do the reference pages live, relative to the repository root?" 1 \
      "Keep  $FOLDER" "Type another folder"

    case "$CHOICE" in
      1) return ;;
      2)
        printf '\nFolder: '
        read_line
        LINE=${LINE%/}
        [ -z "$LINE" ] || FOLDER=$LINE
        ;;
      *) return ;;
    esac
  done
}

agent_label() {
  case "$AGENT" in claude) echo "Claude Code" ;; cursor) echo "Cursor" ;; *) echo "Both Claude Code and Cursor" ;; esac
}

scope_label() {
  if [ "$SCOPE" = global ]; then echo "Everywhere for me  (~/.claude)"; else echo "This project  ($ROOT)"; fi
}

interactive() {
  open_keys
  screen=1
  from_summary=0

  while :; do
    case "$screen" in
      1) screen_agent ;;
      2) screen_scope ;;
      3) screen_folder ;;
      4)
        clear_screen
        header "summary"
        printf '  %s1%s  Agent    %s\n' "$DIM" "$RESET" "$(agent_label)"
        printf '  %s2%s  Scope    %s\n' "$DIM" "$RESET" "$(scope_label)"
        printf '  %s3%s  Folder   %s\n\n' "$DIM" "$RESET" "$FOLDER"
        printf '%sFiles to write:%s\n%s\n\n' "$BOLD" "$RESET" "$(plan_lines)"
        printf '%senter write · 1 2 3 change a step · q quit%s\n' "$DIM" "$RESET"

        case "$(read_key)" in
          enter) clear_screen; return ;;
          1) screen=1; from_summary=1; continue ;;
          2) screen=2; from_summary=1; continue ;;
          3) screen=3; from_summary=1; continue ;;
          quit) CHOICE=quit ;;
          *) continue ;;
        esac
        ;;
    esac

    case "$CHOICE" in
      quit) clear_screen; echo "nothing written"; exit 0 ;;
      back) [ "$screen" -gt 1 ] && screen=$((screen - 1)) ;;
      *)
        if [ "$from_summary" = 1 ]; then
          screen=4; from_summary=0
        else
          screen=$((screen + 1))
        fi
        ;;
    esac
  done
}

# ---------- plan and write ----------

plan_lines() {
  base=$HOME
  [ "$SCOPE" = project ] && base=$ROOT
  printf '  %s/.claude/skills/whatdoesthisdo/SKILL.md\n' "$base"

  if [ "$AGENT" != cursor ]; then
    if [ "$SCOPE" = project ]; then
      printf '  %s/CLAUDE.md  (rule block between <!-- whatdoesthisdo --> markers)\n' "$ROOT"
    else
      printf '  %s/.claude/CLAUDE.md  (rule block between <!-- whatdoesthisdo --> markers)\n' "$HOME"
    fi
  fi

  if [ "$AGENT" != claude ] && [ "$SCOPE" = project ]; then
    printf '  %s/.cursor/rules/whatdoesthisdo.mdc\n' "$ROOT"
  fi

  if [ "$SCOPE" = project ]; then
    printf '  %s/%s/README.md  (only if missing)\n' "$ROOT" "$FOLDER"
  fi
}

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
  [ -f "$1" ] && kept=$(strip_block "$1")
  mkdir -p "$(dirname "$1")"

  if [ -n "$kept" ]; then
    printf '%s\n\n%s\n' "$kept" "$block" > "$1"
  else
    printf '%s\n' "$block" > "$1"
  fi
}

write_files() {
  base=$HOME
  [ "$SCOPE" = project ] && base=$ROOT
  skill="$base/.claude/skills/whatdoesthisdo/SKILL.md"
  mkdir -p "$(dirname "$skill")"
  substitute "$SRC/skill/SKILL.md" > "$skill"

  if [ "$AGENT" != cursor ]; then
    if [ "$SCOPE" = project ]; then
      write_block "$ROOT/CLAUDE.md"
    else
      write_block "$HOME/.claude/CLAUDE.md"
    fi
  fi

  if [ "$AGENT" != claude ] && [ "$SCOPE" = project ]; then
    mkdir -p "$ROOT/.cursor/rules"
    substitute "$SRC/cursor-rule.mdc" > "$ROOT/.cursor/rules/whatdoesthisdo.mdc"
  fi

  if [ "$SCOPE" = project ] && [ ! -f "$ROOT/$FOLDER/README.md" ]; then
    mkdir -p "$ROOT/$FOLDER"
    printf '# Reference pages\n\nMarkdown pages read by the WhatDoesThisDo extension. One page per source file, at the same path as the file with a `.md` extension,\none entry per function or constant. The `whatdoesthisdo` skill describes the format.\n' > "$ROOT/$FOLDER/README.md"
  fi

  printf '%sDone.%s Written:\n%s\n' "$GREEN" "$RESET" "$(plan_lines | sed 's/  (only if missing)//')"

  if [ "$AGENT" != claude ] && [ "$SCOPE" = global ]; then
    printf '\n%sCursor has no global rules file.%s Paste this into Cursor Settings > Rules > User Rules:\n\n' "$YELLOW" "$RESET"
    substitute "$SRC/cursor-rule.mdc" | awk 'f && NF { print } /^---$/ { c++; if (c == 2) f = 1 }'
  fi
}

# ---------- main ----------

if [ "$YES" = 1 ]; then
  [ -n "$AGENT" ] || AGENT=both
  [ -n "$SCOPE" ] || SCOPE=project
  [ -n "$FOLDER" ] || FOLDER=$DEFAULT_FOLDER
elif [ -z "$AGENT" ] || [ -z "$SCOPE" ] || [ -z "$FOLDER" ]; then
  interactive
fi

case "$AGENT" in claude|cursor|both) ;; *) echo "agent must be claude, cursor or both" >&2; exit 2 ;; esac
case "$SCOPE" in project|global) ;; *) echo "scope must be project or global" >&2; exit 2 ;; esac
FOLDER=${FOLDER%/}

if [ "$SCOPE" = project ] && [ -z "$ROOT" ]; then
  echo "not inside a git repository; run from your project or use --scope global" >&2
  exit 1
fi

if [ "$YES" = 1 ]; then
  printf 'Files to write:\n%s\n' "$(plan_lines)"
fi

write_files
