<p align="center">
  <img alt="WhatDoesThisDo logo" src="docs/assets/logo.png" width="200">
</p>

<h1 align="center">WhatDoesThisDo</h1>

<p align="center">
  <strong>Hover over a function or constant name and read what it is for, from markdown pages your AI agent keeps up to date.</strong>
  <br />
  A VS Code and Cursor extension for codebases that grow faster than anyone can read them.
</p>

<p align="center">
  <a href="https://github.com/TonyCJ7/WhatDoesThisDo/blob/main/CHANGELOG.md">
    <img src="https://img.shields.io/github/package-json/v/TonyCJ7/WhatDoesThisDo?style=for-the-badge&label=Version&color=orange&cacheSeconds=300" alt="Version">
  </a>
  <a href="https://github.com/TonyCJ7/WhatDoesThisDo/actions/workflows/tests.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/TonyCJ7/WhatDoesThisDo/tests.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Tests&cacheSeconds=300" alt="Tests">
  </a>
  <a href="https://github.com/TonyCJ7/WhatDoesThisDo">
    <img src="https://img.shields.io/github/stars/TonyCJ7/WhatDoesThisDo?style=for-the-badge&logo=github&cacheSeconds=300" alt="GitHub Stars">
  </a>
  <a href="https://github.com/TonyCJ7/WhatDoesThisDo/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License MIT">
  </a>
</p>

---

## Table of contents

