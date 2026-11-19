using CityTech.Domain.Entities;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;

namespace CityTech.Tests.Integration;

public sealed class ModelConfigurationTests : IntegrationTestBase
{
    public ModelConfigurationTests(SqlServerFixture fixture)
        : base(fixture)
    {
    }

    [Fact]
    public async Task Account_IsMappedWithExpectedColumnsIndexesAndConstraints()
    {
        await using var db = CreateContext();
        var entity = db.GetService<IDesignTimeModel>().Model.FindEntityType(typeof(Account));
        Assert.NotNull(entity);
        Assert.Equal("accounts", entity.GetTableName());

        var primaryKey = entity.FindPrimaryKey();
        Assert.NotNull(primaryKey);
        Assert.Equal("PK_accounts", primaryKey.GetName());
        var id = Assert.Single(primaryKey.Properties);
        Assert.Equal("id", id.GetColumnName());
        Assert.Equal(typeof(Guid), id.ClrType);

        var name = entity.FindProperty(nameof(Account.Name))!;
        Assert.Equal("name", name.GetColumnName());
        Assert.Equal(Account.NameMaxLength, name.GetMaxLength());
        Assert.False(name.IsNullable);

        var email = entity.FindProperty(nameof(Account.Email))!;
        Assert.Equal("email", email.GetColumnName());
        Assert.Equal(Account.EmailMaxLength, email.GetMaxLength());

        var emailNormalized = entity.FindProperty(nameof(Account.EmailNormalized))!;
        Assert.Equal("email_normalized", emailNormalized.GetColumnName());
        Assert.Equal(Account.EmailMaxLength, emailNormalized.GetMaxLength());
        Assert.False(emailNormalized.IsNullable);

        var passwordHash = entity.FindProperty(nameof(Account.PasswordHash))!;
        Assert.Equal("password_hash", passwordHash.GetColumnName());
        Assert.Equal(Account.PasswordHashMaxLength, passwordHash.GetMaxLength());
        Assert.DoesNotContain(entity.GetProperties(), property => property.Name == "Password");

        var role = entity.FindProperty(nameof(Account.Role))!;
        Assert.Equal("role", role.GetColumnName());
        Assert.Equal(20, role.GetMaxLength());
        Assert.Equal(typeof(string), role.GetProviderClrType());

        var version = entity.FindProperty(nameof(Account.Version))!;
        Assert.Equal("bigint", version.GetColumnType());
        Assert.True(version.IsConcurrencyToken);

        var emailIndex = entity.GetIndexes().Single(index =>
            index.Properties.Count == 1 && index.Properties[0].Name == nameof(Account.EmailNormalized));
        Assert.True(emailIndex.IsUnique);
        Assert.Equal("UX_accounts_email_normalized", emailIndex.GetDatabaseName());

        var checkConstraints = entity.GetCheckConstraints().Select(constraint => constraint.Name).ToArray();
        Assert.Contains("CK_accounts_name_length", checkConstraints);
        Assert.Contains("CK_accounts_role", checkConstraints);
        Assert.Contains("CK_accounts_version", checkConstraints);
        Assert.Contains("CK_accounts_email_normalized_lowercase", checkConstraints);

        var followUpsNavigation = entity.FindNavigation(nameof(Account.FollowUps));
        Assert.NotNull(followUpsNavigation);
        Assert.True(followUpsNavigation.IsCollection);
    }

    [Fact]
    public async Task FollowUp_IsMappedWithUniqueUserOccurrenceAndLocalAccountForeignKey()
    {
        await using var db = CreateContext();
        var entity = db.GetService<IDesignTimeModel>().Model.FindEntityType(typeof(FollowUp));
        Assert.NotNull(entity);
        Assert.Equal("follow_ups", entity.GetTableName());

        var occurrenceId = entity.FindProperty(nameof(FollowUp.OccurrenceId))!;
        Assert.Equal("occurrence_id", occurrenceId.GetColumnName());
        Assert.Equal(typeof(Guid), occurrenceId.ClrType);
        Assert.False(occurrenceId.IsNullable);

        var foreignKey = Assert.Single(entity.GetForeignKeys());
        Assert.Equal("FK_follow_ups_accounts_user_id", foreignKey.GetConstraintName());
        Assert.Equal(DeleteBehavior.Cascade, foreignKey.DeleteBehavior);
        Assert.Equal(nameof(FollowUp.UserId), Assert.Single(foreignKey.Properties).Name);
        Assert.Equal(typeof(Account), foreignKey.PrincipalEntityType.ClrType);
        Assert.DoesNotContain(
            entity.GetForeignKeys(),
            candidate => candidate.Properties.Any(property => property.Name == nameof(FollowUp.OccurrenceId)));

        var uniqueIndex = entity.GetIndexes().Single(index =>
            index.Properties.Select(property => property.Name)
                .SequenceEqual(new[] { nameof(FollowUp.UserId), nameof(FollowUp.OccurrenceId) }));
        Assert.True(uniqueIndex.IsUnique);
        Assert.Equal("UX_follow_ups_user_id_occurrence_id", uniqueIndex.GetDatabaseName());

        var note = entity.FindProperty(nameof(FollowUp.Note))!;
        Assert.Equal("note", note.GetColumnName());
        Assert.Equal(FollowUp.NoteMaxLength, note.GetMaxLength());
        Assert.True(note.IsNullable);
    }

