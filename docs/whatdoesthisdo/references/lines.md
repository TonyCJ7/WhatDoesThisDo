## `lines.js`

### [escapeRegExp(text)](../../../lines.js#L14)

Escapes every character that means something in a regular expression, so a name such as `$user` or `my.func` can be
searched for as itself.

- In: `text`, the name an entry is registered under, which may hold `$`, `.` or `-`.
- Out: the name with a backslash before each such character.

### [typedDeclaration(before, after)](../../../lines.js#L18)

Checks whether a name sits in a typed declaration such as C's `int main(` or Java's `String save(`.

- In: `before`, the text left of the name on its line, where a type would stand. `after`, the text right of the
  name, where the parameter list would start.
- Out: true when the left text ends in a word that can be a type, with `*` or `&` allowed between, and the right
  text starts with `(`. A word such as `return` or `new` does not count as a type, so `return save(` is not a
  declaration.

### [declarationScore(before, after)](../../../lines.js#L24)

Scores how much one line looks like the declaration of a name, from what stands around the name on that line.

- In: `before`, the text left of the name on its line, where a keyword or a type would stand. `after`, the text
  right of the name, where `(`, `:` or `=` would follow a declaration.
- Out: 4 for a declaration keyword before the name, such as `function` or `def`. 3 for a type before the name and
  `(` after it. 2 for `(`, `<`, `:` or `=` right after the name. 1 for any other use.
- A name followed by `.` scores 1 whatever stands before it, since the name is then the owner of something else, as
  in Lua's `function Config.save`. A `.` right before the name blocks the score of 2, so `self.save = ` is not a
  declaration either.

### [declarationLine(text, name)](../../../lines.js#L45)

Finds the line where a name is declared, without any language support, by scanning every line for the name as a
whole word and scoring how much each line looks like a declaration. It is a heuristic over keywords and
punctuation, and it is wrong for a language whose declarations use none of those shapes. The line written on the
page then still applies.

- In: `text`, the whole source file. `name`, an entry's name, the declaration to find.
- Out: the 1-based number of the line with the highest score. The first line wins a tie, so a name declared twice
  gives the first declaration. Null when no line holds the name.

## Constants

- [`KEYWORDS`](../../../lines.js#L1): the words that introduce a declaration across languages, from `function`, `def` and `fn` to
  `class`, `struct`, `trait`, `const`, `val`, SQL's `view` and `trigger`, and C's `define`. Matched without regard
  to case.
- [`DECLARATION_KEYWORD`](../../../lines.js#L3): matches text that ends in one of those keywords, then optional modifiers, a Go
  receiver such as `(s *Store)`, or an owner such as `self.`, right before the name.
- [`TYPE_BEFORE_NAME`](../../../lines.js#L4): matches a word, with generics or array brackets allowed, then spaces and an optional
  `*` or `&`, right before the name: the type of a typed declaration.
- [`NOT_A_TYPE`](../../../lines.js#L5): words that can stand before `name(` without declaring anything, such as `return`, `new`,
  `await` and `if`.
- [`CALL_SHAPE`](../../../lines.js#L9): matches `(` right after the name, the shape of both a call and a declaration.
- [`MEMBER_ACCESS`](../../../lines.js#L10): matches `.` right after the name, which makes the name an owner, such as Lua's `Config`
  in `function Config.save`.
- [`DECLARATION_TAIL`](../../../lines.js#L11): matches `(`, `<`, `:` or a single `=` right after the name, the shapes of a call, a
  generic, a type annotation and an assignment.
- [`WORD_EDGE`](../../../lines.js#L12): the characters that continue a name, letters, digits, `_`, `$` and `-`, so a search matches
  whole words only.
