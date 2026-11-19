# Backend .NET — identidade e acompanhamento

**Estado: vertical .NET implementada e verificada localmente em 17/11/2026.** Existem cadastro/login, JWT RS256, proteção de rotas, CRUD de acompanhamentos, validação da ocorrência no Java, idempotência, rate limiting, health checks e Swagger. A integração positiva com o Java real permanece pendente até o backend Java existir. Requisitos NET-01 a NET-11 da [matriz](../docs/requisitos-global-solution.md); contratos e modelo: [contratos](../docs/contratos-api.md) e [modelo](../docs/modelo-dominio.md).

Base implementada: **.NET 10** (SDK 10.0.404, runtime 10.0.15), ASP.NET Core **Minimal API**, **EF Core 10.0.15**, **SQL Server 2022 Developer** e **xUnit 2.9.3**.

## 1. Escopo implementado

- Solução `CityTech.slnx` com `CityTech.Api`, `CityTech.Domain`, `CityTech.Infrastructure` e `CityTech.Tests`.
- Entidades `Account`, `FollowUp`, `IdempotencyRecord` e enum `Role` (`CIDADAO`, `GESTOR`).
- `CityTechDbContext` com Fluent API, tipos/tamanhos, PKs, índices únicos, relacionamento local, checks, UTC e concorrência otimista.
- Migration inicial versionada e aplicada ao SQL Server local.
- Cadastro público somente como `CIDADAO`, login, `/auth/me`, hash de senha com `PasswordHasher` e seed local opcional de `GESTOR`.
- JWT RS256 com `kid`, `iss`, `aud`, `exp`, `iat`, `jti`, `sub` e `roles`; validação de algoritmo, assinatura, emissor, audiência, validade e claims.
- CRUD de acompanhamentos com paginação, propriedade por `sub`, concorrência otimista e chamada autenticada ao Java antes da gravação.
- Idempotência persistida em cadastro/acompanhamento, incluindo replay do status, corpo e `Location`; conflito de payload retorna `409`.
- Rate limiting nativo com `429`/`Retry-After`, Swagger/OpenAPI e envelope de erros sem detalhes internos.
- Health checks `/health/live`, `/health` (SQL Server) e `/health/ready` (SQL Server + Java).
- Testes de domínio, persistência e endpoints HTTP com SQL Server real e Java simulado.

## 2. Limites e pendências

- O Java ainda não é executável. Por isso, o cliente .NET→Java foi verificado com handler HTTP controlado e com a falha real de conexão (`503`), mas o caminho positivo entre os dois processos ainda não foi executado.
- Não há endpoint .NET exclusivo de gestor: o .NET emite/valida os dois papéis, enquanto as operações administrativas do produto pertencem ao Java conforme o contrato.
- Mobile, IA, RabbitMQ da aplicação, Azure, pipeline e scripts Oracle não fazem parte desta vertical.
- O modelo de `Account` guarda somente `PasswordHash`; senha em texto puro existe apenas no DTO/configuração durante o processamento e nunca é persistida.

## 3. Estrutura

```text
backend-dotnet/
├── CityTech.slnx
├── dotnet-tools.json              # dotnet-ef 10.0.15 local
├── src/
│   ├── CityTech.Api/              # endpoints, segurança, health, serviços e host
│   ├── CityTech.Domain/           # entidades, enum e invariantes
│   └── CityTech.Infrastructure/   # DbContext, configurações e migrations
└── tests/
    └── CityTech.Tests/            # domínio + integração SQL Server
```

Separação adotada: o domínio não referencia EF Core; a infraestrutura referencia o domínio; a API referencia a infraestrutura. Os endpoints ficam separados entre autenticação e acompanhamentos, e contratos/segurança/health/integração Java possuem componentes próprios.

## 4. Modelo físico

Tabelas e colunas usam `snake_case`, independentes do Oracle. A migration está em `src/CityTech.Infrastructure/Persistence/Migrations/20261117072823_InitialCreate.cs`.

| Tabela | Conteúdo e restrições principais |
|---|---|
| `accounts` | `id` UUID PK; `name` 2–120; `email` 254; `email_normalized` 254 único e minúsculo; `password_hash` 512; `role` `CIDADAO`/`GESTOR`; `active`; `created_at`/`updated_at` UTC; `version` bigint de concorrência |
| `follow_ups` | `id` UUID PK; `user_id` FK local para `accounts` (cascade); `occurrence_id` UUID **sem FK** para o Oracle; `note` 500 opcional; `created_at`/`updated_at` UTC; `version`; único (`user_id`, `occurrence_id`) |
| `idempotency_records` | `id` UUID PK; `scope` 120; `idempotency_key` 128; `request_hash` SHA-256; `status_code`; corpo e `Location` da resposta; retenção mínima de 24 h; único (`scope`, `idempotency_key`) |

Decisões aplicadas:

- **Sem FK entre bancos:** `follow_ups.occurrence_id` é opaco; a futura validação será feita na API Java antes de gravar.
- **UTC:** um `ValueConverter` lê `DateTime` como UTC e `SaveChanges` rejeita valor não UTC antes de persistir.
- **Concorrência:** `version` é token de concorrência; `SaveChanges` incrementa o valor em `Account`/`FollowUp` modificados. O `WHERE` usa a versão original; conflito gera `DbUpdateConcurrencyException`.
- **Integridade no banco:** check constraints protegem papel, versão, tamanhos de idempotência, status HTTP e expiração, além das validações de domínio.
- **Migrations:** não há `EnsureCreated`; o schema é criado por migration versionada.

## 5. Configuração e execução

