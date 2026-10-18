# Changelog

## 0.1.0

First public release.

- WhatDoesThisDo shows documentation from markdown reference pages in the workspace when you hover a name, in every language.
- Entries matched by name; when a language server reports where the symbol is defined, only the entries for that
  file are shown. Otherwise every entry for the name is shown, same file extension first.
- Page index built when the window opens and refreshed per page on change; pages in subfolders are read.
- Keys in any language's spelling (`save`, `$user`, `my-func`, `--brand`); a trailing `?` or `!` is optional.
- Editor tests across TypeScript, JavaScript, Python, Rust, Ruby, shell, PHP, Go, YAML and plain text, with and
  without language servers.
