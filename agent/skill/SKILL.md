---
name: whatdoesthisdo
description: Keep the markdown reference pages that WhatDoesThisDo shows on hover in step with the code. Use before changing a function, method, class, type or constant, to read its entry, and after creating, changing, renaming, moving or deleting one, to write or update its entry in the same change.
---

<!-- whatdoesthisdo-skill-version: 0.1.4 -->

# WhatDoesThisDo reference pages

The project documents its own functions, methods, classes, types and constants in markdown pages, not in code
comments. Types means anything else with a name a reader can hover: interfaces, enums, structs, traits, type aliases.
Below, "function" stands for any of them. The WhatDoesThisDo editor extension shows an entry when someone hovers the
name. You keep those pages true while you work on the code.

## Where the pages are and how they are named

The folder is `docs/whatdoesthisdo/references/` in the repository root, unless the project's `whatDoesThisDo.folder`
setting or its agent rules name another one. Inside it, the pages mirror the source tree:

- One page per source file, at the same path with the extension replaced by `.md`:
  `src/figma/urls.ts` is documented in `docs/whatdoesthisdo/references/src/figma/urls.md`.
- The page starts with `## ` and the source path in backticks: `` ## `src/figma/urls.ts` ``.
- Functions, methods, classes and types follow as `### ` entries in the order they appear in the source.
- Constants go at the end under `## Constants`, one bullet each.
- Create the folders on the way as needed. Never put two source files in one page, and never document a file in
  a page whose path does not match it.

## Before you change code

Open the page for the source file and read the entry of everything you are about to touch. The
entry says what the code is for and what it refuses, which is the part the code itself does not say. If an entry
contradicts the code, the code is the fact and the entry is what you fix.

## After you change code

In the same change as the code:

- A new function, method, class, type or constant gets an entry on its file's page. A new source file gets a new page.
- A changed one gets its entry re-read and corrected, including the line number in the link. The extension
  rewrites line numbers when it sees a file change, in the editor or on disk, but only while the editor is open on
  the project; the page you commit must be right on its own.
- A renamed one gets its heading and link updated. A moved one moves to the page of its new file.
- A deleted one gets its entry removed. A deleted source file gets its page removed.

Never leave the page for a later task. The hover is wrong the moment the code and the page disagree.

## The format

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

Rules the parser follows:

- A `### ` heading starts an entry. The text before the opening parenthesis in each `[name(...)](link)` is the key
  the hover matches, in the language's own spelling: `save`, `$user`, `my-func`, `--brand`.
- The entry runs from the heading to the next `### `, `## ` or constant bullet.
- A constant is one bullet: `- [` backticked name `](link): text`.
- The link is relative to the page, as in any markdown file, and ends in `#L<line>` of the declaration. From the
  references folder itself the repository root is `../../../`. Add one `../` for every subfolder the page sits in:
  `references/src/config.md` uses `../../../../`, `references/src/figma/urls.md` uses `../../../../../`.
- Write the line. The extension finds the declaration on its own when it shows the hover, but GitHub opens the file
  at the line written here, and a reader of the page sees where to look.
- One heading may list several names when they share an explanation. Each gets its own link.

## What to write

Two to five lines a reader can trust: what it is for, what goes in, what comes out, what it refuses and with which
message. Write the intent you have while writing the code, since that is what a later reader cannot recover from
the code. Do not restate the implementation line by line, and do not describe behaviour you did not verify.

## The shape of an entry

Every entry has the same parts in the same order, so a reader finds the same thing in the same place each time.

1. The first sentence says what the function does, with the function as the subject and a verb first: "Builds",
   "Returns", "Rewrites", "Reads". Never a noun phrase that names the result: not "An absolute URI for the file",
   not "The part of the link before `#`", not "Whether the folder exists", not "Where the pages live". When it is
   not obvious who uses the result, the sentence says so: "the link behind a hover heading".
2. `In:` explains every parameter, in backticks spelled as in the signature: what it is, where it comes from,
   and what the function does with it when the first sentence does not make that plain. "`file`, the absolute path
   of the source file to open" says all three. A type alone, "a string", "a callback", "an object", is not an
   explanation. The bullet is left out only for a function with no parameters.
   After this bullet the prose names a parameter by its backticked name or by its role, "the source file", and
   never uses the bare word for anything else. A code literal that spells like a parameter is reworded, so next to
   a parameter called `file` the URI scheme is written `file://`, not `file:`.
