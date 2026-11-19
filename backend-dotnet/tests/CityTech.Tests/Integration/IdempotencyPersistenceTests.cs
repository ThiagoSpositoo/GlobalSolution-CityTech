using CityTech.Domain.Entities;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Tests.Integration;

public sealed class IdempotencyPersistenceTests : IntegrationTestBase
{
    public IdempotencyPersistenceTests(SqlServerFixture fixture)
        : base(fixture)
    {
    }

    [Fact]
    public async Task Create_PersistsOriginalResponseAndRetentionWindow()
    {
        var key = Guid.NewGuid().ToString();
        var requestBody = """{"occurrenceId":"7f5e6d4c-3b2a-1f00-9e8d-7c6b5a493827"}""";
        var record = IdempotencyRecord.Create(
            "POST:/api/v1/followups:user-1",
            key,
            TestData.RequestHash(requestBody),
            201,
            """{"id":"16fd2706-8baf-433b-82eb-8c7fada847da"}""");

        await using (var db = CreateContext())
        {
            db.IdempotencyRecords.Add(record);
            await db.SaveChangesAsync();
        }

        await using var read = CreateContext();
        var saved = await read.IdempotencyRecords.SingleAsync(candidate => candidate.Id == record.Id);

        Assert.Equal(record.Scope, saved.Scope);
        Assert.Equal(key, saved.Key);
        Assert.Equal(64, saved.RequestHash.Length);
        Assert.Equal(201, saved.StatusCode);
        Assert.Contains("16fd2706", saved.ResponseBody, StringComparison.Ordinal);
        Assert.Equal(DateTimeKind.Utc, saved.CreatedAt.Kind);
        Assert.Equal(DateTimeKind.Utc, saved.ExpiresAt.Kind);
        Assert.True(saved.ExpiresAt - saved.CreatedAt >= TimeSpan.FromHours(24));
    }

    [Fact]
    public async Task DuplicateScopeAndKey_IsRejectedByUniqueIndex()
    {
        var scope = "POST:/api/v1/followups:user-1";
        var key = Guid.NewGuid().ToString();

        await using var db = CreateContext();
        db.IdempotencyRecords.AddRange(
            IdempotencyRecord.Create(scope, key, TestData.RequestHash("corpo"), 201, "{}"),
            IdempotencyRecord.Create(scope, key, TestData.RequestHash("corpo"), 201, "{}"));

        var exception = await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());

        Assert.Contains(
            "UX_idempotency_records_scope_key",
            exception.InnerException?.Message ?? exception.Message,
            StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SameKey_CanBeUsedInDifferentScopes()
    {
        var key = Guid.NewGuid().ToString();

        await using (var db = CreateContext())
        {
            db.IdempotencyRecords.AddRange(
                IdempotencyRecord.Create("POST:/api/v1/followups:user-1", key, TestData.RequestHash("corpo"), 201, "{}"),
                IdempotencyRecord.Create("POST:/api/v1/followups:user-2", key, TestData.RequestHash("corpo"), 201, "{}"));
            await db.SaveChangesAsync();
        }

        await using var read = CreateContext();
        var count = await read.IdempotencyRecords.CountAsync(candidate => candidate.Key == key);

        Assert.Equal(2, count);
    }

    [Fact]
    public async Task Database_RejectsInvalidStatusCode()
    {
        var record = IdempotencyRecord.Create(
            "POST:/api/v1/followups:user-1",
            Guid.NewGuid().ToString(),
            TestData.RequestHash("corpo"),
            201,
            "{}");

        await using (var seed = CreateContext())
        {
            seed.IdempotencyRecords.Add(record);
            await seed.SaveChangesAsync();
        }

        await using var db = CreateContext();
        var exception = await Assert.ThrowsAsync<SqlException>(() =>
            db.Database.ExecuteSqlInterpolatedAsync(
                $"UPDATE idempotency_records SET status_code = 99 WHERE id = {record.Id}"));

        Assert.Contains("CK_idempotency_records_status_code", exception.Message, StringComparison.OrdinalIgnoreCase);
    }
}
