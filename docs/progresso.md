# Progresso e retomada — CityTech

Última atualização: **18/11/2026**.

## 1. Ponto exato de retomada

**Etapas 1–5A/.NET concluídas; vertical 5B/Java, Etapa 7/Mobile e persistências Oracle/MongoDB locais implementadas/verificadas no escopo autorizado.** O .NET mantém **77/77 testes** aprovados contra SQL Server. O Java entrega CRUD/paginação, histórico, indicadores, JWT RS256/papéis, Swagger, outbox, RabbitMQ e pipeline de sugestão/revisão; após a correção do vínculo CORS, **41 testes padrão** passaram e 1 AMQP opt-in foi ignorado por padrão. Em 18/11, um smoke E2E real comprovou .NET → Java → Oracle → RabbitMQ → consumidor/fallback IA → .NET, além de gestão, triagem e revisão humana. O MongoDB possui 3 collections, 30 documentos comparáveis ao Oracle e **25/25 assertions** aprovadas. O Mobile possui rotas, autenticação segura, ocorrências, acompanhamentos, gestão, IA e Sobre; TypeScript/lint, **8/8 testes**, Expo Doctor 20/20 e bundle Web passaram. Expo Web e CORS reais responderam em `19006`, mas a navegação manual e Android ainda permanecem pendentes. A conexão e o schema JPA no Oracle institucional foram validados em 18/11; LLM externo/embeddings, APK e Firebase permanecem pendentes.

Git em `main` com identidade local. A fundação 4A está em **`d4b9eea`** e a vertical 5A em **`6bc996f`**. As alterações posteriores ainda aguardam commit local ao final da revisão. SQL Server foi validado na etapa .NET; RabbitMQ 4.4.0 estava healthy e foi usado no teste AMQP real; MongoDB 8.0.38 foi validado no P0.3.

A preparação documental para continuidade entre sessões está concluída. Leia o [manual permanente](../AGENTS.md) e confira o estado real dos arquivos antes de agir.

**Próxima ação:** executar o roteiro manual no Mobile Web já servido e depois no Android; em paralelo, obter provedor/modelo IA autorizado, integrar o `ChatModel` real e medir a avaliação RAG. Executar os testes PL/SQL e relatórios no Oracle institucional somente se ainda não tiverem sido aplicados nesse schema. Depois, corrigir achados reais e somente com autorização gerar/assinar APK e publicar no Firebase App Distribution. Deploy e operações externas continuam fora do escopo. Relatório da infraestrutura: [verificação 3A](verificacao-etapa-3a.md).

## 2. Etapas concluídas e etapa atual

| Marco | Estado | Resultado |
|---|---|---|
| Etapa 1 — estrutura e arquitetura | Concluída, confirmada pelo usuário | PDF de 97 páginas lido, matriz das sete disciplinas, diagnóstico, decisões, plano, estrutura e 38 documentos/configurações |
| Continuidade documental pós-Etapa 1 | Concluída | `AGENTS.md`, este progresso e links/estado no README |
| Etapa 2 — ferramentas | **Concluída, aceita pelo usuário** | Lotes A/B/C verificados; Git/serviços transferidos ao escopo 3A; Oracle/Android/acessos não presumidos concluídos |
| Etapa 3A — Git e infraestrutura local | **Concluída e reverificada** | Git `main`/identidade local; três serviços healthy com 0 reinícios e testes básicos aprovados |
| Etapa 3B — backlog e contratos de integração | **Concluída (documentação)** | Backlog Epic/Feature/PBI, modelo de domínio, contratos REST/JWT, integração Mobile, ADRs/riscos e rastreabilidade; sem implementação |
| Etapa 4A — fundação e persistência .NET | **Concluída e verificada** | Solução .NET 10, entidades, EF Core, migration aplicada, API mínima com health e 61 testes; sem autenticação/CRUD/integrações |
| Etapa 5A — vertical .NET | **Concluída e verificada localmente** | Auth/JWT, gestor controlado, acompanhamentos, idempotência, 429, Swagger, health, CORS local e 77 testes; Java real pendente |
| Etapa 5B — vertical Java | **Implementada; Oracle local validado** | CRUD/paginação, DTO/erros, JWT/papéis, histórico, indicadores, Swagger, testes H2 e startup Oracle XE 21 |
| Etapa 6 — RabbitMQ/IA | **Parcialmente implementada/verificada** | AMQP real aprovado; corpus/adaptador/revisão implementados; LLM/embeddings reais pendentes |
| Etapa 7 — Mobile | **Implementada; integração em dispositivo pendente** | Expo Router, sessão segura, duas APIs, ocorrências, FollowUp CRUD, gestão/IA, Sobre, 8 testes e bundle Web |
| Etapa 8 — Oracle/PLSQL e MongoDB | **Implementada e validada localmente** | Oracle: DDL/seed/PLSQL/testes; Mongo: 3 collections, 30 documentos, consultas comparáveis e 25 assertions |
| Demais etapas | Planejadas | CI/CD, QA, APK/Firebase e entregas conforme plano |

O complemento documental anterior não iniciou a Etapa 2; esta começou com a nova solicitação explícita do usuário em 17/11/2026. Numeração canônica: [plano de desenvolvimento](plano-desenvolvimento.md), com backends 5A/.NET e 5B/Java.

## 3. Funcionalidades implementadas

O backend .NET expõe cadastro, login, sessão e CRUD de acompanhamentos em `/api/v1`, além de Swagger e health checks. Cadastro público cria somente `CIDADAO`; gestor é seed opcional por três variáveis de ambiente; senhas são persistidas apenas como hash. JWT RS256 contém/valida claims e caminhos protegidos exigem autenticação. Acompanhamentos são sempre filtrados por `sub`, usam `version`, validam a ocorrência no Java antes da gravação e não copiam dados do domínio Java.

Idempotência é obrigatória no cadastro e criação de acompanhamento: persiste hash/status/corpo/`Location`, repete resposta e rejeita chave reutilizada com payload diferente. Rate limits configuráveis retornam `429`/`Retry-After`. Readiness verifica SQL Server e Java; a indisponibilidade real do Java retornou `503`.

O Mobile em `mobile/` possui telas de boas-vindas, login, cadastro, dashboard, lista/nova/detalhe/edição de ocorrência, acompanhamentos, gestão e Sobre. Usa clientes Axios separados, Bearer compartilhado, `expo-secure-store`, guardas por sessão/papel, `version` otimista, `Idempotency-Key` e estados explícitos de loading/erro/vazio. Não há dados mockados de fallback. A integração real em dispositivo ainda não foi executada; Oracle local, binding e CORS estão validados isoladamente, mas a execução conjunta dos processos permanece pendente.

Git inicializado na raiz em `main`, identidade local fornecida pelo usuário e commits locais. Nenhum remoto/push, deploy, recurso cloud, publicação Firebase ou envio acadêmico realizado.

## 4. Verificações e testes realizados

### Histórico da Etapa 1 — 17/11/2026

Fonte: [relatório original](verificacao-etapa-1.md), mantido como registro histórico.

- Leitura integral das 97 páginas e diagnóstico local.
- 38 arquivos de documentação/configuração: UTF-8 válido e nenhum vazio.
- 26 links locais verificados, nenhum quebrado.
- 13 variáveis de interpolação Compose presentes no exemplo; nenhuma chave duplicada.
- Campos de segredo verificados no exemplo sem valores preenchidos.
- Mermaid equivalente entre Markdown e `.mmd`.
- SHA-256 do PDF preservado: `D1FDFCD0B1AB5A86DC5C152D23C7FF6E3CD2696CFEC6CA10D57FC5CB3882AE1A`.

### Complemento de continuidade — 17/11/2026

Arquivos: `AGENTS.md` e `docs/progresso.md` criados; `README.md` atualizado para indicar conclusão e permitir descoberta dos documentos.

Verificações executadas nesta solicitação:

