using System.Net;
using System.Security.Cryptography;
using CityTech.Api.Services;
using CityTech.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace CityTech.Tests.Api;

public sealed class CityTechApiFactory : WebApplicationFactory<Program>
{
    private readonly string _connectionString;
    private readonly string _environment;
    private readonly string _keyDirectory;

    public CityTechApiFactory(
        string connectionString,
        int loginLimit = 1000,
        string environment = "Testing")
    {
        _connectionString = connectionString;
        _environment = environment;
        _keyDirectory = Path.Combine(
            Path.GetTempPath(),
            "citytech-tests",
            Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(_keyDirectory);

        using var rsa = RSA.Create(2048);
        PrivateKeyPath = Path.Combine(_keyDirectory, "private.pem");
        PublicKeyPath = Path.Combine(_keyDirectory, "public.pem");
        File.WriteAllText(PrivateKeyPath, rsa.ExportRSAPrivateKeyPem());
        File.WriteAllText(PublicKeyPath, rsa.ExportSubjectPublicKeyInfoPem());

        Environment.SetEnvironmentVariable("DOTNET_DB_CONNECTION", connectionString);
        Environment.SetEnvironmentVariable("JWT_PRIVATE_KEY_PATH", PrivateKeyPath);
        Environment.SetEnvironmentVariable("JWT_PUBLIC_KEY_PATH", PublicKeyPath);
        Environment.SetEnvironmentVariable("JWT_ISSUER", "citytech-tests");
        Environment.SetEnvironmentVariable("JWT_AUDIENCE", "citytech-api-tests");
        Environment.SetEnvironmentVariable("JWT_KEY_ID", "test-key");
        Environment.SetEnvironmentVariable("RATE_LIMIT_LOGIN_PER_MINUTE", loginLimit.ToString());
        Environment.SetEnvironmentVariable("MANAGER_SEED_NAME", null);
        Environment.SetEnvironmentVariable("MANAGER_SEED_EMAIL", null);
        Environment.SetEnvironmentVariable("MANAGER_SEED_PASSWORD", null);
    }

    public FakeJavaHandler Java { get; } = new();
    public string PrivateKeyPath { get; }
    public string PublicKeyPath { get; }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment(_environment);
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<DbContextOptions<CityTechDbContext>>();
            services.RemoveAll<CityTechDbContext>();
            services.AddDbContext<CityTechDbContext>(options => options.UseSqlServer(_connectionString));
            services.AddHttpClient<OccurrenceClient>()
                .ConfigurePrimaryHttpMessageHandler(() => Java);
        });
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing && Directory.Exists(_keyDirectory))
        {
            Directory.Delete(_keyDirectory, recursive: true);
        }
    }
}

public sealed class FakeJavaHandler : HttpMessageHandler
{
    public HttpStatusCode OccurrenceStatus { get; set; } = HttpStatusCode.OK;
    public HttpStatusCode HealthStatus { get; set; } = HttpStatusCode.OK;
    public string? LastBearerToken { get; private set; }

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        if (request.RequestUri?.AbsolutePath == "/health/live")
        {
            return Task.FromResult(new HttpResponseMessage(HealthStatus));
        }

        LastBearerToken = request.Headers.Authorization?.Parameter;
        return Task.FromResult(new HttpResponseMessage(OccurrenceStatus)
        {
            Content = new StringContent("{}")
        });
    }
}
