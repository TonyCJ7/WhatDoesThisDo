## `extension.js`

### [referencesDir(folder)](../../../extension.js#L19)

Where the pages live for one workspace folder: the `whatDoesThisDo.folder` setting joined onto the folder's path.
The setting is read with that folder's own configuration, so each root of a multi-root workspace can point
somewhere else. Default `docs/whatdoesthisdo/references`.

### [fileOf(link)](../../../extension.js#L25)

The part of a page link before `#`, which is the file it points at.

### [linkFile(entry)](../../../extension.js#L29)

The absolute path of the source file an entry's link points at, resolved from the page's folder. This is the path
the definition match compares against and the key the save listener looks pages up by.

### [entriesIn(markdown, page)](../../../extension.js#L33)

The entries of one page's text, each tagged with `page`, the page's absolute path, and `pageDir`, its folder, because
the links on a page are relative to the page. Takes the text rather than reading the file so the save listener can
parse an editor buffer that has unsaved changes.

### [pageEntries(page)](../../../extension.js#L39)

`entriesIn` for the page as it is on disk.

### [indexPage(page)](../../../extension.js#L43)

What the index keeps per page: the set of entry names and the set of source files the entries link to. The text is
thrown away, which is why 500 pages with 50,000 entries stay under 6 MB in memory.

### [refreshPages(dir)](../../../extension.js#L52)

The index for one references folder: a map from page path to `{ mtimeMs, size, names, files }`.

- Walks the folder and its subfolders, keeps the cached sets for every page whose modification time and size are
  unchanged, and parses only the rest.
- Runs before every hover, after every change that reaches `onFileChanged`, and in `staleFiles`. For an unchanged page that is one `stat`, which is how an edit shows
  up on the next hover without a file watcher.
- Out: an empty map when the folder does not exist, so a project without pages hovers nothing.

### [entriesNamed(dir, word)](../../../extension.js#L75)

Every entry called `word`, read from the pages whose index says they hold that name, usually one.

### [pagesLinking(pages, dir, file)](../../../extension.js#L89)

The absolute paths of the pages in the index `pages` with at least one entry linking to `file`. This is how a
changed source file finds its pages, so a page does not have to sit at the mirrored path to be kept current. Takes
the index as an argument so a burst of changes refreshes it once.

### [definitionLocations(document, position)](../../../extension.js#L93)

Where the language server says the symbol at `position` is declared, as `{ file, line }` with the line 1-based.
Every location, not only the first: a TypeScript interface merged across two files reports both, and the entry may
point at the second. Empty when no server answers, which is the case for Python or Rust without their extensions
installed.

### [searchLine(file, name)](../../../extension.js#L102)

`declarationLine` from `lines.js` over the contents of `file`, or null when the file cannot be read.

### [lineInLink(link)](../../../extension.js#L110)

The number after `#L` at the end of a page link, or null when the link has none.

### [hoverLine(entry, definitions)](../../../extension.js#L116)

The line the hover's heading should open: the language server's line when one of its `definitions` is in the
entry's file, otherwise `searchLine`, otherwise whatever the page wrote. A stale line on the page therefore never
reaches the hover.

### [fileLink(file, line)](../../../extension.js#L123)

An absolute `file:` URI string for `file` with `L<line>` as its fragment, or no fragment when the line is null.

### [rankEntries(candidates, definitions, document)](../../../extension.js#L127)

Which entries to show when several share a name, and in which order.

- One candidate is returned as it is.
- Otherwise the entries whose link file is one of the definition files win, and only those are shown.
- When none match, which is the case without a server or when a page links to the wrong file, every candidate is
  shown, the ones whose link file has the hovered document's extension first. A Python `save` sees the Python page
  before the TypeScript one.

### [absoluteLinks(text, pageDir)](../../../extension.js#L146)

The entry text with every relative markdown link turned into an absolute `file:` link, resolved against the page's
folder, with the `#L` part kept as the URI fragment. Links that already have a scheme are left alone.

- Why: the editor joins a relative link's text onto the base path, fragment included, so `../x.js#L72` opened an
  empty editor called `x.js#L72`. With a real fragment the click opens `x.js` at line 72.

### [markdownFor(entry, definitions)](../../../extension.js#L159)

The hover block for one entry as a MarkdownString: the heading with its link pointed at `hoverLine`, then a
line `Open in <page>.md` linking to the page at the entry's own heading line, then the rest of the entry text, all
links made absolute. Nothing else is set on the string, so an entry cannot run commands.

### [provideHover(document, position)](../../../extension.js#L172)

The hover provider. Asks the language server once, ranks the candidates with its answer, and returns one Hover with
one markdown block per entry, which the editor shows under its own tooltip.

- Null, which leaves the editor's tooltip untouched, when the document is outside a workspace folder, when there is
  no word at the position by the language's own word pattern, or when no page names the word.

### [symbolLines(file)](../../../extension.js#L193)

