fun main() {
    ktTwin(1) + ktTwin(1, 2)
}

fun ktTwin(n: Int): Int = n

fun ktTwin(n: Int, m: Int): Int = n + m
