public class JavaConfig {
    public static int main() {
        return new JavaConfig().run();
    }

    public int run() {
        return JAVA_LIMIT + javaAttempt(1);
    }

    public static final int JAVA_LIMIT = 3;

    private int javaAttempt(int n) {
        return n;
    }
}
