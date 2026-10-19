public class Store
{
    public void Run()
    {
        Persist(1);
    }

    public async Task<int> Persist(int id)
    {
        return id;
    }
}
