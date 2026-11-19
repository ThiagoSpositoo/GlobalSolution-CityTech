using CityTech.Domain.Entities;
using CityTech.Domain.Enums;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Tests.Integration;

public sealed class AccountPersistenceTests : IntegrationTestBase
{
    public AccountPersistenceTests(SqlServerFixture fixture)
        : base(fixture)
    {
    }

    [Fact]
    public async Task RegisterCitizen_PersistsNormalizedEmailAndUtcTimestamps()
    {
        var account = Account.RegisterCitizen(
            "  Maria Silva  ",
            "Maria.Silva@Example.com  ",
            TestData.PasswordHash());

        await using (var db = CreateContext())
        {
            db.Accounts.Add(account);
            await db.SaveChangesAsync();
        }

        await using var read = CreateContext();
        var saved = await read.Accounts.SingleAsync(candidate => candidate.Id == account.Id);

        Assert.Equal("Maria Silva", saved.Name);
        Assert.Equal("Maria.Silva@Example.com", saved.Email);
        Assert.Equal("maria.silva@example.com", saved.EmailNormalized);
        Assert.Equal(Role.CIDADAO, saved.Role);
        Assert.True(saved.Active);
        Assert.Equal(DateTimeKind.Utc, saved.CreatedAt.Kind);
        Assert.Equal(DateTimeKind.Utc, saved.UpdatedAt.Kind);
        Assert.Equal(0, saved.Version);
        Assert.NotEqual(TestData.Password, saved.PasswordHash);
    }

    [Fact]
    public async Task DuplicateNormalizedEmail_IsRejectedByUniqueIndex()
    {
        await using (var seed = CreateContext())
        {
            seed.Accounts.Add(Account.RegisterCitizen(
                "Maria",
                "maria@example.com",
                TestData.PasswordHash()));
            await seed.SaveChangesAsync();
        }

        await using var db = CreateContext();
        db.Accounts.Add(Account.RegisterCitizen(
            "Outra Maria",
            "MARIA@example.com",
            TestData.PasswordHash()));

        var exception = await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());

        Assert.Contains(
            "UX_accounts_email_normalized",
            exception.InnerException?.Message ?? exception.Message,
            StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Rename_IncrementsVersionAndKeepsTimestampsUtc()
    {
        var account = await SeedAccountAsync();

        await using var db = CreateContext();
        var saved = await db.Accounts.SingleAsync(candidate => candidate.Id == account.Id);
        var originalUpdatedAt = saved.UpdatedAt;

        saved.Rename("Maria Souza");
        await db.SaveChangesAsync();

        Assert.Equal("Maria Souza", saved.Name);
        Assert.Equal(1, saved.Version);
        Assert.Equal(DateTimeKind.Utc, saved.UpdatedAt.Kind);
        Assert.True(saved.UpdatedAt >= originalUpdatedAt);
    }

    [Fact]
    public async Task CreateManager_PersistsGestorRole()
    {
        var manager = TestData.NewManager();

        await using (var db = CreateContext())
        {
            db.Accounts.Add(manager);
            await db.SaveChangesAsync();
        }

        await using var read = CreateContext();
        var saved = await read.Accounts.SingleAsync(candidate => candidate.Id == manager.Id);

        Assert.Equal(Role.GESTOR, saved.Role);
        Assert.True(saved.Active);
    }

    [Fact]
    public async Task Database_RejectsRoleOutsideContract()
    {
        var account = await SeedAccountAsync();

        await using var db = CreateContext();
        var exception = await Assert.ThrowsAsync<SqlException>(() =>
            db.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE accounts SET role = 'ADMIN' WHERE id = {account.Id}"));

        Assert.Contains("CK_accounts_role", exception.Message, StringComparison.OrdinalIgnoreCase);
    }
}
