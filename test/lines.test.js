const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const vscode = require("vscode");

const { fixture, sleep, hoverAt, fragmentOf, hoverLine, lineOf, pageHas } = require("./helpers.js");

const references = path.join(fixture, "docs/whatdoesthisdo/references");
const SETTLE_MS = 150;

const languages = [
  ["java", "lines/java.java", 'greet("x")', "greet", 6],
  ["c", "lines/c.c", "tally(1)", "tally", 7],
  ["c#", "lines/csharp.cs", "Persist(1)", "Persist", 8],
  ["kotlin", "lines/kotlin.kt", "store(1)", "store", 5],
  ["swift", "lines/swift.swift", "keep(id: 1)", "keep", 3],
  ["clojure", "lines/clojure.clj", "tally 1", "tally", 5],
  ["elixir, link without a line", "lines/elixir.ex", "load(1)", "load", 4],
  ["sql", "lines/sql.sql", "grand_total(1)", "grand_total", 3],
  ["lua, link without a line", "lines/lua.lua", "stash(1)", "stash", 3],
  ["haskell", "lines/haskell.hs", "twice 1", "twice", 3],
  ["css custom property", "lines/css.css", "var(--brand)", "--brand", 4, 4],
  ["go method with a receiver", "lines/go.go", "Export(1)", "Export", 5],
  ["ruby predicate", "lines/ruby.rb", "ready?(1)", "ready", 3],
  ["php", "lines/php.php", "archive(1)", "archive", 4],
  ["shell variable", "lines/shell.sh", '"$CACHE_DIR"', "CACHE_DIR", 2, 2],
  ["yaml key", "lines/yaml.yaml", "max_tries: 3", "max_tries", 2],
  ["python", "lines/python.py", "gather(1)", "gather", 4],
  ["rust", "lines/rust.rs", "count_up(1)", "count_up", 3],
  ["typescript, through the bundled server", "lines/typescript.ts", "emit(1)", "emit", 3],
];

