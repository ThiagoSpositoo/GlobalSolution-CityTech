using CityTech.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace CityTech.Api;

/// <summary>
/// Permite executar as ferramentas do EF Core sem iniciar o servidor HTTP.
/// A conexão vem exclusivamente da variável de ambiente, nunca de arquivo versionado.
/// </summary>
public sealed class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<CityTechDbContext>
{
    public CityTechDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("DOTNET_DB_CONNECTION");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Defina DOTNET_DB_CONNECTION para executar as ferramentas do EF Core. " +
                "Consulte backend-dotnet/README.md.");
        }

        var options = new DbContextOptionsBuilder<CityTechDbContext>()
            .UseSqlServer(connectionString)
            .Options;

        return new CityTechDbContext(options);
    }
}
