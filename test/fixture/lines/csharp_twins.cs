public class CsTwins
{
    public int Run()
    {
        return CsTwin(1) + CsTwin(1, 2);
    }

    private int CsTwin(int n)
    {
        return n;
    }

    private int CsTwin(int n, int m)
    {
        return n + m;
    }
}
