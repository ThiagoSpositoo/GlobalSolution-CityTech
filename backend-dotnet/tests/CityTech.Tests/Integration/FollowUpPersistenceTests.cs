using CityTech.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Tests.Integration;

public sealed class FollowUpPersistenceTests : IntegrationTestBase
{
    public FollowUpPersistenceTests(SqlServerFixture fixture)
        : base(fixture)
    {
    }

    [Fact]
    public async Task Create_PersistsOccurrenceReferenceNoteAndNavigation()
    {
        var account = await SeedAccountAsync();
        var occurrenceId = Guid.NewGuid();
        var followUp = FollowUp.Create(account.Id, occurrenceId, "  Acompanhar a triagem.  ");

        await using (var db = CreateContext())
        {
            db.FollowUps.Add(followUp);
            await db.SaveChangesAsync();
        }

        await using (var read = CreateContext())
        {
            var saved = await read.FollowUps
                .Include(candidate => candidate.User)
                .SingleAsync(candidate => candidate.Id == followUp.Id);

            Assert.Equal(account.Id, saved.UserId);
            Assert.Equal(account.Id, saved.User.Id);
            Assert.Equal(occurrenceId, saved.OccurrenceId);
            Assert.Equal("Acompanhar a triagem.", saved.Note);
            Assert.Equal(DateTimeKind.Utc, saved.CreatedAt.Kind);
            Assert.Equal(DateTimeKind.Utc, saved.UpdatedAt.Kind);
            Assert.Equal(0, saved.Version);
        }

        await using (var read = CreateContext())
        {
            var accountWithFollowUps = await read.Accounts
                .Include(candidate => candidate.FollowUps)
                .SingleAsync(candidate => candidate.Id == account.Id);

            Assert.Single(accountWithFollowUps.FollowUps);
        }
    }

    [Fact]
    public async Task Create_WithoutNote_PersistsNull()
    {
        var account = await SeedAccountAsync();
        var followUp = FollowUp.Create(account.Id, Guid.NewGuid());

        await using (var db = CreateContext())
        {
            db.FollowUps.Add(followUp);
            await db.SaveChangesAsync();
        }

        await using var read = CreateContext();
        var saved = await read.FollowUps.SingleAsync(candidate => candidate.Id == followUp.Id);

        Assert.Null(saved.Note);
    }

    [Fact]
    public async Task DuplicateUserOccurrencePair_IsRejectedByUniqueIndex()
    {
        var account = await SeedAccountAsync();
        var occurrenceId = Guid.NewGuid();

        await using var db = CreateContext();
        db.FollowUps.AddRange(
            FollowUp.Create(account.Id, occurrenceId),
            FollowUp.Create(account.Id, occurrenceId));

        var exception = await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());

        Assert.Contains(
            "UX_follow_ups_user_id_occurrence_id",
            exception.InnerException?.Message ?? exception.Message,
            StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task DifferentUsers_CanFollowTheSameOccurrence()
    {
        var first = await SeedAccountAsync("primeiro@example.com");
        var second = await SeedAccountAsync("segundo@example.com");
        var occurrenceId = Guid.NewGuid();

        await using (var db = CreateContext())
        {
            db.FollowUps.AddRange(
                FollowUp.Create(first.Id, occurrenceId),
                FollowUp.Create(second.Id, occurrenceId));
            await db.SaveChangesAsync();
        }

        await using var read = CreateContext();
        var count = await read.FollowUps.CountAsync(candidate => candidate.OccurrenceId == occurrenceId);

        Assert.Equal(2, count);
    }

    [Fact]
    public async Task InvalidUserId_IsRejectedByLocalForeignKey()
    {
        await using var db = CreateContext();
        db.FollowUps.Add(FollowUp.Create(Guid.NewGuid(), Guid.NewGuid()));

        var exception = await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());

        Assert.Contains(
            "FK_follow_ups_accounts_user_id",
            exception.InnerException?.Message ?? exception.Message,
            StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task UpdateNote_IncrementsVersion()
    {
        var account = await SeedAccountAsync();
        var followUp = FollowUp.Create(account.Id, Guid.NewGuid(), "inicial");

        await using (var seed = CreateContext())
        {
            seed.FollowUps.Add(followUp);
            await seed.SaveChangesAsync();
        }

        await using var db = CreateContext();
        var saved = await db.FollowUps.SingleAsync(candidate => candidate.Id == followUp.Id);

        saved.UpdateNote("  atualizada  ");
        await db.SaveChangesAsync();

        Assert.Equal("atualizada", saved.Note);
        Assert.Equal(1, saved.Version);
        Assert.Equal(DateTimeKind.Utc, saved.UpdatedAt.Kind);
    }
}
