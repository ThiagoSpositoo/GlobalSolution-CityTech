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
        var privatePem = Environment.GetEnvironmentVariable("JWT_PRIVATE_KEY_PEM");
        var publicPem = Environment.GetEnvironmentVariable("JWT_PUBLIC_KEY_PEM");
        string? privatePath;
        string? publicPath;

        if (!string.IsNullOrWhiteSpace(privatePem) && !string.IsNullOrWhiteSpace(publicPem))
        {
            (privatePath, publicPath) = MaterializePem(privatePem, publicPem);
        }
        else
        {
            privatePath = Environment.GetEnvironmentVariable("JWT_PRIVATE_KEY_PATH");
            publicPath = Environment.GetEnvironmentVariable("JWT_PUBLIC_KEY_PATH");
        }

        if (string.IsNullOrWhiteSpace(privatePath) || !File.Exists(privatePath)
            || string.IsNullOrWhiteSpace(publicPath) || !File.Exists(publicPath))
        {
            throw new InvalidOperationException(
                "Defina JWT_PRIVATE_KEY_PEM e JWT_PUBLIC_KEY_PEM (nuvem) ou " +
                "JWT_PRIVATE_KEY_PATH e JWT_PUBLIC_KEY_PATH apontando para chaves PEM locais.");
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

    /// <summary>
    /// Materializa PEMs recebidos por variável de ambiente (App Service/Key Vault) em arquivos
    /// temporários legíveis apenas pelo processo, mantendo o restante do código baseado em caminho.
    /// </summary>
    public static (string PrivateKeyPath, string PublicKeyPath) MaterializePem(
        string privatePem,
        string publicPem,
        string? directory = null)
    {
        if (!privatePem.Contains("PRIVATE KEY", StringComparison.Ordinal))
        {
            throw new InvalidOperationException("JWT_PRIVATE_KEY_PEM não contém uma chave privada PEM válida.");
        }

        if (!publicPem.Contains("PUBLIC KEY", StringComparison.Ordinal))
        {
            throw new InvalidOperationException("JWT_PUBLIC_KEY_PEM não contém uma chave pública PEM válida.");
        }

        var target = directory ?? Path.Combine(Path.GetTempPath(), "citytech-jwt");
        Directory.CreateDirectory(target);

        var privatePath = Path.Combine(target, "jwt-private.pem");
        var publicPath = Path.Combine(target, "jwt-public.pem");
        var encoding = new System.Text.UTF8Encoding(encoderShouldEmitUTF8Identifier: false);
        File.WriteAllText(privatePath, privatePem, encoding);
        File.WriteAllText(publicPath, publicPem, encoding);

        if (!OperatingSystem.IsWindows())
        {
            File.SetUnixFileMode(privatePath, UnixFileMode.UserRead | UnixFileMode.UserWrite);
            File.SetUnixFileMode(publicPath, UnixFileMode.UserRead | UnixFileMode.UserWrite);
        }

        return (privatePath, publicPath);
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
