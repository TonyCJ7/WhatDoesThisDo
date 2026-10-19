---
name: whatdoesthisdo
description: Keep the markdown reference pages that WhatDoesThisDo shows on hover in step with the code. Use before changing a function, method, class or constant, to read its entry, and after creating, changing, renaming, moving or deleting one, to write or update its entry in the same change.
---

# WhatDoesThisDo reference pages

The project documents its own functions and constants in markdown pages, not in code comments. The WhatDoesThisDo
editor extension shows an entry when someone hovers the name. You keep those pages true while you work on the code.

## Where the pages are and how they are named

The folder is `docs/whatdoesthisdo/references/` in the repository root, unless the project's `whatDoesThisDo.folder`
setting or its agent rules name another one. Inside it, the pages mirror the source tree:

- One page per source file, at the same path with the extension replaced by `.md`:
  `src/figma/urls.ts` is documented in `docs/whatdoesthisdo/references/src/figma/urls.md`.
- The page starts with `## ` and the source path in backticks: `` ## `src/figma/urls.ts` ``.
- Functions, methods and classes follow as `### ` entries in the order they appear in the source.
- Constants go at the end under `## Constants`, one bullet each.
- Create the folders on the way as needed. Never put two source files in one page, and never document a file in
  a page whose path does not match it.

## Before you change code

Open the page for the source file and read the entry of every function or constant you are about to touch. The
entry says what the code is for and what it refuses, which is the part the code itself does not say. If an entry
contradicts the code, the code is the fact and the entry is what you fix.

## After you change code

In the same change as the code:

- A new function, method, class or constant gets an entry on its file's page. A new source file gets a new page.
- A changed one gets its entry re-read and corrected, including the line number in the link.
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
- One heading may list several names when they share an explanation. Each gets its own link.

## What to write

Two to five lines a reader can trust: what it is for, what goes in, what comes out, what it refuses and with which
message. Write the intent you have while writing the code, since that is what a later reader cannot recover from
the code. Do not restate the implementation line by line, and do not describe behaviour you did not verify.

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
