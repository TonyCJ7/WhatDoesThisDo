Set up WhatDoesThisDo documentation for this repository.

1. Find the repository root. Look for an existing `CLAUDE.md`, `.cursor/` folder and a docs folder, and use what
   you find to pre-fill the questions below.
2. Ask me three questions, one at a time, with the defaults shown:
   - Which agent should follow the documentation rule: Claude Code, Cursor, or both? (default: both)
   - Scope: this project only, or global for every project on this machine? (default: this project)
   - References folder, relative to the repository root. (default: docs/whatdoesthisdo/references)
3. Fetch these files from https://github.com/TonyCJ7/WhatDoesThisDo on the main branch, folder `agent/`, and copy
   them unchanged except for the folder path, which you replace with my answer:
   - `agent/skill/SKILL.md` to `.claude/skills/whatdoesthisdo/SKILL.md` for project scope, or
     `~/.claude/skills/whatdoesthisdo/SKILL.md` for global. Claude Code and Cursor both read this location.
   - For Claude Code: the block in `agent/rule-block.md` into `CLAUDE.md` at the repository root (project) or
     `~/.claude/CLAUDE.md` (global). Keep the marker comments. If the markers already exist, replace what is between
     them instead of adding a second block.
   - For Cursor, project scope: `agent/cursor-rule.mdc` to `.cursor/rules/whatdoesthisdo.mdc`. For Cursor, global
     scope: the skill only, and print the rule text for me to paste into Cursor Settings, Rules, User Rules.
4. Create the references folder, if it does not exist, with a `README.md` saying that it holds one page per source
   file at the same path with a `.md` extension, one entry per function or constant, in the format the skill describes.
5. Show me every file you created or changed, then stop. Do not commit.
