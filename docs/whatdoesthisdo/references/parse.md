## `parse.js`

### [keysFor(name)](../../../parse.js#L7)

Lists the keys an entry is registered under. Most editors stop the word under the cursor before a `?` or `!`, so
hovering Ruby's `valid?` gives the word `valid`, and that key must exist too.

- In: `name`, the name written in a heading or a constant bullet.
- Out: the name itself. When it ends in `?` or `!`, the name without the mark as well.

### [linksInHeading(line)](../../../parse.js#L13)

Finds every `[name(params)](link)` in one heading line. A heading may hold several links, and each becomes its own
entry with the same text.

- In: `line`, a page line that starts with `### `.
- Out: a list of name and link pairs. The name is what stands before the parameter list, with backticks stripped,
  so `` [`$user`](...) `` and `[save(id)](...)` both work.

### [addEntries(entries, links, openedAt, lines)](../../../parse.js#L17)

Appends the entries of one heading or constant bullet to the list being built. Appends nothing when there are no
links, which is how text before the first heading, and text under a `## ` title, is dropped.

- In: `entries`, the list being built. `links`, the name and link pairs found in the heading. `openedAt`, the
  1-based page line of the heading or bullet. `lines`, the page lines of the entry, heading included.
- Out: nothing. One entry is appended per key of every link, all sharing the same text, the lines joined and
  trimmed, and the same page line.

### [parseReference(markdown)](../../../parse.js#L27)

Parses one page into entries.

- In: `markdown`, the full text of one page, read from disk or from an open editor document.
- Out: a list of entries in page order, each with a name, the link text, the page line it starts on and its text. A
  `### ` heading opens an entry that runs to the next `### `, `## ` or constant bullet. A `` - [`NAME`](link): text ``
  bullet is a one-line entry for a constant. The page line is where the heading or bullet sits; the hover's
  `Open in` link and the line rewrite both go there. The text is the heading line and everything under it, so the
  hover shows the heading with its link to click.

## Constants

- [`HEADING`](../../../parse.js#L1): matches a line starting with `### `, which opens an entry.
- [`SECTION`](../../../parse.js#L2): matches a line starting with `## `, which closes the open entry without opening one.
- [`LINK_IN_HEADING`](../../../parse.js#L3): matches one `[name(params)](link)` in a heading. The name is captured without backticks
  or the parameter list, so the key is what the editor gives as the word under the cursor.
- [`CONSTANT_BULLET`](../../../parse.js#L4): matches a `` - [`name`](link) `` bullet, the one-line form for a constant.
- [`TRAILING_MARK`](../../../parse.js#L5): matches the `?` or `!` suffix that a name is also registered without.
