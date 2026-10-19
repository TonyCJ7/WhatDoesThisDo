#include <stdio.h>

struct CConfig { int n; };

int main(void) {
    struct CConfig cfg = { C_LIMIT };
    return cfg.n + c_attempt(1);
}

#define C_LIMIT 3

static int c_attempt(int n) {
    return n;
}
