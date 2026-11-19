# CityTech — Backend .NET

**Global Solution 2026/2 — FIAP | CitizenTech**

**Disciplina:** Advanced Business Development with .NET

**Repositório:** https://github.com/ThiagoSpositoo/GlobalSolution-CityTech

## 1. Visão geral

O CityTech é uma plataforma de monitoramento e zeladoria urbana voltada à participação dos cidadãos na identificação e no acompanhamento de problemas de infraestrutura das cidades.

A solução permite que cidadãos registrem ocorrências, como buracos em vias públicas, falhas de iluminação, problemas de acessibilidade e descarte irregular de resíduos.

O backend .NET é responsável pela **identidade, autenticação, autorização e acompanhamento das ocorrências**.

A arquitetura utiliza dois serviços principais:

- **Backend .NET:** cadastro, autenticação, emissão de JWT e gerenciamento de acompanhamentos.
- **Backend Java:** gerenciamento de ocorrências, categorias, histórico, triagem e integração com inteligência artificial.

Cada backend possui responsabilidades e persistência próprias, comunicando-se por APIs REST.

### Estado atual — 19/11/2026

O backend .NET foi implementado, compilado e testado localmente com sucesso.

Foram comprovados:

- Inicialização da API ASP.NET Core na porta 8081.
- Conexão com SQL Server.
- Cadastro de usuário por API REST.
- Login e emissão de JWT RS256.
- Autenticação utilizando o token emitido pelo .NET.
- Validação do JWT pelo backend Java, com resposta HTTP 200.
- Criação autenticada de ocorrência pelo Java, com persistência no Oracle.
- Execução bem-sucedida do build e da suíte de testes .NET.

A integração positiva de autenticação entre os dois backends foi comprovada. O fluxo específico de criação de acompanhamentos do .NET consultando uma ocorrência no Java real permanece como teste adicional de integração.

## 2. Tecnologias utilizadas

| Tecnologia | Utilização |
|---|---|
| .NET 10 | Plataforma de desenvolvimento |
| ASP.NET Core Minimal APIs | Construção dos endpoints REST |
| Entity Framework Core 10 | Persistência e mapeamento objeto-relacional |
| SQL Server 2022 Developer | Banco de dados relacional |
| JWT RS256 | Autenticação baseada em tokens assinados |
| ASP.NET Core Rate Limiting | Controle de requisições |
| ASP.NET Core HealthChecks | Monitoramento da disponibilidade |
| Swagger / OpenAPI | Documentação interativa |
| xUnit | Testes unitários e de integração |
| Docker | Infraestrutura local de desenvolvimento |

O desenvolvimento foi realizado com .NET SDK 10.0.404, runtime 10.0.15, EF Core 10.0.15 e xUnit 2.9.3.

## 3. Requisitos implementados

### 3.1. API RESTful com Minimal APIs

A aplicação utiliza ASP.NET Core Minimal APIs com endpoints organizados por responsabilidade.

As principais funcionalidades são:

- Cadastro de cidadãos.
- Autenticação por e-mail e senha.
- Consulta dos dados do usuário autenticado.
- Criação de acompanhamentos de ocorrências.
- Listagem e consulta de acompanhamentos.
- Atualização e exclusão de acompanhamentos.
- Verificação da saúde da aplicação.

Os endpoints utilizam validações, respostas HTTP adequadas e tratamento padronizado de erros.

### 3.2. Swagger e OpenAPI

A API disponibiliza documentação interativa, incluindo endpoints, contratos de entrada e saída, autenticação e códigos HTTP.

**Acesso local:**

http://localhost:8081/swagger

A documentação pode ser utilizada para explorar as rotas e realizar chamadas de teste.

**Observação:** durante o teste manual, o endpoint de cadastro exigiu o cabeçalho `Idempotency-Key`, mas esse parâmetro não apareceu claramente na interface utilizada. A chamada foi realizada com sucesso pelo PowerShell, informando o cabeçalho. A exposição desse parâmetro no Swagger deve ser revisada para melhorar a documentação.

### 3.3. Idempotência

A API implementa idempotência persistida para operações de cadastro e acompanhamento.

