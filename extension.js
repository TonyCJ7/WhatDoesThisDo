const fs = require("node:fs");
const path = require("node:path");
const vscode = require("vscode");

const { declarationLine } = require("./lines.js");
const { parseReference } = require("./parse.js");

const MARKDOWN_LINK = /\]\(([^)\s]+)\)/g;
const HAS_SCHEME = /^[a-z][a-z0-9+.-]*:/i;
const LINE_IN_LINK = /#L(\d+)$/;
const SIGNATURE = /\(.*$/;
const SETTLE_MS = 150;
const MAX_SEARCH_BYTES = 2 * 1024 * 1024;
const pagesByFolder = new Map();
const pendingChanges = new Map();
const syncedAt = new Map();
let settleTimer;
let queue = Promise.resolve();

function referencesDir(folder) {
  const configured = vscode.workspace.getConfiguration("whatDoesThisDo", folder.uri).get("folder");

  return path.join(folder.uri.fsPath, configured);
}

function fileOf(link) {
  return link.split("#")[0];
}

function linkFile(entry) {
  return path.resolve(entry.pageDir, fileOf(entry.link));
}

function entriesIn(markdown, page) {
  const pageDir = path.dirname(page);

  return parseReference(markdown).map((entry) => ({ ...entry, page, pageDir }));
}

function pageEntries(page) {
  return entriesIn(fs.readFileSync(page, "utf8"), page);
}

function indexPage(page) {
  const entries = pageEntries(page);

  return {
    names: new Set(entries.map((entry) => entry.name)),
    files: new Set(entries.map((entry) => linkFile(entry))),
  };
}

function markdownFilesIn(dir, prefix = "") {
  const files = [];

  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isSymbolicLink()) {
      continue;
    }

    const relative = path.join(prefix, entry.name);

    if (entry.isDirectory()) {
      files.push(...markdownFilesIn(path.join(dir, entry.name), relative));
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      files.push(relative);
    }
  }

  return files;
}

function isRealFolder(dir) {
  try {
    return fs.lstatSync(dir).isDirectory();
  } catch {
    return false;
  }
}

function refreshPages(dir) {
  if (!isRealFolder(dir)) {
    return new Map();
  }

  const known = pagesByFolder.get(dir) ?? new Map();
  const pages = new Map();
  const files = markdownFilesIn(dir).sort();

  for (const page of files) {
    const file = path.join(dir, page);
    const { mtimeMs, size } = fs.statSync(file);
    const cached = known.get(page);
    const unchanged = cached && cached.mtimeMs === mtimeMs && cached.size === size;

    pages.set(page, unchanged ? cached : { mtimeMs, size, ...indexPage(file) });
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

    entries.push(...pageEntries(path.join(dir, page)).filter((entry) => entry.name === word));
  }

  return entries;
}

function pagesLinking(pages, dir, file) {
  return [...pages].filter(([, { files }]) => files.has(file)).map(([page]) => path.join(dir, page));
}

async function definitionLocations(document, position) {
  const locations = await vscode.commands.executeCommand("vscode.executeDefinitionProvider", document.uri, position);

  return locations.map((location) => ({
    file: (location.targetUri ?? location.uri).fsPath,
    line: (location.targetSelectionRange ?? location.targetRange ?? location.range).start.line + 1,
  }));
}

function searchLine(file, name) {
  try {
    if (fs.statSync(file).size > MAX_SEARCH_BYTES) {
      return null;
    }

    return declarationLine(fs.readFileSync(file, "utf8"), name);
  } catch {
    return null;
  }
}

function lineInLink(link) {
  const match = LINE_IN_LINK.exec(link);

  return match ? Number(match[1]) : null;
}

function hoverLine(entry, definitions) {
  const file = linkFile(entry);
  const defined = definitions.find((definition) => definition.file === file);

  return defined?.line ?? searchLine(file, entry.name) ?? lineInLink(entry.link);
}

function fileLink(file, line) {
  return vscode.Uri.file(file).with({ fragment: line ? `L${line}` : "" }).toString();
}