const shapes = [
  ["java method", "lines/java_shapes.java", "javaAttempt(1)", 1, "javaAttempt", "private int javaAttempt("],
  ["java constant", "lines/java_shapes.java", "JAVA_LIMIT +", 1, "JAVA_LIMIT", "static final int JAVA_LIMIT ="],
  ["c function after main", "lines/c_shapes.c", "c_attempt(1)", 1, "c_attempt", "static int c_attempt("],
  ["c preprocessor define", "lines/c_shapes.c", "C_LIMIT }", 1, "C_LIMIT", "#define C_LIMIT"],
  ["c# method", "lines/csharp_shapes.cs", "CsAttempt(1)", 1, "CsAttempt", "private int CsAttempt("],
  ["c# const", "lines/csharp_shapes.cs", "CsLimit +", 1, "CsLimit", "public const int CsLimit"],
  ["kotlin method", "lines/kotlin_shapes.kt", "ktAttempt(1)", 1, "ktAttempt", "private fun ktAttempt("],
  ["kotlin const val", "lines/kotlin_shapes.kt", "KT_LIMIT +", 1, "KT_LIMIT", "const val KT_LIMIT"],
  ["swift method", "lines/swift_shapes.swift", "swiftAttempt(1)", 1, "swiftAttempt", "func swiftAttempt("],
  ["swift let", "lines/swift_shapes.swift", "swiftLimit +", 1, "swiftLimit", "let swiftLimit"],
  ["clojure defn", "lines/clojure_shapes.clj", "(cljattempt 1)", 2, "cljattempt", "(defn cljattempt"],
  ["clojure def", "lines/clojure_shapes.clj", "cljlimit (", 1, "cljlimit", "(def cljlimit"],
  ["elixir private function", "lines/elixir_shapes.ex", "ex_attempt(1)", 1, "ex_attempt", "defp ex_attempt("],
  ["elixir module attribute", "lines/elixir_shapes.ex", "@ex_limit +", 2, "ex_limit", "@ex_limit 3"],
  ["sql function", "lines/sql_shapes.sql", "sql_attempt(1)", 1, "sql_attempt", "CREATE FUNCTION sql_attempt("],
  ["sql view", "lines/sql_shapes.sql", "FROM sql_limit", 6, "sql_limit", "CREATE VIEW sql_limit"],
  ["lua function on a table", "lines/lua_shapes.lua", "LuaConfig.luaAttempt(1)", 11, "luaAttempt", "function LuaConfig.luaAttempt("],
  ["lua global", "lines/lua_shapes.lua", "LUA_LIMIT +", 1, "LUA_LIMIT", "LUA_LIMIT = 3"],
  ["haskell function", "lines/haskell_shapes.hs", "hsAttempt 1", 1, "hsAttempt", "hsAttempt :: Int -> Int"],
  ["haskell binding", "lines/haskell_shapes.hs", "hsLimit +", 1, "hsLimit", "hsLimit :: Int"],
  ["css first custom property", "lines/css_shapes.css", "var(--css-brand)", 4, "--css-brand", "--css-brand: #123"],
  ["css second custom property", "lines/css_shapes.css", "var(--css-gap)", 4, "--css-gap", "--css-gap: 4px"],
  ["go method", "lines/go_shapes.go", "GoAttempt(1)", 1, "GoAttempt", "func (c GoConfig) GoAttempt("],
  ["go const", "lines/go_shapes.go", "GoLimit +", 1, "GoLimit", "const GoLimit"],
  ["go type", "lines/go_shapes.go", "GoConfig{}", 1, "GoConfig", "type GoConfig struct"],
  ["ruby method", "lines/ruby_shapes.rb", "rb_attempt(1)", 1, "rb_attempt", "def rb_attempt("],
  ["ruby constant", "lines/ruby_shapes.rb", "RB_LIMIT +", 1, "RB_LIMIT", "RB_LIMIT = 3"],
  ["php method", "lines/php_shapes.php", "phpAttempt(1)", 1, "phpAttempt", "private function phpAttempt("],
  ["php class constant", "lines/php_shapes.php", "PHP_LIMIT +", 1, "PHP_LIMIT", "const PHP_LIMIT"],
  ["shell function", "lines/shell_shapes.sh", 'sh_attempt "$', 1, "sh_attempt", "sh_attempt() {"],
  ["shell variable", "lines/shell_shapes.sh", '"$SH_LIMIT"', 2, "SH_LIMIT", "SH_LIMIT=3"],
  ["yaml nested key", "lines/yaml_shapes.yaml", "yaml_limit: 3", 1, "yaml_limit", "yaml_limit: 3"],
  ["yaml second nested key", "lines/yaml_shapes.yaml", "yaml_delay: 100", 1, "yaml_delay", "yaml_delay: 100"],
  ["python method", "lines/python_shapes.py", "py_attempt(1)", 1, "py_attempt", "def py_attempt("],
  ["python module constant", "lines/python_shapes.py", "PY_LIMIT +", 1, "PY_LIMIT", "PY_LIMIT = 3"],
  ["rust method in an impl", "lines/rust_shapes.rs", "rs_attempt(1)", 1, "rs_attempt", "fn rs_attempt("],
  ["rust const", "lines/rust_shapes.rs", "RS_LIMIT +", 1, "RS_LIMIT", "const RS_LIMIT"],
  ["typescript method, through the bundled server", "lines/typescript_shapes.ts", "tsAttempt(1)", 1, "tsAttempt", "tsAttempt(n: number)"],
  ["typescript const, through the bundled server", "lines/typescript_shapes.ts", "TS_LIMIT +", 1, "TS_LIMIT", "export const TS_LIMIT"],
  ["java class", "lines/java_shapes.java", "new JavaConfig()", 5, "JavaConfig", "public class JavaConfig {"],
  ["c struct", "lines/c_shapes.c", "CConfig cfg", 1, "CConfig", "struct CConfig { int n; };"],
  ["c# class", "lines/csharp_shapes.cs", "new CsConfig()", 5, "CsConfig", "public class CsConfig"],
  ["kotlin class", "lines/kotlin_shapes.kt", "KtConfig().run()", 1, "KtConfig", "class KtConfig {"],
  ["swift struct", "lines/swift_shapes.swift", "SwiftConfig().run()", 1, "SwiftConfig", "struct SwiftConfig {"],
  ["clojure record", "lines/clojure_shapes.clj", "->CljConfig 1", 3, "CljConfig", "(defrecord CljConfig [n])"],
  ["elixir module", "lines/elixir_shapes.ex", "ExConfig.run()", 1, "ExConfig", "defmodule ExConfig do"],
  ["sql table", "lines/sql_shapes.sql", "FROM sql_config", 6, "sql_config", "CREATE TABLE sql_config"],
  ["lua table", "lines/lua_shapes.lua", "LuaConfig.run()", 1, "LuaConfig", "local LuaConfig = {}"],
  ["haskell data type", "lines/haskell_shapes.hs", "(HsConfig 3)", 2, "HsConfig", "data HsConfig = HsConfig Int"],
  ["ruby class", "lines/ruby_shapes.rb", "RbConfig.new", 1, "RbConfig", "class RbConfig"],
  ["php class", "lines/php_shapes.php", "new PhpConfig()", 5, "PhpConfig", "class PhpConfig {"],
  ["python class", "lines/python_shapes.py", "PyConfig().run()", 1, "PyConfig", "class PyConfig:"],
  ["rust struct", "lines/rust_shapes.rs", "RsConfig.run()", 1, "RsConfig", "struct RsConfig;"],
  ["typescript class, through the bundled server", "lines/typescript_shapes.ts", "new TsConfig()", 5, "TsConfig", "class TsConfig {"],
];

