const fs = require("node:fs");
const path = require("node:path");

const DEFAULT_FOLDER = "docs/whatdoesthisdo/references";
const SKILL_VERSION = /^<!-- whatdoesthisdo-skill-version: (\S+) -->/m;
const SKILL_FOLDER = /^The folder is `(.*)\/` in the repository root/m;
const BLOCK_FOLDER = /^`(.*)\/`, shown on hover by/m;
const BLOCK = /<!-- whatdoesthisdo:start -->[\s\S]*?<!-- whatdoesthisdo:end -->/;

function readIfExists(file) {
  try {
    return fs.readFileSync(file, "utf8");
  } catch {
    return null;
  }
}

function skillVersion(text) {
  const match = SKILL_VERSION.exec(text ?? "");

  return match ? match[1] : null;
}

function isOlder(installed, bundled) {
  if (!installed) {
    return true;
  }

  const a = installed.split(".").map(Number);
  const b = bundled.split(".").map(Number);

  for (let i = 0; i < Math.max(a.length, b.length); i += 1) {
    const difference = (b[i] ?? 0) - (a[i] ?? 0);

    if (difference !== 0) {
      return difference > 0;
    }
  }

  return false;
}

function installPaths(base, scope) {
  return {
    skill: path.join(base, ".claude", "skills", "whatdoesthisdo", "SKILL.md"),
    claudeMd: scope === "project" ? path.join(base, "CLAUDE.md") : path.join(base, ".claude", "CLAUDE.md"),
    cursorRule: scope === "project" ? path.join(base, ".cursor", "rules", "whatdoesthisdo.mdc") : null,
  };
}

function installedFolder(base, scope) {
  const { skill, claudeMd } = installPaths(base, scope);
  const fromSkill = SKILL_FOLDER.exec(readIfExists(skill) ?? "");
  const fromBlock = BLOCK_FOLDER.exec(readIfExists(claudeMd) ?? "");

  return fromSkill?.[1] ?? fromBlock?.[1] ?? DEFAULT_FOLDER;
}

function substitute(text, folder) {
  return text.split(DEFAULT_FOLDER).join(folder);
}

function installedSkillVersion(base, scope) {
  const text = readIfExists(installPaths(base, scope).skill);

  return text === null ? undefined : skillVersion(text);
}

function bundledSkillVersion(agentDir) {
  return skillVersion(readIfExists(path.join(agentDir, "skill", "SKILL.md")));
}

// Rewrites the skill, the rule block and the Cursor rule where they already exist; adds nothing. Returns what it wrote.
function updateInstall(base, scope, agentDir) {
  const { skill, claudeMd, cursorRule } = installPaths(base, scope);
  const folder = installedFolder(base, scope);
  const fresh = (file) => substitute(fs.readFileSync(path.join(agentDir, file), "utf8"), folder);
  const written = [];

  if (readIfExists(skill) !== null) {
    fs.writeFileSync(skill, fresh("skill/SKILL.md"));
    written.push(skill);
  }

  const claudeText = readIfExists(claudeMd);

  if (claudeText !== null && BLOCK.test(claudeText)) {
    fs.writeFileSync(claudeMd, claudeText.replace(BLOCK, () => fresh("rule-block.md").trimEnd()));
    written.push(claudeMd);
  }

  if (cursorRule && readIfExists(cursorRule) !== null) {
    fs.writeFileSync(cursorRule, fresh("cursor-rule.mdc"));
    written.push(cursorRule);
  }

  return written;
}

module.exports = { skillVersion, isOlder, installPaths, installedFolder, installedSkillVersion, bundledSkillVersion, updateInstall };
