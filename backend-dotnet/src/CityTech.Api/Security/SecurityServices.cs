using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using CityTech.Api.Contracts;
using CityTech.Domain.Entities;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;

namespace CityTech.Api.Security;

public sealed record JwtOptions(
    string Issuer,
    string Audience,
    string KeyId,
    string PrivateKeyPath,
    string PublicKeyPath,
    int LifetimeMinutes)
{
    public static JwtOptions FromEnvironment()
    {
        var privatePath = Environment.GetEnvironmentVariable("JWT_PRIVATE_KEY_PATH");
        var publicPath = Environment.GetEnvironmentVariable("JWT_PUBLIC_KEY_PATH");
        if (string.IsNullOrWhiteSpace(privatePath) || !File.Exists(privatePath)
            || string.IsNullOrWhiteSpace(publicPath) || !File.Exists(publicPath))
        {
            throw new InvalidOperationException(
                "Defina JWT_PRIVATE_KEY_PATH e JWT_PUBLIC_KEY_PATH apontando para chaves PEM locais.");
        }

        return new JwtOptions(
            Environment.GetEnvironmentVariable("JWT_ISSUER") ?? "citytech-identity",
            Environment.GetEnvironmentVariable("JWT_AUDIENCE") ?? "citytech-api",
            Environment.GetEnvironmentVariable("JWT_KEY_ID") ?? "citytech-local-v1",
            privatePath,
            publicPath,
            int.TryParse(Environment.GetEnvironmentVariable("JWT_EXPIRES_MINUTES"), out var minutes)
                && minutes is > 0 and <= 1440
                    ? minutes
                    : 60);
    }
}

public sealed class RsaKeyProvider : IDisposable
{
    private readonly RSA _privateKey;

    public RsaKeyProvider(JwtOptions options)
    {
        _privateKey = RSA.Create();
        _privateKey.ImportFromPem(File.ReadAllText(options.PrivateKeyPath));
        SigningKey = new RsaSecurityKey(_privateKey) { KeyId = options.KeyId };
    }

    public RsaSecurityKey SigningKey { get; }

    public void Dispose() => _privateKey.Dispose();
}

public sealed class PasswordService
{
    private readonly PasswordHasher<object> _hasher = new();
    private static readonly object User = new();

    public string Hash(string password) => _hasher.HashPassword(User, password);

    public bool Verify(string hash, string password) =>
        _hasher.VerifyHashedPassword(User, hash, password)
            is PasswordVerificationResult.Success or PasswordVerificationResult.SuccessRehashNeeded;
}

public sealed class JwtTokenService(
    JwtOptions options,
    RsaKeyProvider keys)
{
    public LoginResponse Create(Account account)
    {
        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(options.LifetimeMinutes);
        var credentials = new SigningCredentials(keys.SigningKey, SecurityAlgorithms.RsaSha256);
        var claims = new List<Claim>
        {
            new("sub", account.Id.ToString()),
            new("jti", Guid.NewGuid().ToString()),
            new(
                "roles",
                System.Text.Json.JsonSerializer.Serialize(new[] { account.Role.ToString() }),
                JsonClaimValueTypes.JsonArray),
            new("name", account.Name),
            new("email", account.Email),
            new(
                JwtRegisteredClaimNames.Iat,
                EpochTime.GetIntDate(now).ToString(System.Globalization.CultureInfo.InvariantCulture),
                ClaimValueTypes.Integer64)
        };
        var token = new JwtSecurityToken(
            options.Issuer,
            options.Audience,
            claims,
            notBefore: now,
            expires: expires,
            signingCredentials: credentials);
        token.Header["kid"] = options.KeyId;

        return new LoginResponse(
            new JwtSecurityTokenHandler().WriteToken(token),
            "Bearer",
            checked(options.LifetimeMinutes * 60),
            new UserResponse(account.Id, account.Name, account.Email, account.Role));
    }
}

public static class AuthenticationEvents
{
    public static JwtBearerEvents Create() => new()
    {
        OnTokenValidated = context =>
        {
            var subject = context.Principal?.FindFirstValue("sub");
            var roles = context.Principal?.FindAll("roles").Select(claim => claim.Value).ToArray() ?? [];
            if (!Guid.TryParse(subject, out _)
                || roles.Length == 0
                || roles.Any(role => role is not ("CIDADAO" or "GESTOR")))
            {
                context.Fail("Claims obrigatórias inválidas.");
            }

            return Task.CompletedTask;
        },
        OnChallenge = async context =>
        {
            context.HandleResponse();
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            context.Response.ContentType = "application/json; charset=utf-8";
            await context.Response.WriteAsJsonAsync(
                Services.ApiErrors.Create(
                    context.HttpContext,
                    401,
                    "UNAUTHORIZED",
                    "Não autorizado",
                    "Informe um token JWT válido."),
                Services.JsonDefaults.Options);
        },
        OnForbidden = async context =>
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            context.Response.ContentType = "application/json; charset=utf-8";
            await context.Response.WriteAsJsonAsync(
                Services.ApiErrors.Create(
                    context.HttpContext,
                    403,
                    "FORBIDDEN",
                    "Acesso negado",
                    "O usuário não possui permissão para esta operação."),
                Services.JsonDefaults.Options);
        }
    };
}
