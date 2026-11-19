# CityTech

**Tecnologia que transforma cidades.**

Plataforma CitizenTech de monitoramento colaborativo e zeladoria urbana — Global Solution FIAP 2026/2, ADS.

## Estado do projeto

**Etapas 1–5A/.NET concluídas; vertical 5B/Java e Etapa 7/Mobile implementadas; Oracle e snapshot MongoDB locais validados.** O .NET possui 77 testes aprovados contra SQL Server. O Java possui 41 testes padrão aprovados, 1 AMQP opt-in ignorado por padrão, prova RabbitMQ real e inicialização validada contra Oracle XE 21 com `ddl-auto: validate`. O MongoDB possui 3 collections, 30 documentos comparáveis ao Oracle e 25 assertions aprovadas. Em 18/11, um smoke E2E real comprovou cadastro/login .NET, JWT no Java, ocorrência/Oracle, outbox/RabbitMQ, fallback IA, acompanhamento .NET, gestão, triagem e revisão humana. O Mobile possui 11 rotas; Expo Web e CORS reais estão operacionais, mas navegação manual e Android ainda precisam ser validados. LLM externo, Azure, APK/Firebase e deploy permanecem pendentes.

Para continuar em outra sessão, leia o [manual permanente](AGENTS.md) e o [progresso/ponto de retomada](docs/progresso.md). O progresso deve ser atualizado ao concluir cada etapa ou encerrar uma sessão com trabalho pendente.

Fonte oficial preservada: `Enunciados/2TDS Fevereiro - Global Solution 2026-2.pdf`, lida nas 97 páginas.

**Prazo oficial: 19/11/2026 às 23h55 no Portal FIAP.** Cadastro de grupos até 13/11; confirmar imediatamente sua situação. Apresentações em 23–27/11, com divergência de modalidade em .NET e alinhamento específico em IA.

## Proposta

Cidadãos poderão criar conta, autenticar-se, registrar problemas urbanos com endereço e fotos opcionais e acompanhar sua evolução. Gestores poderão consultar ocorrências, atualizar status e consultar indicadores. A IA sugerirá categoria, prioridade e resumo, com revisão humana.

Categorias iniciais: vias/buracos, iluminação, acessibilidade, descarte irregular, água/vazamentos e outros. Dados de demonstração serão fictícios; não há integração oficial com prefeituras.

## Documentação

- [Manual permanente de desenvolvimento](AGENTS.md)
- [Progresso e retomada entre sessões](docs/progresso.md)
- [Requisitos oficiais, pontos, penalidades e páginas](docs/requisitos-global-solution.md)
- [Arquitetura, integração e decisões](docs/arquitetura.md)
- [Plano de desenvolvimento e dependências](docs/plano-desenvolvimento.md)
- [Diagnóstico do computador e instalações propostas](docs/ambiente-desenvolvimento.md)
- [Versões e fontes técnicas](docs/versoes-e-fontes.md)
- [Verificações e pendências da Etapa 1](docs/verificacao-etapa-1.md)
- [Git e infraestrutura local — resultados da Etapa 3A](docs/verificacao-etapa-3a.md)
- [Backlog priorizado — Épicos, Features e PBIs](docs/backlog.md)
- [Modelo de domínio e máquina de estados](docs/modelo-dominio.md)
- [Contratos REST, JWT e evento RabbitMQ](docs/contratos-api.md)
- [Integração Mobile com Java e .NET](docs/integracao-mobile.md)
- [Decisões de integração e riscos](docs/decisoes-e-riscos.md)
- [Rastreabilidade e casos de teste planejados](docs/rastreabilidade.md)
- [Planejamento QA](qa/README.md)
- [Entregáveis e apresentações](docs/entregas/README.md)

## Organização das sete disciplinas

| Disciplina | Área | Integração planejada |
|---|---|---|
| Java Advanced | `backend-java/` | Ocorrências, gestão, JWT, Spring AI e RabbitMQ; consumido pelo Mobile |
| Advanced Business Development with .NET | `backend-dotnet/` | Contas, autenticação e acompanhamentos; consumido pelo Mobile |
| Mobile Application Development | `mobile/` | React Native/Expo; acesso às duas APIs |
| Mastering Relational and Non-Relational Database | `database/oracle/`, `database/mongodb/` | PL/SQL do domínio e representação documental correspondente |
| Disruptive Architectures | `ai/` + `backend-java/` | Corpus RAG, avaliação e funcionalidade generativa integrada |
| Compliance, Quality Assurance & Tests | `qa/` + Azure Boards/Test Plans | Backlog, critérios de aceite, testes manuais e evidências |
| DevOps Tools & Cloud Computing | `devops/`, `scripts/`, `dockerfiles/` | Azure CLI, Repos, Boards, CI/CD; .NET como alvo inicial |

## Estrutura

```text
.
├── Enunciados/                    # Original existente, preservado
├── backend-java/
│   ├── src/
│   └── tests/
├── backend-dotnet/
│   ├── src/
│   │   ├── CityTech.Api/
│   │   ├── CityTech.Domain/
│   │   └── CityTech.Infrastructure/
│   ├── tests/
│   │   └── CityTech.Tests/
│   └── CityTech.slnx
├── mobile/
│   ├── src/
│   └── assets/
├── database/
│   ├── oracle/
│   ├── mongodb/
│   └── sqlserver/
├── ai/
│   ├── corpus/
│   └── evaluation/
├── qa/
│   ├── backlog/
│   ├── test-cases/
│   └── evidencias/
├── devops/
│   └── pipelines/
├── scripts/
├── dockerfiles/
├── docs/
│   ├── diagramas/
│   └── entregas/
├── docker-compose.yml
├── .env.example
├── .editorconfig
├── .gitattributes
└── .gitignore
```

