const HEADING = /^### /;
const SECTION = /^## /;
const LINK_IN_HEADING = /\[`?([^`\]()]+?)\s*`?(?:\([^)]*\))?\]\(([^)]+)\)/g;
const CONSTANT_BULLET = /^- \[`([^`]+)`\]\(([^)]+)\)/;
const TRAILING_MARK = /[?!]+$/;

function keysFor(name) {
  const bare = name.replace(TRAILING_MARK, "");

  return bare === name ? [name] : [name, bare];
}

function linksInHeading(line) {
  return Array.from(line.matchAll(LINK_IN_HEADING), (match) => ({ name: match[1].trim(), link: match[2] }));
}

function addEntries(entries, links, lines) {
  const text = lines.join("\n").trim();

  for (const { name, link } of links) {
    for (const key of keysFor(name)) {
      entries.push({ name: key, link, text });
    }
  }
}

function parseReference(markdown) {
  const entries = [];
  let links = [];
  let lines = [];

  for (const line of markdown.split("\n")) {
    const constant = CONSTANT_BULLET.exec(line);

    if (HEADING.test(line) || SECTION.test(line) || constant) {
      addEntries(entries, links, lines);
      links = [];
      lines = [];
    }

    if (HEADING.test(line)) {
      links = linksInHeading(line);
    }

    if (constant) {
      links = [{ name: constant[1], link: constant[2] }];
    }

    if (links.length > 0) {
      lines.push(line);
    }
  }

  addEntries(entries, links, lines);

  return entries;
}

module.exports = { parseReference };
