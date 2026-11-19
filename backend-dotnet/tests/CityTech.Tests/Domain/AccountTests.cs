using CityTech.Domain.Entities;
using CityTech.Domain.Enums;

namespace CityTech.Tests.Domain;

public sealed class AccountTests
{
    [Fact]
    public void RegisterCitizen_WithValidData_CreatesActiveCitizen()
    {
        var account = Account.RegisterCitizen(
            "  Maria Silva  ",
            "Maria.Silva@Example.com",
            TestData.PasswordHash());

        Assert.NotEqual(Guid.Empty, account.Id);
        Assert.Equal("Maria Silva", account.Name);
        Assert.Equal("Maria.Silva@Example.com", account.Email);
        Assert.Equal("maria.silva@example.com", account.EmailNormalized);
        Assert.Equal(Role.CIDADAO, account.Role);
        Assert.True(account.Active);
        Assert.Equal(0, account.Version);
        Assert.Equal(DateTimeKind.Utc, account.CreatedAt.Kind);
        Assert.Equal(DateTimeKind.Utc, account.UpdatedAt.Kind);
        Assert.NotEqual(TestData.Password, account.PasswordHash);
    }

    [Fact]
    public void CreateManager_CreatesActiveGestor()
    {
        var manager = Account.CreateManager("Gestor", "gestor@example.com", TestData.PasswordHash());

        Assert.Equal(Role.GESTOR, manager.Role);
        Assert.True(manager.Active);
        Assert.NotEqual(Guid.Empty, manager.Id);
    }

    [Fact]
    public void Rename_WithInvalidName_ThrowsAndPreservesPreviousName()
    {
        var account = Account.RegisterCitizen("Maria", "maria@example.com", TestData.PasswordHash());

        Assert.ThrowsAny<ArgumentException>(() => account.Rename("A"));

        Assert.Equal("Maria", account.Name);
    }

    [Fact]
    public void Deactivate_MarksAccountInactive()
    {
        var account = Account.RegisterCitizen("Maria", "maria@example.com", TestData.PasswordHash());

        account.Deactivate();

        Assert.False(account.Active);
        Assert.Equal(DateTimeKind.Utc, account.UpdatedAt.Kind);
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData("A")]
    public void RegisterCitizen_WithInvalidName_Throws(string name)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            Account.RegisterCitizen(name, "maria@example.com", TestData.PasswordHash()));
    }

    [Fact]
    public void RegisterCitizen_WithNameTooLong_Throws()
    {
        var name = new string('a', Account.NameMaxLength + 1);

        Assert.ThrowsAny<ArgumentException>(() =>
            Account.RegisterCitizen(name, "maria@example.com", TestData.PasswordHash()));
    }

    [Theory]
    [InlineData("sem-arroba")]
    [InlineData("com espaço@example.com")]
    [InlineData("@example.com")]
    public void RegisterCitizen_WithInvalidEmail_Throws(string email)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            Account.RegisterCitizen("Maria", email, TestData.PasswordHash()));
    }

    [Fact]
    public void RegisterCitizen_WithEmailTooLong_Throws()
    {
        var email = new string('a', 244) + "@example.com";

        Assert.ThrowsAny<ArgumentException>(() =>
            Account.RegisterCitizen("Maria", email, TestData.PasswordHash()));
    }

    [Theory]
    [InlineData("")]
    [InlineData("curto")]
    [InlineData("hash com espaço e tamanho suficiente")]
    public void RegisterCitizen_WithInvalidPasswordHash_Throws(string passwordHash)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            Account.RegisterCitizen("Maria", "maria@example.com", passwordHash));
    }

    [Fact]
    public void RegisterCitizen_WithPasswordHashTooLong_Throws()
    {
        var passwordHash = new string('a', Account.PasswordHashMaxLength + 1);

        Assert.ThrowsAny<ArgumentException>(() =>
            Account.RegisterCitizen("Maria", "maria@example.com", passwordHash));
    }

    [Fact]
    public void Account_DoesNotExposePlainTextPasswordProperty()
    {
        Assert.Null(typeof(Account).GetProperty("Password"));
        Assert.NotNull(typeof(Account).GetProperty(nameof(Account.PasswordHash)));
    }
}
