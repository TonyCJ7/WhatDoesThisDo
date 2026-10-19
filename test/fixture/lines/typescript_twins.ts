console.log(tsTwin(1), new TsTwins().tsTwin(1));

function tsTwin(n: number) { return n; }

class TsTwins {
  tsTwin(n: number) { return n + 1; }
}