const twins = [
  ["java overloads", "lines/java_twins.java", "javaTwin(1)", 1, "javaTwin", "private int javaTwin(int n) {"],
  ["c prototype then definition", "lines/c_twins.c", "c_twin(1)", 1, "c_twin", "int c_twin(int n);"],
  ["c# overloads", "lines/csharp_twins.cs", "CsTwin(1)", 1, "CsTwin", "private int CsTwin(int n)"],
  ["kotlin overloads", "lines/kotlin_twins.kt", "ktTwin(1)", 1, "ktTwin", "fun ktTwin(n: Int): Int = n"],
  ["swift overloads", "lines/swift_twins.swift", "swiftTwin(1)", 1, "swiftTwin", "func swiftTwin(_ n: Int) -> Int { n }"],
  ["clojure redefinition", "lines/clojure_twins.clj", "(cljtwin 1)", 2, "cljtwin", "(defn cljtwin [n] n)"],
  ["elixir two clauses", "lines/elixir_twins.ex", "ex_twin(1)", 1, "ex_twin", "def ex_twin(n), do: n"],
  ["sql overloads", "lines/sql_twins.sql", "sql_twin(1)", 1, "sql_twin", "CREATE FUNCTION sql_twin(n int) RETURNS"],
  ["lua local function and table function", "lines/lua_twins.lua", "luaTwin(1)", 1, "luaTwin", "local function luaTwin(n)"],
  ["haskell two where bindings", "lines/haskell_twins.hs", "hsTwin 1", 1, "hsTwin", "    hsTwin :: Int -> Int"],
  ["css property in two selectors", "lines/css_twins.css", "var(--css-twin)", 4, "--css-twin", "--css-twin: #123"],
  ["go method on two types", "lines/go_twins.go", "GoA{}.GoTwin()", 6, "GoTwin", "func (a GoA) GoTwin()"],
  ["ruby method in two classes", "lines/ruby_twins.rb", "rb_twin(1)", 1, "rb_twin", "  def rb_twin(n)"],
  ["php method in two classes", "lines/php_twins.php", "phpTwin(1)", 1, "phpTwin", "public function phpTwin($n)"],
  ["shell function and variable", "lines/shell_twins.sh", 'sh_twin "$', 1, "sh_twin", "sh_twin() {"],
  ["yaml key under two maps", "lines/yaml_twins.yaml", "yaml_twin: 2", 1, "yaml_twin", "yaml_twin: 1"],
  ["python function and method, no server: the first", "lines/python_twins.py", "PyTwins().py_twin(1)", 10, "py_twin", "def py_twin(n):"],
  ["rust function and method, no server: the first", "lines/rust_twins.rs", "RsTwins.rs_twin(1)", 8, "rs_twin", "fn rs_twin(n: i32) -> i32 { n }"],
  ["typescript function, through the server", "lines/typescript_twins.ts", "tsTwin(1)", 1, "tsTwin", "function tsTwin(n: number)"],
  ["typescript method, through the server", "lines/typescript_twins.ts", "new TsTwins().tsTwin(1)", 14, "tsTwin", "  tsTwin(n: number) { return n + 1; }"],
];