- Releitura integral dos dois novos documentos e conferência de escopo, arquitetura, sete disciplinas, autorizações e retomada com as referências existentes.
- Comando PowerShell de validação concluído sem erros: leitura estrita UTF-8 dos três arquivos alterados, nenhum vazio, **31 referências Markdown locais válidas e zero links quebrados**.
- `Get-FileHash -Algorithm SHA256`: PDF com o mesmo hash registrado na Etapa 1.
- `Test-Path .git`: `False`; repositório local ainda não inicializado.
- Manual carregado pelo OpenCode nesta sessão como instrução do projeto.

Os resultados acima são deste complemento, separados das 26 referências verificadas historicamente na Etapa 1. Nenhuma instalação ou teste de aplicação foi executado.

### Início da Etapa 2 — 17/11/2026

- Autorizado pelo usuário: iniciar diagnóstico, propor versões e preparar plano; solicitar autorização antes de instalações globais; não implementar funcionalidades.
- Lidos manual, progresso, ambiente, README, arquitetura, matriz, plano, versões e runbook Compose.
- `Get-Command -All`, registro HKLM/HKCU, diretórios e serviços: Git/JDK/.NET/Node/Docker/Azure CLI ausentes; Python somente alias de 0 bytes. `Test-Path .git` e `.env`: False; status/diff Git bloqueados por ausência da ferramenta/repositório.
- CIM/PowerShell: Windows 11 Pro x64 build 26300 (26H2, revisão 9974), RAM 15,93 GiB, C: livre 217,55 GiB, WinGet 1.29.380; sem elevação. Virtualização firmware/hipervisor ativos; SLAT inconclusivo. Recursos WSL/VirtualMachinePlatform desabilitados; LanmanServer Running/Auto.
- `wsl --status`/`--version`: não instalado (saídas 50/1). Sem engine Docker para validar Compose.
- `winget show --source winget --disable-interactivity`: sete IDs consultados com sucesso. Versões propostas: Git 2.56.0.4, Temurin 21.0.13+9, .NET SDK 10.0.404, Docker Desktop 4.99.0, WSL 3.0.5 e Azure CLI 2.93.0.
- Node: catálogo LTS aponta para 26.13.1; `--version 24.22.3` falhou (exit 1). Seleção preservada em 24.22.3 via MSI oficial; checksum publicado consultado, arquivo ainda não baixado.
- API Adoptium, metadados .NET, checksums Node e documentação Docker/WSL/Azure consultados; disponibilidade de pacote não equivale a instalação ou build.
- Arquivos alterados: `README.md`, `docs/ambiente-desenvolvimento.md`, `docs/versoes-e-fontes.md`, `docs/plano-desenvolvimento.md` e `docs/progresso.md`.
- Plano documentado com lotes de autorização, comandos versionados, validações pós-instalação, Oracle/Android e dependências que podem ficar nos containers/wrappers.
- Verificação documental executada nesta sessão: cinco arquivos alterados com UTF-8 estrito, LF, conteúdo não vazio e newline final válidos; **26 referências Markdown locais válidas, zero quebradas**. Mermaid equivalente ao `.mmd`; SHA-256 do PDF igual ao histórico. Comando PowerShell concluído com saída 0.
- Nenhum programa instalado, sistema/PATH alterado, instalador baixado, credencial criada, serviço iniciado ou funcionalidade implementada.

### Retomada após interrupção — 17/11/2026

- `AGENTS.md` e este progresso relidos a pedido do usuário; resultados anteriores desta mesma sessão recuperados.
- Diagnósticos de ferramentas, hardware, WSL e catálogo já concluídos foram reaproveitados, sem repetição.
- Corrigido o registro da validação documental acima, que havia sido executada antes da interrupção e ainda constava como pendente.
- Diagnóstico e plano de instalação concluídos; **Etapa 2 permanece em andamento**, aguardando autorização dos lotes A/B/C. Próxima execução: começar pelo lote A aprovado, validar ferramentas e então preparar WSL/Docker se autorizado.
- Pendências de decisão: disponibilidade/versão Oracle e caminho de build Android. A retomada não concede autorização de instalação ou alteração do sistema.

### Instalações autorizadas — 17/11/2026

