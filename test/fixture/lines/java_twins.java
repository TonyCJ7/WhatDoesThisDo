public class JavaTwins {
    public int run() {
        return javaTwin(1) + javaTwin(1, 2);
    }

    private int javaTwin(int n) {
        return n;
    }

    private int javaTwin(int n, int m) {
        return n + m;
    }
}
