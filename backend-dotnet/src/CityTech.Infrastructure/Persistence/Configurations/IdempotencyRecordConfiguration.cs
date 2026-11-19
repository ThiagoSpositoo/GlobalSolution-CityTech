using CityTech.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CityTech.Infrastructure.Persistence.Configurations;

public sealed class IdempotencyRecordConfiguration : IEntityTypeConfiguration<IdempotencyRecord>
{
    public void Configure(EntityTypeBuilder<IdempotencyRecord> builder)
    {
        builder.ToTable("idempotency_records", table =>
        {
            table.HasCheckConstraint(
                "CK_idempotency_records_scope_length",
                "LEN([scope]) BETWEEN 1 AND 120");
            table.HasCheckConstraint(
                "CK_idempotency_records_key_length",
                "LEN([idempotency_key]) BETWEEN 8 AND 128");
            table.HasCheckConstraint(
                "CK_idempotency_records_request_hash",
                "LEN([request_hash]) = 64 AND [request_hash] = LOWER([request_hash])");
            table.HasCheckConstraint(
                "CK_idempotency_records_status_code",
                "[status_code] BETWEEN 100 AND 599");
            table.HasCheckConstraint(
                "CK_idempotency_records_expiry",
                "[expires_at] > [created_at]");
        });

        builder.HasKey(record => record.Id).HasName("PK_idempotency_records");

        builder.Property(record => record.Id)
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(record => record.Scope)
            .HasColumnName("scope")
            .HasMaxLength(IdempotencyRecord.ScopeMaxLength)
            .IsRequired();

        builder.Property(record => record.Key)
            .HasColumnName("idempotency_key")
            .HasMaxLength(IdempotencyRecord.KeyMaxLength)
            .IsRequired();

        builder.Property(record => record.RequestHash)
            .HasColumnName("request_hash")
            .HasMaxLength(IdempotencyRecord.RequestHashLength)
            .IsRequired();

        builder.Property(record => record.StatusCode)
            .HasColumnName("status_code")
            .IsRequired();

        builder.Property(record => record.ResponseBody)
            .HasColumnName("response_body")
            .HasColumnType("nvarchar(max)")
            .IsRequired();

        builder.Property(record => record.ResponseLocation)
            .HasColumnName("response_location")
            .HasMaxLength(2048);

        builder.Property(record => record.CreatedAt)
            .HasColumnName("created_at")
            .HasColumnType("datetime2(7)")
            .IsRequired();

        builder.Property(record => record.ExpiresAt)
            .HasColumnName("expires_at")
            .HasColumnType("datetime2(7)")
            .IsRequired();

        builder.HasIndex(record => new { record.Scope, record.Key })
            .IsUnique()
            .HasDatabaseName("UX_idempotency_records_scope_key");

        builder.HasIndex(record => record.ExpiresAt)
            .HasDatabaseName("IX_idempotency_records_expires_at");
    }
}
