using CityTech.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Tests.Integration;

public sealed class ConcurrencyTests : IntegrationTestBase
{
    public ConcurrencyTests(SqlServerFixture fixture)
        : base(fixture)
    {
    }

    [Fact]
    public async Task FollowUp_WithStaleVersion_ThrowsConcurrencyException()
    {
        var account = await SeedAccountAsync();
        var followUp = FollowUp.Create(account.Id, Guid.NewGuid(), "inicial");

        await using (var seed = CreateContext())
        {
            seed.FollowUps.Add(followUp);
            await seed.SaveChangesAsync();
        }

        await using var first = CreateContext();
        await using var second = CreateContext();

        var firstCopy = await first.FollowUps.SingleAsync(candidate => candidate.Id == followUp.Id);
        var secondCopy = await second.FollowUps.SingleAsync(candidate => candidate.Id == followUp.Id);

        firstCopy.UpdateNote("primeira alteração");
        await first.SaveChangesAsync();
        Assert.Equal(1, firstCopy.Version);

        secondCopy.UpdateNote("segunda alteração");
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => second.SaveChangesAsync());

        await using var read = CreateContext();
        var final = await read.FollowUps.SingleAsync(candidate => candidate.Id == followUp.Id);

        Assert.Equal("primeira alteração", final.Note);
        Assert.Equal(1, final.Version);
    }

    [Fact]
    public async Task Account_WithStaleVersion_ThrowsConcurrencyException()
    {
        var account = await SeedAccountAsync();

        await using var first = CreateContext();
        await using var second = CreateContext();

        var firstCopy = await first.Accounts.SingleAsync(candidate => candidate.Id == account.Id);
        var secondCopy = await second.Accounts.SingleAsync(candidate => candidate.Id == account.Id);

        firstCopy.Rename("Primeiro nome");
        await first.SaveChangesAsync();
        Assert.Equal(1, firstCopy.Version);

        secondCopy.Rename("Segundo nome");
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => second.SaveChangesAsync());

        await using var read = CreateContext();
        var final = await read.Accounts.SingleAsync(candidate => candidate.Id == account.Id);

        Assert.Equal("Primeiro nome", final.Name);
        Assert.Equal(1, final.Version);
    }
}