A conexão e as chaves vêm **exclusivamente** de variáveis de ambiente. O `.env` da raiz é ignorado pelo Git, mas o .NET **não o carrega automaticamente**; exporte as variáveis no processo ou configure segredos no host. As chaves RSA devem ser PEM locais fora do Git.

```powershell
# Exemplo com placeholders; use a senha local real apenas no seu ambiente.
$env:DOTNET_DB_CONNECTION = "Server=127.0.0.1,1433;Database=CityTech;User Id=<usuario-local>;Password=<senha-local>;TrustServerCertificate=True;Encrypt=True"
$env:JWT_PRIVATE_KEY_PATH = "C:\caminho-fora-do-git\private.pem"
$env:JWT_PUBLIC_KEY_PATH = "C:\caminho-fora-do-git\public.pem"

dotnet tool restore
dotnet restore CityTech.slnx
dotnet build CityTech.slnx
dotnet run --project src/CityTech.Api
```

Configuração adicional:

- `JWT_ISSUER`, `JWT_AUDIENCE`, `JWT_KEY_ID` e `JWT_EXPIRES_MINUTES` (padrões documentados em `.env.example`);
- `JAVA_API_BASE_URL` (padrão `http://localhost:8080`);
- `CORS_ALLOWED_ORIGINS`: lista separada por vírgulas para Expo Web/LAN; usada somente em `Development` e, quando definida, substitui `Cors:AllowedOrigins` de `appsettings.Development.json`;
- `MANAGER_SEED_NAME`, `MANAGER_SEED_EMAIL` e `MANAGER_SEED_PASSWORD`: opcionais, mas devem ser definidos juntos; o seed é idempotente e nunca promove conta cidadã;
- `RATE_LIMIT_LOGIN_PER_MINUTE`, `RATE_LIMIT_REGISTER_PER_HOUR` e `RATE_LIMIT_FOLLOWUPS_PER_MINUTE`.

Swagger: `http://localhost:8081/swagger`. O profile HTTP escuta em `0.0.0.0:8081`, permitindo Android Emulator e IP LAN quando firewall/rede autorizarem. CORS aceita apenas origens configuradas, métodos/headers necessários e expõe `Retry-After`, `Idempotent-Replayed` e `Location`; não usa credenciais nem origem curinga. A API falha na inicialização, com mensagem clara, se conexão, chaves ou origens Development estiverem ausentes/inválidas.

> `TrustServerCertificate=True` é adequado apenas ao SQL Server local com certificado autoassinado. Em Azure SQL/produção, valide o certificado e não reutilize essa configuração sem revisão.

### Migration e banco

```powershell
dotnet tool restore

dotnet ef migrations add NomeDaMigration `
  --project src/CityTech.Infrastructure `
  --startup-project src/CityTech.Api `
  --output-dir Persistence/Migrations

dotnet ef database update `
  --project src/CityTech.Infrastructure `
  --startup-project src/CityTech.Api

dotnet ef migrations script --idempotent `
  --project src/CityTech.Infrastructure `
  --startup-project src/CityTech.Api
```

A conexão precisa estar exportada para os comandos do EF. O `dotnet-ef` é uma ferramenta **local** (`dotnet-tools.json`, versão 10.0.15); não é necessária instalação global.

## 6. Testes

```powershell
$env:DOTNET_DB_CONNECTION = "Server=127.0.0.1,1433;Database=CityTech;User Id=<usuario-local>;Password=<senha-local>;TrustServerCertificate=True;Encrypt=True"

dotnet test CityTech.slnx
```

- A fixture usa SQL Server real. Ela deriva o banco de teste do banco configurado com o sufixo `_Test` (por exemplo, `CityTech_Test`), aplica as migrations e limpa apenas as linhas das três tabelas antes de cada teste. **Não remove o banco nem volumes.**
- Sem `DOTNET_DB_CONNECTION`, os testes de integração falham com mensagem explícita; não são marcados como aprovados nem ignorados silenciosamente.
- Cobertura atual: **77 testes** de domínio, persistência e HTTP. Além dos 61 casos da fundação, cobrem cadastro, login/JWT, `401`, propriedade, CRUD, versão, idempotência/replay/conflito/concorrência, `429`, Swagger, health, JSON malformado, seed, CORS e falhas `404/403/503` do Java.

Resultado real mais recente: `dotnet build` com **0 avisos e 0 erros** e VSTest com **77/77 aprovados** contra SQL Server. O teste CORS confirmou preflight/origem configurada e ausência de `Access-Control-Allow-Origin` para origem desconhecida. A migration `AddIdempotencyResponseLocation` foi aplicada ao banco de desenvolvimento. Requisições em processo HTTP real confirmaram `201`/replay, login `200`, `/auth/me` `200/401`, Swagger `200`, JSON inválido `400` e, sem Java, readiness/criação de acompanhamento `503`.

## 7. Segurança e limites

- Nenhuma senha, token ou connection string real é versionada. O `.env` é ignorado e não deve ser exibido em logs, capturas ou respostas.
- `PasswordHash` recebe hash produzido pelo serviço de autenticação; não há armazenamento de senha em claro.
- `IdempotencyRecord` guarda apenas respostas de cadastro/acompanhamento, sem token ou senha, com retenção mínima de 24 h.
- `FollowUp` não copia status, categoria ou descrição da ocorrência; o detalhe é obtido no Java.
- A migration inicial só cria estruturas novas. Não há operação destrutiva, `EnsureCreated`, drop de volume ou deploy.

## 8. Próximo passo

Executar a integração positiva .NET→Java com o mesmo JWT/chave pública e depois o roteiro Mobile em Android. O ponto de retomada, bloqueios e resultados verificados estão em [docs/progresso.md](../docs/progresso.md).
