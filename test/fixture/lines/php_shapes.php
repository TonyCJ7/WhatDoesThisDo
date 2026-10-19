<?php
echo (new PhpConfig())->run();

class PhpConfig {
    public function run() {
        return self::PHP_LIMIT + $this->phpAttempt(1);
    }

    const PHP_LIMIT = 3;

    private function phpAttempt($n) {
        return $n;
    }
}
