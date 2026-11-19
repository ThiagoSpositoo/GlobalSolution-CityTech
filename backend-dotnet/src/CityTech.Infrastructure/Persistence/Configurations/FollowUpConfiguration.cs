using CityTech.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CityTech.Infrastructure.Persistence.Configurations;

public sealed class FollowUpConfiguration : IEntityTypeConfiguration<FollowUp>
{
    public void Configure(EntityTypeBuilder<FollowUp> builder)
    {
        builder.ToTable("follow_ups", table =>
        {
            table.HasCheckConstraint("CK_follow_ups_version", "[version] >= 0");
            table.HasCheckConstraint(
                "CK_follow_ups_note_not_blank",
                "[note] IS NULL OR LEN(LTRIM(RTRIM([note]))) > 0");
        });

        builder.HasKey(followUp => followUp.Id).HasName("PK_follow_ups");

        builder.Property(followUp => followUp.Id)
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(followUp => followUp.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        // Referência opaca ao Oracle: occurrence_id é GUID sem FK entre bancos.
        builder.Property(followUp => followUp.OccurrenceId)
            .HasColumnName("occurrence_id")
            .IsRequired();

        builder.Property(followUp => followUp.Note)
            .HasColumnName("note")
            .HasMaxLength(FollowUp.NoteMaxLength);

        builder.Property(followUp => followUp.CreatedAt)
            .HasColumnName("created_at")
            .HasColumnType("datetime2(7)")
            .IsRequired();

        builder.Property(followUp => followUp.UpdatedAt)
            .HasColumnName("updated_at")
            .HasColumnType("datetime2(7)")
            .IsRequired();

        builder.Property(followUp => followUp.Version)
            .HasColumnName("version")
            .IsConcurrencyToken()
            .IsRequired();

        builder.HasIndex(followUp => new { followUp.UserId, followUp.OccurrenceId })
            .IsUnique()
            .HasDatabaseName("UX_follow_ups_user_id_occurrence_id");
    }
}
