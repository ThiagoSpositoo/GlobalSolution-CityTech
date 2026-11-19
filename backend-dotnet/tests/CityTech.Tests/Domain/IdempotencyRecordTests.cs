using CityTech.Domain.Entities;

namespace CityTech.Tests.Domain;

public sealed class IdempotencyRecordTests
{
    private static readonly string ValidHash = TestData.RequestHash("corpo");

    [Fact]
    public void Create_WithValidData_NormalizesHashAndSetsRetention()
    {
        var record = IdempotencyRecord.Create(
            "POST:/api/v1/followups:user-1",
            "chave-valida",
            ValidHash.ToUpperInvariant(),
            201,
            "{}");

        Assert.NotEqual(Guid.Empty, record.Id);
        Assert.Equal(ValidHash, record.RequestHash);
        Assert.Equal(64, record.RequestHash.Length);
        Assert.Equal(201, record.StatusCode);
        Assert.Equal(DateTimeKind.Utc, record.CreatedAt.Kind);
        Assert.Equal(DateTimeKind.Utc, record.ExpiresAt.Kind);
        Assert.True(record.ExpiresAt - record.CreatedAt >= IdempotencyRecord.MinimumRetention);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Create_WithInvalidScope_Throws(string scope)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            IdempotencyRecord.Create(scope, "chave-valida", ValidHash, 201, "{}"));
    }

    [Fact]
    public void Create_WithScopeTooLong_Throws()
    {
        var scope = new string('a', IdempotencyRecord.ScopeMaxLength + 1);

        Assert.ThrowsAny<ArgumentException>(() =>
            IdempotencyRecord.Create(scope, "chave-valida", ValidHash, 201, "{}"));
    }

    [Theory]
    [InlineData("1234567")]
    [InlineData("")]
    public void Create_WithInvalidKeyLength_Throws(string key)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            IdempotencyRecord.Create("escopo", key, ValidHash, 201, "{}"));
    }

    [Fact]
    public void Create_WithKeyTooLong_Throws()
    {
        var key = new string('a', IdempotencyRecord.KeyMaxLength + 1);

        Assert.ThrowsAny<ArgumentException>(() =>
            IdempotencyRecord.Create("escopo", key, ValidHash, 201, "{}"));
    }

    [Theory]
    [InlineData("")]
    [InlineData("nao-e-sha256")]
    [InlineData("zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz")]
    public void Create_WithInvalidRequestHash_Throws(string requestHash)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            IdempotencyRecord.Create("escopo", "chave-valida", requestHash, 201, "{}"));
    }

    [Theory]
    [InlineData(99)]
    [InlineData(600)]
    public void Create_WithInvalidStatusCode_Throws(int statusCode)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            IdempotencyRecord.Create("escopo", "chave-valida", ValidHash, statusCode, "{}"));
    }

    [Fact]
    public void Create_WithRetentionShorterThanMinimum_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            IdempotencyRecord.Create(
                "escopo",
                "chave-valida",
                ValidHash,
                201,
                "{}",
                IdempotencyRecord.MinimumRetention - TimeSpan.FromSeconds(1)));
    }

    [Fact]
    public void Create_WithNullResponseBody_Throws()
    {
        Assert.Throws<ArgumentNullException>(() =>
            IdempotencyRecord.Create("escopo", "chave-valida", ValidHash, 201, null!));
    }
}
