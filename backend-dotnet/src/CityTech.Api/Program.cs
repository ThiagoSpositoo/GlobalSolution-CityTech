using System.Security.Claims;
using System.Text.Json;
using System.Threading.RateLimiting;
using CityTech.Api.Endpoints;
using CityTech.Api.Health;
using CityTech.Api.Security;
using CityTech.Api.Services;
using CityTech.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

var connectionString = Environment.GetEnvironmentVariable("DOTNET_DB_CONNECTION");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "Defina a variável de ambiente DOTNET_DB_CONNECTION com a conexão do SQL Server. " +
        "Consulte backend-dotnet/README.md.");
}

var jwtOptions = JwtOptions.FromEnvironment();
builder.Services.AddSingleton(jwtOptions);
builder.Services.AddSingleton<RsaKeyProvider>();
builder.Services.AddScoped<PasswordService>();
builder.Services.AddScoped<JwtTokenService>();
builder.Services.AddScoped<IdempotencyService>();
builder.Services.AddScoped<ManagerSeeder>();
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter()));

builder.Services.AddDbContext<CityTechDbContext>(options =>
    options.UseSqlServer(connectionString, sql =>
        sql.MigrationsAssembly(typeof(CityTechDbContext).Assembly.GetName().Name!)));

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        using var rsa = System.Security.Cryptography.RSA.Create();
        rsa.ImportFromPem(File.ReadAllText(jwtOptions.PublicKeyPath));
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new RsaSecurityKey(rsa.ExportParameters(false)) { KeyId = jwtOptions.KeyId },
            ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
            ValidateIssuer = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtOptions.Audience,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(60),
            NameClaimType = "name",
            RoleClaimType = "roles"
        };
        options.Events = AuthenticationEvents.Create();
    });
builder.Services.AddAuthorization();

const string developmentCorsPolicy = "DevelopmentCors";
if (builder.Environment.IsDevelopment())
{
    var originsFromEnvironment = Environment.GetEnvironmentVariable("CORS_ALLOWED_ORIGINS");
    var allowedOrigins = string.IsNullOrWhiteSpace(originsFromEnvironment)
        ? builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? []
        : originsFromEnvironment.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
    if (allowedOrigins.Length == 0)
    {
        throw new InvalidOperationException(
            "Configure ao menos uma origem em Cors:AllowedOrigins ou CORS_ALLOWED_ORIGINS.");
    }

    builder.Services.AddCors(options => options.AddPolicy(
        developmentCorsPolicy,
        policy => policy
            .SetIsOriginAllowed(origin =>
            {
                if (allowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase))
                {
                    return true;
                }

                return Uri.TryCreate(origin, UriKind.Absolute, out var uri)
                    && (uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase)
                        || System.Net.IPAddress.TryParse(uri.Host, out var address)
                            && System.Net.IPAddress.IsLoopback(address));
            })
            .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
            .AllowAnyHeader()
            .WithExposedHeaders("Retry-After", "Idempotent-Replayed", "Location")
            .SetPreflightMaxAge(TimeSpan.FromHours(1))));
}

var javaBaseUrl = Environment.GetEnvironmentVariable("JAVA_API_BASE_URL") ?? "http://localhost:8080";
builder.Services.AddHttpClient<OccurrenceClient>(client =>
{
    client.BaseAddress = new Uri(javaBaseUrl);
    client.Timeout = TimeSpan.FromSeconds(5);
});

builder.Services.AddHealthChecks()
    .AddCheck<SqlServerHealthCheck>("sqlServer", tags: ["ready"])
    .AddCheck<JavaApiHealthCheck>("javaApi", tags: ["ready"]);

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = RateLimitResponses.WriteAsync;
    options.AddPolicy("login", context => FixedWindow(
        $"login:{context.Connection.RemoteIpAddress}",
        EnvironmentValue.Int("RATE_LIMIT_LOGIN_PER_MINUTE", 10),
        TimeSpan.FromMinutes(1)));
    options.AddPolicy("register", context => FixedWindow(
        $"register:{context.Connection.RemoteIpAddress}",
        EnvironmentValue.Int("RATE_LIMIT_REGISTER_PER_HOUR", 5),
        TimeSpan.FromHours(1)));
    options.AddPolicy("followups-write", context => FixedWindow(
        $"followups:{context.User.FindFirstValue("sub") ?? context.Connection.RemoteIpAddress?.ToString()}",
        EnvironmentValue.Int("RATE_LIMIT_FOLLOWUPS_PER_MINUTE", 60),
        TimeSpan.FromMinutes(1)));
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "CityTech API .NET",
        Version = "v1",
        Description = "Identidade, autenticação e acompanhamentos do CityTech."
    });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "JWT RS256 emitido por POST /api/v1/auth/login."
    });
    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = []
    });
});

var app = builder.Build();
await using (var scope = app.Services.CreateAsyncScope())
{
    await scope.ServiceProvider.GetRequiredService<ManagerSeeder>().SeedAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseCors(developmentCorsPolicy);
}
app.UseMiddleware<ApiExceptionMiddleware>();
app.UseStatusCodePages(async statusCodeContext =>
{
    var response = statusCodeContext.HttpContext.Response;
    if (response.StatusCode == StatusCodes.Status400BadRequest)
    {
        response.ContentType = "application/json; charset=utf-8";
        await response.WriteAsJsonAsync(
            ApiErrors.Create(
                statusCodeContext.HttpContext,
                400,
                "VALIDATION_ERROR",
                "Requisição inválida",
                "O corpo JSON está ausente ou malformado."),
            JsonDefaults.Options);
    }
});
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "CityTech API .NET v1");
    options.RoutePrefix = "swagger";
});
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => Results.Ok(new { service = "CityTech.Api", status = "ok" }))
    .AllowAnonymous();
app.MapCityTechHealthChecks();
app.MapAuthEndpoints();
app.MapFollowUpEndpoints();

app.Run();

static RateLimitPartition<string> FixedWindow(string key, int permitLimit, TimeSpan window) =>
    RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
    {
        PermitLimit = permitLimit,
        Window = window,
        QueueLimit = 0,
        AutoReplenishment = true
    });

public partial class Program;
