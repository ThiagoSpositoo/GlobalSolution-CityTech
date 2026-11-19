# DevOps — base e runbook inicial

**Estado: infraestrutura local CityTech executada e verificada na Etapa 3A.** SQL Server/MongoDB/RabbitMQ healthy; [relatório de testes](../docs/verificacao-etapa-3a.md). Requisitos cloud/CI/CD DEV-01 a DEV-20 continuam pendentes; o trabalho correspondente está priorizado em [E8 do backlog](../docs/backlog.md) e os health checks/contratos em [contratos-api.md](../docs/contratos-api.md#14-health-checks).

## Caminhos exigidos pelo PDF

- `/scripts`: Azure CLI e futuro `script-bd.sql`.
- `/dockerfiles`: Dockerfiles quando houver containerização na entrega.
- `/azure-pipeline.yml`: futuro pipeline YAML, nome literal, na raiz.
- `devops/pipelines/`: templates/apoio reutilizável, não substitui arquivo da raiz.

Escolha inicial: API .NET em App Service e banco Azure SQL; ambos provisionados por CLI, com orçamento/autorização antes de executar. O app Mobile também depende do Java/Oracle/RabbitMQ disponíveis; hospedagem dessa parte será definida.

## Compose local parcial

Serviços:

| Profile | Serviço | Portas locais padrão |
|---|---|---|
| `java` | RabbitMQ | 5672 AMQP / 15672 administração |
| `dotnet` | SQL Server Developer | 1433 |
| `database` | MongoDB | 27017 |

Todos os bindings são `127.0.0.1`; volumes nomeados ficam fora do código/OneDrive. Imagens baixadas/fixadas por digest e mounts verificados. Oracle e APIs **não** estão neste Compose. Mongo também usa volume anônimo da imagem em `/data/configdb`, preservado.

Procedimento futuro após ferramentas e autorização:

1. Criar `.env` sem sobrescrever arquivo local já existente; preencher senhas e aceite EULA após leitura. Manter senhas apenas localmente.
2. Validar sintaxe/interpolação sem imprimir segredos:

```powershell
docker compose --env-file .env config --quiet
```

3. Depois da validação e escolha das imagens, iniciar apenas o necessário:

```powershell
docker compose --profile java --profile dotnet --profile database up -d
docker compose ps
```

Remover profiles do comando para economizar memória. As variáveis obrigatórias de **todos** os serviços precisam estar preenchidas, pois interpolação ocorre antes da seleção de profiles. SQL Server exige senha forte e aceite EULA; inicialização de Mongo só cria credenciais no primeiro volume vazio.

4. Conferir healthchecks e consulta SQL real; registrar versões/digests e fixar imagens.
5. Para pausar sem remover dados: `docker compose --profile java --profile dotnet --profile database stop`.

O Compose não cria schema CityTech, usuários de aplicação ou carga de domínio. Healthcheck é diagnóstico básico, não teste de aplicação. Não há comando de exclusão de volumes neste runbook.

## CI/CD planejado

Projeto privado Azure Repos, processo Scrum, Work Item inicial, branch por tarefa, PR/main protegida (revisor obrigatório/padrão RM, vínculo de Work Item). Fonte de colaboração única; GitHub recebe o mesmo histórico quando autorizado.

Build em main após merge, testes reais xUnit e artefato de publicação; release automático usa o artefato gerado. Scripts CLI versionados, variáveis/secrets configurados externamente, arquitetura e CRUD de pelo menos duas tabelas; confirmar exigência de todas as tabelas técnicas.

Vídeo DevOps: 720p/voz, tarefa→branch→mudança de código→PR/merge→CI/CD→artefatos/testes→alteração cloud→CRUD/SELECT no banco→tarefa concluída. Sem limite de 5 minutos imposto pelo PDF desta disciplina.
