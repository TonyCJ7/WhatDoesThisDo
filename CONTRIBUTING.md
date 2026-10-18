# Contributing

Thanks for helping. The extension is small on purpose: one parser, one hover provider, no runtime dependencies.

## Run it

```
npm install
npm test               # parser tests, Node's built-in runner
npm run test:editor    # downloads VS Code once and runs the hover tests inside it
```

`npx vscode-test --label builtin` runs only the launch that needs no network. The `servers` launch installs Pylance
and rust-analyzer from the marketplace and needs `cargo` on the machine.

Press F5 in VS Code or Cursor to run the extension from source in a second window.

## Change it

- Logic that does not touch the `vscode` module goes in `parse.js` or a new pure module, with a test in
  `parse.test.js`.
- Behaviour that needs the editor gets a case in `test/builtin.test.js` or `test/servers.test.js`, against the
  fixture workspace in `test/fixture/`. Add a fixture file and a page entry rather than a mock.
- Keep the README's "How it works", page format and test sections true after the change.
- No new runtime dependency without an issue first. Dev dependencies are fine when they earn their place.
- Add a line to `CHANGELOG.md` under the next version.

## Report a bug

Open an issue with the page entry, the file you hovered, the language, whether a language server was running, and
what the hover showed. A minimal fixture that reproduces it in `test/fixture/` is the fastest route to a fix.