3. `Out:` what comes back, with its special cases: the null, the empty list, the fallback. A reader must be able to
   tell input from output without opening the code.
4. `Refuses:` the inputs it rejects and the exact message, in backticks.

`Out:` and `Refuses:` are left out when they have nothing to say. A constant has no bullets, one sentence.

The entry stands alone. A reader must not need another entry, the code or a term's definition to understand it.
Another function's name may appear so the reader can jump to it, never as the explanation: not "from
`entriesNamed`" but "every entry whose name is the hovered word". A term the reader may not know is said in plain
words the first time: not "the language server's locations" but "the places where the editor says the word is
defined, a file and a line each".

One idea per sentence, about twenty words. A sentence that holds "or … when …" or "with … as …" carries two ideas
and is split. A reason gets one clause, "so a typo stops the start"; a longer reason gets its own sentence. Chains
of "which" and "because" are cut into sentences.

Before, an entry that follows none of this:

```markdown
An absolute `file:` URI string for `file` with `L<line>` as its fragment, or no fragment when the line is null.
```

After, the same function:

```markdown
Builds the link behind a hover heading, the one that jumps from the hover to the code.

- In: `file`, the absolute path of the source file to open. `line`, a line number in that file, or null.
- Out: the path as a `file://` URI string. With a line number it ends in `#L<line>`, so the editor opens that
  line. With null there is no fragment, and the editor opens the top of the source file.
```

## Before you save

Read the entry once without the code open, as someone who has never seen the function. Rewrite it when any of
these is true:

- A sentence has no verb.
- You cannot tell which words are inputs and which are the result.
- One word means two things in the entry, a parameter and a plain word, or a parameter and a code literal.
- Two readings fit one sentence.
- A sentence needs the code, another entry or a term you did not explain to be understood.

## How to write it

Write the way the engineer who built this program would answer a colleague who leans over and asks "what does this
do?". That person knows this codebase, so they name the real things: the caller that needs the fallback, the value
a limit protects, the message the user sees. A generic description is wrong even when every word of it is true.

- The first sentence says what the thing is for in this program. "Reads the Figma file key out of the URL a user
  pasted" tells a reader something. "Extracts a key from a string" tells them nothing the signature did not.
- Use the real values from the code: the actual default, the actual limit, the actual error text, in backticks.
- Say why when the code cannot: the reason the limit is 64, the bug a check prevents, the caller that needed the
  special case. If you do not know why, leave it out. Never invent a reason.
- Write in plain present tense with the function as the subject. "Returns the default when the variable is unset."
  Not "This function is responsible for returning" and not "The default will be returned".
- Keep the parts a reader can use and drop the rest. Nobody needs "This is a helper function", "Note that", "It is
  important to", "in order to", "simply", "various", "appropriate", "robust", "seamlessly", "ensures", "leverages"
  or "handles". A sentence that would fit any function in any program is filler.
- No bold labels, no headings inside an entry, no sentence that repeats the one before it in other words, and no
  closing line that sums up. Three bullets because the meaning has three parts, never because three sounds complete.
- Say the point, never a contrast that only adds weight. "Not just a parser, but the place where…" and "rather than
  X, it does Y" name something nobody claimed. Keep a contrast only when the reader would otherwise believe the
  other half.
- No dashes as connectors. A comma, a colon or a new sentence says how two clauses relate; a dash skips that choice.
- Short sentences in plain words, one idea each, that a reader whose first language is not English understands at
  once. No idioms.
- A constant gets one line: what the value means and, if it matters, why it is that value.

Before, the kind of entry an agent writes by default:

```markdown
This function is responsible for validating the user input and ensuring that it is a positive number. It takes
the environment, the name and a fallback value and returns the appropriate result. This is important for
robustness.
```

After, the same function described by someone who knows the program:

```markdown
Reads one env variable as a number that must be above zero, for the timeouts and retry counts in `config.ts`.

- Out: the fallback when the variable is unset or empty; otherwise the number.
- Refuses `"abc"` and `"0"` with `<name> must be a positive number, got "<value>"`, so a typo in `.env` stops the
  start instead of becoming a zero timeout.
```
