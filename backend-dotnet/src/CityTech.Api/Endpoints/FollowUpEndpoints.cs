using System.Security.Claims;
using CityTech.Api.Contracts;
using CityTech.Api.Services;
using Microsoft.AspNetCore.Mvc;
using CityTech.Domain.Entities;
using CityTech.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Api.Endpoints;

public static class FollowUpEndpoints
{
    public static void MapFollowUpEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/followups")
            .WithTags("Acompanhamentos")
            .RequireAuthorization();

        group.MapGet("/", ListAsync).Produces<PageResponse<FollowUpResponse>>();
        group.MapGet("/{id:guid}", GetAsync).Produces<FollowUpResponse>().Produces<ApiError>(404);
        group.MapPost("/", CreateAsync)
            .RequireRateLimiting("followups-write")
            .Produces<FollowUpResponse>(201)
            .Produces<ApiError>(400)
            .Produces<ApiError>(404)
            .Produces<ApiError>(409)
            .Produces<ApiError>(503);
        group.MapPatch("/{id:guid}", UpdateAsync)
            .Produces<FollowUpResponse>()
            .Produces<ApiError>(404)
            .Produces<ApiError>(409);
        group.MapDelete("/{id:guid}", DeleteAsync).Produces(204);
    }

    private static async Task<IResult> ListAsync(
        int? page,
        int? size,
        string? sort,
        ClaimsPrincipal principal,
        HttpContext context,
        CityTechDbContext db,
        CancellationToken cancellationToken)
    {
        if (!TryUserId(principal, out var userId))
        {
            return ApiErrors.Result(context, 401, "UNAUTHORIZED", "Não autorizado", "Token inválido.");
        }

        var pageValue = page ?? 0;
        var sizeValue = size ?? 20;
        var sortValue = sort ?? "createdAt,desc";
        if (pageValue < 0 || sizeValue is < 1 or > 100
            || sortValue is not ("createdAt,asc" or "createdAt,desc" or "updatedAt,asc" or "updatedAt,desc"))
        {
            return ApiErrors.Result(context, 400, "VALIDATION_ERROR", "Requisição inválida",
                "Paginação ou ordenação inválida.");
        }

        var query = db.FollowUps.AsNoTracking().Where(item => item.UserId == userId);
        var total = await query.LongCountAsync(cancellationToken);
        query = sortValue switch
        {
            "createdAt,asc" => query.OrderBy(item => item.CreatedAt),
            "updatedAt,asc" => query.OrderBy(item => item.UpdatedAt),
            "updatedAt,desc" => query.OrderByDescending(item => item.UpdatedAt),
            _ => query.OrderByDescending(item => item.CreatedAt)
        };
        var items = await query.Skip(pageValue * sizeValue).Take(sizeValue)
            .Select(item => Map(item))
            .ToListAsync(cancellationToken);
        var totalPages = total == 0 ? 0 : (int)Math.Ceiling(total / (double)sizeValue);
        return Results.Ok(new PageResponse<FollowUpResponse>(
            items,
            pageValue,
            sizeValue,
            total,
            totalPages,
            pageValue == 0,
            pageValue >= totalPages - 1));
    }

    private static async Task<IResult> GetAsync(
        Guid id,
        ClaimsPrincipal principal,
        HttpContext context,
        CityTechDbContext db,
        CancellationToken cancellationToken)
    {
        if (!TryUserId(principal, out var userId))
        {
            return ApiErrors.Result(context, 401, "UNAUTHORIZED", "Não autorizado", "Token inválido.");
        }

        var item = await db.FollowUps.AsNoTracking()
            .SingleOrDefaultAsync(value => value.Id == id && value.UserId == userId, cancellationToken);
        return item is null
            ? ApiErrors.Result(context, 404, "NOT_FOUND", "Não encontrado",
                "O acompanhamento não existe ou não está visível.")
            : Results.Ok(Map(item));
    }

    private static async Task<IResult> CreateAsync(
        CreateFollowUpRequest request,
        ClaimsPrincipal principal,
        HttpContext context,
	[FromHeader(Name = "Idempotency-Key")] string? idempotencyKey,
        CityTechDbContext db,
        OccurrenceClient occurrences,
        IdempotencyService idempotency,
        CancellationToken cancellationToken)
    {
        if (!TryUserId(principal, out var userId))
        {
            return ApiErrors.Result(context, 401, "UNAUTHORIZED", "Não autorizado", "Token inválido.");
        }

        if (request.OccurrenceId == Guid.Empty || request.Note?.Trim().Length > FollowUp.NoteMaxLength)
        {
            return ApiErrors.Result(context, 400, "VALIDATION_ERROR", "Requisição inválida",
                "OccurrenceId é obrigatório e a observação deve ter no máximo 500 caracteres.");
        }

        var authorization = context.Request.Headers.Authorization.ToString();
        var bearer = authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
            ? authorization[7..]
            : string.Empty;
        var outcome = await idempotency.ExecuteAsync(
            $"followups:{userId}",
            idempotencyKey,
            request,
            async token =>
            {
                await occurrences.EnsureVisibleAsync(request.OccurrenceId, bearer, token);
                if (await db.FollowUps.AnyAsync(
                    item => item.UserId == userId && item.OccurrenceId == request.OccurrenceId,
                    token))
                {
                    return AuthEndpoints.ErrorStored(
                        context, 409, "FOLLOWUP_ALREADY_EXISTS", "Acompanhamento duplicado",
                        "A ocorrência já está sendo acompanhada.");
                }

                var item = FollowUp.Create(userId, request.OccurrenceId, request.Note);
                db.FollowUps.Add(item);
                try
                {
                    await db.SaveChangesAsync(token);
                }
                catch (DbUpdateException exception) when (AuthEndpoints.IsUniqueViolation(exception))
                {
                    db.Entry(item).State = EntityState.Detached;
                    return AuthEndpoints.ErrorStored(
                        context, 409, "FOLLOWUP_ALREADY_EXISTS", "Acompanhamento duplicado",
                        "A ocorrência já está sendo acompanhada.");
                }

                return AuthEndpoints.JsonStored(
                    201,
                    Map(item),
                    $"/api/v1/followups/{item.Id}");
            },
            cancellationToken);
        return AuthEndpoints.ToResult(context, outcome);
    }

    private static async Task<IResult> UpdateAsync(
        Guid id,
        UpdateFollowUpRequest request,
        ClaimsPrincipal principal,
        HttpContext context,
        CityTechDbContext db,
        CancellationToken cancellationToken)
    {
        if (!TryUserId(principal, out var userId))
        {
            return ApiErrors.Result(context, 401, "UNAUTHORIZED", "Não autorizado", "Token inválido.");
        }

        if (request.Version is null or < 0 || request.Note?.Trim().Length > FollowUp.NoteMaxLength)
        {
            return ApiErrors.Result(context, 400, "VALIDATION_ERROR", "Requisição inválida",
                "Versão inválida ou observação acima de 500 caracteres.");
        }

        var item = await db.FollowUps
            .SingleOrDefaultAsync(value => value.Id == id && value.UserId == userId, cancellationToken);
        if (item is null)
        {
            return ApiErrors.Result(context, 404, "NOT_FOUND", "Não encontrado",
                "O acompanhamento não existe ou não está visível.");
        }

        if (item.Version != request.Version.Value)
        {
            return ApiErrors.Result(context, 409, "CONCURRENT_MODIFICATION", "Conflito de alteração",
                "A versão informada está desatualizada.");
        }

        item.UpdateNote(request.Note);
        await db.SaveChangesAsync(cancellationToken);
        return Results.Ok(Map(item));
    }

    private static async Task<IResult> DeleteAsync(
        Guid id,
        ClaimsPrincipal principal,
        HttpContext context,
        CityTechDbContext db,
        CancellationToken cancellationToken)
    {
        if (!TryUserId(principal, out var userId))
        {
            return ApiErrors.Result(context, 401, "UNAUTHORIZED", "Não autorizado", "Token inválido.");
        }

        var item = await db.FollowUps
            .SingleOrDefaultAsync(value => value.Id == id && value.UserId == userId, cancellationToken);
        if (item is not null)
        {
            db.FollowUps.Remove(item);
            await db.SaveChangesAsync(cancellationToken);
        }

        return Results.NoContent();
    }

    private static bool TryUserId(ClaimsPrincipal principal, out Guid userId) =>
        Guid.TryParse(principal.FindFirstValue("sub"), out userId);

    private static FollowUpResponse Map(FollowUp item) =>
        new(item.Id, item.OccurrenceId, item.Note, item.CreatedAt, item.UpdatedAt, item.Version);
}
