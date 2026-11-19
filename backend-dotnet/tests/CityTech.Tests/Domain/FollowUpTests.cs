using CityTech.Domain.Entities;

namespace CityTech.Tests.Domain;

public sealed class FollowUpTests
{
    [Fact]
    public void Create_WithValidData_NormalizesNoteAndStartsAtVersionZero()
    {
        var userId = Guid.NewGuid();
        var occurrenceId = Guid.NewGuid();

        var followUp = FollowUp.Create(userId, occurrenceId, "  Acompanhar a triagem.  ");

        Assert.NotEqual(Guid.Empty, followUp.Id);
        Assert.Equal(userId, followUp.UserId);
        Assert.Equal(occurrenceId, followUp.OccurrenceId);
        Assert.Equal("Acompanhar a triagem.", followUp.Note);
        Assert.Equal(0, followUp.Version);
        Assert.Equal(DateTimeKind.Utc, followUp.CreatedAt.Kind);
        Assert.Equal(DateTimeKind.Utc, followUp.UpdatedAt.Kind);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void Create_WithBlankNote_StoresNull(string? note)
    {
        var followUp = FollowUp.Create(Guid.NewGuid(), Guid.NewGuid(), note);

        Assert.Null(followUp.Note);
    }

    [Fact]
    public void Create_WithEmptyUserId_Throws()
    {
        Assert.Throws<ArgumentException>(() => FollowUp.Create(Guid.Empty, Guid.NewGuid()));
    }

    [Fact]
    public void Create_WithEmptyOccurrenceId_Throws()
    {
        Assert.Throws<ArgumentException>(() => FollowUp.Create(Guid.NewGuid(), Guid.Empty));
    }

    [Fact]
    public void Create_WithNoteTooLong_Throws()
    {
        var note = new string('a', FollowUp.NoteMaxLength + 1);

        Assert.Throws<ArgumentOutOfRangeException>(() =>
            FollowUp.Create(Guid.NewGuid(), Guid.NewGuid(), note));
    }

    [Fact]
    public void UpdateNote_ReplacesNoteAndKeepsUtcTimestamp()
    {
        var followUp = FollowUp.Create(Guid.NewGuid(), Guid.NewGuid(), "inicial");

        followUp.UpdateNote("  atualizada  ");

        Assert.Equal("atualizada", followUp.Note);
        Assert.Equal(DateTimeKind.Utc, followUp.UpdatedAt.Kind);
    }

    [Fact]
    public void UpdateNote_WithBlankValue_ClearsNote()
    {
        var followUp = FollowUp.Create(Guid.NewGuid(), Guid.NewGuid(), "inicial");

        followUp.UpdateNote("   ");

        Assert.Null(followUp.Note);
    }
}