O objetivo é evitar efeitos duplicados quando o cliente repete uma requisição, por exemplo, devido a uma falha de rede ou a um novo clique no botão de envio.

A implementação contempla:

- Identificação das requisições por `Idempotency-Key`.
- Verificação da chave e do conteúdo da requisição.
- Armazenamento de registros de idempotência.
- Reutilização da resposta em requisições equivalentes.
- Retorno de HTTP 409 em caso de reutilização incompatível da chave.
- Preservação de status HTTP, corpo e cabeçalho `Location` na resposta repetida.

A retenção mínima configurada é de 24 horas.

### 3.4. Rate Limiting

O projeto utiliza os recursos nativos do ASP.NET Core para limitar requisições.

As políticas protegem operações como:

- Cadastro de usuários.
- Tentativas de login.
- Operações de acompanhamento.

Ao ultrapassar os limites configurados, a API pode responder com HTTP 429 — Too Many Requests, incluindo o cabeçalho `Retry-After`.

Os limites são configuráveis por variáveis de ambiente.

### 3.5. Autenticação e autorização

A autenticação é implementada por meio de JWT com assinatura assimétrica RS256.

O backend .NET utiliza uma chave privada para assinar os tokens, enquanto o backend Java pode validá-los com a chave pública correspondente.

Os tokens incluem claims como:

- `sub`: identificador do usuário.
- `iss`: emissor do token.
- `aud`: audiência.
- `iat`: data de emissão.
- `exp`: expiração.
- `jti`: identificador do token.
- `roles`: papel do usuário.
- `kid`: identificador da chave de assinatura.

A validação contempla algoritmo, assinatura, emissor, audiência, validade e claims obrigatórias.

**Papéis definidos:**

- `CIDADAO`: usuário responsável pelo registro e acompanhamento das próprias ocorrências.
- `GESTOR`: usuário com permissões administrativas previstas na arquitetura do sistema.

O cadastro público cria contas do tipo `CIDADAO`. A criação de um gestor pode ser realizada por configuração controlada de seed local.

As operações administrativas sobre ocorrências pertencem ao backend Java.

### 3.6. HealthChecks

A aplicação possui três endpoints de monitoramento:

| Endpoint | Finalidade |
|---|---|
| `/health/live` | Verificar se o processo está ativo |
| `/health` | Verificar a disponibilidade do SQL Server |
| `/health/ready` | Verificar as dependências necessárias, incluindo SQL Server e Java |

Essas verificações auxiliam no diagnóstico da aplicação e em sua futura execução em infraestrutura de nuvem.

### 3.7. Testes automatizados

O projeto utiliza xUnit para validar regras de negócio, persistência e endpoints HTTP.

A suíte possui 77 testes na execução documentada do projeto, abrangendo:

- Cadastro e autenticação.
- Geração e validação JWT.
- Requisições não autorizadas — HTTP 401.
- Regras de propriedade de recursos.
- CRUD de acompanhamentos.
- Paginação.
- Controle de versão e concorrência.
- Idempotência, replay e conflitos.
- Rate limiting — HTTP 429.
- Swagger.
- HealthChecks.
- JSON malformado.
- Seed de usuários.
- CORS.
- Respostas HTTP 404, 403 e 503 associadas à integração Java.
- Persistência e regras de domínio.

**Em 19/11/2026, o build e os testes da solução foram executados novamente com sucesso no ambiente local.**

## 4. Arquitetura do projeto

A solução utiliza separação de responsabilidades entre domínio, infraestrutura, aplicação e testes.

```text
backend-dotnet/
├── CityTech.slnx
├── dotnet-tools.json
├── src/
│   ├── CityTech.Api/
│   │   ├── Endpoints REST
│   │   ├── Autenticação e segurança
│   │   ├── Integrações externas
│   │   └── HealthChecks
│   ├── CityTech.Domain/
│   │   ├── Entidades
│   │   ├── Enums
│   │   └── Regras de negócio
│   └── CityTech.Infrastructure/
│       ├── Entity Framework Core
│       ├── DbContext
│       ├── Configurações de persistência
│       └── Migrations
└── tests/
    └── CityTech.Tests/
```

