## `parse.js`

### [keysFor(name)](../../../parse.js#L7)

The keys an entry is registered under: the name itself and, when it ends in `?` or `!`, the name without the mark.
Most editors' word patterns stop before those marks, so hovering Ruby's `valid?` gives the word `valid`, and the
page key has to match that.

### [linksInHeading(line)](../../../parse.js#L13)

Every `[name(params)](link)` on a `### ` line, as `{ name, link }`. The name is what stands before the parameter
list, backticks stripped, so `` [`$user`](...) `` and `[save(id)](...)` both work. A heading may hold several links;
each becomes its own entry with the same text.

### [addEntries(entries, links, openedAt, lines)](../../../parse.js#L17)

Appends one entry per key of every link, all sharing the joined and trimmed `lines` and `openedAt`, the 1-based
page line of the heading or bullet that opened them. Appends nothing when there are no links, which is how text
before the first heading and text under a `## ` title are dropped.

### [parseReference(markdown)](../../../parse.js#L27)

A page's entries as `[{ name, link, line, text }]`, in page order.

- A `### ` heading opens an entry that runs to the next `### `, `## ` or constant bullet.
- A `` - [`NAME`](link): text `` bullet is a one-line entry for a constant.
- `line` is where the heading or bullet sits on the page. The hover's `Open in` link and the save listener's
  rewrite both go to that line.
- The text is the heading line and everything under it. That is what the hover shows, heading included, so the link
  is there to click.

## Constants

- [`HEADING`](../../../parse.js#L1): a line starting with `### ` opens an entry.
- [`SECTION`](../../../parse.js#L2): a line starting with `## ` closes the open entry without opening one.
- [`LINK_IN_HEADING`](../../../parse.js#L3): one `[name(params)](link)` in a heading. The name is captured without
  backticks or the parameter list, so the key is what the editor gives as the word under the cursor.
- [`CONSTANT_BULLET`](../../../parse.js#L4): a `` - [`name`](link) `` bullet, the one-line form for a constant.
- [`TRAILING_MARK`](../../../parse.js#L5): the `?` or `!` suffix that `keysFor` also registers the name without.
