using System.Net.Mail;
using CityTech.Domain.Enums;

namespace CityTech.Domain.Entities;

/// <summary>
/// Identidade de um usuário do CityTech. A senha nunca é armazenada em texto puro:
/// <see cref="PasswordHash"/> recebe o hash produzido pelo serviço de autenticação.
/// </summary>
public sealed class Account
{
    public const int NameMinLength = 2;
    public const int NameMaxLength = 120;
    public const int EmailMaxLength = 254;
    public const int PasswordHashMinLength = 20;
    public const int PasswordHashMaxLength = 512;

    private readonly List<FollowUp> _followUps = [];

    public Guid Id { get; private set; }

    public string Name { get; private set; } = null!;

    /// <summary>E-mail como o usuário o informou, preservado para exibição.</summary>
    public string Email { get; private set; } = null!;

    /// <summary>E-mail em minúsculas, único e usado no login.</summary>
    public string EmailNormalized { get; private set; } = null!;

    public string PasswordHash { get; private set; } = null!;

    public Role Role { get; private set; }

    public bool Active { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public DateTime UpdatedAt { get; private set; }

    /// <summary>Token de concorrência otimista; incrementado a cada alteração.</summary>
    public long Version { get; private set; }

    public IReadOnlyCollection<FollowUp> FollowUps => _followUps;

    private Account()
    {
        // Exigido pelo EF Core para materialização.
    }

    private Account(Guid id, string name, string email, string passwordHash, Role role)
    {
        if (id == Guid.Empty)
        {
            throw new ArgumentException("O identificador da conta é obrigatório.", nameof(id));
        }

        Id = id;
        Name = ValidateName(name);
        Email = ValidateEmail(email);
        EmailNormalized = Email.ToLowerInvariant();
        PasswordHash = ValidatePasswordHash(passwordHash);
        Role = role;
        Active = true;

        var now = DateTime.UtcNow;
        CreatedAt = now;
        UpdatedAt = now;
        Version = 0;
    }

    /// <summary>Cadastro público: cria exclusivamente um cidadão ativo.</summary>
    public static Account RegisterCitizen(string name, string email, string passwordHash) =>
        new(Guid.NewGuid(), name, email, passwordHash, Role.CIDADAO);

    /// <summary>
    /// Criação controlada de gestor (seed ou configuração administrativa futura).
    /// Não deve ser exposta pelo cadastro público.
    /// </summary>
    public static Account CreateManager(string name, string email, string passwordHash) =>
        new(Guid.NewGuid(), name, email, passwordHash, Role.GESTOR);

    public void Rename(string name)
    {
        Name = ValidateName(name);
        UpdatedAt = DateTime.UtcNow;
    }

    public void Deactivate()
    {
        Active = false;
        UpdatedAt = DateTime.UtcNow;
    }

    private static string ValidateName(string name)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        var trimmed = name.Trim();
        if (trimmed.Length is < NameMinLength or > NameMaxLength)
        {
            throw new ArgumentOutOfRangeException(
                nameof(name),
                $"O nome deve ter entre {NameMinLength} e {NameMaxLength} caracteres.");
        }

        return trimmed;
    }

    private static string ValidateEmail(string email)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(email);

        var trimmed = email.Trim();
        if (trimmed.Length > EmailMaxLength || !MailAddress.TryCreate(trimmed, out var parsed)
            || !string.Equals(parsed.Address, trimmed, StringComparison.OrdinalIgnoreCase))
        {
            throw new ArgumentException($"Informe um e-mail válido de até {EmailMaxLength} caracteres.", nameof(email));
        }

        return trimmed;
    }

    private static string ValidatePasswordHash(string passwordHash)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(passwordHash);

        if (passwordHash.Length is < PasswordHashMinLength or > PasswordHashMaxLength
            || passwordHash.Any(char.IsWhiteSpace))
        {
            throw new ArgumentException(
                $"O hash de senha deve ter entre {PasswordHashMinLength} e {PasswordHashMaxLength} caracteres e não conter espaços.",
                nameof(passwordHash));
        }

        return passwordHash;
    }
}
