fun main() {
    KtConfig().run()
}

class KtConfig {
    fun run(): Int {
        return KT_LIMIT + ktAttempt(1)
    }

    private fun ktAttempt(n: Int): Int = n
}

const val KT_LIMIT = 3
