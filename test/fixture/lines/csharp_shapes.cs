public class CsConfig
{
    public static int Main()
    {
        return new CsConfig().Run();
    }

    public int Run()
    {
        return CsLimit + CsAttempt(1);
    }

    public const int CsLimit = 3;

    private int CsAttempt(int n)
    {
        return n;
    }
}
