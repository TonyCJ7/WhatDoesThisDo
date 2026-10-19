const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vscode = require("vscode");

const { fixture, hoverAt, expectEntry } = require("./helpers.js");

suite("with a bundled language server", () => {
  test("typescript: picks the entry of the file the symbol is defined in", async () => {
    const texts = await hoverAt({ file: "src/useB.ts", needle: "save(1)", word: "save", resolves: true });

    expectEntry(texts, "Saves in B", "Saves in A");
  });

  test("javascript: picks the entry of the file the symbol is defined in", async () => {
    const texts = await hoverAt({ file: "src/js/use.js", needle: "persist(1)", word: "persist", resolves: true });

    expectEntry(texts, "Persists in B", "Persists in A");
  });

  test("typescript: a symbol declared in two files matches an entry for either file", async () => {
    const texts = await hoverAt({ file: "src/c/use.ts", needle: "const config: Config", offset: 15, word: "Config", resolves: true });

    expectEntry(texts, "Config in two", "Decoy config");
  });
});

suite("without a language server", () => {
  test("python: same-named entries are all shown, in page order", async () => {
    const texts = await hoverAt({ file: "py/use.py", needle: "fetch(1)", word: "fetch" });

    assert.equal(texts.length, 2);
    assert.match(texts[0], /Fetches in A/);
    assert.match(texts[1], /Fetches in B/);
  });

  test("rust: same-named entries are all shown", async () => {
    const texts = await hoverAt({ file: "rs/src/main.rs", needle: "total(1)", word: "total" });

    assert.equal(texts.length, 2);
    expectEntry(texts, "Totals in A");
    expectEntry(texts, "Totals in B");
  });

  test("an entry's link becomes an absolute file link with the line as its fragment", async () => {
    const [text] = await hoverAt({ file: "plain/tool.py", needle: "fetch_user(1)", word: "fetch_user" });
    const expected = vscode.Uri.file(path.join(fixture, "plain/tool.py")).with({ fragment: "L1" }).toString();

    assert.ok(text.includes(`](${expected})`), text);
  });

  test("the hover offers a link to the page, under the heading, at the entry's own line", async () => {
    const [text] = await hoverAt({ file: "plain/tool.py", needle: "fetch_user(1)", word: "fetch_user" });
    const page = vscode.Uri.file(path.join(fixture, "docs/whatdoesthisdo/references/plain/tool.md")).with({ fragment: "L3" });

    assert.equal(text.split("\n")[2], `[Open in tool.md](${page.toString()})`, text);
  });

  test("a link without a line gets the line of the declaration found in the file", async () => {
    const [text] = await hoverAt({ file: "plain/tool.py", needle: "load_user(1)", word: "load_user" });
    const expected = vscode.Uri.file(path.join(fixture, "plain/tool.py")).with({ fragment: "L8" }).toString();

    assert.ok(text.includes(`](${expected})`), text);
  });

  test("saving a source file moves the line numbers on its page", async () => {
    const source = path.join(fixture, "temp_lines.py");
    const page = path.join(fixture, "docs/whatdoesthisdo/references/temp_lines.md");

    fs.writeFileSync(source, "def alpha():\n    return 1\n");
    fs.writeFileSync(page, "### [alpha()](../../../temp_lines.py#L1)\n\nTemporary.\n");

    try {
      const document = await vscode.workspace.openTextDocument(source);
      const editor = await vscode.window.showTextDocument(document);

      await editor.edit((edit) => edit.insert(new vscode.Position(0, 0), "import os\n\n\n"));
      await document.save();

      for (let attempt = 0; attempt < 40 && !fs.readFileSync(page, "utf8").includes("#L4"); attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, 250));
      }

      assert.match(fs.readFileSync(page, "utf8"), /\(\.\.\/\.\.\/\.\.\/temp_lines\.py#L4\)/);
    } finally {
      await vscode.commands.executeCommand("workbench.action.closeAllEditors");
      fs.rmSync(source, { force: true });
      fs.rmSync(page, { force: true });
    }
  });

  test("python: a name with one entry on a page in a subfolder shows it", async () => {
    expectEntry(await hoverAt({ file: "plain/tool.py", needle: "fetch_user(1)", word: "fetch_user" }), "Fetches one user");
  });

  test("python: an entry whose link has the hovered file's extension ranks first", async () => {
    const texts = await hoverAt({ file: "plain/tool.py", needle: "save(1)", word: "save" });

    assert.equal(texts.length, 3);
    assert.match(texts[0], /Saves in Python/);
    assert.match(texts[1], /Saves in A/);
    assert.match(texts[2], /Saves in B/);
  });

  test("ruby: the word stops before the predicate's question mark, as does the page key", async () => {
    expectEntry(await hoverAt({ file: "plain/script.rb", needle: "valid?(1)", word: "valid" }), "Ruby predicate");
  });

  test("shell: the word excludes the dollar and matches a key without it", async () => {
    expectEntry(await hoverAt({ file: "plain/run.sh", needle: '"$CONFIG_DIR"', offset: 2, word: "CONFIG_DIR" }), "shell variable");
  });

  test("shell: hovering the dollar itself is no word and no hover", async () => {
    const texts = await hoverAt({ file: "plain/run.sh", needle: '"$CONFIG_DIR"', offset: 1, word: null });

    assert.deepEqual(texts, []);
  });

  test("php: the word includes the dollar and matches a key with it", async () => {
    expectEntry(await hoverAt({ file: "plain/index.php", needle: "echo $user", offset: 6, word: "$user" }), "PHP variable");
  });

  test("go: an exported function matches by name", async () => {
    expectEntry(await hoverAt({ file: "plain/main.go", needle: "Save(1)", word: "Save" }), "Go exported function");
  });

  test("yaml: a key matches a constant entry", async () => {
    expectEntry(await hoverAt({ file: "plain/config.yaml", needle: "retry_count: 3", word: "retry_count" }), "yaml key");
  });

  test("plain text: no extension matches, so every entry is shown in page order", async () => {
    const texts = await hoverAt({ file: "notes.txt", needle: "save", word: "save" });

    assert.equal(texts.length, 3);
    assert.match(texts[0], /Saves in Python/);
  });

  test("an added, edited and removed page takes effect on the next hover", async () => {
    const page = path.join(fixture, "docs/whatdoesthisdo/references/temp.md");
    const write = (body) => {
      fs.writeFileSync(page, `### [temporary()](../../../notes.txt#L1)\n\n${body}\n`);
      fs.utimesSync(page, new Date(), new Date(Date.now() + 2000));
    };

    try {
      write("First version.");
      expectEntry(await hoverAt({ file: "notes.txt", needle: "temporary", word: "temporary" }), "First version");
      write("Second version.");
      expectEntry(await hoverAt({ file: "notes.txt", needle: "temporary", word: "temporary" }), "Second version");
      fs.unlinkSync(page);
      assert.deepEqual(await hoverAt({ file: "notes.txt", needle: "temporary", word: "temporary" }), []);
    } finally {
      fs.rmSync(page, { force: true });
    }
  });

  test("plain text: adds nothing for a word without an entry", async () => {
    const texts = await hoverAt({ file: "notes.txt", needle: "call", word: "call" });

    assert.deepEqual(texts, []);
  });
});
