## `extension.js`

### [referencesDir(folder)](../../../extension.js#L20)

Finds the folder that holds the pages for one folder open in the editor.

- In: `folder`, a folder open in the editor, the one that contains the hovered file.
- Out: the absolute path of its pages folder. That is the `whatDoesThisDo.folder` setting, by default
  `docs/whatdoesthisdo/references`, joined onto the open folder's path.

### [fileOf(link)](../../../extension.js#L26)

Strips the line part from a page link.

- In: `link`, the link text of an entry as written on the page, `../../src/a.ts#L12`.
- Out: the part before `#`, `../../src/a.ts`, the path of the source file the link points at, relative to the page.

### [linkFile(entry)](../../../extension.js#L30)

Resolves the source file that an entry documents to an absolute path. The link on the page is relative to the page,
so it is joined onto the page's folder.

- In: `entry`, an entry read from a page, with the field `pageDir` that holds the page's folder.
- Out: the absolute path of the source file. Every comparison with a path the editor reports uses this form.

### [entriesIn(markdown, page)](../../../extension.js#L34)

Parses the text of one page into entries, and tags each entry with where it came from.

- In: `markdown`, the page text, read from disk or taken from an open editor document. `page`, the absolute path of
  that page.
- Out: the entries, each with two extra fields: `page`, the page's absolute path, and `pageDir`, the page's folder.
  The hover uses the folder to resolve the entry's links and the path to build its `Open in` link.

### [pageEntries(page)](../../../extension.js#L40)

Reads one page from disk and parses it into entries.

- In: `page`, the absolute path of the page to read.
- Out: its entries, each tagged with the page's path and folder.

### [indexPage(page)](../../../extension.js#L44)

Summarises one page for the index, the in-memory summary of every page that lets a hover find the right page
without reading all of them.

- In: `page`, the absolute path of the page to summarise.
- Out: an object with two sets. `names` holds every entry name on the page. `files` holds the absolute path of every
  source file the entries link to. The entry text is not kept, so the index stays small.

### [markdownFilesIn(dir, prefix)](../../../extension.js#L53)

Lists every markdown page under a folder, subfolders included. Walks the folders itself, because Node's own
recursive listing follows symbolic links inside the editor, and a link could pull in pages from anywhere on the
disk. A symbolic link is skipped, whether it points at a file or a folder.

- In: `dir`, the absolute path of the folder to walk. `prefix`, the path of the subfolder being walked, relative to
  the folder of the first call. The first call leaves it empty; only the recursion sets it.
- Out: the paths of the `.md` files, relative to the folder of the first call.

### [isRealFolder(dir)](../../../extension.js#L73)

Checks that a path is a directory in its own right, so that a pages folder which is itself a symbolic link is
ignored and never pulls pages in from elsewhere.

- In: `dir`, the absolute path to check.
- Out: true for a directory. False when the path is missing, is a file or is a symbolic link.

### [refreshPages(dir)](../../../extension.js#L81)

Builds or refreshes the index of one pages folder, the in-memory summary of every page, and keeps it for the next
call. A page whose modification time and size are unchanged keeps its old summary; every other page is read again.
On a folder with two thousand pages the check takes a few milliseconds, since it is one file stat per page.

- In: `dir`, the absolute path of the pages folder.
- Out: a map from page path, relative to the pages folder, to its modification time, size, entry names and the
  source files it links to. An empty map when the path is not a real folder.

### [entriesNamed(dir, word)](../../../extension.js#L104)

Collects every entry with one name from the pages of a folder. Only the pages whose index summary lists that name
are read, which is usually one page.

- In: `dir`, the absolute path of the pages folder to search. `word`, the word under the cursor, as the editor's
  word rules for the language give it.
- Out: the entries whose name is that word. An empty list when no page has it.

### [pagesLinking(pages, dir, file)](../../../extension.js#L118)

Finds the pages whose entries document one source file. This is how a change to one source file leads to the one
or two pages that need their line numbers rewritten.

- In: `pages`, the index of the pages folder, a map from page path to its summary. `dir`, the absolute path of that
  folder, needed to turn the relative page paths in the index into absolute ones. `file`, the absolute path of the
  source file that changed.
- Out: the absolute paths of the pages that link to the source file.

### [definitionLocations(document, position)](../../../extension.js#L122)

Asks the editor's language support where the word under the cursor is defined.

- In: `document`, the file being hovered, as the editor holds it. `position`, the cursor position in it.
- Out: a list with one item per place the editor reports, each the absolute path of a source file and a 1-based
  line. An empty list when the editor has no language support for the file, or when it does not know the word.
  Both are normal, so an empty answer never fails the hover.

### [searchLine(file, name)](../../../extension.js#L131)

Finds the line where a name is declared by reading the source file and scoring every line that holds the name,
with the declaration keywords and punctuation of common languages. This is the fallback when the editor's language
support has no answer.

- In: `file`, the absolute path of the source file an entry documents. `name`, the entry's name, the declaration to
  find in that file.
- Out: the 1-based line number. Null when the file cannot be read, when it is larger than two megabytes, or when no
  line holds the name.

