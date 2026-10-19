fn main() { rs_twin(1); RsTwins.rs_twin(1); }

fn rs_twin(n: i32) -> i32 { n }

struct RsTwins;

impl RsTwins {
    fn rs_twin(&self, n: i32) -> i32 { n + 1 }
}
