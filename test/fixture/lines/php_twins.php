<?php
echo (new PhpA())->phpTwin(1) + (new PhpB())->phpTwin(1);

class PhpA {
    public function phpTwin($n) {
        return $n;
    }
}

class PhpB {
    public function phpTwin($n) {
        return $n + 1;
    }
}
