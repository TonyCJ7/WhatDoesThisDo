## `extension.js`

### [referencesDir(folder)](../../../extension.js#L11)

Where the pages live for one workspace folder: the `whatDoesThisDo.folder` setting joined onto the folder's path.
The setting is read with that folder's own configuration, so each root of a multi-root workspace can point
somewhere else. Default `docs/whatdoesthisdo/references`.

### [namesIn(file)](../../../extension.js#L17)

The set of entry names on one page, which is all the index keeps per page. The page is parsed in full and the text
thrown away; that is why 500 pages with 50,000 entries stay under 6 MB in memory.

### [refreshPages(dir)](../../../extension.js#L21)

The index for one references folder: a map from page path to `{ mtimeMs, size, names }`.

- Walks the folder and its subfolders, keeps the cached names for every page whose modification time and size are
  unchanged, and parses only the rest.
- Runs before every hover. For an unchanged page that is one `stat`, which is how an edit shows up on the next hover
  without a file watcher.
- Out: an empty map when the folder does not exist, so a project without pages hovers nothing.

### [entriesNamed(dir, word)](../../../extension.js#L44)

Every entry called `word`, read from the pages whose index says they hold that name, usually one. Each entry is
tagged with `pageDir`, the page's own folder, because the links on a page are relative to the page.

### [definitionFiles(document, position)](../../../extension.js#L64)

The files in which the language server says the symbol at `position` is declared. Every location, not only the
first: a TypeScript interface merged across two files reports both, and the entry may point at the second. Empty
when no server answers, which is the case for Python or Rust without their extensions installed.

### [linkFile(entry)](../../../extension.js#L70)

The absolute path of the source file an entry's link points at, resolved from the page's folder with the `#L` part
dropped. This is the path the definition match compares against.

### [rankEntries(candidates, document, position)](../../../extension.js#L74)

Which entries to show when several share a name, and in which order.

- One candidate is returned as it is, without asking the language server.
- Otherwise the entries whose link file is one of the definition locations win, and only those are shown.
- When none match, which is the case without a server or when a page links to the wrong file, every candidate is
  shown, the ones whose link file has the hovered document's extension first. A Python `save` sees the Python page
  before the TypeScript one.

### [absoluteLinks(text, pageDir)](../../../extension.js#L93)

The entry text with every relative markdown link turned into an absolute `file:` link, resolved against the page's
folder, with the `#L` part kept as the URI fragment. Links that already have a scheme are left alone.

- Why: the editor joins a relative link's text onto the base path, fragment included, so `../x.js#L72` opened an
  empty editor called `x.js#L72`. With a real fragment the click opens `x.js` at line 72.

### [markdownFor(entry)](../../../extension.js#L106)

The entry text as a MarkdownString with its links made absolute. Nothing else is set on it, so an entry cannot run
commands.

### [provideHover(document, position)](../../../extension.js#L110)

The hover provider. Returns one Hover with one markdown block per entry, in ranked order, which the editor shows
under its own tooltip.

- Null, which leaves the editor's tooltip untouched, when the document is outside a workspace folder, when there is
  no word at the position by the language's own word pattern, or when no page names the word.

### [warmIndex()](../../../extension.js#L130)

Builds the index for every workspace folder at activation, so the first hover does not pay the few hundred
milliseconds a cold index costs on a large project. A folder that cannot be read is skipped and the first hover
retries it; activation never fails because of it.

### [activate(context)](../../../extension.js#L140)

Registers the hover provider for every `file:` document in any language, then warms the index. Runs on
`onStartupFinished`, after the window is up, so it never slows the editor's start.

## Constants

- [`MARKDOWN_LINK`](../../../extension.js#L7): the `](href)` tail of a markdown link, href captured, no spaces
  allowed inside.
- [`HAS_SCHEME`](../../../extension.js#L8): an href that starts with a URI scheme such as `https:` or `file:`, which
  `absoluteLinks` leaves as it is.
- [`pagesByFolder`](../../../extension.js#L9): the index cache, references folder path to the map `refreshPages`
  builds. One entry per workspace folder; it lives as long as the window.
