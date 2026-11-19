using System.Collections.Concurrent;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using CityTech.Api.Contracts;
using CityTech.Domain.Entities;
using CityTech.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Api.Services;

public static class JsonDefaults
{
    public static readonly JsonSerializerOptions Options = Create();

    private static JsonSerializerOptions Create()
    {
        var options = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        options.Converters.Add(new JsonStringEnumConverter());
        return options;
    }
}

public static class EnvironmentValue
{
    public static int Int(string name, int fallback) =>
        int.TryParse(Environment.GetEnvironmentVariable(name), out var value) && value > 0
            ? value
            : fallback;
}

public static class ApiErrors
{
    public static IResult Result(
        HttpContext context,
        int status,
        string code,
        string title,
        string detail,
        IReadOnlyList<FieldError>? errors = null)
    {
        var body = Create(context, status, code, title, detail, errors);
        return Results.Json(body, JsonDefaults.Options, statusCode: status);
    }

    public static ApiError Create(
        HttpContext context,
        int status,
        string code,
        string title,
        string detail,
        IReadOnlyList<FieldError>? errors = null) =>
        new(
            $"https://citytech.example/errors/{code.ToLowerInvariant().Replace('_', '-')}",
            title,
            status,
            detail,
            context.Request.Path,
            code,
            context.TraceIdentifier,
            errors);
}

public sealed record StoredResponse(int StatusCode, string Body, string? Location = null);
public sealed record IdempotencyOutcome(StoredResponse Response, bool Replayed);

public sealed class IdempotencyService(CityTechDbContext db)
{
    private static readonly ConcurrentDictionary<string, SemaphoreSlim> Locks = new();

    public async Task<IdempotencyOutcome> ExecuteAsync(
        string scope,
        string? key,
        object request,
        Func<CancellationToken, Task<StoredResponse>> operation,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(key)
            || key.Trim().Length is < IdempotencyRecord.KeyMinLength or > IdempotencyRecord.KeyMaxLength)
        {
            throw new IdempotencyKeyException();
        }

        key = key.Trim();
        var requestJson = JsonSerializer.Serialize(request, JsonDefaults.Options);
        var hash = Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(requestJson)));
        var lockKey = $"{scope}:{key}";
        var gate = Locks.GetOrAdd(lockKey, _ => new SemaphoreSlim(1, 1));
        await gate.WaitAsync(cancellationToken);
        try
        {
            var existing = await db.IdempotencyRecords
                .SingleOrDefaultAsync(record => record.Scope == scope && record.Key == key, cancellationToken);
            if (existing is not null && existing.ExpiresAt > DateTime.UtcNow)
            {
                if (!string.Equals(existing.RequestHash, hash, StringComparison.Ordinal))
                {
                    throw new IdempotencyConflictException();
                }

                return new IdempotencyOutcome(
                    new StoredResponse(
                        existing.StatusCode,
                        existing.ResponseBody,
                        existing.ResponseLocation),
                    true);
            }

            if (existing is not null)
            {
                db.IdempotencyRecords.Remove(existing);
            }

            await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
            var response = await operation(cancellationToken);
            db.IdempotencyRecords.Add(IdempotencyRecord.Create(
                scope,
                key,
                hash,
                response.StatusCode,
                response.Body,
                responseLocation: response.Location));
            try
            {
                await db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);
                return new IdempotencyOutcome(response, false);
            }
            catch (DbUpdateException exception) when (IsUniqueViolation(exception))
            {
                await transaction.RollbackAsync(cancellationToken);
                db.ChangeTracker.Clear();

                var concurrent = await db.IdempotencyRecords
                    .AsNoTracking()
                    .SingleOrDefaultAsync(
                        record => record.Scope == scope && record.Key == key,
                        cancellationToken);
                if (concurrent is null)
                {
                    throw;
                }

                if (!string.Equals(concurrent.RequestHash, hash, StringComparison.Ordinal))
                {
                    throw new IdempotencyConflictException();
                }

                return new IdempotencyOutcome(
                    new StoredResponse(
                        concurrent.StatusCode,
                        concurrent.ResponseBody,
                        concurrent.ResponseLocation),
                    true);
            }
        }
        finally
        {
            gate.Release();
        }
    }

    private static bool IsUniqueViolation(DbUpdateException exception) =>
        exception.InnerException is SqlException { Number: 2601 or 2627 };
}

public sealed class IdempotencyKeyException : Exception;
public sealed class IdempotencyConflictException : Exception;
public sealed class OccurrenceNotFoundException : Exception;
public sealed class OccurrenceServiceUnavailableException : Exception;
