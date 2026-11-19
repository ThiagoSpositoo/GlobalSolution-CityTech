using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using CityTech.Api.Contracts;
using CityTech.Api.Services;
using CityTech.Domain.Enums;
using CityTech.Tests.Integration;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Tests.Api;

[Collection("SqlServer")]
public sealed class ApiEndpointTests : IAsyncLifetime, IDisposable
{
    private readonly SqlServerFixture _fixture;
    private readonly CityTechApiFactory _factory;
    private readonly HttpClient _client;

    public ApiEndpointTests(SqlServerFixture fixture)
    {
        _fixture = fixture;
        _factory = new CityTechApiFactory(fixture.ConnectionString);
        _client = _factory.CreateClient();
    }

    public Task InitializeAsync() => _fixture.ResetAsync();
    public Task DisposeAsync() => Task.CompletedTask;

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    [Fact]
    public async Task Register_ReplaysSameResponse_AndRejectsChangedBody()
    {
        const string key = "register-key-0001";
        var request = new RegisterRequest("Pessoa Teste", "pessoa@example.test", "Senha123");

        var first = await PostJsonAsync("/api/v1/auth/register", request, key);
        var replay = await PostJsonAsync("/api/v1/auth/register", request, key);
        var conflict = await PostJsonAsync(
            "/api/v1/auth/register",
            request with { Name = "Outro Nome" },
            key);

        Assert.Equal(HttpStatusCode.Created, first.StatusCode);
        Assert.Equal(HttpStatusCode.Created, replay.StatusCode);
        Assert.Equal("true", replay.Headers.GetValues("Idempotent-Replayed").Single());
        Assert.Equal(
            await first.Content.ReadAsStringAsync(),
            await replay.Content.ReadAsStringAsync());
        Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode);
        Assert.Equal("IDEMPOTENCY_CONFLICT", await ErrorCodeAsync(conflict));
    }

    [Fact]
    public async Task Register_ValidatesFields_AndReturnsStringRole()
    {
        var invalid = await PostJsonAsync(
            "/api/v1/auth/register",
            new RegisterRequest("x", "invalido", "fraca"),
            "register-key-0002");
        var valid = await RegisterAsync("cidadao@example.test", "register-key-0003");

        Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode);
        using var invalidJson = JsonDocument.Parse(await invalid.Content.ReadAsStringAsync());
        var fields = invalidJson.RootElement.GetProperty("errors")
            .EnumerateArray()
            .Select(item => item.GetProperty("field").GetString())
            .ToArray();
        Assert.Contains("name", fields);
        Assert.Contains("email", fields);
        Assert.Contains("password", fields);

        Assert.Equal(HttpStatusCode.Created, valid.StatusCode);
        using var validJson = JsonDocument.Parse(await valid.Content.ReadAsStringAsync());
        Assert.Equal("CIDADAO", validJson.RootElement.GetProperty("role").GetString());
        Assert.False(validJson.RootElement.TryGetProperty("password", out _));
        Assert.False(validJson.RootElement.TryGetProperty("passwordHash", out _));
    }

    [Fact]
    public async Task Register_DuplicateEmailWithAnotherKey_ReturnsStableConflict()
    {
        await RegisterAsync("duplicado@example.test", "register-key-0004");

        var duplicate = await RegisterAsync("DUPLICADO@example.test", "register-key-0005");
        var replay = await RegisterAsync("DUPLICADO@example.test", "register-key-0005");

        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);
        Assert.Equal("EMAIL_ALREADY_EXISTS", await ErrorCodeAsync(duplicate));
        Assert.Equal(HttpStatusCode.Conflict, replay.StatusCode);
        Assert.Equal("true", replay.Headers.GetValues("Idempotent-Replayed").Single());
    }

    [Fact]
    public async Task Register_ConcurrentSameKey_PersistsOneEffectAndReplaysResponse()
    {
        const string key = "register-concurrent-key";
        var request = new RegisterRequest(
            "Pessoa Concorrente",
            "concorrente@example.test",
            "Senha123");

        var responses = await Task.WhenAll(
            PostJsonAsync("/api/v1/auth/register", request, key),
            PostJsonAsync("/api/v1/auth/register", request, key));

        Assert.All(responses, response => Assert.Equal(HttpStatusCode.Created, response.StatusCode));
        Assert.Single(responses, response =>
            response.Headers.TryGetValues("Idempotent-Replayed", out var values)
            && values.Single() == "true");

        await using var db = _fixture.CreateContext();
        Assert.Equal(1, await db.Accounts.CountAsync());
        Assert.Equal(1, await db.IdempotencyRecords.CountAsync());
    }

    [Fact]
    public async Task Login_EmitsRs256Token_AndMeRequiresAuthentication()
    {
        await RegisterAsync("login@example.test", "register-key-0006");
        var unauthorized = await _client.GetAsync("/api/v1/auth/me");
        var wrongPassword = await _client.PostAsJsonAsync(
            "/api/v1/auth/login",
            new LoginRequest("login@example.test", "Errada123"));
        var login = await LoginAsync("login@example.test");
        var payload = await login.Content.ReadFromJsonAsync<LoginResponse>(JsonDefaults.Options);

        Assert.Equal(HttpStatusCode.Unauthorized, unauthorized.StatusCode);
        Assert.Equal("UNAUTHORIZED", await ErrorCodeAsync(unauthorized));
        Assert.Equal(HttpStatusCode.Unauthorized, wrongPassword.StatusCode);
        Assert.NotNull(payload);

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(payload.AccessToken);
        Assert.Equal("RS256", jwt.Header.Alg);
        Assert.Equal("test-key", jwt.Header.Kid);
        Assert.Equal("citytech-tests", jwt.Issuer);
        Assert.Contains("citytech-api-tests", jwt.Audiences);
        Assert.NotEqual(default, jwt.Payload.IssuedAt);
        Assert.Equal("CIDADAO", jwt.Claims.Single(claim => claim.Type == "roles").Value);

        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", payload.AccessToken);
        var me = await _client.GetAsync("/api/v1/auth/me");
        Assert.Equal(HttpStatusCode.OK, me.StatusCode);
        using var meJson = JsonDocument.Parse(await me.Content.ReadAsStringAsync());
        Assert.Equal("CIDADAO", meJson.RootElement.GetProperty("role").GetString());
    }

    [Fact]
    public async Task FollowUp_CrudPreservesOwnershipVersionAndIdempotentLocation()
    {
        var token = await RegisterAndLoginAsync("dono@example.test", "register-key-0007");
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var occurrenceId = Guid.NewGuid();
        var createRequest = new CreateFollowUpRequest(occurrenceId, "  Acompanhar  ");

        var created = await PostJsonAsync("/api/v1/followups", createRequest, "followup-key-0001");
        var replay = await PostJsonAsync("/api/v1/followups", createRequest, "followup-key-0001");

        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        Assert.Equal(created.Headers.Location, replay.Headers.Location);
        Assert.Equal("true", replay.Headers.GetValues("Idempotent-Replayed").Single());
        Assert.False(string.IsNullOrWhiteSpace(_factory.Java.LastBearerToken));

        var item = await created.Content.ReadFromJsonAsync<FollowUpResponse>(JsonDefaults.Options);
        Assert.NotNull(item);
        Assert.Equal("Acompanhar", item.Note);

        var listed = await _client.GetFromJsonAsync<PageResponse<FollowUpResponse>>(
            "/api/v1/followups?page=0&size=20&sort=createdAt,desc",
            JsonDefaults.Options);
        Assert.NotNull(listed);
        Assert.Single(listed.Items);

        var updated = await _client.PatchAsJsonAsync(
            $"/api/v1/followups/{item.Id}",
            new UpdateFollowUpRequest(item.Version, "Atualizada"));
        Assert.Equal(HttpStatusCode.OK, updated.StatusCode);
        var updatedItem = await updated.Content.ReadFromJsonAsync<FollowUpResponse>(JsonDefaults.Options);
        Assert.Equal(item.Version + 1, updatedItem!.Version);

        var stale = await _client.PatchAsJsonAsync(
            $"/api/v1/followups/{item.Id}",
            new UpdateFollowUpRequest(item.Version, "Conflito"));
        Assert.Equal(HttpStatusCode.Conflict, stale.StatusCode);
        Assert.Equal("CONCURRENT_MODIFICATION", await ErrorCodeAsync(stale));

        var missingVersion = await _client.PatchAsJsonAsync(
            $"/api/v1/followups/{item.Id}",
            new { note = "Sem versão" });
        Assert.Equal(HttpStatusCode.BadRequest, missingVersion.StatusCode);

        var deleted = await _client.DeleteAsync($"/api/v1/followups/{item.Id}");
        var deletedAgain = await _client.DeleteAsync($"/api/v1/followups/{item.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, deletedAgain.StatusCode);
    }

    [Fact]
    public async Task FollowUp_IsInvisibleToAnotherAccount()
    {
        var ownerToken = await RegisterAndLoginAsync("owner@example.test", "register-key-0008");
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", ownerToken);
        var created = await PostJsonAsync(
            "/api/v1/followups",
            new CreateFollowUpRequest(Guid.NewGuid(), null),
            "followup-key-0002");
        var item = await created.Content.ReadFromJsonAsync<FollowUpResponse>(JsonDefaults.Options);

        var otherToken = await RegisterAndLoginAsync("other@example.test", "register-key-0009");
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", otherToken);
        var hidden = await _client.GetAsync($"/api/v1/followups/{item!.Id}");

        Assert.Equal(HttpStatusCode.NotFound, hidden.StatusCode);
        Assert.Equal("NOT_FOUND", await ErrorCodeAsync(hidden));
    }

    [Theory]
    [InlineData(HttpStatusCode.NotFound, HttpStatusCode.NotFound, "OCCURRENCE_NOT_FOUND")]
    [InlineData(HttpStatusCode.Forbidden, HttpStatusCode.NotFound, "OCCURRENCE_NOT_FOUND")]
    [InlineData(HttpStatusCode.ServiceUnavailable, HttpStatusCode.ServiceUnavailable, "OCCURRENCE_SERVICE_UNAVAILABLE")]
    public async Task FollowUp_MapsJavaFailures(
        HttpStatusCode javaStatus,
        HttpStatusCode expectedStatus,
        string expectedCode)
    {
        var token = await RegisterAndLoginAsync(
            $"java-{(int)javaStatus}@example.test",
            $"register-java-{(int)javaStatus}");
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);
        _factory.Java.OccurrenceStatus = javaStatus;

        var response = await PostJsonAsync(
            "/api/v1/followups",
            new CreateFollowUpRequest(Guid.NewGuid(), null),
            $"followup-java-{(int)javaStatus}");

        Assert.Equal(expectedStatus, response.StatusCode);
        Assert.Equal(expectedCode, await ErrorCodeAsync(response));
    }

    [Fact]
    public async Task HealthChecks_ReportLivenessAndDependencyReadiness()
    {
        var live = await _client.GetAsync("/health/live");
        var ready = await _client.GetAsync("/health/ready");
        _factory.Java.HealthStatus = HttpStatusCode.ServiceUnavailable;
        var unavailable = await _client.GetAsync("/health/ready");

        Assert.Equal(HttpStatusCode.OK, live.StatusCode);
        Assert.Equal(HttpStatusCode.OK, ready.StatusCode);
        Assert.Equal(HttpStatusCode.ServiceUnavailable, unavailable.StatusCode);
    }

    [Fact]
    public async Task OpenApi_DescribesImplementedEndpointsAndBearerSecurity()
    {
        var response = await _client.GetAsync("/swagger/v1/swagger.json");
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var paths = document.RootElement.GetProperty("paths");
        Assert.True(paths.TryGetProperty("/api/v1/auth/login", out _));
        Assert.True(paths.TryGetProperty("/api/v1/followups", out _));
        Assert.True(
            document.RootElement
                .GetProperty("components")
                .GetProperty("securitySchemes")
                .TryGetProperty("Bearer", out _));
    }

    [Fact]
    public async Task DevelopmentCors_AllowsLoopbackPortsAndAnyHeaderButRejectsExternalOrigins()
    {
        const string allowedOrigin = "http://localhost:8082";
        using var developmentFactory = new CityTechApiFactory(
            _fixture.ConnectionString,
            environment: "Development");
        using var client = developmentFactory.CreateClient();

        using var preflight = new HttpRequestMessage(HttpMethod.Options, "/api/v1/auth/register");
        preflight.Headers.Add("Origin", allowedOrigin);
        preflight.Headers.Add("Access-Control-Request-Method", "POST");
        preflight.Headers.Add(
            "Access-Control-Request-Headers",
            "Authorization, Content-Type, Idempotency-Key, X-Local-Debug");
        var allowed = await client.SendAsync(preflight);

        Assert.Equal(HttpStatusCode.NoContent, allowed.StatusCode);
        Assert.Equal(
            allowedOrigin,
            allowed.Headers.GetValues("Access-Control-Allow-Origin").Single());
        Assert.Contains(
            "POST",
            string.Join(',', allowed.Headers.GetValues("Access-Control-Allow-Methods")));
        Assert.Contains(
            "X-Local-Debug",
            string.Join(',', allowed.Headers.GetValues("Access-Control-Allow-Headers")),
            StringComparison.OrdinalIgnoreCase);

        using var actualRequest = new HttpRequestMessage(HttpMethod.Get, "/");
        actualRequest.Headers.Add("Origin", allowedOrigin);
        var actual = await client.SendAsync(actualRequest);
        var exposed = string.Join(',', actual.Headers.GetValues("Access-Control-Expose-Headers"));
        Assert.Contains("Retry-After", exposed, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("Idempotent-Replayed", exposed, StringComparison.OrdinalIgnoreCase);

        using var deniedRequest = new HttpRequestMessage(HttpMethod.Options, "/api/v1/auth/register");
        deniedRequest.Headers.Add("Origin", "https://not-allowed.example");
        deniedRequest.Headers.Add("Access-Control-Request-Method", "POST");
        var denied = await client.SendAsync(deniedRequest);
        Assert.False(denied.Headers.Contains("Access-Control-Allow-Origin"));

        using var testingRequest = new HttpRequestMessage(HttpMethod.Get, "/");
        testingRequest.Headers.Add("Origin", allowedOrigin);
        var testing = await _client.SendAsync(testingRequest);
        Assert.False(testing.Headers.Contains("Access-Control-Allow-Origin"));
    }

    [Fact]
    public async Task MalformedJson_ReturnsValidationEnvelope()
    {
        using var content = new StringContent("{", Encoding.UTF8, "application/json");
        var response = await _client.PostAsync("/api/v1/auth/login", content);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("VALIDATION_ERROR", await ErrorCodeAsync(response));
    }

    [Fact]
    public async Task LoginRateLimit_Returns429AndRetryAfter()
    {
        using var limitedFactory = new CityTechApiFactory(_fixture.ConnectionString, loginLimit: 1);
        using var client = limitedFactory.CreateClient();

        var first = await client.PostAsJsonAsync(
            "/api/v1/auth/login",
            new LoginRequest("ausente@example.test", "Senha123"));
        var limited = await client.PostAsJsonAsync(
            "/api/v1/auth/login",
            new LoginRequest("ausente@example.test", "Senha123"));

        Assert.Equal(HttpStatusCode.Unauthorized, first.StatusCode);
        Assert.Equal((HttpStatusCode)429, limited.StatusCode);
        Assert.True(limited.Headers.RetryAfter?.Delta > TimeSpan.Zero);
        Assert.Equal("RATE_LIMITED", await ErrorCodeAsync(limited));
    }

    private Task<HttpResponseMessage> RegisterAsync(string email, string key) =>
        PostJsonAsync(
            "/api/v1/auth/register",
            new RegisterRequest("Pessoa Teste", email, "Senha123"),
            key);

    private Task<HttpResponseMessage> LoginAsync(string email) =>
        _client.PostAsJsonAsync(
            "/api/v1/auth/login",
            new LoginRequest(email, "Senha123"));

    private async Task<string> RegisterAndLoginAsync(string email, string key)
    {
        var registered = await RegisterAsync(email, key);
        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);
        var login = await LoginAsync(email);
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        return (await login.Content.ReadFromJsonAsync<LoginResponse>(JsonDefaults.Options))!.AccessToken;
    }

    private async Task<HttpResponseMessage> PostJsonAsync<T>(string path, T body, string idempotencyKey)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, path)
        {
            Content = JsonContent.Create(body)
        };
        request.Headers.Add("Idempotency-Key", idempotencyKey);
        return await _client.SendAsync(request);
    }

    private static async Task<string?> ErrorCodeAsync(HttpResponseMessage response)
    {
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return json.RootElement.GetProperty("code").GetString();
    }
}
