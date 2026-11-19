# Versões propostas e fontes técnicas

Consultas realizadas em **17/11/2026**. O PDF prevalece para avaliação; fontes abaixo servem para compatibilidade técnica. As verticais .NET e Java foram validadas por restore/build/teste nos ambientes registrados; stacks externas restantes continuam propostas até a validação correspondente.

## Base selecionada

| Componente | Seleção | Compatibilidade/razão |
|---|---|---|
| Java | Temurin/OpenJDK **21.0.13+9 LTS** | API Adoptium e WinGet confirmados na Etapa 2; Boot 4.1.2 aceita Java 17–27 |
| Spring Boot | **4.1.2** | Release estável indicada pela documentação consultada |
| Spring AI | **2.0.2** | Referência 2.0.2; série 2.0.x declara suporte Boot 4.0.x/4.1.x |
| Spring Data JPA / Security / AMQP | Gerenciados pelo BOM do Boot | Evitar versões avulsas conflitantes |
| springdoc-openapi | **3.2.0**, starter WebMVC UI | Linha 3 para Spring Boot 4; Swagger UI exigido |
| Maven | **3.10.1**, via Wrapper | Wrapper executado com Java 21; build/teste/package aprovados |
| .NET / ASP.NET Core | **10 LTS**, SDK **10.0.404**, runtime **10.0.15** | Confirmado por `dotnet --info` e build da 4A; suporte até 14/11/2028 |
| EF Core | **10.0.15**, provider SqlServer e Design | Fixado nos `.csproj` da 4A; migration aplicada ao SQL Server 2022 e testes de integração aprovados |
| JWT / Swagger / testes HTTP .NET | JwtBearer **10.0.15**, Swashbuckle **11.0.1**, Mvc.Testing **10.0.15** | Fixados na 5A; build sem avisos e endpoints exercitados |
| xUnit | **2.9.3**, runner Visual Studio **3.1.4**, Test SDK **17.14.1**, coverlet **6.0.4** | Pacotes fixados; 77 testes executados |
| Node.js | **24.22.3 LTS** | Linha 24 consta como LTS; distribuição oficial consultada |
| Expo | **SDK 58** | Referência latest consultada, sem canary/beta |
| React Native / React | **0.88 / 19.3.0**, conforme Expo 58 | Matriz Expo; Node mínimo 22.13.x |
| TypeScript / Expo Router / Axios | Versões compatíveis selecionadas pelo scaffold/Expo e lockfile futuro | Não escolher React/React Native independentemente do SDK |
| SQL Server | **2022 Developer**, Azure SQL para nuvem futura | Linha suportada pelo provider e caminho PaaS explícito no PDF |
| Oracle | **19c como baseline PL/SQL**, versão efetiva da disciplina a confirmar | Referência oficial 19c acessível; sem exigir sintaxe exclusiva de versão mais nova |
| MongoDB | **8.0**, patch consultado 8.0.38 | Linha major com suporte on-premises; fixar imagem após validação |
| RabbitMQ | **4.x**, release consultada 4.4.0 | Opção A Java; AMQP; fixar imagem após validação |
| Git | **2.56.0.4** para Windows x64 | Catálogo WinGet consultado na Etapa 2 |
| Docker / Compose | Desktop **4.99.0**, CLI/engine **29.9.3**, Compose **5.7.0** | Instalados; hello-world via Docker e Compose passou |
| WSL | Aplicativo **3.0.5**, backend **WSL 2** | Instalado e operacional; distribuição docker-desktop Running/2 |
| Azure CLI | **2.93.0** x64 | Instalado; versão e ajuda passaram; sem login |

Na Etapa 3A, as famílias `4-management`, `8.0` e `2022-latest` foram baixadas e os digests reais fixados no Compose/exemplo. Serviços healthy: RabbitMQ 4.4.0, MongoDB 8.0.38 e SQL Server 16.0.4325.4 Developer. Digests e testes em [verificação 3A](verificacao-etapa-3a.md).

Antes da implementação de cada stack, fixar versões exatas no `pom.xml`, BOM AI, `.csproj`, `global.json`, manifesto de ferramentas, `package.json` e lockfile, conforme aplicável. Não criar esses arquivos com números de SDK não instalados. Java/Spring AI compilam e os testes controlados passaram; isso não substitui Oracle/LLM externo. Expo ainda precisa de scaffold/build. O `dotnet-ef` está no manifesto local `backend-dotnet/dotnet-tools.json`.

## Fontes consultadas com sucesso

