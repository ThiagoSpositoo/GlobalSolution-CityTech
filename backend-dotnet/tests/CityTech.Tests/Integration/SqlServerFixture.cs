using CityTech.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Tests.Integration;

/// <summary>
/// Fixture de integração com o SQL Server local. O banco de teste é derivado do banco
/// configurado com o sufixo <c>_Test</c>; a limpeza só é permitida nesse sufixo.
/// </summary>
public sealed class SqlServerFixture : IAsyncLifetime
{
    private const string TestDatabaseSuffix = "_Test";
    private string _databaseName = null!;

    public string ConnectionString { get; private set; } = null!;

    public DbContextOptions<CityTechDbContext> Options { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        var configured = Environment.GetEnvironmentVariable("DOTNET_DB_CONNECTION");
        if (string.IsNullOrWhiteSpace(configured))
        {
            throw new InvalidOperationException(
                "Defina DOTNET_DB_CONNECTION para executar os testes de integração. " +
                "Consulte backend-dotnet/README.md.");
        }

        var builder = new SqlConnectionStringBuilder(configured);
        if (string.IsNullOrWhiteSpace(builder.InitialCatalog))
        {
            throw new InvalidOperationException(
                "A conexão de DOTNET_DB_CONNECTION deve informar Database ou Initial Catalog.");
        }

        _databaseName = builder.InitialCatalog.EndsWith(TestDatabaseSuffix, StringComparison.OrdinalIgnoreCase)
            ? builder.InitialCatalog
            : builder.InitialCatalog + TestDatabaseSuffix;

        var masterBuilder = new SqlConnectionStringBuilder(configured) { InitialCatalog = "master" };
        await using (var connection = new SqlConnection(masterBuilder.ConnectionString))
        {
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText =
                """
                IF DB_ID(@name) IS NULL
                BEGIN
                    DECLARE @sql nvarchar(max) = N'CREATE DATABASE ' + QUOTENAME(@name);
                    EXEC(@sql);
                END;
                """;
            command.Parameters.AddWithValue("@name", _databaseName);
            await command.ExecuteNonQueryAsync();
        }

        builder.InitialCatalog = _databaseName;
        ConnectionString = builder.ConnectionString;
        Options = new DbContextOptionsBuilder<CityTechDbContext>()
            .UseSqlServer(ConnectionString)
            .Options;

        await using var db = CreateContext();
        await db.Database.MigrateAsync();
    }

    public CityTechDbContext CreateContext() => new(Options);

    /// <summary>Remove apenas linhas do banco de teste; nunca remove o banco ou volumes.</summary>
    public async Task ResetAsync()
    {
        if (!_databaseName.EndsWith(TestDatabaseSuffix, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Limpeza bloqueada: o banco de teste precisa terminar em _Test.");
        }

        await using var db = CreateContext();
        await db.Database.ExecuteSqlRawAsync(
            "DELETE FROM follow_ups; DELETE FROM accounts; DELETE FROM idempotency_records;");
    }

    public Task DisposeAsync() => Task.CompletedTask;
}

[CollectionDefinition("SqlServer")]
public sealed class SqlServerCollection : ICollectionFixture<SqlServerFixture>
{
}
