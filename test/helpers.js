const assert = require("node:assert/strict");
const path = require("node:path");
const vscode = require("vscode");

const fixture = vscode.workspace.workspaceFolders[0].uri.fsPath;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function open(file) {
  const document = await vscode.workspace.openTextDocument(path.join(fixture, file));

  await vscode.window.showTextDocument(document);

  return document;
}

function positionOf(document, needle, offset) {
  const index = document.getText().indexOf(needle);

  assert.notEqual(index, -1, `${needle} not found in ${document.fileName}`);

  return document.positionAt(index + offset);
}

function wordAt(document, position) {
  const range = document.getWordRangeAtPosition(position);

  return range ? document.getText(range) : null;
}

async function waitForWord(document, position, word) {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    if (wordAt(document, position) === word) {
      return;
    }

    await sleep(250);
  }

  assert.equal(wordAt(document, position), word, "the editor's word pattern never produced the expected word");
}

async function definitionFiles(document, position) {
  const locations = await vscode.commands.executeCommand("vscode.executeDefinitionProvider", document.uri, position);

  return locations.map((location) => (location.targetUri ?? location.uri).fsPath).sort().join("\n");
}

async function waitForStableDefinitionAcrossFiles(document, position) {
  let previous = "";
  let stableRounds = 0;

  for (let attempt = 0; attempt < 120; attempt += 1) {
    const files = await definitionFiles(document, position);
    const crossFile = files.split("\n").some((file) => file && file !== document.uri.fsPath);

    stableRounds = crossFile && files === previous ? stableRounds + 1 : 0;
    previous = files;

    if (stableRounds >= 3) {
      return;
    }

    await sleep(500);
  }

  throw new Error(`the language server never settled on a definition for the symbol in ${document.fileName}`);
}

async function ourHovers(document, position) {
  const hovers = await vscode.commands.executeCommand("vscode.executeHoverProvider", document.uri, position);

  return hovers.flatMap((hover) => hover.contents.map((content) => content.value)).filter((value) => /^(### |- \[)/.test(value));
}

async function hoverAt({ file, needle, offset = 1, word, resolves = false }) {
  const document = await open(file);
  const position = positionOf(document, needle, offset);

  await waitForWord(document, position, word);

  if (resolves) {
    await waitForStableDefinitionAcrossFiles(document, position);
  }

  return ourHovers(document, position);
}

function expectEntry(texts, shown, hidden) {
  const joined = texts.join("\n---\n");

  assert.ok(texts.some((text) => text.includes(shown)), `expected "${shown}" in:\n${joined}`);

  if (hidden) {
    assert.ok(!texts.some((text) => text.includes(hidden)), `did not expect "${hidden}" in:\n${joined}`);
  }
}

module.exports = { fixture, hoverAt, expectEntry };