Os README das áreas documentam responsabilidades e estado. .NET, Java e Mobile contêm implementação e testes reais; o Java empacota também o corpus versionado de `ai/corpus`. O DDL/PLSQL Oracle está em `database/oracle/` e o snapshot MongoDB comparável em `database/mongodb/`. `azure-pipeline.yml`, Dockerfiles e entregáveis externos ainda serão criados nas etapas autorizadas correspondentes.

## Ambiente e execução

Windows 11 Pro x64, 15,93 GiB de RAM. Instalados: Git 2.56.0.windows.4, Temurin 21.0.13+9, .NET SDK 10.0.404, Node 24.22.3/npm 11.19.1, WSL 3.0.5, Docker Desktop 4.99.0 (engine 29.9.3), Compose 5.7.0 e Azure CLI 2.93.0. Testes básicos dos três lotes passaram, incluindo containers Linux via Docker e Compose. Resultados e pendências em [ambiente](docs/ambiente-desenvolvimento.md), seções 7–8.

O [Compose](docker-compose.yml) executa RabbitMQ, Oracle XE 21, SQL Server e MongoDB locais com imagens fixadas por digest, volumes e healthchecks. Não contém as aplicações. Para reproduzir em outro ambiente:

1. Criar `.env` local a partir de `.env.example`, preencher somente segredos locais e confirmar o aceite SQL Server.
2. Gerar o par JWT compartilhado: `mkdir -p secrets/jwt && openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out secrets/jwt/private.pem && openssl pkey -in secrets/jwt/private.pem -pubout -out secrets/jwt/public.pem`.
3. Validar com `docker compose --env-file .env config --quiet`.
4. Seguir o [guia DevOps](devops/README.md) antes de iniciar serviços.

O Compose lê `.env` automaticamente. O launcher [`backend-java/run-local.sh`](backend-java/run-local.sh) também o carrega; o .NET ainda exige exportar as variáveis no processo. Há exemplos sem segredos nos READMEs de [Java](backend-java/README.md) e [.NET](backend-dotnet/README.md). `EXPO_PUBLIC_*` é público no app e nunca deve conter segredos.

Topologia local: Java em `8080`, .NET em `8081` e Expo/Metro/Web normalmente em `19006`. Expo Web usa `localhost`; Android Emulator usa `10.0.2.2`; dispositivo físico usa o IP LAN do computador. Em `Development`/profile `local`, as APIs aceitam origens loopback em qualquer porta e qualquer cabeçalho solicitado; domínios externos continuam restritos a `CORS_ALLOWED_ORIGINS`. Produção não recebe essa política implicitamente.

### Ordem para subir os backends

Execute a partir da raiz. Se `ORACLE_JDBC_URL` apontar para a FIAP, não suba o serviço `oracle` local; use o XE somente quando a URL for `jdbc:oracle:thin:@localhost:1521/XEPDB1`.

```bash
# 1. Infra: RabbitMQ e SQL Server. Os serviços explicitados evitam iniciar Oracle XE.
docker compose --profile java --profile dotnet up -d --wait rabbitmq sqlserver

# 2. Bancos: o Oracle recebe database/oracle/install.sql somente em schema vazio.
# O SQL Server recebe as migrations versionadas do .NET.
set +H
set -a
source .env
set +a
cd backend-dotnet
dotnet tool restore
dotnet ef database update --project src/CityTech.Infrastructure --startup-project src/CityTech.Api
cd ..

# 3. Identidade .NET: em outro terminal, exporte o mesmo .env e execute:
dotnet run --project backend-dotnet/src/CityTech.Api

# 4. Java/Oracle/RabbitMQ: em outro terminal:
backend-java/run-local.sh
```

Confirme `http://localhost:8081/health/live`, `http://localhost:8080/actuator/health`, Swagger .NET em `http://localhost:8081/swagger` e Swagger Java em `http://localhost:8080/swagger-ui.html`.

## Identidade e impacto

Azul, branco e verde; estilo moderno, profissional e acessível. ODS principal proposto: **11 — Cidades e comunidades sustentáveis**, com contribuição a espaços públicos acessíveis e gestão participativa. Metas e indicadores propostos estão na arquitetura; impacto real ainda não foi medido.

## Integrantes e links

Nome do grupo: CityTech.

- Thiago Sposito — RM 561694
- Vitor Madrigrano — RM 564191
- Lucas Lopes — RM 563544
- Turmas do grupo: 2TDSA / 2TDSR

A associação individual entre integrante e turma e o representante permanecem pendentes de conferência. GitHub: <https://github.com/ThiagoSpositoo/GlobalSolution-CityTech>. Links Azure DevOps, deploy, Firebase e vídeos ainda não foram registrados neste README. Os backends expõem localmente seus endpoints `/api/v1`, health e Swagger; não há usuário/senha versionados nem URL pública.

## Declaração de uso de IA

Na Etapa 1 foi utilizado OpenCode com apoio de modelo de linguagem para leitura do enunciado, diagnóstico, planejamento arquitetural e documentação/configuração inicial. Nas etapas seguintes, também apoiou ambiente e implementação/revisão dos backends .NET/Java, testes, RabbitMQ e estrutura Spring AI/RAG. Resultados foram separados entre testes controlados, SQL Server/RabbitMQ reais e bloqueios Oracle/LLM; nenhuma inferência externa foi alegada. A equipe deverá revisar, compreender e conseguir explicar as decisões e todo código antes da entrega.
# GlobalSolution-CityTech
