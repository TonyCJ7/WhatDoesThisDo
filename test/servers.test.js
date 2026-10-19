const fs = require("node:fs");
const path = require("node:path");
const vscode = require("vscode");

const { fixture, hoverAt, expectEntry, hoverLine, lineOf, pageHas } = require("./helpers.js");

const references = path.join(fixture, "docs/whatdoesthisdo/references");

async function saveWithLinesAtTop(file, header) {
  const document = await vscode.workspace.openTextDocument(file);
  const editor = await vscode.window.showTextDocument(document);

  await editor.edit((edit) => edit.insert(new vscode.Position(0, 0), header));
  await document.save();
}

async function restore(file, original) {
  const document = await vscode.workspace.openTextDocument(file);
  const editor = await vscode.window.showTextDocument(document);
  const whole = new vscode.Range(document.positionAt(0), document.positionAt(document.getText().length));

  await editor.edit((edit) => edit.replace(whole, original));
  await document.save();
}

suite("with an installed language server", () => {
  test("python via Pylance: picks the entry of the file the symbol is defined in", async () => {
    const texts = await hoverAt({ file: "py/use.py", needle: "fetch(1)", word: "fetch", resolves: true });

    expectEntry(texts, "Fetches in B", "Fetches in A");
  });

  test("rust via rust-analyzer: picks the entry of the file the symbol is defined in", async () => {
    const texts = await hoverAt({ file: "rs/src/main.rs", needle: "total(1)", word: "total", resolves: true });

    expectEntry(texts, "Totals in B", "Totals in A");
  });

  test("python via Pylance: a symbol defined in the same file still shows its single entry", async () => {
    expectEntry(await hoverAt({ file: "plain/tool.py", needle: "fetch_user(1)", word: "fetch_user" }), "Fetches one user");
  });

  test("python via Pylance: the server's line wins where a text search would pick the first use", async () => {
    await hoverLine({ file: "py/symbols.py", needle: "print(height)", offset: 6, word: "height", line: 3 });
  });

  test("python via Pylance: a function and a method with one name each open their own line", async () => {
    const file = "lines/python_twins.py";

    await hoverLine({ file, needle: "py_twin(1)", offset: 1, word: "py_twin", line: lineOf(file, "def py_twin(n):") });
    await hoverLine({ file, needle: "PyTwins().py_twin(1)", offset: 10, word: "py_twin", line: lineOf(file, "def py_twin(self, n):") });
  });

  test("rust via rust-analyzer: a function and a method with one name each open their own line", async () => {
    const file = "rs/src/twins.rs";

    await hoverLine({ file, needle: "rs_twin(1)", offset: 1, word: "rs_twin", line: lineOf(file, "fn rs_twin(n: i32)") });
    await hoverLine({ file, needle: "RsTwins.rs_twin(1)", offset: 8, word: "rs_twin", line: lineOf(file, "fn rs_twin(&self") });
  });

  test("python via Pylance: saving a.py moves the line on its page, and back", async () => {
    const source = path.join(fixture, "py/a.py");
    const page = path.join(references, "py/a.md");
    const original = fs.readFileSync(source, "utf8");

    try {
      await saveWithLinesAtTop(source, "import os\n\n");
      await pageHas(page, "py/a.py#L3)");
    } finally {
      await restore(source, original);
      await pageHas(page, "py/a.py#L1)");
      await vscode.commands.executeCommand("workbench.action.closeAllEditors");
    }
  });

  test("rust via rust-analyzer: saving a.rs moves the line on its page, and back", async () => {
    const source = path.join(fixture, "rs/src/a.rs");
    const page = path.join(references, "rs/src/a.md");
    const original = fs.readFileSync(source, "utf8");

    try {
      await saveWithLinesAtTop(source, "use std::fmt;\n\n");
      await pageHas(page, "rs/src/a.rs#L3)");
    } finally {
      await restore(source, original);
      await pageHas(page, "rs/src/a.rs#L1)");
      await vscode.commands.executeCommand("workbench.action.closeAllEditors");
    }
  });
});
