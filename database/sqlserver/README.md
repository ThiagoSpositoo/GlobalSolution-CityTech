# SQL Server / Azure SQL — domínio .NET

**Estado: implementado e validado localmente.** SQL Server 2022 Developer é executado pelo profile Compose `dotnet`; Azure SQL continua futuro e condicionado a autorização/custos. O modelo efetivo está documentado em [contas e acompanhamentos](../../docs/modelo-dominio.md).

EF Core é a fonte de verdade do schema .NET. As migrations versionadas estão em `backend-dotnet/src/CityTech.Infrastructure/Persistence/Migrations/`:

- `20261117072823_InitialCreate`: `accounts`, `follow_ups`, `idempotency_records`, índices, checks e a única FK local;
- `20261117125534_AddIdempotencyResponseLocation`: persiste o `Location` necessário ao replay idempotente.

`follow_ups.occurrence_id` é apenas uma referência UUID ao domínio Java/Oracle, sem FK entre bancos. O banco não armazena ocorrências completas nem senhas em texto.

Para aplicar ou atualizar o schema, exporte `DOTNET_DB_CONNECTION` e execute em `backend-dotnet/`:

```bash
dotnet tool restore
dotnet ef database update --project src/CityTech.Infrastructure --startup-project src/CityTech.Api
```

Os testes xUnit derivam `CityTech_Test`, aplicam as mesmas migrations e limpam somente linhas das tabelas. A execução mais recente aprovou **77/77 testes** contra SQL Server real.

O DDL da entrega DevOps deverá estar em **`/scripts/script-bd.sql`**, exportado/revisado a partir da mesma versão do modelo .NET. Não manter duas fontes divergentes de schema. Demonstrar CRUD com SELECT diretamente no banco cloud, não só GET da API.

O Compose cria o serviço/volume, não o schema da aplicação nem um usuário restrito. As migrations EF criam/atualizam o banco configurado; SA local é somente administração inicial. Não há `EnsureCreated`, drop automático de banco ou remoção de volume.