### Princípios adotados

- O domínio não depende diretamente do Entity Framework Core.
- A infraestrutura implementa a persistência das entidades do domínio.
- A API expõe os casos de uso por endpoints REST.
- Os testes verificam regras de domínio, persistência e comportamento HTTP.
- As integrações externas possuem contratos próprios.

Essa separação facilita manutenção, testes automatizados e evolução da solução.

## 5. Modelo de dados

O backend .NET utiliza banco SQL Server próprio, separado do Oracle utilizado pelo backend Java.

### Entidades principais

**Account**

Representa a conta de um usuário.

Possui identificador UUID, nome, e-mail normalizado, hash de senha, papel, status de atividade, datas e versão de concorrência.

O sistema não persiste senhas em texto puro.

**FollowUp**

Representa o acompanhamento de uma ocorrência por um usuário.

Possui:

- Identificador UUID.
- Referência ao usuário.
- Identificador da ocorrência no Java.
- Nota opcional.
- Datas de criação e atualização.
- Versão para controle de concorrência.

A combinação entre usuário e ocorrência possui restrição de unicidade.

**IdempotencyRecord**

Armazena o controle de requisições repetidas.

Contém:

- Identificador.
- Escopo da operação.
- Chave de idempotência.
- Hash SHA-256 da requisição.
- Status HTTP.
- Corpo da resposta.
- Cabeçalho `Location`.
- Informações de expiração.

### Tabelas SQL Server

| Tabela | Responsabilidade |
|---|---|
| `accounts` | Usuários, credenciais e papéis |
| `follow_ups` | Acompanhamentos de ocorrências |
| `idempotency_records` | Controle de requisições repetidas |

### Decisões de persistência

**Identificadores UUID:** usados para identificar entidades sem dependência de sequências compartilhadas.

**Sem chaves estrangeiras entre bancos:** o identificador de uma ocorrência é armazenado no SQL Server, mas validado por chamada à API Java.

**Datas em UTC:** a persistência exige tratamento consistente de datas e horários.

**Concorrência otimista:** o campo `version` permite detectar atualizações conflitantes.

**Migrations versionadas:** o schema é gerenciado por migrations do Entity Framework Core, sem depender de `EnsureCreated`.

A migration inicial está localizada em:

`src/CityTech.Infrastructure/Persistence/Migrations/20261117072823_InitialCreate.cs`

A migration `AddIdempotencyResponseLocation` também foi aplicada ao banco de desenvolvimento.

## 6. Endpoints principais

A API utiliza o prefixo `/api/v1`.

### Autenticação

| Método | Endpoint | Descrição |
|---|---|---|
| POST | `/api/v1/auth/register` | Cadastrar cidadão |
| POST | `/api/v1/auth/login` | Autenticar usuário e emitir JWT |
| GET | `/api/v1/auth/me` | Consultar usuário autenticado |

### Acompanhamentos

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/api/v1/followups` | Listar acompanhamentos |
| POST | `/api/v1/followups` | Criar acompanhamento |
| GET | `/api/v1/followups/{id}` | Consultar acompanhamento |
| PATCH | `/api/v1/followups/{id}` | Atualizar acompanhamento |
| DELETE | `/api/v1/followups/{id}` | Excluir acompanhamento |

As rotas protegidas exigem JWT válido e aplicam as regras de autorização e propriedade do domínio.

## 7. Integração com o backend Java

O CityTech foi dividido em dois backends com responsabilidades complementares.

**API .NET**

- Gerencia contas.
- Autentica usuários.
- Emite JWT RS256.
- Gerencia acompanhamentos.

**API Java**

- Gerencia ocorrências.
- Persiste dados no Oracle.
- Gerencia categorias e histórico.
- Realiza a triagem.
- Integra RabbitMQ e Spring AI.

### Integração JWT comprovada

Em 19/11/2026, foi realizado o seguinte teste:

1. A API .NET iniciou em `http://localhost:8081`.
2. Um cidadão foi cadastrado com sucesso pela rota `/api/v1/auth/register`, usando `Idempotency-Key`.
3. O usuário realizou login pela rota `/api/v1/auth/login`.
4. A API emitiu um `accessToken`.
5. O token foi enviado à API Java no cabeçalho `Authorization: Bearer`.
6. A rota `GET /api/v1/occurrences` respondeu **HTTP 200**.
7. Uma ocorrência também foi criada pela API Java com autenticação JWT e persistida no Oracle.

