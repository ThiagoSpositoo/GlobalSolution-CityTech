# Código do backend .NET

**Estado: fundação, persistência e vertical HTTP .NET implementadas.** A solução `CityTech.slnx` separa `CityTech.Api` (endpoints Minimal API, JWT, health e integrações), `CityTech.Domain` (entidades/invariantes), `CityTech.Infrastructure` (EF Core, configurações e migrations) e `tests/CityTech.Tests`.

O domínio não referencia EF Core; a infraestrutura referencia o domínio; a API referencia a infraestrutura. `Contracts`, `Endpoints`, `Security`, `Services` e `Health` separam contratos HTTP, composição e integrações. A integração positiva com o Java real ainda depende da implementação desse backend.

Detalhes de schema, comandos e resultados: [README do backend](../README.md).
