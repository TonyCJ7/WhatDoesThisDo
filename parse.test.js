const { test } = require("node:test");
const assert = require("node:assert/strict");

const { parseReference } = require("./parse.js");

const sample = `# Part 1 reference

Intro line that is not an entry.

## \`src/config.ts\`

### [loadConfig(env)](../../../src/config.ts#L37)

Turns the raw environment into the typed object.

- In: an env object.
- Out: a Config.

### [readPositiveNumber(env, name, fallback)](../../../src/config.ts#L5)

Reads one env variable as a number that must be above zero.

### [notAFigmaLink(input)](../../../src/figma/urls.ts#L31), [notANodeId(id)](../../../src/figma/urls.ts#L8)

Build the two error objects.

### [valid?(x)](../../../lib/user.rb#L3)

Ruby predicate.

### [my-func](../../../styles/tokens.clj#L1), [save!(record)](../../../lib/record.rb#L9)

Names outside the C family.

## Constants

- [\`FILE_KEY\`](../../../src/figma/urls.ts#L4): alphanumeric, 10 to 64 characters.
- [\`NODE_ID\`](../../../src/figma/urls.ts#L5): \`12:34\`, or \`I\` plus ids.
- [\`--brand\`](../../../styles/tokens.css#L2): css custom property.
`;

function entriesNamed(name) {
  return parseReference(sample).filter((entry) => entry.name === name);
}

test("maps a function heading to its heading line and body", () => {
  assert.equal(
    entriesNamed("readPositiveNumber")[0].text,
    "### [readPositiveNumber(env, name, fallback)](../../../src/config.ts#L5)\n\nReads one env variable as a number that must be above zero.",
  );
});

test("keeps the bullet list in the body and stops at the next heading", () => {
  assert.equal(
    entriesNamed("loadConfig")[0].text,
    "### [loadConfig(env)](../../../src/config.ts#L37)\n\nTurns the raw environment into the typed object.\n\n- In: an env object.\n- Out: a Config.",
  );
});

test("registers every name in a heading that lists two functions", () => {
  assert.equal(entriesNamed("notAFigmaLink")[0].text, entriesNamed("notANodeId")[0].text);
  assert.match(entriesNamed("notANodeId")[0].text, /Build the two error objects/);
});

test("keeps each name's own link target", () => {
  assert.equal(entriesNamed("notAFigmaLink")[0].link, "../../../src/figma/urls.ts#L31");
  assert.equal(entriesNamed("notANodeId")[0].link, "../../../src/figma/urls.ts#L8");
});

test("registers a constant from a bullet with a backticked link", () => {
  assert.deepEqual(entriesNamed("FILE_KEY"), [
    {
      name: "FILE_KEY",
      link: "../../../src/figma/urls.ts#L4",
      text: "- [`FILE_KEY`](../../../src/figma/urls.ts#L4): alphanumeric, 10 to 64 characters.",
    },
  ]);
});

test("knows nothing about words that have no entry", () => {
  assert.equal(entriesNamed("Intro").length, 0);
  assert.equal(entriesNamed("src").length, 0);
});

test("keeps a name's trailing question or bang mark and also registers it without", () => {
  assert.match(entriesNamed("valid?")[0].text, /Ruby predicate/);
  assert.match(entriesNamed("valid")[0].text, /Ruby predicate/);
  assert.match(entriesNamed("save!")[0].text, /outside the C family/);
  assert.equal(entriesNamed("save")[0].link, "../../../lib/record.rb#L9");
});

test("keeps a kebab-case name whole and does not register its first word", () => {
  assert.equal(entriesNamed("my-func")[0].link, "../../../styles/tokens.clj#L1");
  assert.equal(entriesNamed("my").length, 0);
});

test("registers a constant whose name starts with punctuation", () => {
  assert.equal(entriesNamed("--brand")[0].link, "../../../styles/tokens.css#L2");
});
