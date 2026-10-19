fn main() { RsConfig.run(); }

struct RsConfig;

impl RsConfig {
    fn run(&self) -> i32 { RS_LIMIT + self.rs_attempt(1) }

    fn rs_attempt(&self, n: i32) -> i32 { n }
}

const RS_LIMIT: i32 = 3;