function rankEntries(candidates, definitions, document) {
  if (candidates.length === 1) {
    return candidates;
  }

  const files = definitions.map((definition) => definition.file);
  const defined = candidates.filter((candidate) => files.includes(linkFile(candidate)));

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

function markdownFor(entry, definitions) {
  const declaration = fileLink(linkFile(entry), hoverLine(entry, definitions));
  const [heading, ...body] = entry.text.split("\n");
  const text = [
    heading.replace(`](${entry.link})`, `](${declaration})`),
    "",
    `[Open in ${path.basename(entry.page)}](${fileLink(entry.page, entry.line)})`,
    ...body,
  ].join("\n");

  return new vscode.MarkdownString(absoluteLinks(text, entry.pageDir));
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

  const definitions = await definitionLocations(document, position);
  const entries = rankEntries(candidates, definitions, document);

  return new vscode.Hover(entries.map((entry) => markdownFor(entry, definitions)), range);
}

async function symbolLines(file) {
  const lines = new Map();
  let symbols;

  try {
    symbols = (await vscode.commands.executeCommand("vscode.executeDocumentSymbolProvider", vscode.Uri.file(file))) ?? [];
  } catch {
    return lines;
  }

  const visit = (symbol) => {
    const range = symbol.selectionRange ?? symbol.location.range;
    const name = symbol.name.replace(SIGNATURE, "").trim();

    if (!lines.has(name)) {
      lines.set(name, range.start.line + 1);
    }

    (symbol.children ?? []).forEach(visit);
  };

  symbols.forEach(visit);

  return lines;
}

function relinkedLine(text, entries, lineFor) {
  return text.replace(MARKDOWN_LINK, (match, href) => {
    const line = entries.filter((entry) => entry.link === href).map(lineFor).find(Boolean);

    return line ? `](${fileOf(href)}#L${line})` : match;
  });
}

async function rewriteLines(page, file, lineFor) {
  const document = await vscode.workspace.openTextDocument(page);
  const entries = entriesIn(document.getText(), page).filter((entry) => linkFile(entry) === file);
  const edit = new vscode.WorkspaceEdit();
  let changed = 0;

  for (const line of new Set(entries.map((entry) => entry.line))) {
    const textLine = document.lineAt(line - 1);
    const updated = relinkedLine(textLine.text, entries.filter((entry) => entry.line === line), lineFor);

    if (updated !== textLine.text) {
      edit.replace(document.uri, textLine.range, updated);
      changed += 1;
    }
  }

  if (changed === 0) {
    return 0;
  }

  const wasDirty = document.isDirty;

  await vscode.workspace.applyEdit(edit);

  if (!wasDirty) {
    await document.save();
  }

  return changed;
}

async function updateLinesFor(dir, file, index = refreshPages(dir)) {
  const pages = pagesLinking(index, dir, file);

  if (pages.length === 0) {
    return 0;
  }

  const symbols = await symbolLines(file);
  const lineFor = (entry) => symbols.get(entry.name) ?? searchLine(file, entry.name);
  let changed = 0;

  for (const page of pages) {
    changed += await rewriteLines(page, file, lineFor);
  }

  return changed;
}

function updatesEnabled(folder) {
  return vscode.workspace.getConfiguration("whatDoesThisDo", folder.uri).get("updateLines");
}

function isPage(dir, file) {
  return file.startsWith(dir + path.sep);
}

function enqueue(task) {
  queue = queue.then(task).catch(() => {
    // A page that cannot be rewritten now is caught by the next change, the next focus or the command.
  });

  return queue;
}

async function flushChanges() {
  const changes = [...pendingChanges];

  pendingChanges.clear();

  for (const [dir, files] of changes) {
    const index = refreshPages(dir);

    for (const file of files) {
      await updateLinesFor(dir, file, index);
    }
  }
}

function onFileChanged(uri) {
  const folder = vscode.workspace.getWorkspaceFolder(uri);

  if (!folder || !updatesEnabled(folder)) {
    return;
  }

  const dir = referencesDir(folder);
  const file = uri.fsPath;

  if (isPage(dir, file)) {
    return;
  }

  if (!pendingChanges.has(dir)) {
    pendingChanges.set(dir, new Set());
  }

  pendingChanges.get(dir).add(file);
  clearTimeout(settleTimer);
  settleTimer = setTimeout(() => enqueue(flushChanges), SETTLE_MS);
}

function staleFiles(dir) {
  const stale = new Map();

  for (const { mtimeMs, files } of refreshPages(dir).values()) {
    for (const file of files) {
      let changedAt;

      try {
        changedAt = fs.statSync(file).mtimeMs;
      } catch {
        continue;
      }

      if (changedAt > mtimeMs && syncedAt.get(file) !== changedAt) {
        stale.set(file, changedAt);
      }
    }
  }

  return stale;
}

async function syncStalePages() {
  for (const folder of vscode.workspace.workspaceFolders ?? []) {
    if (!updatesEnabled(folder)) {
      continue;
    }

    const dir = referencesDir(folder);

    for (const [file, changedAt] of staleFiles(dir)) {
      syncedAt.set(file, changedAt);
      await updateLinesFor(dir, file);
    }
  }
}

async function updateAllLines() {
  let changed = 0;

  for (const folder of vscode.workspace.workspaceFolders ?? []) {
    const dir = referencesDir(folder);
    const index = refreshPages(dir);
    const files = new Set([...index.values()].flatMap(({ files }) => [...files]));

    for (const file of files) {
      if (fs.existsSync(file)) {
        changed += await updateLinesFor(dir, file, index);
      }
    }
  }

  vscode.window.showInformationMessage(`WhatDoesThisDo: updated ${changed} line number${changed === 1 ? "" : "s"}.`);
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
  const watcher = vscode.workspace.createFileSystemWatcher("**/*", true, false, true);

  context.subscriptions.push(
    vscode.languages.registerHoverProvider({ scheme: "file" }, { provideHover }),
    vscode.workspace.onDidSaveTextDocument((document) => onFileChanged(document.uri)),
    watcher,
    watcher.onDidChange(onFileChanged),
    vscode.window.onDidChangeWindowState((state) => state.focused && enqueue(syncStalePages)),
    vscode.commands.registerCommand("whatDoesThisDo.updateLines", () => enqueue(updateAllLines)),
  );
  warmIndex();
  enqueue(syncStalePages);
}

module.exports = { activate };
