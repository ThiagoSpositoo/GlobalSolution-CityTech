using CityTech.Api.Security;
using CityTech.Api.Services;
using CityTech.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;

namespace CityTech.Tests.Integration;

public sealed class ManagerSeederTests(SqlServerFixture fixture) : IntegrationTestBase(fixture)
{
    [Fact]
    public async Task SeedAsync_IsExplicitIdempotentAndCreatesGestor()
    {
        Environment.SetEnvironmentVariable("MANAGER_SEED_NAME", "Gestora Local");
        Environment.SetEnvironmentVariable("MANAGER_SEED_EMAIL", "gestora@example.test");
        Environment.SetEnvironmentVariable("MANAGER_SEED_PASSWORD", "SenhaGestor123");
        try
        {
            await using var db = CreateContext();
            var seeder = new ManagerSeeder(
                db,
                new PasswordService(),
                NullLogger<ManagerSeeder>.Instance);

            await seeder.SeedAsync();
            await seeder.SeedAsync();

            var manager = await db.Accounts.AsNoTracking().SingleAsync();
            Assert.Equal(Role.GESTOR, manager.Role);
            Assert.Equal("gestora@example.test", manager.EmailNormalized);
            Assert.DoesNotContain("SenhaGestor123", manager.PasswordHash);
        }
        finally
        {
            Environment.SetEnvironmentVariable("MANAGER_SEED_NAME", null);
            Environment.SetEnvironmentVariable("MANAGER_SEED_EMAIL", null);
            Environment.SetEnvironmentVariable("MANAGER_SEED_PASSWORD", null);
        }
    }
}