**Resultado:** a autenticação entre os dois serviços foi validada com sucesso.

Esse teste comprova a interoperabilidade dos tokens JWT emitidos pelo .NET e aceitos pelo Java.

### Limitação do teste integrado

O endpoint de criação de acompanhamentos do .NET possui integração para validar ocorrências na API Java antes de persistir o acompanhamento.

Essa lógica foi coberta por testes automatizados com handler HTTP controlado, incluindo cenários de indisponibilidade.

Entretanto, o teste positivo de criação de um acompanhamento utilizando simultaneamente o .NET e o Java reais não foi registrado nesta validação manual.

Essa distinção evita confundir testes simulados de integração com uma execução real entre os serviços.

## 8. Configuração e execução

### Pré-requisitos

- .NET SDK 10.
- Docker Desktop.
- SQL Server acessível.
- Banco `CityTech` com migrations aplicadas.
- Par de chaves RSA PEM compatível com o backend Java.
- Backend Java disponível quando for necessário testar a integração completa.

### Variáveis de ambiente

| Variável | Descrição |
|---|---|
| `DOTNET_DB_CONNECTION` | String de conexão do SQL Server |
| `JWT_PRIVATE_KEY_PATH` | Caminho da chave privada RSA |
| `JWT_PUBLIC_KEY_PATH` | Caminho da chave pública RSA |
| `JWT_ISSUER` | Emissor dos tokens |
| `JWT_AUDIENCE` | Audiência dos tokens |
| `JWT_KEY_ID` | Identificador da chave |
| `JWT_EXPIRES_MINUTES` | Tempo de expiração |
| `JAVA_API_BASE_URL` | Endereço do backend Java |
| `CORS_ALLOWED_ORIGINS` | Origens permitidas no ambiente Development |

Também existem parâmetros opcionais para seed de gestor e políticas de rate limiting.

Os arquivos de chave devem permanecer fora do repositório.

O `.env` da raiz é ignorado pelo Git, mas **a aplicação .NET não o carrega automaticamente**. As variáveis precisam ser configuradas no processo ou fornecidas pelo ambiente de execução.

### Exemplo de configuração local no PowerShell

```powershell
$env:DOTNET_DB_CONNECTION = "Server=127.0.0.1,1433;Database=CityTech;User Id=sa;Password=<SENHA_LOCAL>;TrustServerCertificate=True;Encrypt=True"

$env:JWT_PRIVATE_KEY_PATH = "C:\CAMINHO_PRIVADO\jwt-private.pem"
$env:JWT_PUBLIC_KEY_PATH = "C:\CAMINHO_PRIVADO\jwt-public.pem"

$env:JAVA_API_BASE_URL = "http://localhost:8080"
```

Os valores acima são exemplos. Não devem ser substituídos por credenciais reais em arquivos versionados.

`TrustServerCertificate=True` é destinado ao ambiente local com certificado autoassinado. Em produção, deve ser utilizada uma configuração adequada de validação de certificados.

### Instalar dependências e compilar

Dentro da pasta `backend-dotnet`:

```powershell
dotnet tool restore
dotnet restore CityTech.slnx
dotnet build CityTech.slnx
```

### Iniciar a aplicação

```powershell
dotnet run --project src/CityTech.Api
```

No ambiente local validado, a API iniciou em:

http://localhost:8081

Swagger:

http://localhost:8081/swagger

### Aplicar migrations

```powershell
dotnet ef database update `
  --project src/CityTech.Infrastructure `
  --startup-project src/CityTech.Api
```

Para gerar um script SQL idempotente:

```powershell
dotnet ef migrations script --idempotent `
  --project src/CityTech.Infrastructure `
  --startup-project src/CityTech.Api
```