### [lineInLink(link)](../../../extension.js#L143)

Reads the line number written at the end of a page link.

- In: `link`, the link text of an entry as written on the page.
- Out: the number after `#L`. Null when the link has no line.

### [hoverLine(entry, definitions)](../../../extension.js#L149)

Picks the line that a hover heading opens. Tries three sources in order and takes the first that answers.

- In: `entry`, the entry behind the heading, which names the source file and may carry a `#L` line. `definitions`,
  the places where the editor says the hovered word is defined, a source file and a line each.
- Out: the editor's line, when one of its places is in the entry's source file. Otherwise the line found by reading
  that file. Otherwise the `#L` written on the page. Null when all three fail, and the heading then opens the top of
  the source file.

### [fileLink(file, line)](../../../extension.js#L156)

Builds the link behind a hover heading, the one that jumps from the hover to the code.

- In: `file`, the absolute path of the source file to open. `line`, a line number in that file, or null.
- Out: the path as a `file://` address. With a line number it ends in `#L<line>`, so the editor opens that line.
  With null there is no line part, and the editor opens the top of the source file.

### [rankEntries(candidates, definitions, document)](../../../extension.js#L160)

Decides which entries the hover shows when more than one page has an entry with the hovered name, and in which
order.

- In: `candidates`, every entry whose name is the hovered word, from one page or several. `definitions`, the places
  where the editor says that word is defined, a source file and a line each; the list is empty when the editor has
  no language support for the file. `document`, the file being hovered.
- Out: the entries to show, in that order.
- One candidate is returned as it is.
- When the editor named the file where the word is defined, only the candidates that document that file are
  returned. Two functions called `save` in different files each show their own entry.
- When the editor named no file, every candidate is returned. Those that document a file with the same extension as
  the hovered file come first, since a `save` hovered in a `.py` file is most likely the Python one.

### [absoluteLinks(text, pageDir)](../../../extension.js#L179)

Rewrites every relative link in a hover text into an absolute `file://` address. The editor treats the `#L…` part
of a relative link as part of the file name, which breaks the jump to the line, so the hover cannot use the links
as written on the page.

- In: `text`, the markdown of the hover. `pageDir`, the absolute path of the page's folder, which the links on the
  page are relative to.
- Out: the same text with every relative link turned into a `file://` address with its `#L<line>` kept. A link that
  already starts with a scheme, such as `https:`, is left as it is.

### [markdownFor(entry, definitions)](../../../extension.js#L192)

Builds the text of one hover block.

- In: `entry`, the entry to show. `definitions`, the places where the editor says the hovered word is defined,
  used to pick the line the heading opens.
- Out: the markdown the editor renders in the hover, in three parts: the heading, with its link pointed at the
  line the declaration is on now; a line with `Open in <page>.md`, linking to the entry on its page; and the entry
  text. The text is marked untrusted, so it cannot run editor commands.

### [provideHover(document, position)](../../../extension.js#L205)

Answers the editor's hover request. Collects the entries named like the word under the cursor, asks the editor's
language support once where the word is defined, picks and orders the entries and builds one block per entry.

- In: `document`, the file being hovered, as the editor holds it. `position`, the cursor position in it.
- Out: one hover with the blocks. Null when the file is outside every folder open in the editor, when there is no
  word under the cursor, or when no page has the word, so other hover providers are not disturbed.

### [symbolLines(file)](../../../extension.js#L226)

Asks the editor's language support for every named thing in one source file, nested ones included, and where each
is declared.

- In: `file`, the absolute path of the source file that changed, whose declarations may have moved.
- Out: a map from name to its 1-based line. A parameter list that some language supports append to the name,
  `save(id)`, is stripped so the name matches the page. When two things share a name, the first keeps the line. An
  empty map when the editor has no language support for the file or it fails.

### [relinkedLine(text, entries, lineFor)](../../../extension.js#L252)

Rewrites the `#L` number in each link on one line of a page.

- In: `text`, one line of the page, a heading or a constant bullet. `entries`, the entries that opened on that line,
  so each link can be matched to its entry. `lineFor`, a function that gives the new line number for an entry, or
  nothing when it has none.
- Out: the page line with each link's number replaced. A link whose entry gets no number is left as it is,
  including a link that had no number.

### [rewriteLines(page, file, lineFor)](../../../extension.js#L260)

Updates the links to one source file on one page. Opens the page the way the editor does, so an editor with the
page open sees the change, and edits only the lines whose links change. Saves the page afterwards unless it already
had unsaved changes.

- In: `page`, the absolute path of the page to edit. `file`, the absolute path of the source file whose links to
  update; links to other files on the same page are left alone. `lineFor`, a function that gives the new line
  number for an entry.
- Out: how many page lines changed.

### [updateLinesFor(dir, file, index)](../../../extension.js#L291)

Brings every page that documents one source file up to date with the file's current lines. Takes each entry's line
from the editor's language support first, and by reading the file for the names the editor did not report.

