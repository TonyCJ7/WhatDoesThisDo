# Changelog

## Unreleased

- The setup scripts ask on screen: a welcome page with the logo drawn as terminal pixel art, then arrow keys, enter, `b` to go back, `q` to quit,
  a summary that lets you change any step before the files are written, and a success page that reminds you to
  reload the editor. Flags still skip the screens.

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
