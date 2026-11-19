using CityTech.Api.Contracts;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Api.Services;

public sealed class ApiExceptionMiddleware(RequestDelegate next, ILogger<ApiExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (IdempotencyKeyException)
        {
            await WriteAsync(context, 400, "VALIDATION_ERROR", "Requisição inválida",
                "O header Idempotency-Key deve ter entre 8 e 128 caracteres.");
        }
        catch (IdempotencyConflictException)
        {
            await WriteAsync(context, 409, "IDEMPOTENCY_CONFLICT", "Conflito de idempotência",
                "A chave de idempotência já foi usada com outro conteúdo.");
        }
        catch (OccurrenceNotFoundException)
        {
            await WriteAsync(context, 404, "OCCURRENCE_NOT_FOUND", "Ocorrência não encontrada",
                "A ocorrência não existe ou não está visível para o usuário.");
        }
        catch (OccurrenceServiceUnavailableException)
        {
            await WriteAsync(context, 503, "OCCURRENCE_SERVICE_UNAVAILABLE", "Serviço indisponível",
                "Não foi possível validar a ocorrência no serviço Java.");
        }
        catch (DbUpdateConcurrencyException)
        {
            await WriteAsync(context, 409, "CONCURRENT_MODIFICATION", "Conflito de alteração",
                "O recurso foi alterado por outra requisição. Atualize os dados e tente novamente.");
        }
        catch (BadHttpRequestException exception) when (exception.StatusCode == StatusCodes.Status400BadRequest)
        {
            await WriteAsync(context, 400, "VALIDATION_ERROR", "Requisição inválida",
                "O corpo JSON está ausente ou malformado.");
        }
        catch (Exception exception)
        {
            logger.LogError(exception, "Falha não tratada. TraceId: {TraceId}", context.TraceIdentifier);
            await WriteAsync(context, 500, "INTERNAL_ERROR", "Erro interno",
                "Não foi possível concluir a operação.");
        }
    }

    private static async Task WriteAsync(
        HttpContext context,
        int status,
        string code,
        string title,
        string detail)
    {
        if (context.Response.HasStarted)
        {
            return;
        }

        context.Response.StatusCode = status;
        context.Response.ContentType = "application/json; charset=utf-8";
        await context.Response.WriteAsJsonAsync(
            ApiErrors.Create(context, status, code, title, detail),
            JsonDefaults.Options);
    }
}
