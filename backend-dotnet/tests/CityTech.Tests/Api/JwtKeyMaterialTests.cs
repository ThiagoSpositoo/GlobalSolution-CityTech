using System.Security.Cryptography;
using CityTech.Api.Security;

namespace CityTech.Tests.Api;

/// <summary>
/// Cobre o caminho de nuvem: o App Service recebe as chaves por variável de ambiente
/// (JWT_PRIVATE_KEY_PEM/JWT_PUBLIC_KEY_PEM) e o código continua lendo arquivos PEM.
/// </summary>
public sealed class JwtKeyMaterialTests : IDisposable
{
    private readonly string _directory =
        Path.Combine(Path.GetTempPath(), "citytech-jwt-test-" + Guid.NewGuid().ToString("N"));

    [Fact]
    public void MaterializePemWritesBothKeysForSigningAndValidation()
    {
        using var rsa = RSA.Create(2048);
        var privatePem = rsa.ExportPkcs8PrivateKeyPem();
        var publicPem = rsa.ExportSubjectPublicKeyInfoPem();

        var (privatePath, publicPath) = JwtOptions.MaterializePem(privatePem, publicPem, _directory);

        Assert.True(File.Exists(privatePath));
        Assert.True(File.Exists(publicPath));
        Assert.Equal(privatePem, File.ReadAllText(privatePath));
        Assert.Equal(publicPem, File.ReadAllText(publicPath));

        using var loaded = RSA.Create();
        loaded.ImportFromPem(File.ReadAllText(privatePath));
        using var verifier = RSA.Create();
        verifier.ImportFromPem(File.ReadAllText(publicPath));

        var payload = new byte[] { 1, 2, 3, 4 };
        var signature = loaded.SignData(payload, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        Assert.True(verifier.VerifyData(payload, signature, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1));
    }

    [Fact]
    public void MaterializePemRejectsMissingKeyMaterial()
    {
        Assert.Throws<InvalidOperationException>(() =>
            JwtOptions.MaterializePem("not-a-private-key", "-----BEGIN PUBLIC KEY-----\n", _directory));
        Assert.Throws<InvalidOperationException>(() =>
            JwtOptions.MaterializePem("-----BEGIN PRIVATE KEY-----\n", "not-a-public-key", _directory));
    }

    public void Dispose()
    {
        if (Directory.Exists(_directory))
        {
            Directory.Delete(_directory, recursive: true);
        }
    }
}