- **Lote A concluído:** Git 2.56.0.windows.4; Temurin Java 21.0.13+9/javac 21.0.13; .NET SDK 10.0.404; Node v24.22.3; npm/npx 11.19.1.
- WinGet Git/JDK/.NET: hashes verificados e instalações exit 0. Node: SHA-256 conferido, assinatura Valid/OpenJS Foundation, MSI `/passive /norestart` exit 0.
- PATH e JAVA_HOME configurados pelos instaladores; comandos resolvidos após recarregar ambiente do processo. JAVA_HOME de máquina aponta para `C:\Program Files\Eclipse Adoptium\jdk-21.0.13.9-hotspot\`.
- Testes básicos passaram: Git init/status temporário; Java JShell com asserção; console .NET net10.0 com restore/build/run; Node assert e versões npm/npx. Sem APIs/app ou projetos de aplicação na raiz.
- Primeira execução .NET criou automaticamente certificado HTTPS de desenvolvimento; não foi concedida confiança com `--trust`. Sem credenciais de aplicação/contas externas.
- **Lote B parcial:** WSL sem elevação falhou (exit 1); repetição com UAC/RunAs passou (exit 0). WSL 3.0.5.0, kernel 6.18.58.1-1, versão padrão 2.
- `wsl --status` informa WSL 2 sem condições de iniciar, apesar de exit 0. VirtualMachinePlatform habilitado e CBS RebootPending=True. **Usuário avisado; pausa antes de Docker/C; nenhum reboot automático.**
- Docker/Compose não instalados; lote C/Azure CLI não iniciado. Oracle institucional não confirmado e mantido pendente conforme solicitado.
- Logs, diretórios temporários, comandos, correção WSL e retomada detalhados em `docs/ambiente-desenvolvimento.md`, seção 7.
- Documentos atualizados nesta execução: progresso, ambiente e README. Validação PowerShell passou: três arquivos UTF-8/LF com newline final; **23 links locais válidos, zero quebrados**. `.git` e `.env` da raiz continuam ausentes.

### Pós-reinicialização — 17/11/2026

- Manual/progresso/ambiente relidos; lote A preservado, sem reinstalação ou repetição dos testes.
- WSL 3.0.5.0 padrão 2, VirtualMachinePlatform habilitado e CBS RebootPending=False; distribuição docker-desktop Running/WSL 2 após instalação.
- Docker Desktop **4.99.0.245822**, assinatura Docker Inc válida/hash conferido, instalado por usuário com exit 0. CLI/engine **29.9.3**, Compose **v5.7.0**.
- `docker info` confirmou Linux/kernel WSL2. Pull e hello-world passaram; Compose temporário `config --quiet`/`run` passaram; ambos containers encerrados com ExitCode=0.
- Azure CLI **2.93.0** instalado via WinGet, hash verificado, exit 0; versão e ajuda completa exit 0. Sem extensões/login.
- Correções: download Docker excedeu timeout, repetido com curl nativo; helper Docker fora do PATH antigo, resolvido recarregando PATH; ajuda Azure interrompida por filtro, repetida integralmente.
- Arquivos temporários, imagem, rede de teste e containers encerrados preservados; nenhuma operação destrutiva.
- Arquivos atualizados: README, progresso, ambiente, versões e `devops/README.md`. Resultados/comandos em ambiente, seção 8.
- Validação documental PowerShell: cinco arquivos UTF-8/LF/newline final válidos; **25 links locais válidos e zero quebrados**. `.git` e `.env` da raiz ausentes.
- Nenhum banco/broker iniciado, `.env` criado ou funcionalidade implementada. Instalações solicitadas concluídas; Etapa 2 integral ainda depende das pendências abaixo.

### Etapa 3A — 17/11/2026

- Usuário encerrou Etapa 2 no escopo das ferramentas e autorizou Git/infra local como 3A, sem backends. Backlog/contratos continuam como próximo trabalho da fase 3 canônica.
- Identidade fornecida/configurada localmente: Thiago Sposito / spositothiagoo@gmail.com. Autorizadas senhas aleatórias locais; EULA SQL Server Developer confirmada.
- `git init -b main`; `.gitignore` revisado e verificado. `.env` criado sem sobrescrita/exposição, ignorado.
- Pull de SQL Server 2022/Mongo 8.0/RabbitMQ 4-management confirmou linux/amd64; digests reais fixados em Compose/exemplo.
- Compose config quiet/up wait: exit 0. `citytech-sqlserver-1`, `citytech-mongodb-1`, `citytech-rabbitmq-1`: healthy, loopback, volumes persistentes montados.
- Versões: SQL Server 16.0.4325.4 Developer; MongoDB 8.0.38; RabbitMQ 4.4.0.
- Testes SQL SELECT/escrita temporária, Mongo autenticação/ping, Rabbit diagnóstico/HTTP autenticado/401 anônimo e TCP nas quatro portas passaram.
- Único bloqueio técnico inicial: PATH antigo sem Docker; recarga do ambiente do processo resolveu. Nenhuma incompatibilidade exigiu troca de tecnologia.
- Relatório de comandos, mounts, limites e operação: `docs/verificacao-etapa-3a.md`. Volumes e containers anteriores preservados.

### Revisão final da Etapa 3A — 17/11/2026

- Verificação somente de leitura: nenhuma instalação, recriação de container, remoção de volume ou mudança de arquitetura.
- `citytech-sqlserver-1`, `citytech-mongodb-1` e `citytech-rabbitmq-1`: todos **running/healthy**, **0 reinícios**, portas apenas em `127.0.0.1`.
- SQL: `sqlcmd` exit 0, **16.0.4325.4 Developer**, `SELECT 1` = 1. Mongo: autenticado, **8.0.38**, ping 1, exit 0. RabbitMQ: nó `rabbit@citytech-rabbitmq` booted, portas internas OK, **4.4.0**, exit 0.
- Volumes `citytech_sqlserver-data`, `citytech_mongodb-data` e `citytech_rabbitmq-data` presentes, além do volume anônimo do Mongo em `/data/configdb`.
- `.env` existe e é ignorado por `.gitignore:2`; `.env.example` **não** é ignorado. Nenhum segredo foi exibido.
- Git: raiz inicializada, branch `main`, identidade local correta, **sem remoto**. Commit inicial local **`2d4053c`** (41 arquivos, árvore limpa) criado ao final da revisão para registrar o estado da Etapa 3A.
- Nenhuma pendência técnica da infraestrutura local ficou aberta. Persistência após recriação/reboot, AMQP da aplicação e integrações continuam como testes futuros, não como falhas atuais.
- Nova conferência antes de encerrar a documentação: três serviços healthy/0 reinícios; `main` com histórico local e árvore limpa; `.env` não rastreado.

### Etapa 3B — backlog e contratos de integração — 17/11/2026

- Escopo autorizado: requisitos funcionais, critérios de aceite, modelo conceitual, contratos das APIs e integração Mobile. **Não** autorizava implementar APIs/app, alterar bancos, instalar dependências ou criar recursos externos.
- Documentos criados: `docs/backlog.md`, `docs/modelo-dominio.md`, `docs/contratos-api.md`, `docs/integracao-mobile.md`, `docs/decisoes-e-riscos.md` e `docs/rastreabilidade.md`.
- Backlog: 8 épicos, 21 Features e 60 PBIs priorizados em P0/P1/P2, com critérios de aceite verificáveis e vínculo aos IDs da matriz.
- Modelo: entidades Java (categoria, ocorrência, histórico, sugestão IA, outbox) e .NET (conta, acompanhamento, idempotência); máquina de estados com seis valores e transições explícitas; cancelamento lógico; histórico append-only.
- Contratos: `/api/v1`, JWT RS256 emitido pelo .NET e validado pelo Java, envelope de erro comum, paginação, idempotência, rate limit, health checks e evento RabbitMQ.
- Integração Mobile: dois clientes HTTP, sessão em `SecureStore`, papel/propriedade no servidor, detalhe da ocorrência sempre no Java e acompanhamento no .NET.
- Rastreabilidade: cobertura planejada dos IDs NET, JAV, MOB, IA, DB, QA, DEV e GER; 59 casos de teste planejados, **nenhum executado**.
- Documentos alterados para coerência: `README.md`, `docs/arquitetura.md`, `docs/plano-desenvolvimento.md`, `qa/README.md`, `qa/backlog/README.md`, `qa/test-cases/README.md`, READMEs de `backend-java`, `backend-dotnet`, `mobile`, `ai`, `devops` e `database/*`, `.gitattributes` (LF para `.env.example`) e `.env.example` (nomes de variáveis JWT/Java, sem segredos).
- Verificações desta etapa: releitura dos documentos, checagem de links locais e de UTF-8/LF, revisão de que nenhum segredo, DDL ou código foi criado. Os casos descritos são **planejados**; não há teste de aplicação, contrato ou integração executado.
- Commit local **`c09a0c2`** (23 arquivos: 6 novos documentos e 17 atualizações, incluindo `.gitattributes`/`.env.example`); sem remoto, push ou publicação.
- Docker nesta sessão: CLI fora do PATH e engine/pipe não acessível. Containers **não** foram iniciados, parados ou verificados; a saúde registrada permanece a da 3A, não reconfirmada agora.

### Etapa 4A — fundação técnica e persistência .NET — 17/11/2026

- Escopo autorizado: .NET 10, Minimal API, EF Core, SQL Server e xUnit; somente fundação e persistência. **Não** autorizava autenticação, JWT, CRUD completo, integração Java/.NET, Mobile, IA, RabbitMQ, Azure ou scripts Oracle.
- Ambiente reconfirmado antes das alterações: SDK **10.0.404**, runtime **10.0.15**, Docker Engine **29.9.3**, SQL Server 2022 Developer **16.0.4325.4**; `citytech-sqlserver-1`, `citytech-mongodb-1` e `citytech-rabbitmq-1` **running/healthy**.
- Solução `backend-dotnet/CityTech.slnx` criada com `src/CityTech.Api`, `src/CityTech.Domain`, `src/CityTech.Infrastructure` e `tests/CityTech.Tests`, todos em `net10.0`. Referências: Infrastructure → Domain; Api → Infrastructure; Tests → Domain/Infrastructure.
- Pacotes fixados: EF Core/SQL Server e EF Core Design **10.0.15**; xUnit **2.9.3**, runner Visual Studio **3.1.4**, Microsoft.NET.Test.Sdk **17.14.1** e coverlet.collector **6.0.4**. `dotnet-ef` **10.0.15** instalado como ferramenta local em `backend-dotnet/dotnet-tools.json`.
- Domínio implementado: `Account`, `FollowUp`, `IdempotencyRecord` e enum `Role` (`CIDADAO`, `GESTOR`). `Account` guarda apenas `PasswordHash`, com validação de e-mail normalizado, papel e invariantes; o cadastro público cria somente cidadão. `FollowUp` usa `occurrenceId` opaco, sem FK para o Oracle. `IdempotencyRecord` valida escopo, chave de 8–128 caracteres, SHA-256 de 64 caracteres, status HTTP e retenção mínima de 24 h.
- `CityTechDbContext` com Fluent API, tabelas/colunas `snake_case`, `DateTime` UTC por conversor e validação no `SaveChanges`, token de concorrência `version` incrementado em alterações e `ApplyConfigurationsFromAssembly`. Não há `EnsureCreated`.
- Migration **`20261117072823_InitialCreate`** gerada em `src/CityTech.Infrastructure/Persistence/Migrations` e aplicada ao banco de desenvolvimento `CityTech`. Consultas reais confirmaram `accounts`, `follow_ups`, `idempotency_records` e `__EFMigrationsHistory`; índices únicos `UX_accounts_email_normalized`, `UX_follow_ups_user_id_occurrence_id` e `UX_idempotency_records_scope_key`; índice de expiração; check constraints; e **uma única FK local**, `FK_follow_ups_accounts_user_id`, sem FK para `occurrence_id`.
- API mínima em `src/CityTech.Api/Program.cs`: `GET /` respondeu `CityTech.Api / ok` e `GET /health` respondeu `Healthy` consultando a conexão real. A API falha com mensagem explícita se `DOTNET_DB_CONNECTION` estiver ausente. `DesignTimeDbContextFactory` permite usar `dotnet ef` sem subir HTTP.
- Suíte criada: **61 testes aprovados**, sendo **40 de domínio** e **21 de integração com SQL Server real**. A fixture deriva o banco `CityTech_Test` do banco configurado, aplica as migrations e limpa somente linhas das três tabelas; não remove bancos nem volumes. Cobertura inclui mapeamento, tipos/tamanhos, PKs, unicidade, FK local, ausência de FK de ocorrência, persistência/recuperação, UTC, concorrência otimista, checks do banco e dados inválidos.
- Correções durante a validação, sem remover testes: (1) o `CREATE DATABASE` da fixture falhou porque `EXEC()` não aceita concatenação com `QUOTENAME`; o comando passou a montar uma variável T-SQL antes do `EXEC`; (2) dois testes consultavam check constraints no modelo de runtime otimizado do EF 10; passaram a usar `IDesignTimeModel`, que contém essas anotações.
- Comandos executados em `backend-dotnet`: `dotnet tool restore`, `dotnet restore CityTech.slnx`, `dotnet build CityTech.slnx`, `dotnet test CityTech.slnx`, `dotnet ef migrations add InitialCreate`, `dotnet ef database update` e consultas `sqlcmd` ao schema. Resultado do build: **0 avisos e 0 erros**; testes: **61/61 aprovados**.
- `DOTNET_DB_CONNECTION` está vazio no `.env` local. Para esta sessão, a conexão foi montada **somente no processo** a partir de `MSSQL_SA_PASSWORD` e `SQLSERVER_PORT`, sem alterar o `.env` e sem imprimir a senha. O .NET não carrega `.env` automaticamente; preencher/exportar a variável é necessário para uso futuro.
- Arquivos criados/alterados na 4A: `backend-dotnet/CityTech.slnx`, `backend-dotnet/dotnet-tools.json`, projetos e código em `backend-dotnet/src/*` e `backend-dotnet/tests/CityTech.Tests/*`, `backend-dotnet/README.md`, `backend-dotnet/src/README.md`, `backend-dotnet/tests/README.md`, `README.md`, `docs/progresso.md`, `docs/modelo-dominio.md`, `docs/arquitetura.md`, `docs/plano-desenvolvimento.md`, `docs/versoes-e-fontes.md` e `docs/ambiente-desenvolvimento.md`.
- Nenhuma operação destrutiva, remoção de banco/volume, deploy, push ou publicação foi executada. Verificação final: `.env` é ignorado por `.gitignore` e **não rastreado**; a senha SA não foi encontrada em nenhum dos 81 arquivos versionáveis varridos fora do `.env`; os demais resultados da varredura por padrões são placeholders, referências `${MSSQL_SA_PASSWORD}`, senha fictícia de teste ou falsos positivos em binários nativos. Nenhuma credencial real foi gravada em arquivo versionado.

### Etapa 5A — vertical .NET — 17/11/2026

- Escopo solicitado: concluir, testar, documentar e integrar os backends, iniciando pelo .NET; sem Mobile, deploy, push ou entregas externas.
- Dependências adicionadas e fixadas: `Microsoft.AspNetCore.Authentication.JwtBearer` **10.0.15**, `Microsoft.AspNetCore.Mvc.Testing` **10.0.15** e `Swashbuckle.AspNetCore` **11.0.1**. Tentativas iniciais sem versão resolveram pacote 11 incompatível com `net10.0`; a correção foi fixar versões compatíveis.
- Implementados `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `GET /api/v1/auth/me` e CRUD/paginação de `/api/v1/followups`.
- Senha usa `PasswordHasher`; cadastro público cria somente `CIDADAO`. Seed local opcional cria `GESTOR` de forma idempotente quando `MANAGER_SEED_NAME`, `MANAGER_SEED_EMAIL` e `MANAGER_SEED_PASSWORD` estão todos definidos; não promove cidadão existente.
- JWT RS256 é emitido somente pelo .NET, com `kid`, `iss`, `aud`, `sub`, `exp`, `iat`, `jti`, `roles`, nome e e-mail. Validação recusa algoritmo, assinatura, emissor, audiência, validade ou claims inválidas. Chaves são lidas de caminhos externos; nenhuma chave foi versionada.
- Acompanhamentos aplicam propriedade pelo `sub`, paginação/ordenação em whitelist, concorrência por `version`, exclusão idempotente e validação HTTP da ocorrência no Java com propagação do Bearer.
- Cliente Java traduz `404/403` para `404 OCCURRENCE_NOT_FOUND` e indisponibilidade/timeout para `503 OCCURRENCE_SERVICE_UNAVAILABLE`, sem gravar o acompanhamento.
- Idempotência persistida no cadastro e `POST /followups`: chave de 8–128, hash SHA-256, escopo, retenção mínima de 24 h, replay de status/corpo/`Location` e `409` para payload divergente. A migration **`20261117125534_AddIdempotencyResponseLocation`** foi gerada e aplicada ao `CityTech`; o banco `CityTech_Test` também foi migrado pela fixture.
- Rate limiting nativo em cadastro/login/criação de acompanhamento, com limites configuráveis, `429 RATE_LIMITED` e `Retry-After`. Swagger/OpenAPI inclui Bearer. Erros usam envelope uniforme, inclusive JSON malformado.
- Health: `/health/live` verifica processo; `/health` verifica SQL Server; `/health/ready` verifica SQL Server + Java e retorna `503` se a dependência estiver indisponível.
- Build final: **0 avisos, 0 erros**. Suíte final: **76/76 aprovada**, sendo os 61 casos anteriores e 15 casos novos de seed/endpoints HTTP. Cobertura nova: validações, duplicidade, concorrência idempotente, login/claims JWT, `401`, propriedade, CRUD/versão, idempotência/replay/conflito/`Location`, falhas Java, health, Swagger, JSON malformado e `429`.
- Correções durante a validação: import do metadado `Retry-After`; validação de e-mail desacoplada da validação de nome; desserialização de enums nos testes; envelope para JSON malformado; descarte do estado EF após violação única; replay do `Location`; rollback/replay em corrida entre instâncias; `version` ausente rejeitada. Uma tentativa de clonar/descartar a chave RSA conflitou com o cache criptográfico do IdentityModel e causou um `500` reproduzível no segundo login; foi revertida para uma chave singleton descartada somente no encerramento do host, e a suíte completa voltou a passar.
- Requisições em processo HTTP real, usando banco de teste e chaves RSA temporárias: cadastro `201`, replay `201` com header, login `200`, `/auth/me` `200` e sem token `401`, liveness `200`, Swagger `200`, JSON inválido `400`, readiness sem Java `503` e criação de acompanhamento sem Java `503`. Dados temporários foram limpos pela fixture; processo encerrado e chaves temporárias removidas.
- A integração positiva .NET→Java foi verificada apenas com handler HTTP controlado nos testes, pois o Java ainda não é executável. Isso comprova o cliente e seus mapeamentos, não substitui o teste futuro entre processos reais.
- Arquivos principais: `backend-dotnet/src/CityTech.Api/{Contracts,Endpoints,Health,Security,Services}`, `Program.cs`, migration aditiva, testes em `tests/CityTech.Tests/Api` e `ManagerSeederTests.cs`; READMEs, contrato, arquitetura, plano, `.env.example` e este progresso atualizados.
- Nenhum push, deploy, conta externa, chave persistente, recurso pago ou alteração de Mobile/Java foi realizado nesta fase.

### Etapa 5B e fase 6 parcial — Java/RabbitMQ/IA — 17/11/2026

- Projeto Maven Wrapper com Java 21, Spring Boot **4.1.2**, Spring AI **2.0.2**, springdoc **3.2.0**, JPA, Resource Server e AMQP; `ojdbc17` em runtime e H2 somente em teste.
- Implementadas entidades relacionadas `Category`, `Occurrence`, `StatusHistory`, `AiSuggestion`, `OutboxEvent` e `ProcessedEvent`; UUIDs, UTC, concorrência otimista e histórico append-only.
- Endpoints de categorias, ocorrências, filtros/paginação, triagem/status/cancelamento lógico, histórico, indicadores e revisão humana de sugestão; validação/erros uniformes e OpenAPI.
- JWT RS256 valida chave pública externa, algoritmo suportado pelo decoder, `kid`, emissor, audiência, expiração, `sub` UUID e papéis `CIDADAO`/`GESTOR`. Cidadão só acessa recursos próprios; gestor possui endpoints dedicados.
- Criação de ocorrência grava histórico e `OccurrenceCreated.v1` no outbox na mesma transação. Publicador, exchange/fila/DLX/DLQ duráveis, retry limitado, consumidor e deduplicação por `eventId` implementados.
- Corpus versionado em `ai/corpus`; recuperação lexical, prompt defensivo, adaptador `ChatModel` Spring AI, validação de categoria/prioridade/tamanhos/fontes e revisão humana implementados. Sem `ChatModel`, a sugestão termina explicitamente em `FALHOU/MODEL_NOT_CONFIGURED`.
- Testes padrão: **38 aprovados**, **0 falhas**, mais um teste AMQP opt-in ignorado por padrão. `.\mvnw.cmd package` gerou `target/citytech-java-0.0.1-SNAPSHOT.jar`.
- Teste opt-in separado: **1/1 aprovado** contra `citytech-rabbitmq-1` **4.4.0** real; conexão autenticada, evento publicado pelo outbox, consumido assincronamente, deduplicado e persistido como fallback sem modelo. Filas de classificação/DLQ foram limpas pelo próprio teste.
- Cobertura inclui domínio/máquina de estados, categorias, mapeamento JPA H2, queries agregadas, JWT, `401/403/404/409`, validação, propriedade, paginação/ordenação, concorrência, histórico, health, OpenAPI, outbox, fallback idempotente, recuperação de corpus, saída Spring AI controlada e revisão humana.
- Correções encontradas pelos testes: Jackson 2 → Jackson 3 no filtro Boot 4; retorno gerenciado de `save` para timestamps com UUID atribuído; `AccessDeniedException` de método deixou de virar `500`; cancelamento passou a exigir `version`; revisão e outbox foram alinhados ao contrato.
- Limitações: H2 não comprova Oracle; produção usa `ddl-auto=validate` e ainda não possui schema Oracle validado. O teste de adaptador usa `ChatModel` controlado; nenhum LLM externo, embedding, métrica ou resultado generativo real foi alegado.
- Arquivos principais: `backend-java/pom.xml`, `src/main/java/.../{category,occurrence,history,security,messaging,classification}`, testes em `src/test/java`, `ai/corpus/*`, READMEs, contratos, arquitetura, modelo, plano e este progresso.

### Revisão final da vertical Java — 17/11/2026

- A revisão identificou que `OccurrenceService.triage` e `reviewSuggestion` liam `occurrence.getStatus()` depois da mutação para preencher `fromStatus`/`toStatus`, e que `Occurrence.triage` não iniciava a triagem. Na prática, uma ocorrência `ABERTA` permanecia registrada como `ABERTA → ABERTA`, em vez de `ABERTA → EM_TRIAGEM`.
- Correção focada, sem alterar contratos HTTP: `Occurrence.triage` inicia `EM_TRIAGEM` quando o estado é `ABERTA` (reutilizando a máquina de estados) e mantém o status nos demais estados não terminais; o serviço captura `before` antes da triagem e grava `TRIAGEM`/`REVISAO_IA` com `before → occurrence.getStatus()`.
- Testes adicionados/ajustados: unidade `triageStartsFromOpenStatusAndKeepsLaterStatus`; API `managerTriageRecordsPreviousAndNewStatus`; aceitação de sugestão agora confere `status=EM_TRIAGEM`, `fromStatus=ABERTA`, `toStatus=EM_TRIAGEM`, ação `REVISAO_IA` e nota.
- `.\mvnw.cmd package`: **41 executados, 40 aprovados, 0 falhas/erros, 1 AMQP ignorado**, BUILD SUCCESS; JAR `target/citytech-java-0.0.1-SNAPSHOT.jar` gerado.
- Teste opt-in: **1/1 aprovado** com `CITYTECH_RUN_RABBIT_INTEGRATION=true` contra `citytech-rabbitmq-1` **4.4.0** healthy; credenciais lidas do `.env` apenas no processo, sem impressão; filas limpas pelo teste.
- Verificações de Git/segredos: executadas após esta atualização e antes do commit; resultado final registrado abaixo.
- Commit local desta revisão: registrado no checkpoint documental seguinte.

### Etapa 7 — implementação Mobile — 17/11/2026

- Escopo explicitamente autorizado: implementação completa em `mobile/` conforme os contratos reais, incluindo scaffold Expo/TypeScript/Router, design system, clientes .NET/Java, autenticação, ocorrências, acompanhamentos, gestão, IA e Sobre. Sem deploy, push, APK, Firebase ou recurso externo.
- Auditoria após interrupção anterior confirmou árvore Git limpa, apenas três READMEs originais em `mobile/`, ausência de `package.json`/`node_modules` e nenhuma atualização anterior deste progresso; não havia arquivo parcial para preservar.
- Scaffold fixado em Expo SDK **58.0.26**, React Native **0.88.1**, React **19.3.0** e TypeScript **6.0.3**, com Expo Router, Axios, SecureStore, Crypto, Constants, Safe Area, Screens, Vector Icons, Jest/Testing Library, ESLint e Prettier. `package-lock.json` foi gerado.
- Implementadas 11 rotas/telas: boas-vindas, login, cadastro, dashboard, lista de ocorrências, nova ocorrência, detalhe, edição, acompanhamentos, gestão e Sobre. Sobre exibe versão e `EXPO_PUBLIC_GIT_COMMIT_HASH` injetado no build.
- Sessão: cadastro/login reais no .NET, `Idempotency-Key`, token/dados públicos no `expo-secure-store`, restauração validada por `/auth/me`, expiração local, interceptor Bearer compartilhado, logout com limpeza e guardas de rota/papel.
- Ocorrências Java: categorias, listagem paginada com filtros/busca, criação, detalhe, edição, cancelamento lógico, histórico, polling limitado da IA, aceite/rejeição, triagem e transições com `version`. CEP vazio é convertido em `null` conforme o DTO Java.
- Acompanhamentos .NET: listar, criar, editar nota e remover; detalhe atual hidratado pelo Java; indisponibilidade é exibida sem dados falsos. Dashboard e gestor usam os payloads reais, inclusive o indicador Java reduzido a `totalOccurrences`, `byStatus` e `byCategory`.
- Erros: mapeamento explícito de validação por campo, `401` com encerramento da sessão, `403`, `404`, conflitos `409` por `code`, `429`/`Retry-After`, `500`/`503` e rede; `traceId` aparece somente em desenvolvimento.
- Rede documentada em `mobile/.env.example`, `src/api/config.ts` e README: `localhost` no computador, `10.0.2.2` no Android Emulator, IP LAN para Expo Go em dispositivo físico e HTTPS estável para APK.
- Instalação inicial foi interrompida por timeout e deixou `node_modules` parcial sem lockfile; a retomada detectou o estado, resolveu o conflito transitório React/React DOM sem `--force`, gerou lockfile e deixou `npm ls --depth=0` íntegro. Auditoria npm ainda relata vulnerabilidades transitivas do ecossistema Expo; não foi executado `npm audit fix --force` por risco de quebrar a matriz do SDK.
- Verificações finais em `mobile/`: `npm run typecheck` passou; `npm run lint` passou; Jest **8/8** em 3 suítes; `npx expo install --check` sem incompatibilidades; Expo Doctor **20/20**; `expo export --platform web` compilou **978 módulos** e todas as rotas. O bundle temporário ficou fora do repositório.
- Correção Web posterior: `secureStorage.ts` passou a usar `localStorage` quando `Platform.OS === "web"`, com fallback em memória se `window`/armazenamento estiver indisponível; Android/iOS continuam exclusivamente no SecureStore. Busca confirmou nenhuma chamada direta fora desse adaptador e `npx tsc --noEmit` permaneceu aprovado.
- Limites: nenhuma chamada ponta a ponta real foi executada porque Java/Oracle e URLs alcançáveis ainda não estão disponíveis; não houve validação em Android/iOS, LLM real, APK assinado, Firebase App Distribution, vídeo ou publicação. Esses itens não são considerados concluídos.

### Etapa 8 parcial — Oracle e PL/SQL — 17/11/2026

- Escopo autorizado: mapear integralmente as entidades JPA e deixar Oracle/schema/backend Java executáveis; MongoDB foi explicitamente excluído.
- Criados `database/oracle/01-schema.sql` a `07-reports.sql`, agregador `install.sql` e scripts de bootstrap, healthcheck e execução segura para o container.
- Schema JPA: `categories`, `occurrences`, `status_history`, `ai_suggestions`, `processed_events` e `outbox_events`; UUID `RAW(16)`, `Instant` como `TIMESTAMP(6) WITH TIME ZONE`, enums `VARCHAR2`, LOBs `CLOB`, PKs/FKs/uniques/checks e índices alinhados ao código. IDs JPA são atribuídos pela aplicação; a única sequence atende `occurrence_audit`.
- Requisitos acadêmicos implementados: 6 categorias e 12 ocorrências fictícias determinísticas, dois blocos anônimos, dois packages com duas funções e dois procedures, trigger de auditoria, trigger append-only, testes e três relatórios comparáveis ao Mongo futuro.
- `docker-compose.yml` recebeu Oracle XE 21 local em profile `oracle`/`java`, imagem fixada pelo digest `sha256:f82bccdf...55de`, volume persistente, porta loopback, usuário de aplicação e healthcheck que só aprova schema/objetos válidos.
- Duas inicializações independentes foram verificadas. Na segunda, bootstrap fresco, healthcheck, `06-tests.sql` e `07-reports.sql` passaram; 6 objetos package/body/trigger ficaram `VALID`, os 13 assertions PL/SQL passaram e os relatórios retornaram 6 categorias/12 ocorrências.
- O Java iniciou em porta temporária contra o Oracle XE 21 com o driver real e `ddl-auto: validate`; `/health/ready` retornou sucesso. Rabbit/IA foram desativados apenas nessa prova isolada.
- A suíte Java foi repetida após corrigir somente permissões do diretório gerado `target/`: **41 executados, 40 aprovados, 0 falhas/erros e 1 AMQP ignorado**, `BUILD SUCCESS`.
- Uma primeira inicialização de validação falhou antes do schema porque a senha administrativa efêmera tinha 48 caracteres; o limite local foi documentado como 8–30 e a repetição usou 24. O volume falho foi preservado, sem remoção destrutiva.
- Não houve credencial versionada, MongoDB, alteração de conta FIAP, deploy, push ou publicação. O Oracle institucional ainda precisa repetir `install.sql`, testes e relatórios quando host/serviço/VPN/credenciais forem disponibilizados.

### P0.2 — rede local e CORS para Mobile — 17/11/2026

- .NET alinhado em `0.0.0.0:8081`; Java permanece em `8080`; scripts Expo fixados em `19006` para não disputar a porta 8081 com a API.
- .NET habilita a política `DevelopmentCors` somente em `Development`; Java registra CORS somente no profile `local`. Ambos aceitam origens exatas de `CORS_ALLOWED_ORIGINS`, sem curinga/credenciais, e expõem `Retry-After`, `Idempotent-Replayed` e `Location`.
- Defaults cobrem `localhost`/`127.0.0.1` nas portas 19006 e 8081. Android Emulator usa `10.0.2.2`; dispositivo físico exige IP LAN nas URLs Expo e origem Web LAN explícita quando aplicável.
- Java: `bash mvnw test` terminou em `BUILD SUCCESS`, **42 executados, 41 aprovados e 1 AMQP opt-in ignorado**; o novo teste confirmou preflight, origem permitida, headers expostos e rejeição de origem desconhecida.
- .NET: build no SDK 10 isolado terminou com **0 warnings/0 errors**; VSTest contra SQL Server real aprovou **77/77**, incluindo CORS Development. O host desta sessão tinha SDKs 8/9, por isso o SDK 10 foi usado em container sem instalação global.
- Ainda não foi alegado E2E: falta iniciar simultaneamente dependências, backends e Expo e provar chamadas reais no navegador/Android.

### P0.3 — MongoDB documental comparável ao Oracle — 17/11/2026

- Criados `database/mongodb/01-schema.js` a `04-tests.js` e o runner executável `run-mongodb.sh`; o Compose agora injeta `MONGODB_DATABASE`, com default `citytech_demo`.
- Collections `categorias`, `ocorrencias` e `eventos_triagem` usam `$jsonSchema` estrito, rejeição de documento inválido e índices únicos/compostos para código, status, prioridade, bairro, data, IA e sequência operacional.
- Seed determinístico preserva `_id`/`oracleId` da massa Oracle: 6 categorias, 12 ocorrências, 12 históricos/eventos e 3 sugestões IA incorporadas. Categoria, endereço, histórico e classificação IA são embutidos na ocorrência; eventos ficam também em log analítico append-only.
- `03-queries.js` executa 2 buscas `find` e 6 agregações. Os três relatórios comparáveis coincidiram: 2 ocorrências por categoria; fila `CRITICA=2`, `ALTA=4`, `MEDIA=3`; 12 combinações categoria/status com contagem 1.
- `04-tests.js` aprovou **25/25 assertions**, incluindo collections/validators, 30 documentos, rastreabilidade, índices, rejeição de documento inválido, histórico e estados IA `PRONTA=1`, `ACEITA=1`, `FALHOU=1`.
- O runner foi executado duas vezes. Na repetição, registrou 0 inseridos e 30 sincronizados, sem duplicatas, drop, remoção de volume ou exclusão de documentos externos.
- MongoDB 8.0.38 ficou healthy durante a validação. Não existe sincronização automática Oracle→Mongo; Oracle continua fonte transacional e o Mongo é snapshot acadêmico reproduzível.

### Smoke E2E real entre processos — 18/11/2026

- SQL Server, Oracle XE 21 e RabbitMQ ficaram healthy. O volume Oracle ativo não possuía o schema CityTech; com autorização explícita, o usuário local foi criado e `install.sql` aplicado sem remover volumes. As duas migrations EF Core também foram aplicadas ao banco `CityTech` ausente.
- .NET em `8081` e Java em `8080` iniciaram com a mesma chave RS256 temporária fora do Git; `/health/ready` respondeu `200` em ambos.
- Um roteiro Node sem mocks confirmou cadastro/login de cidadão, JWT validado pelo Java, criação de ocorrência no Oracle, publicação do outbox, consumo RabbitMQ, fallback `FALHOU/MODEL_NOT_CONFIGURED`, acompanhamento persistido no SQL Server, login de gestor, listagem, indicadores, triagem e histórico.
- A revisão da sugestão em fallback retornou o `409 AI_SUGGESTION_NOT_READY` esperado; uma sugestão `PRONTA` da massa Oracle foi revisada e persistida como `REJEITADA`, comprovando o fluxo humano positivo.
- Verificação direta: ocorrência, fallback, outbox publicado e `processed_events` existem uma vez no Oracle; acompanhamento existe uma vez no SQL Server; fila principal ficou com 0 mensagens e 1 consumidor. A DLQ contém 1 mensagem da carga seed antiga/incompleta, não do evento criado no E2E; corrigir a massa/outbox antes da entrega.
- O smoke revelou que `CORS_ALLOWED_ORIGINS` não estava vinculado a `citytech.cors.allowed-origins` no YAML. O vínculo foi adicionado, `./mvnw package` passou com **42 executados, 41 aprovados e 1 AMQP ignorado**, e o preflight Java passou para `http://localhost:19006`.
- Expo Web iniciou em `19006` e respondeu `200`. Isso comprova servidor/bundle e acesso CORS, não substitui a navegação manual do fluxo nem a validação Android.

### Configuração local reproduzível do Java — 18/11/2026

- Auditoria integral confirmou um Compose na raiz, `.env`/`.env.example`, DDL/DML/PLSQL Oracle em `database/oracle/`, ausência inicial de PEM e RabbitMQ usado somente pelo Java.
- Gerado par RSA 3072 bits em `secrets/jwt/`, ignorado pelo Git; chave privada com modo `600`, chave pública válida e correspondente. O `.env` local aponta os dois backends para esse par sem versionar credenciais.
- `.env.example` raiz e `backend-java/.env.example` documentam as variáveis; `.gitignore` também protege SQLs locais sensíveis. `backend-java/run-local.sh` carrega o `.env` raiz e executa Maven com profile local.
- `ddl-auto` foi mantido em `validate`, pois `database/oracle/install.sql` é a fonte oficial do schema. A conexão com Oracle FIAP 19.3 no schema configurado passou e o Hibernate validou as entidades.
- Compose validado com `config --quiet`; RabbitMQ, Oracle XE e SQL Server estavam healthy. RabbitMQ respondeu ao diagnóstico, tinha um consumidor Java, fila principal vazia e uma DLQ antiga já registrada no smoke.
- Uma nova execução chegou ao start do Tomcat, mas não abriu outro listener porque a porta já estava ocupada pelo JAR do próprio projeto. A instância existente em `8080` respondeu health `UP` e OpenAPI; .NET em `8081` respondeu liveness `UP`.
- `mvn -f backend-java/pom.xml test` terminou em `BUILD SUCCESS`: 42 testes executados, 41 aprovados e 1 integração AMQP opt-in ignorada conforme esperado.

### Reexecução das APIs no ambiente Linux — 18/11/2026

- O `.env` local foi conferido sem exposição dos valores: variáveis de SQL Server, Oracle remoto, RabbitMQ e JWT estão definidas, e os dois arquivos PEM referenciados existem. `docker compose --env-file .env config --quiet` passou.
- SQL Server e RabbitMQ foram reiniciados preservando containers e volumes e ficaram `healthy`. Oracle local não foi iniciado porque `ORACLE_JDBC_URL` aponta para o servidor remoto configurado.
- .NET: restore/build passaram com 0 avisos e 0 erros; migrations já estavam atualizadas; **77/77 testes** passaram. O conflito inicial de portas foi corrigido: API em `http://localhost:8081`, ambiente `Development` e PID 25855.
- Java: Maven Wrapper 3.10.1 executado com OpenJDK 25 disponível no host, embora Java 21 continue sendo a versão exigida/recomendada. `./mvnw package` passou com **42 testes, 41 aprovados e 1 AMQP opt-in ignorado**; a API iniciou em `http://localhost:8080` (PID 17161).
- Verificação entre processos: readiness .NET confirmou SQL Server e Java saudáveis; readiness Java confirmou Oracle `UP`; Actuator ficou `UP`; OpenAPI .NET e Java responderam HTTP 200. Expo Web foi reiniciado pelo script versionado em `http://localhost:19006` (PID 25857), apontando explicitamente para .NET `8081` e Java `8080`. Preflight de login retornou `204` com a origem `19006` permitida; login inválido chegou à API e retornou `401 application/json`, em vez do `200 text/html` incorreto do Expo. Logs temporários estão em `/tmp/opencode/citytech-dotnet-8081.log`, `/tmp/opencode/citytech-java.log` e `/tmp/opencode/citytech-expo-19006.log`.

### Correção do fluxo de ocorrências — 19/11/2026

- O Mobile foi auditado do formulário ao cliente HTTP; rota, payload, Bearer e CORS estavam alinhados com `POST /api/v1/occurrences`. Testes diretos confirmaram preflight, JWT, categorias e validação do endpoint.
- O `409 DATA_CONFLICT` vinha da camada de persistência, mas o processo antigo não registrava a causa. `GlobalExceptionHandler` agora registra `DataIntegrityViolationException` com o mesmo `traceId` devolvido ao cliente, sem registrar payload ou credenciais; `./mvnw package` passou com **42 testes, 41 aprovados e 1 AMQP opt-in ignorado**.
- A inspeção somente leitura do Oracle institucional mostrou schema Hibernate parcial, sem triggers acadêmicos, e principalmente **0 categorias e 0 ocorrências**. Com `GET /categories` retornando `[]`, o fluxo não tinha categoria ativa utilizável. Nenhuma alteração foi feita no banco institucional.
- O usuário escolheu usar o Oracle XE local. O volume existente foi preservado; a senha apenas do usuário local `CITYTECH` foi redefinida com autorização e salva em `.env.local` ignorado, modo `600`. O `.env` institucional permaneceu intacto.
- Oracle XE ficou `healthy`, com 6 categorias ativas e massa local. O Java foi reiniciado contra `jdbc:oracle:thin:@localhost:1521/XEPDB1`. Um smoke real criou ocorrência com HTTP `201` e a cancelou com HTTP `204`, validando JWT, controller, serviço, Oracle, histórico e outbox.
- `backend-java/run-local.sh` agora carrega `.env.local` depois de `.env` e usa o Maven Wrapper, tornando a seleção local reproduzível sem Maven global.

### Testes ainda não executados

Testes PL/SQL/relatórios completos no Oracle institucional, se ainda não aplicados; LLM/embeddings externos e avaliação RAG real; navegação E2E pelo Mobile e consumo em dispositivo; pipelines; Test Plans; APK/Firebase. O smoke de APIs comprovou a integração positiva .NET→Java e o Expo Web está servido, mas ainda não houve execução manual das telas nem Android/iOS.

## 5. Pendências

**.NET e Java/Oracle local sem bloqueio interno; integração positiva das APIs comprovada:** a solução .NET builda, possui migrations e 77 testes. O Java builda, possui 41 testes padrão, 1 AMQP opt-in ignorado por padrão, prova RabbitMQ real e startup validado com Oracle XE 21; LLM externo continua pendente. Binding e CORS locais passaram em execução real. O Mobile compila e o Web está servido, mas a navegação manual e a execução em dispositivo permanecem pendentes.

### Ambiente e permissões

- `DOTNET_DB_CONNECTION` e os caminhos JWT estão preenchidos somente no `.env` local ignorado. O .NET não carrega `.env` automaticamente; exportá-lo no processo antes de executar. Não versionar valores ou chaves.
- Lotes A/B/C instalados e testados. Reabrir terminal/OpenCode se necessário para herdar PATH atualizado. O Docker Desktop foi iniciado nesta sessão e os três containers estavam healthy.
- Git da raiz com commits locais; reconferir `docker compose ps` antes de usar os serviços.
- WSL 2/Docker Linux operacionais. RAM do host 15,93 GiB; iniciar apenas serviços necessários.
- Oracle local XE 21 está validado. Oracle institucional 19.3 aceitou a conexão configurada e o Hibernate validou o schema JPA; ainda conferir os testes PL/SQL/relatórios acadêmicos antes da apresentação.
- Versões das ferramentas consultadas no catálogo/fontes; reconferir antes de instalar. .NET e Java foram validados nos ambientes descritos; Mobile foi validado por TypeScript/lint/teste/bundle, enquanto Oracle/LLM e execução Mobile em dispositivo dependem da validação correspondente.

### Acadêmicas e externas

- Entrega oficial: **19/11/2026 às 23h55**. Cadastro encerrou em 13/11; situação do grupo não confirmada.
- Obter integrantes/RMs/turmas/representante e contatos dos professores.
- Resolver dúvidas registradas na matriz: integração Mobile dupla, .NET online/presencial, formato Banco, padrões/licença Test Plans e CRUD de tabelas técnicas em DevOps.
- Autorizar separadamente contas/operações GitHub, Azure e Firebase, convites/permissões, publicação, deploy e qualquer custo.
- Definir provedor/modelos IA, orçamento e autorização; definir hospedagem acessível de Java/Oracle/RabbitMQ e .NET.
- Decidir toolchain Android/build APK e preparar distribuição Firebase na etapa correspondente.

## 6. Próximas ações em ordem

1. Executar manualmente o fluxo Mobile no Web já servido e depois no Android, preservando evidências dos resultados.
2. Definir provedor/modelos/credenciais IA autorizados, adicionar o starter correspondente e executar avaliação RAG/LLM real.
3. No Oracle institucional, executar `06-tests.sql` e `07-reports.sql`; executar `install.sql` somente se o schema estiver vazio.
4. Confirmar build Android e acessos Azure/Firebase antes das etapas externas; não publicar nem provisionar recurso sem autorização específica.

A 4A termina no commit local **`d4b9eea`** e a 5A em **`6bc996f`**. Nenhum push, deploy ou publicação foi autorizado.

## 7. Decisões técnicas importantes

| Decisão | Situação |
|---|---|
| Java/Oracle para ocorrências, gestão e IA; .NET/SQL Server ou Azure SQL para contas/JWT/acompanhamentos | .NET/SQL Server verificado; Java validado com H2, Oracle XE 21 local e schema JPA no Oracle FIAP 19.3 |
| Mobile consome diretamente ambas as APIs | Estratégia para atender Java e .NET; confirmação docente pendente |
| Um dono por dado/regra; referências por ID, sem escrita dupla ou senha duplicada | Regra permanente |
| JWT RS256: .NET assina; Java valida chave pública; 60 min, sem refresh no MVP | Emissão .NET e validação Java implementadas e comprovadas entre processos no smoke E2E |
| Ocorrência com estados `ABERTA`→`EM_TRIAGEM`→`EM_ANDAMENTO`→`RESOLVIDA`→`ENCERRADA`, mais `CANCELADA`; cancelamento lógico e histórico append-only | Java e DDL Oracle implementados; trigger protege histórico físico |
| Acompanhamento .NET referencia `occurrenceId` sem copiar status; valida no Java | Endpoint/cliente e caminho positivo com Java real comprovados no smoke E2E |
| .NET com tabelas `snake_case`, PK UUID, UTC, `version` otimista e checks no SQL Server | Implementado e verificado na 4A; migration `20261117072823_InitialCreate` |
| Idempotência .NET por (`scope`, `idempotency_key`) com hash SHA-256 e retenção ≥24 h | Implementada/testada no cadastro e acompanhamento |
| IA consultiva via outbox + RabbitMQ + RAG, com revisão humana obrigatória | Pipeline/revisão implementados; geração real depende de provedor/modelos |
| RabbitMQ, alternativa A de Java | Publicação/consumo reais verificados localmente com teste opt-in |
| Spring AI + RAG básico, revisão humana e fallback manual | Adaptador/recuperação/fallback implementados; embeddings/LLM externo pendentes |
| MongoDB como snapshot acadêmico do Oracle | Implementado/validado com 3 collections, 30 documentos e relatórios equivalentes; sem sincronização automática |
| .NET App Service + Azure SQL como alvo inicial DevOps | Planejamento; conta/custos/provisionamento não autorizados |
| Fotos, mapas/GPS, push e refresh token em P2/fora do MVP | Decisão de escopo da 3B |
| PostgreSQL retirado; Maven Wrapper, CLI sem IDE obrigatória | Redução de dependências |
| Manual estável e progresso mutável | Atualização obrigatória ao concluir etapa ou encerrar sessão incompleta |

Detalhes: [arquitetura/ADRs](arquitetura.md), [versões fixadas](versoes-e-fontes.md) e [matriz](requisitos-global-solution.md). .NET e Java foram validados por build/testes dentro dos limites registrados; versões/integrações externas não testadas continuam explicitamente pendentes.

## 8. Autorizações e manutenção

- Autorizado e realizado: documentação/configuração da Etapa 1 e complemento de continuidade solicitado pelo usuário.
- Autorizado na solicitação atual: **início da Etapa 2 para diagnóstico e plano de instalação**, com atualização documental.
- **Autorização posterior explícita:** instalar Git, Temurin JDK 21, .NET SDK 10, Node 24/npm, WSL 2, Docker Desktop/Compose e Azure CLI; configurar PATH/JAVA_HOME e recursos Windows necessários ao WSL. Executar A → B → C, verificar versões e testes básicos, informar reinicialização antes de continuar. Não remover ferramentas, executar operações destrutivas ou instalar software adicional.
- Etapa 3A autorizada e concluída: Git local, configuração/execução/testes SQL Server/MongoDB/RabbitMQ. Usuário forneceu identidade Git, autorizou geração de senhas locais e confirmou EULA Developer.
- **Etapa 3B autorizada e concluída (somente documentação):** backlog, critérios de aceite, modelo conceitual, contratos REST/JWT, integração Mobile, decisões/riscos e rastreabilidade. Sem implementação de APIs/app, alteração de banco, instalação ou recurso externo.
- **Etapa 4A autorizada e concluída:** fundação técnica e persistência do backend .NET com .NET 10, Minimal API, EF Core, SQL Server e xUnit. Criados solução, entidades, mapeamentos, migration, API mínima e testes; banco de desenvolvimento `CityTech` e banco de teste `CityTech_Test` criados sem remoção de estruturas.
- **Etapa 5A autorizada pela solicitação de conclusão dos backends e concluída localmente:** autenticação/JWT, acompanhamentos, idempotência, rate limiting, Swagger, health e testes. Integração positiva com Java permanece pendente; nenhuma operação externa foi realizada.
- **Etapa 5B e fase 6 parcial autorizadas pela mesma solicitação de conclusão dos backends:** vertical Java, RabbitMQ, estrutura Spring AI/RAG, revisão humana e testes implementados. O broker local já autorizado foi usado sem alterar credenciais; nenhuma conta/modelo externo foi acessado.
- **Etapa 7/Mobile autorizada e implementada:** Expo/TypeScript/Router, design system, sessão segura, duas APIs, ocorrências, acompanhamentos, gestão/IA e Sobre; dependências locais instaladas e verificações estáticas executadas. Não autoriza nem realizou APK, Firebase, deploy, push ou conta externa.
- **Etapa 8/Oracle parcial autorizada e implementada:** DDL JPA, seed, PL/SQL acadêmico, Compose local e validação do backend Java. MongoDB foi excluído pelo usuário; nenhum recurso institucional foi alterado.
- **P0.3/MongoDB autorizado e concluído:** validators, índices, snapshot comparável, consultas/agregações, testes e documentação executados no serviço local; nenhum volume removido, credencial alterada ou recurso externo acessado.
- Permanecem sem autorização: novas credenciais de contas externas, publicação/deploy ou implementação de funcionalidades além das etapas aprovadas. Testes PL/SQL completos no Oracle institucional ainda precisam ser confirmados.
- Não há autorização registrada para publicação, deploy, recursos pagos, exclusão importante ou alteração administrativa.

Ao concluir cada etapa ou interromper uma sessão, atualizar este registro e os documentos relacionados com fatos verificados. Acrescentar comandos/resultados, arquivos alterados, pendências e decisões; nunca incluir credenciais. Preservar resultados históricos e indicar claramente o novo ponto de retomada.