    [Fact]
    public async Task IdempotencyRecord_IsMappedWithUniqueScopeKeyAndExpiryIndex()
    {
        await using var db = CreateContext();
        var entity = db.GetService<IDesignTimeModel>().Model.FindEntityType(typeof(IdempotencyRecord));
        Assert.NotNull(entity);
        Assert.Equal("idempotency_records", entity.GetTableName());

        var key = entity.FindProperty(nameof(IdempotencyRecord.Key))!;
        Assert.Equal("idempotency_key", key.GetColumnName());
        Assert.Equal(IdempotencyRecord.KeyMaxLength, key.GetMaxLength());

        var requestHash = entity.FindProperty(nameof(IdempotencyRecord.RequestHash))!;
        Assert.Equal("request_hash", requestHash.GetColumnName());
        Assert.Equal(IdempotencyRecord.RequestHashLength, requestHash.GetMaxLength());

        var responseBody = entity.FindProperty(nameof(IdempotencyRecord.ResponseBody))!;
        Assert.Equal("nvarchar(max)", responseBody.GetColumnType());

        var uniqueIndex = entity.GetIndexes().Single(index =>
            index.Properties.Select(property => property.Name)
                .SequenceEqual(new[] { nameof(IdempotencyRecord.Scope), nameof(IdempotencyRecord.Key) }));
        Assert.True(uniqueIndex.IsUnique);
        Assert.Equal("UX_idempotency_records_scope_key", uniqueIndex.GetDatabaseName());

        var expiryIndex = entity.GetIndexes().Single(index =>
            index.Properties.Count == 1 && index.Properties[0].Name == nameof(IdempotencyRecord.ExpiresAt));
        Assert.False(expiryIndex.IsUnique);
        Assert.Equal("IX_idempotency_records_expires_at", expiryIndex.GetDatabaseName());

        var checkConstraints = entity.GetCheckConstraints().Select(constraint => constraint.Name).ToArray();
        Assert.Contains("CK_idempotency_records_scope_length", checkConstraints);
        Assert.Contains("CK_idempotency_records_key_length", checkConstraints);
        Assert.Contains("CK_idempotency_records_request_hash", checkConstraints);
        Assert.Contains("CK_idempotency_records_status_code", checkConstraints);
        Assert.Contains("CK_idempotency_records_expiry", checkConstraints);
    }

    [Fact]
    public async Task Database_HasMigrationAppliedAndOnlyTheLocalForeignKey()
    {
        await using var connection = new SqlConnection(Fixture.ConnectionString);
        await connection.OpenAsync();

        var tables = await QueryStringsAsync(
            connection,
            "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;");

        Assert.Contains("accounts", tables);
        Assert.Contains("follow_ups", tables);
        Assert.Contains("idempotency_records", tables);

        var foreignKeys = await QueryStringsAsync(
            connection,
            """
            SELECT name
            FROM sys.foreign_keys
            WHERE parent_object_id IN (
                OBJECT_ID('accounts'),
                OBJECT_ID('follow_ups'),
                OBJECT_ID('idempotency_records'))
            ORDER BY name;
            """);

        Assert.Equal(new[] { "FK_follow_ups_accounts_user_id" }, foreignKeys);

        var migrations = await QueryStringsAsync(
            connection,
            "SELECT MigrationId FROM __EFMigrationsHistory ORDER BY MigrationId;");

        Assert.Contains(migrations, migration => migration.EndsWith("_InitialCreate", StringComparison.Ordinal));
    }

    private static async Task<List<string>> QueryStringsAsync(SqlConnection connection, string sql)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = sql;

        await using var reader = await command.ExecuteReaderAsync();
        var values = new List<string>();
        while (await reader.ReadAsync())
        {
            values.Add(reader.GetString(0));
        }

        return values;
    }
}
