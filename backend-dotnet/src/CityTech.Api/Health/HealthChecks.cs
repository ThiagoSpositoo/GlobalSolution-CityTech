using CityTech.Api.Services;
using CityTech.Infrastructure.Persistence;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace CityTech.Api.Health;

public sealed class SqlServerHealthCheck(CityTechDbContext db) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default) =>
        await db.Database.CanConnectAsync(cancellationToken)
            ? HealthCheckResult.Healthy()
            : HealthCheckResult.Unhealthy("SQL Server indisponível.");
}

public sealed class JavaApiHealthCheck(OccurrenceClient client) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default) =>
        await client.IsHealthyAsync(cancellationToken)
            ? HealthCheckResult.Healthy()
            : HealthCheckResult.Unhealthy("API Java indisponível.");
}

public static class HealthEndpoints
{
    public static void MapCityTechHealthChecks(this WebApplication app)
    {
        app.MapGet("/health/live", () => Results.Ok(new { status = "UP" })).AllowAnonymous();
        app.MapHealthChecks("/health/ready", new()
        {
            Predicate = check => check.Tags.Contains("ready"),
            ResponseWriter = WriteResponseAsync
        }).AllowAnonymous();
        app.MapHealthChecks("/health", new()
        {
            Predicate = check => check.Name == "sqlServer",
            ResponseWriter = WriteResponseAsync
        }).AllowAnonymous();
    }

    private static Task WriteResponseAsync(HttpContext context, HealthReport report)
    {
        context.Response.ContentType = "application/json; charset=utf-8";
        var body = new
        {
            status = report.Status == HealthStatus.Healthy ? "UP" : "DOWN",
            checks = report.Entries.ToDictionary(
                entry => entry.Key,
                entry => new { status = entry.Value.Status.ToString() })
        };
        return context.Response.WriteAsJsonAsync(body, JsonDefaults.Options);
    }
}
