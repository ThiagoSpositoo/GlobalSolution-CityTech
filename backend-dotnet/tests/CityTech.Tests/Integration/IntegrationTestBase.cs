using CityTech.Domain.Entities;
using CityTech.Infrastructure.Persistence;

namespace CityTech.Tests.Integration;

[Collection("SqlServer")]
public abstract class IntegrationTestBase : IAsyncLifetime
{
    protected SqlServerFixture Fixture { get; }

    protected IntegrationTestBase(SqlServerFixture fixture)
    {
        Fixture = fixture;
    }

    public Task InitializeAsync() => Fixture.ResetAsync();

    public Task DisposeAsync() => Task.CompletedTask;

    protected CityTechDbContext CreateContext() => Fixture.CreateContext();

    protected async Task<Account> SeedAccountAsync(string email = "cidadao@example.com")
    {
        var account = TestData.NewCitizen(email);

        await using var db = CreateContext();
        db.Accounts.Add(account);
        await db.SaveChangesAsync();

        return account;
    }
}
