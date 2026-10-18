const fs = require("node:fs");
const path = require("node:path");
const vscode = require("vscode");

const { parseReference } = require("./parse.js");

const pagesByFolder = new Map();

function referencesDir(folder) {
  const configured = vscode.workspace.getConfiguration("whatDoesThisDo", folder.uri).get("folder");

  return path.join(folder.uri.fsPath, configured);
}

function namesIn(file) {
  return new Set(parseReference(fs.readFileSync(file, "utf8")).map((entry) => entry.name));
}

function refreshPages(dir) {
  if (!fs.existsSync(dir)) {
    return new Map();
  }

  const known = pagesByFolder.get(dir) ?? new Map();
  const pages = new Map();
  const files = fs.readdirSync(dir, { recursive: true }).filter((name) => name.endsWith(".md")).sort();

  for (const page of files) {
    const file = path.join(dir, page);
    const { mtimeMs, size } = fs.statSync(file);
    const cached = known.get(page);
    const unchanged = cached && cached.mtimeMs === mtimeMs && cached.size === size;

    pages.set(page, unchanged ? cached : { mtimeMs, size, names: namesIn(file) });
  }

  pagesByFolder.set(dir, pages);

  return pages;
}

function entriesNamed(dir, word) {
  const entries = [];

  for (const [page, { names }] of refreshPages(dir)) {
    if (names.has(word)) {
      entries.push(...parseReference(fs.readFileSync(path.join(dir, page), "utf8")).filter((entry) => entry.name === word));
    }
  }

  return entries;
}

async function definitionFiles(document, position) {
  const locations = await vscode.commands.executeCommand("vscode.executeDefinitionProvider", document.uri, position);

  return locations.map((location) => (location.targetUri ?? location.uri).fsPath);
}

function linkFile(dir, link) {
  return path.resolve(dir, link.split("#")[0]);
}

async function rankEntries(dir, candidates, document, position) {
  if (candidates.length === 1) {
    return candidates;
  }

  const definitions = await definitionFiles(document, position);
  const defined = candidates.filter((candidate) => definitions.includes(linkFile(dir, candidate.link)));

  if (defined.length > 0) {
    return defined;
  }

  const extension = path.extname(document.fileName);
  const sameExtension = candidates.filter((candidate) => path.extname(candidate.link.split("#")[0]) === extension);
  const others = candidates.filter((candidate) => !sameExtension.includes(candidate));

  return [...sameExtension, ...others];
}

function markdownFor(dir, entry) {
  const markdown = new vscode.MarkdownString(entry.text);

  markdown.baseUri = vscode.Uri.file(path.join(dir, path.sep));

  return markdown;
}

async function provideHover(document, position) {
  const folder = vscode.workspace.getWorkspaceFolder(document.uri);
  const range = document.getWordRangeAtPosition(position);

  if (!folder || !range) {
    return null;
  }

  const dir = referencesDir(folder);
  const candidates = entriesNamed(dir, document.getText(range));

  if (candidates.length === 0) {
    return null;
  }

  const entries = await rankEntries(dir, candidates, document, position);

  return new vscode.Hover(entries.map((entry) => markdownFor(dir, entry)), range);
}

function warmIndex() {
  for (const folder of vscode.workspace.workspaceFolders ?? []) {
    try {
      refreshPages(referencesDir(folder));
    } catch {
      // An unreadable folder must not stop activation; the first hover retries.
    }
  }
}

function activate(context) {
  context.subscriptions.push(vscode.languages.registerHoverProvider({ scheme: "file" }, { provideHover }));
  warmIndex();
}

module.exports = { activate };
