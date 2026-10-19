console.log(new TsConfig().run());

class TsConfig {
  run() {
    return TS_LIMIT + this.tsAttempt(1);
  }

  tsAttempt(n: number) {
    return n;
  }
}

export const TS_LIMIT = 3;
