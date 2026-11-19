using System.Net;
using System.Net.Http.Headers;

namespace CityTech.Api.Services;

public sealed class OccurrenceClient(HttpClient httpClient)
{
    public async Task EnsureVisibleAsync(Guid occurrenceId, string bearerToken, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            $"/api/v1/occurrences/{occurrenceId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

        try
        {
            using var response = await httpClient.SendAsync(request, cancellationToken);
            if (response.IsSuccessStatusCode)
            {
                return;
            }

            if (response.StatusCode is HttpStatusCode.NotFound or HttpStatusCode.Forbidden)
            {
                throw new OccurrenceNotFoundException();
            }

            throw new OccurrenceServiceUnavailableException();
        }
        catch (OccurrenceNotFoundException)
        {
            throw;
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            throw new OccurrenceServiceUnavailableException();
        }
        catch (HttpRequestException)
        {
            throw new OccurrenceServiceUnavailableException();
        }
    }

    public async Task<bool> IsHealthyAsync(CancellationToken cancellationToken)
    {
        try
        {
            using var response = await httpClient.GetAsync("/health/live", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch (HttpRequestException)
        {
            return false;
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            return false;
        }
    }
}
