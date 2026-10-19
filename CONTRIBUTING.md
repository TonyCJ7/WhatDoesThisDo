# Contributing

Thanks for helping. The extension is small on purpose: one parser, one hover provider, no runtime dependencies.

## Run it

```
npm install            # Node.js 22 or later, see .nvmrc
npm test               # parser tests, Node's built-in runner
npm run test:editor    # downloads VS Code once and runs the hover tests inside it
```

`npx vscode-test --label builtin` runs only the launch that needs no network. The `servers` launch installs Pylance
and rust-analyzer from the marketplace and needs `cargo` on the machine.

Before you open a pull request, `npm test && npx vscode-test --label builtin` must pass. GitHub runs the same checks
on the pull request through the Tests workflow, and the branch rules do not let it merge until they are green. The
`servers` launch also runs there, as an advisory job.

Press F5 in VS Code or Cursor to run the extension from source in a second window.

## Change it

- Logic that does not touch the `vscode` module goes in `parse.js`, `lines.js` or a new pure module, with a test
  next to it such as `parse.test.js` or `lines.test.js`.
- Behaviour that needs the editor gets a case in `test/builtin.test.js`, `test/lines.test.js` or
  `test/servers.test.js`, against the fixture workspace in `test/fixture/`. Add a fixture file and a page entry rather
  than a mock. A new language gets a file in `test/fixture/lines/` with a call before the declaration and a page
  whose line is wrong, so the test proves the line comes from the code, plus a `_shapes` file with a method and a
  constant. The tables at the top of `test/lines.test.js` then run the hover, save, watcher and command cases for it.
- Keep the README's "How it works", page format and test sections true after the change.
- No new runtime dependency without an issue first. Dev dependencies are fine when they earn their place.
- Add a line to `CHANGELOG.md` under the next version.

## Report a bug

Open an issue with the page entry, the file you hovered, the language, whether a language server was running, and
what the hover showed. A minimal fixture that reproduces it in `test/fixture/` is the fastest route to a fix.
