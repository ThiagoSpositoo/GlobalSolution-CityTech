using CityTech.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CityTech.Infrastructure.Persistence.Configurations;

public sealed class AccountConfiguration : IEntityTypeConfiguration<Account>
{
    public void Configure(EntityTypeBuilder<Account> builder)
    {
        builder.ToTable("accounts", table =>
        {
            table.HasCheckConstraint("CK_accounts_name_length", "LEN([name]) >= 2");
            table.HasCheckConstraint("CK_accounts_role", "[role] IN ('CIDADAO', 'GESTOR')");
            table.HasCheckConstraint("CK_accounts_version", "[version] >= 0");
            table.HasCheckConstraint(
                "CK_accounts_email_normalized_lowercase",
                "[email_normalized] = LOWER([email_normalized])");
        });

        builder.HasKey(account => account.Id).HasName("PK_accounts");

        builder.Property(account => account.Id)
            .HasColumnName("id")
            .ValueGeneratedNever();

        builder.Property(account => account.Name)
            .HasColumnName("name")
            .HasMaxLength(Account.NameMaxLength)
            .IsRequired();

        builder.Property(account => account.Email)
            .HasColumnName("email")
            .HasMaxLength(Account.EmailMaxLength)
            .IsRequired();

        builder.Property(account => account.EmailNormalized)
            .HasColumnName("email_normalized")
            .HasMaxLength(Account.EmailMaxLength)
            .IsRequired();

        builder.Property(account => account.PasswordHash)
            .HasColumnName("password_hash")
            .HasMaxLength(Account.PasswordHashMaxLength)
            .IsRequired();

        builder.Property(account => account.Role)
            .HasColumnName("role")
            .HasMaxLength(20)
            .HasConversion<string>()
            .IsRequired();

        builder.Property(account => account.Active)
            .HasColumnName("active")
            .IsRequired();

        builder.Property(account => account.CreatedAt)
            .HasColumnName("created_at")
            .HasColumnType("datetime2(7)")
            .IsRequired();

        builder.Property(account => account.UpdatedAt)
            .HasColumnName("updated_at")
            .HasColumnType("datetime2(7)")
            .IsRequired();

        builder.Property(account => account.Version)
            .HasColumnName("version")
            .IsConcurrencyToken()
            .IsRequired();

        builder.HasIndex(account => account.EmailNormalized)
            .IsUnique()
            .HasDatabaseName("UX_accounts_email_normalized");

        builder.HasMany(account => account.FollowUps)
            .WithOne(followUp => followUp.User)
            .HasForeignKey(followUp => followUp.UserId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_follow_ups_accounts_user_id");
    }
}
