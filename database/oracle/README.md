# Oracle / PL-SQL

**Estado: implementado e validado localmente em Oracle XE 21.** O schema segue as seis entidades JPA do backend Java e usa sintaxe compativel com Oracle 19c. O Hibernate iniciou com `ddl-auto: validate`, e os testes SQL de dados, packages, constraints e triggers passaram. A versao e as credenciais institucionais da FIAP continuam externas ao repositorio.

## Compatibilidade JPA

O `ddl-auto: validate` exige estas tabelas:

| Tabela | Entidade | Observacoes |
|---|---|---|
| `categories` | `Category` | `code` unico; boolean em `NUMBER(1,0)` |
| `occurrences` | `Occurrence` + `Address` | FK de categoria; `@Version`; endereco incorporado |
| `status_history` | `StatusHistory` | FK de ocorrencia; append-only |
| `ai_suggestions` | `AiSuggestion` | `occurrence_id` unico; dois FKs; `sources_json` CLOB |
| `processed_events` | `ProcessedEvent` | PK implementa deduplicacao |
| `outbox_events` | `OutboxEvent` | payload CLOB; indice para polling |

UUIDs usam `RAW(16)`, `Instant` usa `TIMESTAMP(6) WITH TIME ZONE`, enums usam `VARCHAR2` e os inteiros usam `NUMBER` com precisao compativel. Todos os IDs JPA sao gerados pela aplicacao, portanto **nenhuma sequence e usada pelo Hibernate**. `seq_occurrence_audit` pertence apenas a tabela academica `occurrence_audit`.

## Scripts

| Ordem | Arquivo | Finalidade |
|---|---|---|
| 1 | `01-schema.sql` | tabelas, PKs, FKs, uniques, checks, indices e sequence de auditoria |
| 2 | `02-seed.sql` | 6 categorias, 12 ocorrencias e dados tecnicos ficticios |
| 3 | `03-blocks.sql` | dois blocos anonimos com decisao, cursor e repeticao |
| 4 | `04-packages.sql` | dois packages, duas funcoes e dois procedures de relatorio/operacao |
| 5 | `05-triggers.sql` | auditoria de ocorrencias e protecao append-only do historico |
| 6 | `06-tests.sql` | assertions de dados, packages, constraints e triggers, com rollback |
| 7 | `07-reports.sql` | tres relatorios que serao comparados ao snapshot Mongo futuro |

`install.sql` aplica os arquivos 01 a 05. O schema nao possui `DROP`; execute-o em um usuario vazio. Os testes nao alteram permanentemente a amostra.

## Oracle local com Compose

1. Preencha no `.env` local `ORACLE_ADMIN_PASSWORD` e `ORACLE_PASSWORD` com senhas distintas de 8 a 30 caracteres. Nao versione o arquivo.
2. Inicie o banco:

```bash
docker compose --profile oracle up -d --wait oracle
```

Na primeira criacao do volume, a imagem cria o usuario `CITYTECH` e executa `install.sql`. Scripts de inicializacao nao rodam novamente em volume existente.

Execute testes e relatorios sem expor a senha na linha de comando:

```bash
docker compose exec -T oracle bash /opt/citytech/oracle/run-script.sh 06-tests.sql
docker compose exec -T oracle bash /opt/citytech/oracle/run-script.sh 07-reports.sql
```

Configuracao Java local:

```text
ORACLE_JDBC_URL=jdbc:oracle:thin:@localhost:1521/XEPDB1
ORACLE_USERNAME=CITYTECH
ORACLE_PASSWORD=<senha local da aplicacao>
```

O servico usa `gvenzl/oracle-xe:21-slim-faststart`, fixado por digest e restrito a `127.0.0.1`. A imagem e comunitaria e baseada no Oracle XE; para avaliacao institucional, prefira o Oracle fornecido pela FIAP quando disponivel.

## Oracle da FIAP

Nao altere os scripts. Crie ou obtenha um usuario/schema vazio com privilegios para tabelas, sequences, packages, procedures, functions e triggers. Conecte com SQLcl, SQL*Plus ou ferramenta equivalente e execute:

```sql
@install.sql
@06-tests.sql
@07-reports.sql
```

Configure o backend com a URL no formato fornecido pela instituicao, por exemplo `jdbc:oracle:thin:@//host:1521/servico`. VPN, host, porta, service name e credenciais nao devem ser gravados no Git.

## Escopo das regras PL/SQL

O Java continua sendo o unico dono do CRUD e da maquina de estados. Os packages PL/SQL produzem contagens e diagnosticos de categoria/outbox; nao implementam uma segunda transicao de ocorrencia. Os triggers acrescentam auditoria fisica e imutabilidade ao historico, complementando as regras da aplicacao.

MongoDB nao faz parte desta etapa. Os IDs e os tres relatorios foram mantidos deterministas para permitir o snapshot comparavel futuro.
