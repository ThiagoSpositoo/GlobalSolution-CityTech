using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace CityTech.Infrastructure.Persistence.Conversions;

/// <summary>
/// Garante que todo <see cref="DateTime"/> lido do SQL Server volte com <see cref="DateTimeKind.Utc"/>.
/// A gravação de valores não UTC é bloqueada pelo <see cref="CityTechDbContext"/>.
/// </summary>
public sealed class UtcDateTimeConverter : ValueConverter<DateTime, DateTime>
{
    public UtcDateTimeConverter()
        : base(
            value => value,
            value => DateTime.SpecifyKind(value, DateTimeKind.Utc))
    {
    }
}
