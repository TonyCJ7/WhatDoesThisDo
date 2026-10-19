const fs = require("node:fs");
const path = require("node:path");
const vscode = require("vscode");

const { parseReference } = require("./parse.js");

const MARKDOWN_LINK = /\]\(([^)\s]+)\)/g;
const HAS_SCHEME = /^[a-z][a-z0-9+.-]*:/i;
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
    if (!names.has(word)) {
      continue;
    }

    const pageDir = path.join(dir, path.dirname(page));

    for (const entry of parseReference(fs.readFileSync(path.join(dir, page), "utf8"))) {
      if (entry.name === word) {
        entries.push({ ...entry, pageDir });
      }
    }
  }

  return entries;
}

async function definitionFiles(document, position) {
  const locations = await vscode.commands.executeCommand("vscode.executeDefinitionProvider", document.uri, position);

  return locations.map((location) => (location.targetUri ?? location.uri).fsPath);
}

function linkFile(entry) {
  return path.resolve(entry.pageDir, entry.link.split("#")[0]);
}

async function rankEntries(candidates, document, position) {
  if (candidates.length === 1) {
    return candidates;
  }

  const definitions = await definitionFiles(document, position);
  const defined = candidates.filter((candidate) => definitions.includes(linkFile(candidate)));

  if (defined.length > 0) {
    return defined;
  }

  const extension = path.extname(document.fileName);
  const sameExtension = candidates.filter((candidate) => path.extname(linkFile(candidate)) === extension);
  const others = candidates.filter((candidate) => !sameExtension.includes(candidate));

  return [...sameExtension, ...others];
}

function absoluteLinks(text, pageDir) {
  return text.replace(MARKDOWN_LINK, (match, href) => {
    if (HAS_SCHEME.test(href)) {
      return match;
    }

    const [file, fragment = ""] = href.split("#");
    const uri = vscode.Uri.file(path.resolve(pageDir, file)).with({ fragment });

    return `](${uri.toString()})`;
  });
}

function markdownFor(entry) {
  return new vscode.MarkdownString(absoluteLinks(entry.text, entry.pageDir));
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

  const entries = await rankEntries(candidates, document, position);

  return new vscode.Hover(entries.map((entry) => markdownFor(entry)), range);
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