O projeto utiliza `dotnet-ef` como ferramenta local, configurada em `dotnet-tools.json`.

## 9. Testes e resultados

Para executar os testes:

```powershell
dotnet test CityTech.slnx
```

Os testes de integração utilizam SQL Server real.

A fixture deriva um banco separado com o sufixo `_Test`, como `CityTech_Test`, aplica as migrations e prepara os dados necessários aos testes.

Ela não precisa excluir o banco principal nem remover volumes Docker.

Sem `DOTNET_DB_CONNECTION`, os testes que exigem SQL Server devem falhar explicitamente, em vez de produzir um resultado de sucesso artificial.

### Resultados registrados

| Teste | Resultado |
|---|---|
| Compilação da solução | Sucesso |
| Suíte automatizada xUnit | Aprovada |
| Cadastro real via API .NET | Sucesso |
| Login real via API .NET | Sucesso |
| Emissão de JWT RS256 | Sucesso |
| JWT aceito pela API Java | HTTP 200 |
| Criação autenticada de ocorrência no Java | Sucesso |
| Persistência da ocorrência no Oracle | Confirmada |
| Acesso ao Swagger .NET | Sucesso |

A execução documentada da suíte registra **77 testes aprovados**, abrangendo regras de negócio, persistência e endpoints HTTP.

A compilação e os testes foram executados novamente com sucesso em 19/11/2026.

### Teste de cadastro com idempotência

Durante a validação manual, uma primeira tentativa de cadastro pelo Swagger retornou HTTP 400 porque o cabeçalho `Idempotency-Key` estava ausente.

Em seguida, o cadastro foi executado pelo PowerShell com uma chave UUID válida no cabeçalho.

O cadastro foi concluído com sucesso.

Esse teste confirmou a exigência de idempotência na operação de cadastro e revelou uma melhoria necessária na documentação interativa do Swagger.

## 10. Segurança

A solução adota os seguintes cuidados:

- Senhas armazenadas por hash.
- JWT com assinatura RSA.
- Chaves privadas fora do repositório.
- Validação de emissor, audiência, assinatura e expiração.
- Endpoints protegidos por autorização.
- Validação de propriedade dos acompanhamentos.
- Idempotência para operações sensíveis a duplicação.
- Rate limiting.
- Tratamento padronizado de erros.
- Separação de bancos por serviço.
- Configuração de CORS sem liberar indiscriminadamente todas as origens.

Nenhuma senha, token, chave de API ou string de conexão com credenciais reais deve ser publicada no GitHub.

O arquivo `.env` não deve ser versionado.

## 11. Limitações e melhorias futuras

A solução está funcional no ambiente local, mas existem possibilidades de melhoria:

- Validar manualmente o fluxo completo de criação de acompanhamentos .NET → Java utilizando os dois serviços reais.
- Expor claramente o cabeçalho `Idempotency-Key` nos contratos OpenAPI das operações que o exigem.
- Executar testes adicionais em ambiente de nuvem.
- Configurar monitoramento e observabilidade para produção.
- Reforçar políticas de gerenciamento e rotação de chaves.
- Validar o comportamento integrado com o aplicativo Mobile em ambiente Android.

Esses pontos não anulam os recursos implementados, mas representam oportunidades de evolução e validação.

## 12. Entrega acadêmica

O backend .NET foi desenvolvido como parte da Global Solution 2026/2 — CitizenTech.

O projeto está disponível no repositório:

https://github.com/ThiagoSpositoo/GlobalSolution-CityTech

A entrega deve seguir as instruções da disciplina no Portal FIAP, incluindo identificação dos integrantes, referência ao repositório e material de apresentação, quando aplicável.

O repositório contém código-fonte, migrations, configuração de exemplo, testes automatizados e documentação técnica.

Durante o desenvolvimento foram utilizadas ferramentas de inteligência artificial como apoio à implementação e à revisão do projeto. O código, os testes e os resultados apresentados devem ser compreendidos e validados pelos integrantes do grupo.

---

**CityTech — Tecnologia para cidades mais inteligentes, participativas e eficientes.**