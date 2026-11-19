using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;

namespace CityTech.Api.Services;

public static class RateLimitResponses
{
    public static async ValueTask WriteAsync(OnRejectedContext rejected, CancellationToken cancellationToken)
    {
        var retryAfter = 60;
        if (rejected.Lease.TryGetMetadata(MetadataName.RetryAfter, out var value))
        {
            retryAfter = Math.Max(1, (int)Math.Ceiling(value.TotalSeconds));
        }

        rejected.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        rejected.HttpContext.Response.Headers.RetryAfter = retryAfter.ToString();
        await rejected.HttpContext.Response.WriteAsJsonAsync(
            ApiErrors.Create(
                rejected.HttpContext,
                429,
                "RATE_LIMITED",
                "Limite excedido",
                "Aguarde antes de realizar uma nova requisição."),
            JsonDefaults.Options,
            cancellationToken);
    }
}
