namespace CityTech.Domain.Entities;

/// <summary>
/// Registro técnico da resposta original de uma operação idempotente.
/// Não é uma entidade de negócio e não possui relacionamento por FK.
/// </summary>
public sealed class IdempotencyRecord
{
    public const int ScopeMaxLength = 120;
    public const int KeyMinLength = 8;
    public const int KeyMaxLength = 128;
    public const int RequestHashLength = 64;
    public static readonly TimeSpan MinimumRetention = TimeSpan.FromHours(24);

    public Guid Id { get; private set; }

    /// <summary>Escopo da operação, por exemplo rota + usuário.</summary>
    public string Scope { get; private set; } = null!;

    /// <summary>Valor do header <c>Idempotency-Key</c>.</summary>
    public string Key { get; private set; } = null!;

    /// <summary>SHA-256 hexadecimal minúsculo do corpo canônico.</summary>
    public string RequestHash { get; private set; } = null!;

    public int StatusCode { get; private set; }

    public string ResponseBody { get; private set; } = null!;

    public string? ResponseLocation { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public DateTime ExpiresAt { get; private set; }

    private IdempotencyRecord()
    {
        // Exigido pelo EF Core para materialização.
    }

    private IdempotencyRecord(
        Guid id,
        string scope,
        string key,
        string requestHash,
        int statusCode,
        string responseBody,
        string? responseLocation,
        TimeSpan retention)
    {
        Id = id;
        Scope = ValidateScope(scope);
        Key = ValidateKey(key);
        RequestHash = ValidateRequestHash(requestHash);
        StatusCode = ValidateStatusCode(statusCode);
        ResponseBody = responseBody ?? throw new ArgumentNullException(nameof(responseBody));
        ResponseLocation = string.IsNullOrWhiteSpace(responseLocation) ? null : responseLocation.Trim();

        var now = DateTime.UtcNow;
        CreatedAt = now;
        ExpiresAt = now.Add(retention);
    }

    public static IdempotencyRecord Create(
        string scope,
        string key,
        string requestHash,
        int statusCode,
        string responseBody,
        TimeSpan? retention = null,
        string? responseLocation = null)
    {
        var effectiveRetention = retention ?? MinimumRetention;
        if (effectiveRetention < MinimumRetention)
        {
            throw new ArgumentOutOfRangeException(
                nameof(retention),
                $"A retenção mínima é de {MinimumRetention.TotalHours:0} horas.");
        }

        return new IdempotencyRecord(
            Guid.NewGuid(),
            scope,
            key,
            requestHash,
            statusCode,
            responseBody,
            responseLocation,
            effectiveRetention);
    }

    private static string ValidateScope(string scope)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(scope);

        var trimmed = scope.Trim();
        if (trimmed.Length > ScopeMaxLength)
        {
            throw new ArgumentOutOfRangeException(
                nameof(scope),
                $"O escopo deve ter no máximo {ScopeMaxLength} caracteres.");
        }

        return trimmed;
    }

    private static string ValidateKey(string key)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);

        var trimmed = key.Trim();
        if (trimmed.Length is < KeyMinLength or > KeyMaxLength)
        {
            throw new ArgumentOutOfRangeException(
                nameof(key),
                $"A chave de idempotência deve ter entre {KeyMinLength} e {KeyMaxLength} caracteres.");
        }

        return trimmed;
    }

    private static string ValidateRequestHash(string requestHash)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(requestHash);

        var trimmed = requestHash.Trim();
        if (trimmed.Length != RequestHashLength || !trimmed.All(Uri.IsHexDigit))
        {
            throw new ArgumentException(
                $"O hash da requisição deve ser SHA-256 em hexadecimal ({RequestHashLength} caracteres).",
                nameof(requestHash));
        }

        return trimmed.ToLowerInvariant();
    }

    private static int ValidateStatusCode(int statusCode)
    {
        if (statusCode is < 100 or > 599)
        {
            throw new ArgumentOutOfRangeException(nameof(statusCode), "O status HTTP deve estar entre 100 e 599.");
        }

        return statusCode;
    }
}
