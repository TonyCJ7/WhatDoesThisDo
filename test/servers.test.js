const { hoverAt, expectEntry } = require("./helpers.js");

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
});
