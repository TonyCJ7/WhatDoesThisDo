# Changelog

## 0.1.3

- The hover has a second link under the heading, `Open in <page>.md`, which opens the page at the entry.
- The heading opens the declaration's current line: the language server's answer, then a search of the linked file,
  and only then the `#L` on the page. A link may leave the line out.
- The `#L` numbers on the pages are rewritten when a source file is saved, when it changes on disk through an agent
  or a `git pull`, when the window opens and when it regains focus. Setting `whatDoesThisDo.updateLines` turns that
  off; the command `WhatDoesThisDo: Update line numbers` does it for every page at once.
- The page walk no longer follows symbolic links, and a linked file above two megabytes is not searched.

## 0.1.2

- Fixed: clicking an entry's heading in the hover opened an empty editor named after the `#L` fragment. Links are now
  absolute file links with the line as the fragment, so the click opens the source at the declaration.

- The setup scripts ask on screen: a welcome page with the logo drawn as terminal pixel art, then arrow keys, enter, `b` to go back, `q` to quit,
  a summary that lets you change any step before the files are written, and a success page that reminds you to
  reload the editor. Flags still skip the screens. Ctrl+C leaves the macOS and Linux scripts at any point and
  restores the terminal; `q` on the Windows welcome screen exits cleanly.
- The skill tells the agent how to write an entry so it reads like the engineer who built the function wrote it,
  with a before and after.
- The README shows a recording of the hover, the page edit and the click to the declaration, and the repository
  documents its own source files under `docs/whatdoesthisdo/references/`.

## 0.1.1

- Search keywords so the extension is found by `WDTD`, `What does this do?`, and terms like AI documentation, agent,
  Claude Code and Cursor.
- Social preview image for the GitHub repository.

## 0.1.0

First public release.

- WhatDoesThisDo shows documentation from markdown reference pages in the workspace when you hover a name, in every language.
- Entries matched by name; when a language server reports where the symbol is defined, only the entries for that
  file are shown. Otherwise every entry for the name is shown, same file extension first.
- Pages mirror the source tree, one page per source file, and links resolve relative to the page as on GitHub.
- Setup scripts for macOS, Linux and Windows, and a setup prompt, that install the `whatdoesthisdo` skill and rule for
  Claude Code and Cursor.
- Page index built when the window opens and refreshed per page on change; pages in subfolders are read.
- Keys in any language's spelling (`save`, `$user`, `my-func`, `--brand`); a trailing `?` or `!` is optional.
- Editor tests across TypeScript, JavaScript, Python, Rust, Ruby, shell, PHP, Go, YAML and plain text, with and
  without language servers.
