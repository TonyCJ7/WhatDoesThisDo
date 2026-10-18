# WhatDoesThisDo

WhatDoesThisDo shows the documentation for your own functions and constants when you hover them, read from markdown
reference pages in the workspace rather than from comments in the code. The explanation appears when you rest the mouse
on a name, and the source files stay free of doc comments.

The idea came out of AI-assisted development, where code gets written faster than anyone reads it. If each part of a
project has a reference page, written while the code is written, every function has somewhere to be explained. This
extension shows that explanation where you are already looking.

## How it works

1. Open any file in the workspace. The extension works in every language.
2. Hover a name. The extension looks the word up in its index of the references folder, reads the page or pages that
   hold it, and shows the entries under the editor's own signature hover.
3. If no page has an entry for the word, this extension adds nothing, and the editor's own hover is left as it was.

The index is built from the pages when the window opens and kept in memory as a map from name to page, without the
entry text. Before every hover the extension checks each page's modification time and size and re-reads only the pages
that changed, so an edit shows up on the next hover, and a folder of two thousand pages still answers in a few
milliseconds. The extension writes nothing to disk and has no runtime dependencies.

## When a name has several entries

A name such as `save` can be documented in several files. If a language server is running for the hovered file and
reports where the symbol is defined, the hover shows only the entries whose link points at one of those files. If there
is no server, or no entry points at a file the server named, the hover shows every entry for the name, each with its
link, with the entries whose link has the hovered file's extension first.

## Language servers

The built-in TypeScript server, Pylance and rust-analyzer are all examples of servers the extension can ask. Without
one, matching is by name alone, which is fine for most projects. A server helps once the same function name exists in
several files with separate entries.

## The reference page format

Default folder: `docs/whatdoesthisdo/references/` in the workspace root (setting `whatDoesThisDo.folder`). Any
number of pages, in the folder or any subfolder; all are read. In a multi-root workspace each folder has its own.

```markdown
## `src/config.ts`

### [readPositiveNumber(env, name, fallback)](../../../src/config.ts#L5)

Reads one env variable as a number that must be above zero.

- In: the env, the variable name, the default.
- Out: the default when unset or empty; otherwise the number.
- Refuses: `"abc"`, `"0"`, with `<name> must be a positive number, got "<value>"`.

### [notAFigmaLink(input)](../../../src/figma/urls.ts#L31), [notANodeId(id)](../../../src/figma/urls.ts#L8)

Build the two error objects. Every name in the heading gets this entry.

## Constants

- [`FILE_KEY`](../../../src/figma/urls.ts#L4): alphanumeric, 10 to 64 characters.
```

Rules the parser follows:

- A `### ` heading starts an entry. Every `[name(...)](link)` in the heading becomes a key, paired with its link. The
  key is the text before the opening parenthesis, in whatever spelling the language uses: `save`, `$user`, `my-func`,
  `--brand`. A name ending in `?` or `!` is also registered without the mark, because most editors' word patterns stop
  before it.
- The entry is the heading line plus every line until the next `### `, `## `, or constant bullet.
- A bullet `- [` + backticked name + `](link): text` is a one-line entry for a constant.
- Links are relative to the references folder. They are clickable in the hover, and the file part of the link is what
  the definition match compares against.

## Install

```
npm install
npm test
npm run test:editor
npm run package
"/Applications/Cursor.app/Contents/Resources/app/bin/cursor" --install-extension whatdoesthisdo-<version>.vsix
```

For VS Code use `code --install-extension` instead. Then "Developer: Reload Window". To develop, open this folder
and press F5: a second editor window starts with the extension loaded from source.

`npm run test:editor` downloads a stock VS Code build into `.vscode-test/` on first run and runs the tests inside it,
against the fixture workspace in `test/fixture/`, in two launches configured by `.vscode-test.mjs`:

- `builtin` runs `test/builtin.test.js` with other extensions disabled. TypeScript and JavaScript use the bundled
  server and pick the entry by definition. Python, Rust, Ruby, shell, PHP, Go, YAML and plain text have no server there
  and show every entry for the name, same extension first, including each language's word shape (`$user` in PHP keeps
  the dollar, `$CONFIG_DIR` in shell drops it, Ruby's `valid?` stops before the question mark). It also edits a page
  mid-run to check the index refreshes, and reads a page from a subfolder.
- `servers` runs `test/servers.test.js` after installing Pylance and rust-analyzer from the marketplace, and checks
  that Python and Rust pick the entry by definition. It needs network access and `cargo` on the machine.

`npx vscode-test --label builtin` runs one launch.

`scripts/package.py` writes the `.vsix` (a zip with a manifest) with Python's standard library, so no packaging tool
is needed.

## Contributing

Issues and pull requests are welcome. `CONTRIBUTING.md` has the short version: run both test suites, keep the
extension free of runtime dependencies, and document any new behaviour in this README. Released under the MIT
license, see `LICENSE`.

## Layout

- `extension.js`: activation, the hover provider and the definition lookup. It needs the editor's `vscode` module, so
  the editor tests cover it rather than the unit tests.
- `parse.js`: the markdown parser, pure, tested by `parse.test.js` with Node's built-in runner.
- `test/builtin.test.js`, `test/servers.test.js`, `test/helpers.js`: the editor tests, run by `@vscode/test-cli` per
  `.vscode-test.mjs`, with the workspace in `test/fixture/`.
- `scripts/package.py`: builds the installable `.vsix`.