1. [Spring Boot — requisitos](https://docs.spring.io/spring-boot/system-requirements.html): Boot 4.1.2, Java, Maven e Gradle.
2. [Spring AI — Getting Started](https://docs.spring.io/spring-ai/reference/getting-started.html): série 2.0 e compatibilidade Boot 4.0/4.1.
3. [Spring Boot 3.5 — requisitos](https://docs.spring.io/spring-boot/3.5/system-requirements.html): comparado como alternativa; não selecionado para misturar com Spring AI 2.
4. [springdoc-openapi](https://springdoc.org/): versão 3.2.0 e suporte Boot 4. Projeto comunitário, não mantido pela equipe Spring.
5. [Apache Maven — downloads](https://maven.apache.org/download.cgi): 3.10.1 estável; 3.9.16 mantida; Maven 4 ainda RC na consulta.
6. [.NET — política de suporte](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core): .NET 10 LTS, .NET 11 STS; .NET 8/9 fora de suporte em 10/11/2026.
7. [EF Core SQL Server](https://learn.microsoft.com/en-us/ef/core/providers/sql-server/): provider Microsoft, SQL Server/Azure SQL.
8. [Node — releases](https://nodejs.org/en/about/previous-releases): linhas LTS 22/24/26; 24 selecionada para maturidade.
9. [Node 24 — checksums oficiais](https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt): distribuição 24.22.3.
10. [Expo — SDK reference](https://docs.expo.dev/versions/latest/): matriz SDK 58 / RN 0.88 / React 19.3.0, Node ≥22.13, Android compileSdk 37/target 36.
11. [Firebase — distribuir APK pelo console](https://firebase.google.com/docs/app-distribution/android/distribute-console): APK assinado, registro do app e testers; autenticação Firebase não é necessária só para distribuir.
12. [Docker Desktop Windows](https://docs.docker.com/desktop/setup/install/windows-install/): WSL ≥2.1.5, virtualização, SLAT, RAM e modos de instalação.
13. [SQL Server em containers](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver17): imagem 2022 disponível, `MSSQL_SA_PASSWORD`, volumes e caminho `mssql-tools18` nas CUs recentes.
14. [Oracle PL/SQL 19c](https://docs.oracle.com/en/database/oracle/oracle-database/19/lnpls/index.html): referência técnica, revisão indicada de abril/2026.
15. [RabbitMQ — download](https://www.rabbitmq.com/docs/download): release 4.4.0 na consulta.
16. [MongoDB 8.0 — release notes](https://www.mongodb.com/docs/v8.0/release-notes/8.0/): major on-premises, patches e restrições de plataforma a conferir com o kernel WSL instalado.

## Falha de consulta e limites

`https://www.oracle.com/database/free/` retornou **HTTP 403**. A documentação PL/SQL 19c foi acessada separadamente com HTTP 200. Não se concluiu versão/imagem de Oracle Free nem disponibilidade de conta institucional a partir da página bloqueada.

Na Etapa 1 não foram validados registros de pacotes WinGet. Na Etapa 2, as consultas abaixo verificaram disponibilidade no catálogo desta máquina. Restore Maven/NuGet e imagens por digest foram posteriormente exercitados; endpoint de IA, npm do app, contas Azure/Firebase e pipeline continuam não verificados.

## Revalidação de ferramentas — início da Etapa 2, 17/11/2026

- `winget show --id <ID> --exact --source winget --disable-interactivity`: Git.Git 2.56.0.4; EclipseAdoptium.Temurin.21.JDK 21.0.13.9; Microsoft.DotNet.SDK.10 10.0.404; Docker.DockerDesktop 4.99.0; Microsoft.WSL 3.0.5; Microsoft.AzureCLI 2.93.0.
- `OpenJS.NodeJS.LTS` retornou **26.13.1**; consulta com `--version 24.22.3` falhou (exit 1). Node 24.22.3 permanece a seleção; usar MSI oficial com hash conferido, conforme [plano de instalação](ambiente-desenvolvimento.md).
- [API Adoptium — JDK 21 Windows x64](https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows): 21.0.13+9, instalador e checksum oficiais.
- [Metadados .NET 10](https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/10.0/releases.json): latest-sdk 10.0.404, runtime 10.0.15, LTS ativo e fim de suporte 14/11/2028.
- [Checksums Node 24](https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt): confirma `node-v24.22.3-x64.msi`; hash registrado no plano.
- [Docker Windows](https://docs.docker.com/desktop/setup/install/windows-install/): requisitos WSL, RAM, virtualização e instalação por usuário novamente consultados.
- [WSL — comandos básicos](https://learn.microsoft.com/en-us/windows/wsl/basic-commands): confirma `--no-distribution` e verificações.
- [Azure CLI Windows](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows): 2.93.0 e instalador x64.

Na rodada inicial acima foram consultados somente metadados/documentação. Posteriormente os lotes A/B/C foram instalados e testados: resultados em [ambiente](ambiente-desenvolvimento.md), seções 7–8. Frameworks/bancos devem ser revalidados antes de gerar projetos ou baixar suas imagens; testes de ferramentas não comprovam integração da aplicação.