function pageFor(file) {
  return path.join(references, file.replace(/\.[^.]+$/, ".md"));
}

function writeTemp(files) {
  for (const [file, text] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, text);
  }
}

async function removeTemp(files) {
  await vscode.commands.executeCommand("workbench.action.closeAllEditors");

  for (const file of Object.keys(files)) {
    fs.rmSync(file, { force: true });
  }
}

function tempCopy(file, line, pageLine) {
  const temp = file.replace(/([^/]+)$/, "temp_$1");
  const source = path.join(fixture, temp);
  const page = pageFor(temp);
  const link = path.relative(path.dirname(page), source).split(path.sep).join("/");

  return {
    source,
    page,
    files: {
      [source]: fs.readFileSync(path.join(fixture, file), "utf8"),
      [page]: `## \`${temp}\`\n\n### [${line.word}](${link}#L${pageLine})\n\nTemporary copy.\n`,
    },
  };
}

function snapshotPages() {
  const pages = new Map();

  for (const name of fs.readdirSync(references, { recursive: true })) {
    if (name.endsWith(".md")) {
      pages.set(path.join(references, name), fs.readFileSync(path.join(references, name), "utf8"));
    }
  }

  return pages;
}

function restorePages(pages) {
  for (const [page, text] of pages) {
    if (fs.readFileSync(page, "utf8") !== text) {
      fs.writeFileSync(page, text);
    }
  }
}

async function saveWithLinesAtTop(file, header) {
  const document = await vscode.workspace.openTextDocument(file);
  const editor = await vscode.window.showTextDocument(document);

  await editor.edit((edit) => edit.insert(new vscode.Position(0, 0), header));
  await document.save();

  return document;
}

suite("the heading opens the declaration's current line, whatever the page says", () => {
  for (const [label, file, needle, word, line, offset = 1] of languages) {
    test(`${label}: ${word} opens line ${line}`, async () => {
      await hoverLine({ file, needle, offset, word, line });
    });
  }

  for (const [label, file, needle, offset, word, declaration] of shapes) {
    test(`${label}: ${word} opens its declaration`, async () => {
      await hoverLine({ file, needle, offset, word, line: lineOf(file, declaration) });
    });
  }

  for (const [label, file, needle, offset, word, declaration] of twins) {
    test(`${label}: ${word} declared twice opens ${declaration.trim()}`, async () => {
      await hoverLine({ file, needle, offset, word, line: lineOf(file, declaration) });
    });
  }

  test("typescript: the server's line wins where a text search would pick the first use", async () => {
    await hoverLine({ file: "lines/symbols.ts", needle: "console.log(width)", offset: 12, word: "width", line: 3 });
  });

  test("a constant's page link opens the page at its bullet", async () => {
    const [text] = await hoverAt({ file: "lines/yaml.yaml", needle: "max_tries: 3", word: "max_tries" });
    const page = vscode.Uri.file(path.join(references, "lines/yaml.md")).with({ fragment: "L5" });

    assert.equal(text.split("\n")[2], `[Open in yaml.md](${page.toString()})`, text);
  });
});

