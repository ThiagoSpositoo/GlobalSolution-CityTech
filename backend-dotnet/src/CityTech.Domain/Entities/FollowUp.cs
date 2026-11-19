namespace CityTech.Domain.Entities;

/// <summary>
/// Acompanhamento local de uma ocorrência. <see cref="OccurrenceId"/> é uma referência
/// opaca ao serviço Java, sem chave estrangeira entre SQL Server e Oracle.
/// </summary>
public sealed class FollowUp
{
    public const int NoteMaxLength = 500;

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public Account User { get; private set; } = null!;

    /// <summary>ID opaco da ocorrência no Oracle; não é validado por FK local.</summary>
    public Guid OccurrenceId { get; private set; }

    public string? Note { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public DateTime UpdatedAt { get; private set; }

    /// <summary>Token de concorrência otimista; incrementado a cada alteração.</summary>
    public long Version { get; private set; }

    private FollowUp()
    {
        // Exigido pelo EF Core para materialização.
    }

    private FollowUp(Guid id, Guid userId, Guid occurrenceId, string? note)
    {
        if (id == Guid.Empty)
        {
            throw new ArgumentException("O identificador do acompanhamento é obrigatório.", nameof(id));
        }

        if (userId == Guid.Empty)
        {
            throw new ArgumentException("O identificador do usuário é obrigatório.", nameof(userId));
        }

        if (occurrenceId == Guid.Empty)
        {
            throw new ArgumentException("O identificador da ocorrência é obrigatório.", nameof(occurrenceId));
        }

        Id = id;
        UserId = userId;
        OccurrenceId = occurrenceId;
        Note = NormalizeNote(note);

        var now = DateTime.UtcNow;
        CreatedAt = now;
        UpdatedAt = now;
        Version = 0;
    }

    public static FollowUp Create(Guid userId, Guid occurrenceId, string? note = null) =>
        new(Guid.NewGuid(), userId, occurrenceId, note);

    public void UpdateNote(string? note)
    {
        Note = NormalizeNote(note);
        UpdatedAt = DateTime.UtcNow;
    }

    private static string? NormalizeNote(string? note)
    {
        if (string.IsNullOrWhiteSpace(note))
        {
            return null;
        }

        var trimmed = note.Trim();
        if (trimmed.Length > NoteMaxLength)
        {
            throw new ArgumentOutOfRangeException(
                nameof(note),
                $"A observação deve ter no máximo {NoteMaxLength} caracteres.");
        }

        return trimmed;
    }
}
