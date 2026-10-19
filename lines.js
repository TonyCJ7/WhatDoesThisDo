const KEYWORDS =
  "function|func|fun|fn|def|defp|defn|defun|defmacro|defmethod|defmodule|defstruct|defrecord|deftype|defprotocol|define|data|newtype|class|struct|enum|trait|interface|type|module|object|const|let|var|val|sub|proc|macro|procedure|view|table|trigger";
const DECLARATION_KEYWORD = new RegExp(`(?:^|[^\\w$-])(?:${KEYWORDS})\\s+(?:\\([^)]*\\)\\s+)?(?:[\\w$]+\\s+|[\\w$]+\\.)*$`, "i");
const TYPE_BEFORE_NAME = /(?:^|[\s(,])([A-Za-z_][\w$<>[\],.]*)\s+[*&]*$/;
const NOT_A_TYPE = new Set([
  "return", "new", "await", "yield", "throw", "else", "case", "in", "not", "and", "or", "typeof", "instanceof",
  "delete", "print", "echo", "if", "while", "for", "do", "then", "unless", "until",
]);
const CALL_SHAPE = /^\s*\(/;
const MEMBER_ACCESS = /^\s*\./;
const DECLARATION_TAIL = /^\s*(?:\(|<|:|=[^=])/;
const WORD_EDGE = "[\\p{L}\\p{N}_$-]";

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function typedDeclaration(before, after) {
  const type = TYPE_BEFORE_NAME.exec(before);

  return Boolean(type) && !NOT_A_TYPE.has(type[1]) && CALL_SHAPE.test(after);
}

function declarationScore(before, after) {
  if (MEMBER_ACCESS.test(after)) {
    return 1;
  }

  if (DECLARATION_KEYWORD.test(before)) {
    return 4;
  }

  if (typedDeclaration(before, after)) {
    return 3;
  }

  if (!before.endsWith(".") && DECLARATION_TAIL.test(after)) {
    return 2;
  }

  return 1;
}

// TODO: a keyword-and-punctuation heuristic; revisit when a language with declarations it misses is reported.
function declarationLine(text, name) {
  const word = new RegExp(`(?<!${WORD_EDGE})${escapeRegExp(name)}(?!${WORD_EDGE})`, "u");
  let best = { score: 0, line: null };

  text.split("\n").forEach((line, index) => {
    const match = word.exec(line);

    if (!match) {
      return;
    }

    const score = declarationScore(line.slice(0, match.index), line.slice(match.index + name.length));

    if (score > best.score) {
      best = { score, line: index + 1 };
    }
  });

  return best.line;
}

module.exports = { declarationLine };