suite("saving a source file rewrites the lines on its pages", () => {
  for (const [label, file, , word, line] of languages) {
    test(`${label}: two lines added at the top move ${word} from ${line} to ${line + 2}`, async () => {
      const { source, page, files } = tempCopy(file, { word }, line);

      writeTemp(files);

      try {
        await saveWithLinesAtTop(source, "\n\n");
        await pageHas(page, `#L${line + 2})`);
      } finally {
        await removeTemp(files);
      }
    });
  }

  test("typescript: the server's symbols place a name a text search would misplace", async () => {
    const files = {
      [path.join(fixture, "lines/temp_symbols.ts")]: "console.log(width);\n\nexport const [width] = [1];\n",
      [path.join(references, "lines/temp_symbols.md")]: "### [width](../../../../lines/temp_symbols.ts#L1)\n\nTemporary.\n",
    };

    writeTemp(files);

    try {
      await saveWithLinesAtTop(path.join(fixture, "lines/temp_symbols.ts"), "// header\n\n");
      await pageHas(path.join(references, "lines/temp_symbols.md"), "temp_symbols.ts#L5)");
    } finally {
      await removeTemp(files);
    }
  });

  test("a page open with unsaved edits is updated in its buffer and left unsaved", async () => {
    const source = path.join(fixture, "temp_dirty.py");
    const page = path.join(references, "temp_dirty.md");
    const files = { [source]: "def alpha():\n    return 1\n", [page]: "### [alpha()](../../../temp_dirty.py#L1)\n\nTemporary.\n" };

    writeTemp(files);

    try {
      const pageDocument = await vscode.workspace.openTextDocument(page);
      const pageEditor = await vscode.window.showTextDocument(pageDocument);

      await pageEditor.edit((edit) => edit.insert(new vscode.Position(2, 0), "Edited. "));
      assert.ok(pageDocument.isDirty);

      await saveWithLinesAtTop(source, "import os\n\n\n");

      for (let attempt = 0; attempt < 40 && !pageDocument.getText().includes("#L4)"); attempt += 1) {
        await sleep(250);
      }

      assert.match(pageDocument.getText(), /temp_dirty\.py#L4\)/);
      assert.ok(pageDocument.isDirty, "the page should stay unsaved");
      assert.match(fs.readFileSync(page, "utf8"), /temp_dirty\.py#L1\)/);

      await vscode.window.showTextDocument(pageDocument);
      await vscode.commands.executeCommand("workbench.action.files.revert");
    } finally {
      await removeTemp(files);
    }
  });

  test("an entry whose name is no longer in the file is left alone", async () => {
    const source = path.join(fixture, "temp_gone.py");
    const page = path.join(references, "temp_gone.md");
    const files = { [source]: "def alpha():\n    return 1\n", [page]: "### [gone()](../../../temp_gone.py#L1)\n\nTemporary.\n" };

    writeTemp(files);

    try {
      await saveWithLinesAtTop(source, "import os\n\n\n");
      await sleep(2000);
      assert.match(fs.readFileSync(page, "utf8"), /temp_gone\.py#L1\)/);
    } finally {
      await removeTemp(files);
    }
  });

  test("every page linking to the file is updated, mirrored or not", async () => {
    const source = path.join(fixture, "temp_multi.py");
    const mirrored = path.join(references, "temp_multi.md");
    const elsewhere = path.join(references, "other/temp_multi_notes.md");
    const files = {
      [source]: "def beta():\n    return 1\n",
      [mirrored]: "### [beta()](../../../temp_multi.py#L1)\n\nMirrored page.\n",
      [elsewhere]: "### [beta()](../../../../temp_multi.py#L1)\n\nPage in another folder.\n",
    };

    writeTemp(files);

    try {
      await saveWithLinesAtTop(source, "import os\n\n\n");
      await pageHas(mirrored, "temp_multi.py#L4)");
      await pageHas(elsewhere, "temp_multi.py#L4)");
    } finally {
      await removeTemp(files);
      fs.rmSync(path.dirname(elsewhere), { recursive: true, force: true });
    }
  });

  test("the setting turns the rewrite off", async () => {
    const source = path.join(fixture, "temp_off.py");
    const page = path.join(references, "temp_off.md");
    const files = { [source]: "def alpha():\n    return 1\n", [page]: "### [alpha()](../../../temp_off.py#L1)\n\nTemporary.\n" };
    const settings = vscode.workspace.getConfiguration("whatDoesThisDo");
    const hadSettingsFolder = fs.existsSync(path.join(fixture, ".vscode"));

    writeTemp(files);
    await settings.update("updateLines", false, vscode.ConfigurationTarget.Workspace);

    try {
      await saveWithLinesAtTop(source, "import os\n\n\n");
      await sleep(2000);
      assert.match(fs.readFileSync(page, "utf8"), /temp_off\.py#L1\)/);
    } finally {
      await settings.update("updateLines", undefined, vscode.ConfigurationTarget.Workspace);
      await removeTemp(files);

      if (!hadSettingsFolder) {
        fs.rmSync(path.join(fixture, ".vscode"), { recursive: true, force: true });
      }
    }
  });
});

suite("changes made outside the editor", () => {
  test("a page whose source was newer when the editor started was fixed at launch", async () => {
    const page = path.join(references, "launch/stale.md");

    try {
      await pageHas(page, "launch/stale.py#L4)");
    } finally {
      fs.rmSync(path.join(fixture, "launch"), { recursive: true, force: true });
      fs.rmSync(path.dirname(page), { recursive: true, force: true });
    }
  });

  for (const [label, file, , word, line] of languages) {
    test(`${label}: ${word} rewritten on disk by another program moves its page line`, async () => {
      const { source, page, files } = tempCopy(file, { word }, line);

      writeTemp(files);

      try {
        await sleep(SETTLE_MS * 2);
        fs.writeFileSync(source, `\n\n\n${files[source]}`);
        await pageHas(page, `#L${line + 3})`);
      } finally {
        await removeTemp(files);
      }
    });
  }

  test("saving a page itself rewrites nothing", async () => {
    const source = path.join(fixture, "temp_page_save.py");
    const page = path.join(references, "temp_page_save.md");
    const files = {
      [source]: "print(alpha())\n\n\ndef alpha():\n    return 1\n",
      [page]: "### [alpha()](../../../temp_page_save.py#L1)\n\nTemporary.\n",
    };

    writeTemp(files);

    try {
      const document = await vscode.workspace.openTextDocument(page);
      const editor = await vscode.window.showTextDocument(document);

      await editor.edit((edit) => edit.insert(new vscode.Position(2, 0), "Edited. "));
      await document.save();
      await sleep(2000);
      assert.match(fs.readFileSync(page, "utf8"), /temp_page_save\.py#L1\)/);
    } finally {
      await removeTemp(files);
    }
  });
});

suite("the command updates every page that drifted without a save", () => {
  for (const [label, file, , word, line] of languages) {
    test(`${label}: ${word} goes from line 1 to ${line}`, async () => {
      const { page, files } = tempCopy(file, { word }, 1);
      const before = snapshotPages();

      writeTemp(files);

      try {
        await vscode.commands.executeCommand("whatDoesThisDo.updateLines");
        await pageHas(page, `#L${line})`);
      } finally {
        await removeTemp(files);
        restorePages(before);
      }
    });
  }
});

suite("what the extension refuses to read", () => {
  test("a symbolic link inside the references folder is not followed", async () => {
    const outside = fs.mkdtempSync(path.join(os.tmpdir(), "wdtd-outside-"));
    const link = path.join(references, "temp_link");
    const source = path.join(fixture, "temp_symlink.py");
    const files = {
      [source]: "print(symlinked_entry(1))\n",
      [path.join(outside, "elsewhere.md")]: "### [symlinked_entry()](elsewhere.py#L1)\n\nA page outside the workspace.\n",
    };

    writeTemp(files);
    fs.symlinkSync(outside, link, "junction");

    try {
      assert.deepEqual(await hoverAt({ file: "temp_symlink.py", needle: "symlinked_entry(1)", word: "symlinked_entry" }), []);
    } finally {
      fs.rmSync(link, { force: true });
      await removeTemp(files);
      fs.rmSync(outside, { recursive: true, force: true });
    }
  });

  test("a references folder that is itself a symbolic link is ignored", async () => {
    const outside = fs.mkdtempSync(path.join(os.tmpdir(), "wdtd-refs-"));
    const link = path.join(fixture, "temp_linked_refs");
    const source = path.join(fixture, "temp_linked_folder.py");
    const files = {
      [source]: "print(linked_folder_entry(1))\n",
      [path.join(outside, "elsewhere.md")]: "### [linked_folder_entry()](elsewhere.py#L1)\n\nA page behind a linked folder.\n",
    };
    const settings = vscode.workspace.getConfiguration("whatDoesThisDo");
    const hadSettingsFolder = fs.existsSync(path.join(fixture, ".vscode"));

    writeTemp(files);
    fs.symlinkSync(outside, link, "junction");
    await settings.update("folder", "temp_linked_refs", vscode.ConfigurationTarget.Workspace);

    try {
      assert.deepEqual(await hoverAt({ file: "temp_linked_folder.py", needle: "linked_folder_entry(1)", word: "linked_folder_entry" }), []);
    } finally {
      await settings.update("folder", undefined, vscode.ConfigurationTarget.Workspace);
      fs.rmSync(link, { force: true });
      await removeTemp(files);
      fs.rmSync(outside, { recursive: true, force: true });

      if (!hadSettingsFolder) {
        fs.rmSync(path.join(fixture, ".vscode"), { recursive: true, force: true });
      }
    }
  });

  test("a linked file above two megabytes is not searched, so the page line is used", async () => {
    const source = path.join(fixture, "temp_big.py");
    const page = path.join(references, "temp_big.md");
    const files = {
      [source]: `${"# filler\n".repeat(300000)}def big_entry():\n    return 1\n\n\nbig_entry(1)\n`,
      [page]: "### [big_entry()](../../../temp_big.py#L7)\n\nToo big to search; the page line stands.\n",
    };

    writeTemp(files);

    try {
      const [text] = await hoverAt({ file: "temp_big.py", needle: "big_entry(1)", word: "big_entry" });

      assert.equal(fragmentOf(text), 7, text);
    } finally {
      await removeTemp(files);
    }
  });
});

suite("the hover block", () => {
  test("shows the heading, then the page link, then the text", async () => {
    const [text] = await hoverAt({ file: "lines/python.py", needle: "gather(1)", word: "gather" });
    const lines = text.split("\n");

    assert.equal(fragmentOf(text), 4);
    assert.match(lines[0], /^### \[gather\(id\)\]\(file:/);
    assert.equal(lines[1], "");
    assert.match(lines[2], /^\[Open in python\.md\]\(file:.*python\.md#L3\)$/);
    assert.equal(lines[3], "");
    assert.equal(lines[4], "Python def; the page line is stale.");
  });
});
