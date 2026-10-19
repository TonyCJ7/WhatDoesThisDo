## `lines.js`

### [escapeRegExp(text)](../../../lines.js#L14)

`text` with every regex metacharacter escaped, so an entry name such as `$user` or `valid?` can be searched for
literally.

### [typedDeclaration(before, after)](../../../lines.js#L18)

Whether the name between `before` and `after` sits in a C-family declaration: a type or modifier word right before
it, pointer stars allowed, and `(` right after. `public static void save(int id)` and `char *save(int id)` pass;
`return save(1)` does not, because `return` and the other words in `NOT_A_TYPE` are never types.

### [declarationScore(before, after)](../../../lines.js#L24)

How much a line looks like the declaration of the name found between `before` and `after`: 1 when a `.` follows
the name, whatever stands before it; otherwise 4 when a declaration keyword such as `function`, `def`, `fn` or `const` stands before the name, 3 for a `typedDeclaration`, 2 when the
name is followed by `(`, `<`, `:` or `=` and not preceded by `.`, which rules out a method call, 1 for any other
occurrence.

### [declarationLine(text, name)](../../../lines.js#L45)

The 1-based line of `name`'s declaration in the source `text`: the first line with the highest `declarationScore`
among those holding the name as a whole word, so a name declared twice, as with overloads, opens the first
declaration. Word edges are letters, digits, `_`, `$` and `-`, so `save` does not match inside `save_all` but
`valid` does match `def valid?`. Null when the name is not in the text.

- Why: this is what finds the line when no language server is installed, what lets a hand-written link leave the
  `#L` part out, and what the save listener uses for names the server does not report. `lines.test.js` runs it over
  one declaration per language, each with a call before it.

## Constants

- [`KEYWORDS`](../../../lines.js#L1): the words that introduce a declaration across languages, from `function` and
  `def` to `defrecord`, `data`, `define`, `view` and `procedure`, matched without regard to case so `CREATE FUNCTION`
  and `#define` count.
- [`DECLARATION_KEYWORD`](../../../lines.js#L3): text that ends in one of `KEYWORDS`, with modifiers such as
  `export async` or `pub` before it, a Go receiver `(s *Store)` after it, or a dotted owner right before the name,
  as in Ruby's `def self.find` and Lua's `function Config.run`.
- [`TYPE_BEFORE_NAME`](../../../lines.js#L4): a word, with generics or array brackets, then spaces and optional
  `*` or `&`, at the end of the text before the name: the return type of a C, Java or C# declaration.
- [`NOT_A_TYPE`](../../../lines.js#L5): words that can stand before `name(` without declaring anything, such as
  `return`, `await` and `new`.
- [`CALL_SHAPE`](../../../lines.js#L9): `(` right after the name, the shape of both a call and a declaration.
- [`MEMBER_ACCESS`](../../../lines.js#L10): `.` right after the name, which makes the name an owner such as Lua's
  `Config` in `function Config.run`, never the thing declared.
- [`DECLARATION_TAIL`](../../../lines.js#L11): `(`, `<`, `:` or a single `=` right after a name, the shapes of a
  call signature, a generic, a key and an assignment.
- [`WORD_EDGE`](../../../lines.js#L12): the characters that continue a name, so a search matches whole words only.
