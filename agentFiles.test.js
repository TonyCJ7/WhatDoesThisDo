const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { test } = require("node:test");
const { skillVersion, isOlder, installedFolder, installedSkillVersion, bundledSkillVersion, updateInstall } = require("./agentFiles.js");

const AGENT_DIR = path.join(__dirname, "agent");
const read = (file) => fs.readFileSync(file, "utf8");

function install(base, scope, { folder = "docs/whatdoesthisdo/references", agent = "both" } = {}) {
  const sub = (file) => read(path.join(AGENT_DIR, file)).split("docs/whatdoesthisdo/references").join(folder);
  const skill = path.join(base, ".claude/skills/whatdoesthisdo/SKILL.md");

  fs.mkdirSync(path.dirname(skill), { recursive: true });
  fs.writeFileSync(skill, sub("skill/SKILL.md"));

  if (agent !== "cursor") {
    const claudeMd = scope === "project" ? path.join(base, "CLAUDE.md") : path.join(base, ".claude/CLAUDE.md");
    fs.writeFileSync(claudeMd, `# My rules\n\n${sub("rule-block.md")}\nTail rule.\n`);
  }

  if (agent !== "claude" && scope === "project") {
    const rule = path.join(base, ".cursor/rules/whatdoesthisdo.mdc");
    fs.mkdirSync(path.dirname(rule), { recursive: true });
    fs.writeFileSync(rule, sub("cursor-rule.mdc"));
  }

  return skill;
}

const temp = () => fs.mkdtempSync(path.join(os.tmpdir(), "wdtd-agent-"));

test("the bundled skill carries a version and reads it back", () => {
  const version = bundledSkillVersion(AGENT_DIR);

  assert.match(version, /^\d+\.\d+\.\d+$/);
  assert.equal(skillVersion("<!-- whatdoesthisdo-skill-version: 1.2.3 -->\n# x"), "1.2.3");
  assert.equal(skillVersion("# no version"), null);
});

test("older compares dotted numbers and treats a missing version as older", () => {
  assert.equal(isOlder("0.1.2", "0.1.3"), true);
  assert.equal(isOlder("0.1.3", "0.1.3"), false);
  assert.equal(isOlder("0.2.0", "0.1.9"), false);
  assert.equal(isOlder("0.1", "0.1.1"), true);
  assert.equal(isOlder(null, "0.1.3"), true);
});

test("an installed skill reports its version and an absent one reports undefined", () => {
  const base = temp();

  assert.equal(installedSkillVersion(base, "project"), undefined);
  const skill = install(base, "project");
  assert.equal(installedSkillVersion(base, "project"), bundledSkillVersion(AGENT_DIR));
  fs.writeFileSync(skill, read(skill).replace(/skill-version: \S+/, "skill-version: 0.0.1"));
  assert.equal(installedSkillVersion(base, "project"), "0.0.1");
});

test("update rewrites an old project install in place and keeps the folder and the rest of CLAUDE.md", () => {
  const base = temp();
  const skill = install(base, "project", { folder: "docs/refs" });

  fs.appendFileSync(skill, "\nold line\n");
  const claudeMd = path.join(base, "CLAUDE.md");
  fs.writeFileSync(claudeMd, read(claudeMd).replace("read its entry", "read its old entry"));

  const written = updateInstall(base, "project", AGENT_DIR);

  assert.deepEqual(written, [skill, claudeMd, path.join(base, ".cursor/rules/whatdoesthisdo.mdc")]);
  assert.equal(read(skill), read(path.join(AGENT_DIR, "skill/SKILL.md")).split("docs/whatdoesthisdo/references").join("docs/refs"));
  const claude = read(claudeMd);
  assert.ok(claude.startsWith("# My rules"));
  assert.ok(claude.endsWith("Tail rule.\n"));
  assert.ok(!claude.includes("old entry"));
  assert.ok(claude.includes("docs/refs/"));
  assert.equal(claude.match(/whatdoesthisdo:start/g).length, 1);
  assert.equal(installedFolder(base, "project"), "docs/refs");
});

test("update of a global install touches ~/.claude/CLAUDE.md and no cursor file", () => {
  const base = temp();

  install(base, "global");
  const written = updateInstall(base, "global", AGENT_DIR);

  assert.deepEqual(written, [path.join(base, ".claude/skills/whatdoesthisdo/SKILL.md"), path.join(base, ".claude/CLAUDE.md")]);
  assert.ok(!fs.existsSync(path.join(base, ".cursor")));
});

test("update of a cursor-only install creates no CLAUDE.md, and nothing installed writes nothing", () => {
  const base = temp();

  install(base, "project", { agent: "cursor" });
  assert.deepEqual(updateInstall(base, "project", AGENT_DIR), [
    path.join(base, ".claude/skills/whatdoesthisdo/SKILL.md"),
    path.join(base, ".cursor/rules/whatdoesthisdo.mdc"),
  ]);
  assert.ok(!fs.existsSync(path.join(base, "CLAUDE.md")));
  assert.deepEqual(updateInstall(temp(), "project", AGENT_DIR), []);
});