- [The problem](#-the-problem)
- [What is WhatDoesThisDo?](#-what-is-whatdoesthisdo)
- [Why not comments or docstrings?](#-why-not-comments-or-docstrings)
- [How it works](#-how-it-works)
- [Getting started](#-getting-started)
- [Let your AI agent write the documentation](#-let-your-ai-agent-write-the-documentation)
- [Documenting the code you already have](#-documenting-the-code-you-already-have)
- [Writing documentation by hand](#-writing-documentation-by-hand)
- [Settings](#-settings)
- [Performance](#-performance)
- [Local development](#-local-development)
- [Scripts](#scripts)
- [Contributing](#-contributing)
- [Support the project](#-support-the-project)
- [License](#license)

---

## 🧭 The problem

AI agents write code faster than a team can read it. A function lands in the repository, the tests pass, and a week
later someone has to read its body to find out what it is for. A constant appears with a value and nobody remembers
why it is that value. Whoever or whatever wrote the code knew, and nothing wrote it down.

Code comments are the usual answer, and they have their own problems. They clutter the file, they go stale next to
the code they describe, and an agent asked to write them tends to restate the line below.

## ✨ What is WhatDoesThisDo?

WhatDoesThisDo is an editor extension. When you hold the mouse over the name of one of your own functions or constants,
it shows a short description of what that thing is for. The descriptions live in markdown pages inside the repository,
one page per source file. The same AI agent that writes the code can write them, in the same change, while it still
knows why.

- It works in any language the editor can open: TypeScript, Python, Rust, Go, Ruby, shell, PHP, YAML and so on. The
  extension asks the editor what the word under the cursor is, using that language's own rules.
- The pages are plain markdown. They read well on GitHub, their links jump to the source line, and they show up in
  pull request diffs like any other file.
- The agent keeps them true. A one-line setup installs a skill and a rule for Claude Code and Cursor, so the agent
  reads the entry before changing a function and updates it afterwards, in the same change.
- When a language server is running, the extension knows which definition you mean. Two functions called `save` in
  different files each show their own entry.
- It stays fast on large projects. The index is built in memory when the window opens and only the pages that changed
  are read again. Two thousand pages still answer in a few milliseconds.

---

## 💬 Why not comments or docstrings?

Keep your docstrings. They are the right place for the contract of a public function, and the editor already shows
them on hover. WhatDoesThisDo holds what docstrings rarely do: why a function exists, why a constant has the value it
has, what the function refuses. It also covers the internal functions nobody bothers to document, and languages with
no docstrings at all, such as shell, YAML and CSS.

The pages are separate from the code on purpose. The source file stays readable, a change to a page shows up in a
pull request as prose a reviewer can read, and the pages work as a guide on GitHub without opening the code. The agent
rule gets a concrete file to open before it changes a function, which comments spread through the file cannot give
it. When two files define a function with the same name, the extension still knows which entry you mean, because
every entry links to its source line.

---

## 🎬 How it works

<p align="center">
  <img src="docs/assets/hover-demo.gif" alt="A line is typed into the reference page, the hover on the function shows it, and a click on the heading jumps to the declaration" width="720">
</p>

1. You hold the mouse over a name in any file.
2. The extension looks the word up in its index of `docs/whatdoesthisdo/references/`, reads the page that holds it,
   and adds the entry to the editor's tooltip. The heading of the entry is a link: click it and the source file opens
   at the declaration, with or without a language server. Under the heading, `Open in <page>.md` opens the page at
   the entry, for when the text needs a correction.
3. If no page has an entry for that word, the extension adds nothing and the tooltip stays as it was.

The extension finds the line a heading opens at hover time: the language server's answer first, then a search for
the declaration in the linked file, and only then the `#L` written on the page. A link can leave the line out. When a file declares a name twice, as with overloads or a function and a method of
the same name, the search opens the first declaration and a language server opens the one the cursor refers to.
The extension also rewrites the `#L` numbers on the pages themselves, so they stay
right after lines move: when you save a source file, when a file changes on disk because an agent edited it from a
terminal or a `git pull` landed, when the window opens, and when it regains focus. The command
`WhatDoesThisDo: Update line numbers` does the same for every page at once. One setting turns the automatic rewrites
off.

When several files document the same name, the extension asks the language server where the symbol under the cursor
is defined and shows the entry for that file. Without a server, or when no entry points at the file the server named,
it shows every entry for the name with its link, entries from files of the same type first.

---

## 🚀 Getting started

### 1. Install the extension

Open the Extensions view in your editor, search for **WhatDoesThisDo** and install it. VS Code finds it on the
[Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=TonyCJ7.whatdoesthisdo) and Cursor
on [Open VSX](https://open-vsx.org/extension/TonyCJ7/whatdoesthisdo). It is the same extension on both. There is
nothing to configure and no runtime dependency to install.

From a terminal:

```bash
code --install-extension TonyCJ7.whatdoesthisdo      # VS Code
cursor --install-extension TonyCJ7.whatdoesthisdo    # Cursor
```

### 2. Set up your AI agent

In your own project, run the installer for your operating system. It opens with a welcome screen, then asks three
questions: which agent to set up, whether for this project or for every project, and where the pages live. Arrow keys
move, enter selects, `b` goes back and `q` quits. A summary shows your choices and the files it is about to write, and
you can jump back to any step from there. Once the files are written it reminds you to reload the editor, because
skills and rules are read when a session starts.

macOS:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/setup/setup-macos.sh)"
```

Linux:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/setup/setup-linux.sh)"
```

Windows, in PowerShell:

```powershell
irm https://raw.githubusercontent.com/TonyCJ7/WhatDoesThisDo/main/setup/setup-windows.ps1 | iex
```

If you would rather not run a script, paste the contents of [`agent/PROMPT.md`](agent/PROMPT.md) into Claude Code or
Cursor. The agent asks the same questions and copies the same files.

### 3. Try it

Ask the agent to write or change a function. It adds the entry to that file's page in the same change. Hold the mouse
over the function name in the editor and the entry appears.

To see it work before involving an agent, write one page by hand as described in
[Writing documentation by hand](#-writing-documentation-by-hand).

---

## 🤖 Let your AI agent write the documentation

The agent setup writes two things. Claude Code and Cursor both read them.

| | Project scope | Global scope |
|---|---|---|
| The `whatdoesthisdo` skill | `.claude/skills/whatdoesthisdo/SKILL.md` | `~/.claude/skills/whatdoesthisdo/SKILL.md` |
| The rule for Claude Code | a marked block in `CLAUDE.md` | a marked block in `~/.claude/CLAUDE.md` |
| The rule for Cursor | `.cursor/rules/whatdoesthisdo.mdc` | printed for you to paste into Cursor Settings, Rules, User Rules |
| The references folder | created with a short `README.md` if missing | not touched |

The skill is the full instruction: where the pages live, how they are named and laid out, the page format, how to
work out the link to a source line, and what a good entry says. It also tells the agent to read the entry before
touching a function and to update it in the same change as the code. Its text is
[`agent/skill/SKILL.md`](agent/skill/SKILL.md).

The rule is three sentences that sit in the agent's context all the time and point at the skill, so the agent reaches
for it without being asked. Its text is [`agent/rule-block.md`](agent/rule-block.md).

The skill uses the same names and folder layout as the next section, so pages written by an agent and pages written by
hand end up in the same places.

Running the setup again replaces the marked block rather than adding a second one. For scripts and CI, the installers
take `--agent`, `--scope`, `--folder` and `--yes` (`-Agent`, `-Scope`, `-Folder`, `-Yes` on Windows) and skip the
screens.

---

## 📚 Documenting the code you already have

Neither the extension nor your AI agent writes descriptions for existing code on its own. The extension shows whatever
is on the pages, and the agent setup covers code the agent changes from now on. A function nobody has touched since
the setup has no entry until someone writes one.

The agent can catch up on old code when you ask. Prompt it to add descriptions for a file or a folder using the skill
installed during setup. It writes one page per source file, in the place the tooltip reads from. On a large codebase
ask for one folder at a time, so the agent reads every file and the pull request stays small enough to review. Treat
the entries it writes for old code like any other code review, since it is describing functions it did not write.

---

## ✍️ Writing documentation by hand

You can write or edit any page yourself. The extension reads every `.md` file under the references folder and does not
care who wrote it.

### Folder structure and naming

Pages mirror the source tree. Each source file has one page at the same path under the references folder, with the
file extension replaced by `.md`.

```
your-project/
├── src/
│   ├── config.ts
│   └── figma/
│       └── urls.ts
├── scripts/
│   └── release.py
└── docs/
    └── whatdoesthisdo/
        └── references/
            ├── README.md              # what the folder is for; the installer writes it
            ├── src/
            │   ├── config.md          # documents src/config.ts
            │   └── figma/
            │       └── urls.md        # documents src/figma/urls.ts
            └── scripts/
                └── release.md         # documents scripts/release.py
```

Inside a page:

- The first line is `## ` and the source path in backticks, for example `` ## `src/figma/urls.ts` ``.
- Each function, method or class is a `### ` entry, in the order it appears in the source.
- Constants go at the end under a `## Constants` heading, one bullet each.

The extension does not enforce this layout. It reads any `.md` file in the folder or its subfolders. The layout is
there so that a reader, or an agent, can find the page for a file without searching.

### Page format

```markdown
## `src/config.ts`

### [readPositiveNumber(env, name, fallback)](../../../../src/config.ts#L5)

Reads one env variable as a number that must be above zero.

- In: the env, the variable name, the default.
- Out: the default when unset or empty; otherwise the number.
- Refuses: `"abc"`, `"0"`, with `<name> must be a positive number, got "<value>"`.

### [notAFigmaLink(input)](../../../../src/config.ts#L31), [notANodeId(id)](../../../../src/config.ts#L48)

Build the two error objects. Every name in the heading gets this entry.

## Constants

- [`FILE_KEY`](../../../../src/config.ts#L4): alphanumeric, 10 to 64 characters.
```

### Rules the parser follows

- A `### ` heading starts an entry. Every `[name(...)](link)` in the heading becomes a key, paired with its link. The
  key is the text before the opening parenthesis, in whatever spelling the language uses: `save`, `$user`, `my-func`,
  `--brand`. A name ending in `?` or `!` is also registered without the mark, because most editors' word patterns stop
  before it.
- The entry is the heading line plus every line until the next `### `, `## `, or constant bullet.
- A bullet `- [` + backticked name + `](link): text` is a one-line entry for a constant.
- Links are relative to the page, as in any markdown file, and end in `#L<line>` of the declaration. From the
  references folder itself the repository root is `../../../`. Add one `../` for each subfolder the page sits in, so
  `references/src/config.md` uses `../../../../`. The links are clickable in the tooltip, and the file part of the link
  is what the extension compares with the language server's answer. The `#L` part is optional: the extension finds
  the declaration itself and keeps the number current when the source file is saved. It is still worth writing,
  because GitHub opens the file at that line.
- A heading can list several names when they share an explanation. Each gets its own link.

### What makes a good entry

Two to five lines a reader can trust: what it is for, what goes in, what comes out, what it refuses and with which
message. Write down the intent. The code already shows the mechanics.

Write it the way the engineer who built the function would answer a colleague asking what it does: name the caller it
serves, the real default, the actual error text, and the reason behind a value when there is one. "Reads the Figma
file key out of the URL a user pasted" tells a reader something that "Extracts a key from a string" does not. The
skill in `agent/skill/SKILL.md` spells this out for the agent, with a before and after.

---

## ⚙️ Settings

| Setting | Default | Meaning |
|---|---|---|
| `whatDoesThisDo.folder` | `docs/whatdoesthisdo/references` | Folder, relative to each workspace folder, whose markdown pages hold the entries. Subfolders are read. In a multi-root workspace each folder has its own. |
| `whatDoesThisDo.updateLines` | `true` | Keep the `#L` numbers on the pages pointing at the declarations: on save, when a file changes on disk, at launch and on focus. Turn it off to keep the pages untouched; the command `WhatDoesThisDo: Update line numbers` still works. |

---

## ⚡ Performance

The index is built from the pages when the window opens and kept in memory as a map from name to page, without the
entry text. Each time you hover over a name the extension checks every page's modification time and size and re-reads
only the pages that changed, so an edit shows up the next time. Measured on 500 pages with 50,000 entries, a lookup
takes about 5 ms once the index exists, and the index itself is under 6 MB. The extension writes nothing to disk.

---

## 💻 Local development

Requires Node.js 22 or later (`.nvmrc` pins 22).

```bash
git clone https://github.com/TonyCJ7/WhatDoesThisDo.git
cd WhatDoesThisDo
npm install
npm test
npm run test:editor
```

Open the folder in VS Code or Cursor and press F5 to run the extension from source in a second editor window.

To install a local build instead of the published one, `npm run package` writes `whatdoesthisdo-<version>.vsix`, and
`code --install-extension whatdoesthisdo-<version>.vsix` installs it. For Cursor use the `cursor` command, or on macOS
`"/Applications/Cursor.app/Contents/Resources/app/bin/cursor"`. Then run "Developer: Reload Window".

`npm run test:editor` downloads a stock VS Code build into `.vscode-test/` on first run and runs the hover tests inside
it, against the fixture workspace in `test/fixture/`, in two launches configured by `.vscode-test.mjs`:

- `builtin` runs with other extensions disabled. TypeScript and JavaScript use the bundled language server and pick
  the entry by definition. Python, Rust, Ruby, shell, PHP, Go, YAML and plain text have no server there, so they show
  every entry for the name, same file type first, and the tests check each language's word shape. The launch also
  edits a page mid-run to check that the index refreshes, and reads pages from subfolders. `test/lines.test.js` then
  takes nineteen languages, from Java and C# to Clojure and Haskell, through every case that depends on the
  language: a function, a method inside a class or module, a constant, and a type where the language has one, each
  hovered from a use that comes before the declaration against a page whose line is wrong or missing; then a save
  that must move the page line, a rewrite of the file on disk by another program that must do the same through the
  watcher, and the command on a page that drifted. A page made stale before the editor starts checks the sync at
  launch. The cases that share one code path for every language, an open page keeping its unsaved edits, a name no
  longer in the file, several pages for one file, a page's own save and the setting turned off, run once.
- `servers` installs Pylance and rust-analyzer from the marketplace and checks that Python and Rust pick the entry by
  definition, that the server's line wins where a text search would not find it, and that saving a Python or Rust
  file moves the line on its page and back. It needs network access and `cargo`.

Every pull request runs these on GitHub. The Tests workflow starts the parser tests, the `builtin` editor launch and
the three installer tests on each pull request and on every push to `main`, and the branch rules do not let a pull
request merge until those five jobs pass. The `servers` launch runs there too, but as an advisory job, because it
downloads two extensions from the marketplace on each run.

The installer scripts have their own tests, run against temporary repositories on each operating system by the
Tests workflow on GitHub. Their welcome and success screens draw `docs/assets/logo.png` as terminal pixel art;
`python3 setup/make-logo.py` (Pillow and numpy) regenerates that data inside the three scripts after a logo change.

The repository documents its own two source files under `docs/whatdoesthisdo/references/`, so the hover works in this
checkout too.

---

## Scripts

| Command | Description |
|---|---|
| `npm test` | Parser tests, Node's built-in runner |
| `npm run test:editor` | Both editor launches inside a downloaded VS Code |
| `npx vscode-test --label builtin` | The editor launch that needs no network |
| `npm run package` | Build `whatdoesthisdo-<version>.vsix` with `@vscode/vsce`; `.vscodeignore` says what stays out |
| `sh setup/test-setup.sh setup/setup-macos.sh` | Installer test, also with `setup-linux.sh` or `SH=dash` |
| `pwsh setup/test-setup.ps1` | Windows installer test |

**Verify before opening a PR:** `npm test && npx vscode-test --label builtin`. These are the checks GitHub requires on
the pull request, so a branch that fails them locally will not merge.

---

## 🤝 Contributing

Thanks for helping. The extension is small on purpose: one parser, one hover provider, no runtime dependencies.

### Pull requests

1. Branch from `main` with a short kebab-case name: `feature/<topic>`, `fix/<topic>` or `docs/<topic>`.
2. One concern per PR. Split unrelated changes so each is easy to review and revert.
3. Run the checks before you push: `npm test && npx vscode-test --label builtin`. The pull request cannot merge until
   the same checks pass on GitHub. Run `npm run test:editor` when you touch the definition or line lookup, and the
   installer test for your OS when you touch `setup/` or `agent/`.
4. Describe what changed and why. For a bug fix, include the steps that reproduce it before your change. If the
   tooltip changes, a screenshot of before and after helps.
5. Add a line to `CHANGELOG.md` under the next version, and keep this README true when behaviour changes.

### Code style guidelines

| Topic | Guideline |
|---|---|
| **Comments** | Clear names and small functions instead of comments. A comment is for a why the code cannot express. |
| **Dependencies** | None at runtime. A dev dependency is fine when it earns its place; open an issue first for a new one. |
| **Pure logic** | Anything that does not need the `vscode` module goes in `parse.js` or a new pure module, with a test in `parse.test.js`. |
| **Editor behaviour** | Gets a case in `test/builtin.test.js`, `test/lines.test.js` or `test/servers.test.js`, with a fixture file and a page entry rather than a mock. A new language gets a file in `test/fixture/lines/` with a call before the declaration and a page with a wrong line. |
| **Installers** | Three separate scripts by design, one per operating system. A change to the questions or the written files is made in all three; the Tests workflow runs each. |
| **Agent content** | `agent/` is the single source for the skill, rule and prompt. The scripts copy it, they do not carry their own text. |
| **Scope** | The smallest change that solves the request. No speculative options or abstractions without a second user. |

### Reporting issues

Open a [GitHub issue](https://github.com/TonyCJ7/WhatDoesThisDo/issues) with:

1. What happened and what you expected.
2. The page entry and the file you were in, with the language and whether a language server was running for it.
3. What the tooltip showed, as text or a screenshot.
4. Your editor and its version, the operating system, and the output of `node -v` if the build is involved.

A small fixture in `test/fixture/` that reproduces the problem is the fastest route to a fix.

---

## ❤️ Support the project

If WhatDoesThisDo saves you some reading, you can:

- ⭐ [Star the repository](https://github.com/TonyCJ7/WhatDoesThisDo) on GitHub.
- 🤝 [Contribute](#-contributing) with an issue or a pull request.
- ☕ Buy me a coffee:

<p align="center">
  <a href="https://ko-fi.com/tonycj07" target="_blank" rel="noopener noreferrer">
    <img src="https://raw.githubusercontent.com/TonyCJ7/FlumeTV-UI/refs/heads/main/public/assets/kofi-logomark.png" alt="Ko-fi" height="40" />
  </a>
</p>

---

## License

This project is licensed under the [MIT License](LICENSE).
