print(SwiftConfig().run())

struct SwiftConfig {
    func run() -> Int {
        return swiftLimit + swiftAttempt(1)
    }

    func swiftAttempt(_ n: Int) -> Int { n }
}

let swiftLimit = 3
