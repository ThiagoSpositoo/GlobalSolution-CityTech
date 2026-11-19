namespace CityTech.Domain.Enums;

/// <summary>
/// Papéis previstos no contrato. O cadastro público só pode criar <see cref="CIDADAO"/>.
/// </summary>
public enum Role
{
    CIDADAO = 0,
    GESTOR = 1
}