- In: `dir`, the absolute path of the pages folder. `file`, the absolute path of the source file that changed.
  `index`, the in-memory summary of the pages folder, passed in when one refresh serves a whole burst of changes,
  and built fresh when left out.
- Out: how many page lines changed across the pages. Zero when no page documents the source file.

### [updatesEnabled(folder)](../../../extension.js#L309)

Reads the `whatDoesThisDo.updateLines` setting for one folder open in the editor.

- In: `folder`, a folder open in the editor.
- Out: true when the automatic line number rewrites are on for it, which is the default.

### [isPage(dir, file)](../../../extension.js#L313)

Checks whether a changed file is itself a page. A page is never treated as a source file, which also stops a page
save from starting another rewrite.

- In: `dir`, the absolute path of the pages folder. `file`, the absolute path of the changed file.
- Out: true when the changed file lies inside the pages folder.

### [enqueue(task)](../../../extension.js#L317)

Runs one rewrite task after every rewrite already waiting. All rewrites go through this one queue, so a burst of
changes, a catch-up on focus and the command never rewrite the same page at the same time.

- In: `task`, the rewrite to run, a function that finishes later: the flush of collected changes, the catch-up on
  stale pages, or the command that rewrites every page.
- Out: a promise that settles when the task has run. An error in a task is swallowed, and the next change, focus or
  command catches up.

### [flushChanges()](../../../extension.js#L325)

Handles every file collected since the last flush. Refreshes the index once per pages folder, then rewrites the
pages of each file in turn. Clears the collected set first, so changes that arrive during the flush are kept for the
next one.

### [onFileChanged(uri)](../../../extension.js#L339)

Takes one changed file from either source, a save in the editor or a change on disk seen by the file watcher. Adds
the file to the set of changes waiting for its pages folder and restarts the one settle timer. The flush runs 150 ms
after the last event, so a `git pull` that touches fifty files costs one index refresh.

- In: `uri`, the address of the changed file, as the save listener or the watcher reports it.
- Refuses: a file outside every folder open in the editor, a file in a folder whose updates are turned off, and a
  page. Each is ignored.

### [staleFiles(dir)](../../../extension.js#L362)

Finds the source files that changed after the page documenting them, which is what happens while the editor is
closed.

- In: `dir`, the absolute path of the pages folder whose pages to check.
- Out: a map from source file path to its modification time. A source file whose time was already handled by an
  earlier catch-up is skipped, so a file is not handled again on every focus. A source file that no longer exists
  is skipped too.

### [syncStalePages()](../../../extension.js#L384)

Catches up on code that changed while the editor was closed or unfocused. Rewrites the pages of every stale source
file in every folder open in the editor whose updates are on, and remembers each file's time so the same change is
not handled twice. Runs at activation and each time the window regains focus.

### [updateAllLines()](../../../extension.js#L399)

Runs the command `WhatDoesThisDo: Update line numbers`. Rewrites the links to every source file any page documents,
in every folder open in the editor, whether the file changed or not. A source file that no longer exists is
skipped. Shows a message with the number of changed lines.

### [warmIndex()](../../../extension.js#L417)

Builds the index for every folder open in the editor at activation, so the first hover does not pay the few hundred
milliseconds of reading every page. An unreadable folder is ignored, and the first hover reads it again.

### [activate(context)](../../../extension.js#L427)

Starts the extension. Registers the hover provider for every file on disk in any language, the save listener, a
watcher for changes on disk, the focus listener and the command. Then warms the index and queues one catch-up on
stale pages.

- In: `context`, the object the editor passes to every extension at activation. Everything registered goes on its
  `subscriptions`, so it is released when the extension unloads.

## Constants

- [`MARKDOWN_LINK`](../../../extension.js#L8): matches the `](href)` tail of a markdown link and captures the href. An href with a space
  in it is not a link.
- [`HAS_SCHEME`](../../../extension.js#L9): matches an href that starts with a scheme such as `https:` or `file:`. Such a link is left
  as it is.
- [`LINE_IN_LINK`](../../../extension.js#L10): matches the `#L<number>` at the end of a page link.
- [`SIGNATURE`](../../../extension.js#L11): matches the `(` and everything after it in a name reported by the editor. Some language
  supports append the parameters to the name, and the page key has none.
- [`SETTLE_MS`](../../../extension.js#L12): how long the extension waits after the last file change before rewriting pages, 150 ms.
  Long enough to gather a `git pull`, short enough that a hover after a save sees the new line.
- [`MAX_SEARCH_BYTES`](../../../extension.js#L13): two megabytes, the largest source file the line search reads. A generated bundle
  linked by mistake does not stall a hover.
- [`pagesByFolder`](../../../extension.js#L14): the index cache, from pages folder path to the summary of its pages.
- [`pendingChanges`](../../../extension.js#L15): the files changed since the last flush, grouped by pages folder.
- [`syncedAt`](../../../extension.js#L16): the modification time of each source file the last catch-up handled.
- [`settleTimer`](../../../extension.js#L17): the one timer that every file change restarts.
- [`queue`](../../../extension.js#L18): the chain every rewrite runs on, one task at a time.
