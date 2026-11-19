using System.Security.Claims;
using System.Net.Mail;
using System.Text.Json;
using CityTech.Api.Contracts;
using CityTech.Api.Security;
using CityTech.Api.Services;
using CityTech.Domain.Entities;
using CityTech.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/auth").WithTags("Autenticação");

        group.MapPost("/register", RegisterAsync)
            .AllowAnonymous()
            .RequireRateLimiting("register")
            .Produces<AccountResponse>(201)
            .Produces<ApiError>(400)
            .Produces<ApiError>(409)
            .Produces<ApiError>(429);

        group.MapPost("/login", LoginAsync)
            .AllowAnonymous()
            .RequireRateLimiting("login")
            .Produces<LoginResponse>()
            .Produces<ApiError>(400)
            .Produces<ApiError>(401)
            .Produces<ApiError>(429);

        group.MapGet("/me", MeAsync)
            .RequireAuthorization()
            .Produces<UserResponse>()
            .Produces<ApiError>(401);
    }

    private static async Task<IResult> RegisterAsync(
        RegisterRequest request,
        HttpContext context,
        CityTechDbContext db,
        PasswordService passwords,
        IdempotencyService idempotency,
        CancellationToken cancellationToken)
    {
        var errors = ValidateRegistration(request);
        if (errors.Count > 0)
        {
            return ApiErrors.Result(context, 400, "VALIDATION_ERROR", "Requisição inválida",
                "Corrija os campos informados.", errors);
        }

        var normalizedEmail = request.Email!.Trim().ToLowerInvariant();
        var outcome = await idempotency.ExecuteAsync(
            $"register:{context.Connection.RemoteIpAddress}",
            context.Request.Headers["Idempotency-Key"].FirstOrDefault(),
            request,
            async token =>
            {
                if (await db.Accounts.AnyAsync(account => account.EmailNormalized == normalizedEmail, token))
                {
                    return ErrorStored(context, 409, "EMAIL_ALREADY_EXISTS", "E-mail já cadastrado",
                        "Já existe uma conta com o e-mail informado.");
                }

                var account = Account.RegisterCitizen(
                    request.Name!,
                    request.Email!,
                    passwords.Hash(request.Password!));
                db.Accounts.Add(account);
                try
                {
                    await db.SaveChangesAsync(token);
                }
                catch (DbUpdateException exception) when (IsUniqueViolation(exception))
                {
                    db.Entry(account).State = EntityState.Detached;
                    return ErrorStored(context, 409, "EMAIL_ALREADY_EXISTS", "E-mail já cadastrado",
                        "Já existe uma conta com o e-mail informado.");
                }

                var response = new AccountResponse(
                    account.Id,
                    account.Name,
                    account.Email,
                    account.Role,
                    account.CreatedAt);
                return JsonStored(201, response);
            },
            cancellationToken);

        return ToResult(context, outcome);
    }

    private static async Task<IResult> LoginAsync(
        LoginRequest request,
        HttpContext context,
        CityTechDbContext db,
        PasswordService passwords,
        JwtTokenService tokens,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
        {
            return ApiErrors.Result(context, 400, "VALIDATION_ERROR", "Requisição inválida",
                "E-mail e senha são obrigatórios.");
        }

        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var account = await db.Accounts.AsNoTracking()
            .SingleOrDefaultAsync(item => item.EmailNormalized == normalizedEmail, cancellationToken);
        if (account is null || !account.Active || !passwords.Verify(account.PasswordHash, request.Password))
        {
            return ApiErrors.Result(context, 401, "UNAUTHORIZED", "Não autorizado",
                "E-mail ou senha inválidos.");
        }

        return Results.Ok(tokens.Create(account));
    }

    private static async Task<IResult> MeAsync(
        ClaimsPrincipal principal,
        HttpContext context,
        CityTechDbContext db,
        CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(principal.FindFirstValue("sub"), out var id))
        {
            return ApiErrors.Result(context, 401, "UNAUTHORIZED", "Não autorizado", "Token inválido.");
        }

        var account = await db.Accounts.AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == id && item.Active, cancellationToken);
        return account is null
            ? ApiErrors.Result(context, 401, "UNAUTHORIZED", "Não autorizado", "Conta inválida ou inativa.")
            : Results.Ok(new UserResponse(account.Id, account.Name, account.Email, account.Role));
    }

    private static List<FieldError> ValidateRegistration(RegisterRequest request)
    {
        var errors = new List<FieldError>();
        var name = request.Name?.Trim();
        if (name is null || name.Length is < Account.NameMinLength or > Account.NameMaxLength)
        {
            errors.Add(new("name", "deve ter entre 2 e 120 caracteres"));
        }

        var email = request.Email?.Trim();
        if (email is null
            || email.Length > Account.EmailMaxLength
            || !MailAddress.TryCreate(email, out var parsed)
            || !string.Equals(parsed.Address, email, StringComparison.OrdinalIgnoreCase))
        {
            errors.Add(new("email", "deve ser um e-mail válido de até 254 caracteres"));
        }

        var password = request.Password;
        if (password is null || password.Length is < 8 or > 128
            || !password.Any(char.IsLetter) || !password.Any(char.IsDigit))
        {
            errors.Add(new("password", "deve ter entre 8 e 128 caracteres, com letra e número"));
        }

        return errors;
    }

    internal static StoredResponse JsonStored<T>(int status, T value, string? location = null) =>
        new(status, JsonSerializer.Serialize(value, JsonDefaults.Options), location);

    internal static StoredResponse ErrorStored(
        HttpContext context,
        int status,
        string code,
        string title,
        string detail) =>
        JsonStored(status, ApiErrors.Create(context, status, code, title, detail));

    internal static IResult ToResult(HttpContext context, IdempotencyOutcome outcome)
    {
        if (outcome.Replayed)
        {
            context.Response.Headers["Idempotent-Replayed"] = "true";
        }

        if (!string.IsNullOrWhiteSpace(outcome.Response.Location))
        {
            context.Response.Headers.Location = outcome.Response.Location;
        }

        return Results.Content(
            outcome.Response.Body,
            "application/json; charset=utf-8",
            statusCode: outcome.Response.StatusCode);
    }

    internal static bool IsUniqueViolation(DbUpdateException exception) =>
        exception.InnerException is SqlException { Number: 2601 or 2627 };
}
