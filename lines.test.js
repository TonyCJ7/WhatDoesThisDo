const { test } = require("node:test");
const assert = require("node:assert/strict");

const { declarationLine } = require("./lines.js");

const cases = [
  ["javascript function after a call", "save(1);\nexport async function save(id) {}\n", "save", 2],
  ["javascript const", "run(total);\nconst total = 3;\n", "total", 2],
  ["javascript method in a class, called through this first", "this.save(1);\n  save(id) {\n", "save", 2],
  ["typescript interface", "const c: Config = {};\nexport interface Config {}\n", "Config", 2],
  ["typescript generic function", "load<User>(1);\nfunction load<T>(id: number) {}\n", "load", 2],
  ["python def after a call", "fetch_user(1)\n\ndef fetch_user(id):\n", "fetch_user", 3],
  ["python async def", "await fetch(1)\nasync def fetch(id):\n", "fetch", 2],
  ["python constant with a type", "print(RETRIES)\nRETRIES: int = 3\n", "RETRIES", 2],
  ["ruby predicate, key without the mark", "valid?(1)\ndef valid?(x)\n", "valid", 2],
  ["ruby class method", "User.find(1)\n  def self.find(id)\n", "find", 2],
  ["go function", "Save(1)\nfunc Save(id int) {}\n", "Save", 2],
  ["go method with a receiver", "s.Save(1)\nfunc (s *Store) Save(id int) {}\n", "Save", 2],
  ["rust pub fn", "total(1);\npub fn total(n: u32) -> u32 {}\n", "total", 2],
  ["rust struct", "let c = Config {};\npub struct Config {}\n", "Config", 2],
  ["java method with modifiers and a type", "save(1);\n  public static void save(int id) {}\n", "save", 2],
  ["java method called before it, with a return", "return save(1);\n  private User save(int id) {}\n", "save", 2],
  ["c function with a pointer return type", "save(1);\nchar *save(int id) {\n", "save", 2],
  ["c function with a plain return type", "save(1);\nint save(int id) {\n", "save", 2],
  ["c# method", "Save(1);\n  public async Task<User> Save(int id)\n", "Save", 2],
  ["kotlin fun", "save(1)\nfun save(id: Int) {}\n", "save", 2],
  ["swift func", "save(1)\nfunc save(id: Int) {}\n", "save", 2],
  ["php function and a dollar variable", "save(1);\nfunction save($id) {}\n$user = 1;\n", "save", 2],
  ["php dollar variable", "echo $user;\n$user = 1;\n", "$user", 2],
  ["shell variable", 'echo "$CONFIG_DIR"\nCONFIG_DIR=/etc\n', "CONFIG_DIR", 2],
  ["yaml key", "# retry_count is read at start\nretry_count: 3\n", "retry_count", 2],
  ["css custom property", "color: var(--brand);\n  --brand: #123;\n", "--brand", 2],
  ["clojure defn with a kebab name", "(my-func 1)\n(defn my-func [x] x)\n", "my-func", 2],
  ["elixir def", "fetch(1)\n  def fetch(id) do\n", "fetch", 2],
  ["elixir module", "Users.fetch(1)\ndefmodule Users do\n", "Users", 2],
  ["sql function", "SELECT total(1);\nCREATE FUNCTION total(n int)\n", "total", 2],
  ["lua local function", "save(1)\nlocal function save(id) end\n", "save", 2],
  ["haskell signature", "x = save 1\nsave :: Int -> Int\n", "save", 2],
  ["c preprocessor define", "return LIMIT;\n#define LIMIT 3\n", "LIMIT", 2],
  ["lua function on a table", "Config.save(1)\nfunction Config.save(id) end\n", "save", 2],
  ["lua table whose function is declared later", "local Config = {}\nfunction Config.save(id) end\n", "Config", 1],
  ["sql view", "SELECT * FROM limits;\nCREATE VIEW limits AS SELECT 3;\n", "limits", 2],
  ["haskell data type", "size (Config 3)\ndata Config = Config Int\n", "Config", 2],
  ["clojure defrecord", "(->Config 1)\n(defrecord Config [n])\n", "Config", 2],
  ["a name declared twice: the first declaration", "save(1)\nfunction save(a) {}\nfunction save(a, b) {}\n", "save", 2],
  ["name only used, never declared: first use", "run(save)\ncall(save)\n", "save", 1],
  ["name inside a longer word is not a match", "save_all()\nsaves = 1\n", "save", null],
  ["name absent", "nothing here\n", "save", null],
];

for (const [label, text, name, line] of cases) {
  test(label, () => {
    assert.equal(declarationLine(text, name), line);
  });
}
