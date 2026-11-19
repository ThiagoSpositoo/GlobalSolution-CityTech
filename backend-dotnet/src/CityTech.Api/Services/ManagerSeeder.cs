using CityTech.Api.Security;
using CityTech.Domain.Entities;
using CityTech.Domain.Enums;
using CityTech.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CityTech.Api.Services;

public sealed class ManagerSeeder(
    CityTechDbContext db,
    PasswordService passwords,
    ILogger<ManagerSeeder> logger)
{
    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        var name = Environment.GetEnvironmentVariable("MANAGER_SEED_NAME");
        var email = Environment.GetEnvironmentVariable("MANAGER_SEED_EMAIL");
        var password = Environment.GetEnvironmentVariable("MANAGER_SEED_PASSWORD");
        var configured = new[] { name, email, password }.Any(value => !string.IsNullOrWhiteSpace(value));

        if (!configured)
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(name)
            || string.IsNullOrWhiteSpace(email)
            || string.IsNullOrWhiteSpace(password))
        {
            throw new InvalidOperationException(
                "Para criar o gestor local, defina MANAGER_SEED_NAME, MANAGER_SEED_EMAIL e " +
                "MANAGER_SEED_PASSWORD em conjunto.");
        }

        if (password.Length is < 8 or > 128
            || !password.Any(char.IsLetter)
            || !password.Any(char.IsDigit))
        {
            throw new InvalidOperationException(
                "MANAGER_SEED_PASSWORD deve ter entre 8 e 128 caracteres, com letra e número.");
        }

        var normalizedEmail = email.Trim().ToLowerInvariant();
        var existing = await db.Accounts.SingleOrDefaultAsync(
            account => account.EmailNormalized == normalizedEmail,
            cancellationToken);
        if (existing is not null)
        {
            if (existing.Role != Role.GESTOR)
            {
                throw new InvalidOperationException(
                    "MANAGER_SEED_EMAIL já pertence a uma conta que não é GESTOR.");
            }

            logger.LogInformation("Seed de gestor já aplicado para a conta {AccountId}.", existing.Id);
            return;
        }

        var manager = Account.CreateManager(name, email, passwords.Hash(password));
        db.Accounts.Add(manager);
        await db.SaveChangesAsync(cancellationToken);
        logger.LogInformation("Gestor local criado com a conta {AccountId}.", manager.Id);
    }
}