A map from symbol name to 1-based line for every symbol the language server reports in `file`, nested ones
included, first occurrence winning. A signature the server puts in the name, as Java's `save(int)`, is cut off so
the entry name matches. Empty when no server answers or the provider throws, so the text search still runs.

### [relinkedLine(text, entries, lineFor)](../../../extension.js#L219)

One page line with each entry link's `#L` number replaced by what `lineFor` returns for that link's entries. A link
whose entries all resolve to nothing is left as it is, so a wrong guess never overwrites a correct line.

### [rewriteLines(page, file, lineFor)](../../../extension.js#L227)

Rewrites the links to `file` on one page and returns how many lines changed. Works on the editor's document, so an
open page updates in its buffer; the page is saved afterwards only when it had no unsaved changes before.

### [updateLinesFor(dir, file, index)](../../../extension.js#L258)

Updates every page in `dir` that links to `file`: the language server's symbols first, `searchLine` for the names it
does not know. Returns the number of changed lines. `index` is the refreshed page index; a caller handling many
files passes one it refreshed itself, a single call lets the default refresh it.

### [updatesEnabled(folder)](../../../extension.js#L276)

The `whatDoesThisDo.updateLines` setting for one workspace folder, which turns every automatic rewrite off at once.

### [isPage(dir, file)](../../../extension.js#L280)

Whether `file` lies inside the references folder `dir`. A page is never a source file to rewrite for, which is also
what stops the page save the rewrite causes from looping.

### [enqueue(task)](../../../extension.js#L284)

Runs `task` after every rewrite already queued, so a burst of changes, a focus sync and the command never rewrite
the same page at the same time. A task that throws is dropped; the next change, focus or command catches up.

### [flushChanges()](../../../extension.js#L292)

Handles every file collected since the last flush: one index refresh per references folder, then `updateLinesFor`
on each file in turn.

### [onFileChanged(uri)](../../../extension.js#L306)

What a save in the editor and a change on disk both call. Adds the file to the set for its references folder and
restarts the `SETTLE_MS` timer, so a save that the watcher also reports, or a checkout that touches a thousand
files, ends in one queued `flushChanges`. Nothing happens for a file outside a workspace folder, for a page, or when
the setting is off.

### [staleFiles(dir)](../../../extension.js#L329)

The source files linked from pages in `dir` that changed after the page that links to them, as a map from file to
its modification time. A file whose time was already handled by `syncStalePages` is left out, so a page that needed
no rewrite is not checked again on every focus. A file that is gone is skipped and its entries stay as they are.

### [syncStalePages()](../../../extension.js#L351)

`updateLinesFor` on every stale file of every workspace folder. Queued at activation and each time the window
regains focus, which is how a `git pull`, a branch switch or an agent's edit from a terminal reaches the pages
without a save.

### [updateAllLines()](../../../extension.js#L366)

The command `WhatDoesThisDo: Update line numbers`: `updateLinesFor` on every source file any page links to, in every
workspace folder, then a message with the count. For a project whose pages drifted before the extension was
installed.

### [warmIndex()](../../../extension.js#L384)

Builds the index for every workspace folder at activation, so the first hover does not pay the few hundred
milliseconds a cold index costs on a large project. A folder that cannot be read is skipped and the first hover
retries it; activation never fails because of it.

### [activate(context)](../../../extension.js#L394)

Registers the hover provider for every `file:` document in any language, the save listener, a watcher for changes
on disk, the focus listener and the update command, then warms the index and syncs the pages that went stale while
the editor was closed. The watcher subscribes to the editor's own file watching with the glob `**/*`, change events
only, so it starts no process of its own. Runs on `onStartupFinished`, after the window is up, so it never slows the editor's start.

## Constants

- [`MARKDOWN_LINK`](../../../extension.js#L8): the `](href)` tail of a markdown link, href captured, no spaces
  allowed inside.
- [`HAS_SCHEME`](../../../extension.js#L9): an href that starts with a URI scheme such as `https:` or `file:`, which
  `absoluteLinks` leaves as it is.
- [`LINE_IN_LINK`](../../../extension.js#L10): the `#L<number>` at the end of a page link.
- [`SIGNATURE`](../../../extension.js#L11): the `(` and everything after it in a symbol name, which some language
  servers append to a method's name.
- [`SETTLE_MS`](../../../extension.js#L12): how long `onFileChanged` waits after the last event before flushing,
  long enough for a save and the watcher's report of it to collapse into one run.
- [`pagesByFolder`](../../../extension.js#L13): the index cache, references folder path to the map `refreshPages`
  builds. One entry per workspace folder; it lives as long as the window.
- [`pendingChanges`](../../../extension.js#L14): the files changed since the last flush, grouped by references folder.
- [`syncedAt`](../../../extension.js#L15): the modification time of each source file `syncStalePages` last handled.
- [`settleTimer`](../../../extension.js#L16): the one timer that `onFileChanged` restarts on every event.
- [`queue`](../../../extension.js#L17): the promise chain every rewrite runs on, one task at a time.
