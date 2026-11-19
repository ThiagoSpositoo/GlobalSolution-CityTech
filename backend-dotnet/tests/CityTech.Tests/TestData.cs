using System.Security.Cryptography;
using System.Text;
using CityTech.Domain.Entities;

namespace CityTech.Tests;

internal static class TestData
{
    public const string Password = "senha-ficticia";

    public static string PasswordHash(string password = Password) =>
        Convert.ToBase64String(SHA256.HashData(Encoding.UTF8.GetBytes(password)));

    public static string RequestHash(string body) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(body))).ToLowerInvariant();

    public static Account NewCitizen(string email = "cidadao@example.com") =>
        Account.RegisterCitizen("Cidadão Teste", email, PasswordHash());

    public static Account NewManager(string email = "gestor@example.com") =>
        Account.CreateManager("Gestor Teste", email, PasswordHash());
}
