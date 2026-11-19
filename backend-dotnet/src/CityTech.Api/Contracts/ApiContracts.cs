using CityTech.Domain.Enums;

namespace CityTech.Api.Contracts;

public sealed record RegisterRequest(string? Name, string? Email, string? Password);
public sealed record LoginRequest(string? Email, string? Password);
public sealed record CreateFollowUpRequest(Guid OccurrenceId, string? Note);
public sealed record UpdateFollowUpRequest(long? Version, string? Note);

public sealed record UserResponse(Guid Id, string Name, string Email, Role Role);
public sealed record AccountResponse(Guid Id, string Name, string Email, Role Role, DateTime CreatedAt);
public sealed record LoginResponse(string AccessToken, string TokenType, int ExpiresIn, UserResponse User);
public sealed record FollowUpResponse(
    Guid Id,
    Guid OccurrenceId,
    string? Note,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    long Version);
public sealed record PageResponse<T>(
    IReadOnlyList<T> Items,
    int Page,
    int Size,
    long TotalElements,
    int TotalPages,
    bool First,
    bool Last);

public sealed record FieldError(string Field, string Message);
public sealed record ApiError(
    string Type,
    string Title,
    int Status,
    string Detail,
    string Instance,
    string Code,
    string TraceId,
    IReadOnlyList<FieldError>? Errors = null);
