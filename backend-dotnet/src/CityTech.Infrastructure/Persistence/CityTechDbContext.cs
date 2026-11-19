using CityTech.Domain.Entities;
using CityTech.Infrastructure.Persistence.Conversions;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Infrastructure.Persistence;

/// <summary>
/// Contexto de persistência do domínio .NET: contas, acompanhamentos e idempotência.
/// </summary>
public sealed class CityTechDbContext : DbContext
{
    public CityTechDbContext(DbContextOptions<CityTechDbContext> options)
        : base(options)
    {
    }

    public DbSet<Account> Accounts => Set<Account>();

    public DbSet<FollowUp> FollowUps => Set<FollowUp>();

    public DbSet<IdempotencyRecord> IdempotencyRecords => Set<IdempotencyRecord>();

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        configurationBuilder.Properties<DateTime>().HaveConversion<UtcDateTimeConverter>();
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CityTechDbContext).Assembly);
    }

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        PrepareForSave();
        return base.SaveChanges(acceptAllChangesOnSuccess);
    }

    public override Task<int> SaveChangesAsync(
        bool acceptAllChangesOnSuccess,
        CancellationToken cancellationToken = default)
    {
        PrepareForSave();
        return base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
    }

    private void PrepareForSave()
    {
        EnsureUtcTimestamps();
        IncrementVersions();
    }

    /// <summary>
    /// R15: a API não aceita timezone implícito. Qualquer data persistida precisa ser UTC.
    /// </summary>
    private void EnsureUtcTimestamps()
    {
        foreach (var entry in ChangeTracker.Entries())
        {
            if (entry.State is not (EntityState.Added or EntityState.Modified))
            {
                continue;
            }

            foreach (var property in entry.Properties)
            {
                if (property.Metadata.ClrType == typeof(DateTime)
                    && property.CurrentValue is DateTime value
                    && value.Kind != DateTimeKind.Utc)
                {
                    throw new InvalidOperationException(
                        $"A propriedade '{entry.Metadata.ClrType.Name}.{property.Metadata.Name}' deve ser informada em UTC.");
                }
            }
        }
    }

    /// <summary>
    /// Concorrência otimista por <c>version</c>. O valor original permanece no WHERE
    /// e o novo valor é gravado; uma alteração concorrente gera <see cref="DbUpdateConcurrencyException"/>.
    /// </summary>
    private void IncrementVersions()
    {
        foreach (var entry in ChangeTracker.Entries<Account>())
        {
            if (entry.State == EntityState.Modified)
            {
                var version = entry.Property(account => account.Version);
                version.CurrentValue = (long)version.OriginalValue! + 1;
            }
        }

        foreach (var entry in ChangeTracker.Entries<FollowUp>())
        {
            if (entry.State == EntityState.Modified)
            {
                var version = entry.Property(followUp => followUp.Version);
                version.CurrentValue = (long)version.OriginalValue! + 1;
            }
        }
    }
}
