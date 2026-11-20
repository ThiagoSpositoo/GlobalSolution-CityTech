# CityTech — Mastering Relational and Non-Relational Database

Entrega da disciplina de banco de dados da **Global Solution FIAP 2026/2**.

**Problema:** cidadãos precisam registrar problemas de infraestrutura urbana e acompanhar sua resolução. O Oracle mantém o domínio transacional usado pela API Java; o MongoDB representa um snapshot documental, orientado a leitura e análise, da mesma amostra fictícia.

## Integrantes

| Integrante | RM |
|---|---:|
| Thiago Sposito | 561694 |
| Vitor Madrigrano | 564191 |
| Lucas Lopes | 563544 |

**Turmas do grupo:** 2TDSA / 2TDSR. A associação individual entre integrante e turma deve ser conferida antes do envio, pois não foi informada.
**GitHub:** <https://github.com/ThiagoSpositoo/GlobalSolution-CityTech>

## Conteúdo e cobertura

### Oracle

O modelo em [`oracle/`](oracle/) preserva a compatibilidade com as entidades JPA do backend Java:

- `categories` 1:N `occurrences`;
- `occurrences` 1:N `status_history`;
- `occurrences` 1:1 `ai_suggestions`;
- `outbox_events` e `processed_events` suportam mensageria e deduplicação;
- `occurrence_audit` registra a trilha física acadêmica.

PKs e FKs usam UUID em `RAW(16)`. Checks protegem enums, cancelamento, versão e booleanos. A massa contém 6 categorias, 12 ocorrências, 12 eventos de histórico e 3 sugestões de IA com IDs determinísticos.

| Requisito | Implementação |
|---|---|
| 2 blocos PL/SQL | `03-blocks.sql`: decisão sobre criticidade; cursor/loop por categoria |
| 2 funções | `pkg_citytech_reports.fn_occurrence_count`; `pkg_citytech_operations.fn_pending_outbox` |
| 2 procedures | `pkg_citytech_reports.pr_category_summary`; `pkg_citytech_operations.pr_outbox_summary` |
| 2 packages | `pkg_citytech_reports` e `pkg_citytech_operations`, ambos com specification e body |
| 2 triggers | `trg_occurrences_audit` e `trg_history_append_only` |
| Auditoria | operação, data/hora, usuário e valores antigos/novos de categoria, prioridade, status e versão |
| Testes | `06-tests.sql`, transacional e finalizado com `ROLLBACK` |
| Relatórios | `07-reports.sql`, três consultas da amostra comparáveis ao MongoDB |

O Java continua dono do CRUD e da máquina de estados. O PL/SQL acrescenta relatórios, diagnóstico operacional, auditoria e imutabilidade do histórico sem duplicar a regra transacional da aplicação.

### MongoDB

O modelo em [`mongodb/`](mongodb/) utiliza três collections e 30 documentos:

- `categorias`: entidade de referência com identidade e ciclo de vida próprios;
- `ocorrencias`: categoria resumida, endereço, histórico e sugestão de IA incorporados;
- `eventos_triagem`: log analítico append-only derivado do histórico.

Categoria e eventos permanecem em collections próprias porque são consultados independentemente. Endereço, histórico e IA são incorporados à ocorrência porque pertencem ao mesmo agregado e normalmente são lidos juntos. A duplicação controlada reduz `$lookup`; `oracleId`, `origem` e `snapshotVersao` preservam a rastreabilidade.

Os scripts usam `db.getSiblingDB`, `createCollection`, `insertMany`, `find`, pipelines `aggregate`, `$jsonSchema` estrito e índices. Não executam `drop`, não removem collections e não apagam documentos externos.

## Ordem e execução

### Oracle em schema vazio

Use SQLcl, SQL*Plus ou ferramenta compatível, conectado a um **schema de desenvolvimento vazio**:

```sql
@database/oracle/install.sql
@database/oracle/06-tests.sql
@database/oracle/07-reports.sql
```

`install.sql` chama, na ordem, `01-schema.sql` a `05-triggers.sql`. Ele não contém `DROP` ou `TRUNCATE`. Não o execute sobre um schema que já possua os objetos. Instruções de Compose e conexão institucional sem credenciais estão em [`oracle/README.md`](oracle/README.md).

### MongoDB no ambiente local

```bash
docker compose --profile database up -d --wait mongodb
./database/mongodb/run-mongodb.sh
```

O runner executa `01-schema.js`, `02-seed.js`, `03-queries.js` e `04-tests.js` via quatro invocações independentes do `mongosh`. Consulte [`mongodb/README.md`](mongodb/README.md) para o comando seguro de arquivo isolado pelo container. Credenciais devem ficar somente no `.env` ignorado.

## Mapeamento Oracle → MongoDB

| Oracle | MongoDB | Estratégia |
|---|---|---|
| `categories` | `categorias` e `ocorrencias.category` | collection de referência + resumo incorporado |
| `occurrences` e colunas de endereço | `ocorrencias` e `address` | agregado principal + subdocumento |
| `status_history` | `ocorrencias.history[]` e `eventos_triagem` | detalhe incorporado + log analítico |
| `ai_suggestions` | `ocorrencias.aiSuggestion` | relação 1:1 incorporada |
| PK/FK/checks | `_id`, `oracleId`, validators e índices únicos | integridade adaptada ao modelo documental |

Oracle é a fonte transacional. MongoDB é um snapshot acadêmico reproduzível; não há escrita dupla nem sincronização automática.

## Três relatórios comparáveis

| Relatório | Oracle | MongoDB | Resultado da amostra |
|---|---|---|---|
| Ocorrências por categoria | join e `GROUP BY` | pipeline por `category.code` | 2 para cada um dos 6 códigos |
| Fila não terminal por prioridade | filtro + `GROUP BY` | `$match` + `$group` | CRITICA=2, ALTA=4, MEDIA=3 |
| Categoria e status | join + `GROUP BY` | agrupamento composto | 12 combinações, contagem 1 |

Oracle filtra os 12 UUIDs acadêmicos, assim dados adicionais criados pela API não contaminam a comparação. O MongoDB testa os mesmos IDs. Consultas extras mostram iluminação pendente, fila alta/crítica, bairro/status, IA e eventos por ação/papel.

## Testes e evidências

- Oracle XE 21: schema, packages, triggers e testes executados localmente; o Java também iniciou com `ddl-auto=validate`.
- MongoDB 8.0.38: 3 collections, 30 documentos e 25 assertions aprovadas; uma segunda carga não criou duplicatas.
- Sintaxe dos quatro arquivos JavaScript também pode ser conferida com `node --check`.
- Evidências reproduzidas para o pacote final ficam em [`evidencias/`](evidencias/). A pasta diferencia resultados atuais de registros históricos.

O Oracle institucional não foi modificado nesta finalização. A execução integral de PL/SQL nessa instância depende de um schema vazio/autorizado e continua sendo uma limitação explícita.

## Segurança e limitações

- Dados são fictícios e não representam integração oficial com prefeitura.
- Não versionar `.env`, senhas, tokens, chaves, dumps ou arquivos de banco.
- Não executar o instalador em schema com objetos/dados reais.
- Resultados locais não comprovam automaticamente a execução no Oracle institucional.
- A relação individual integrante↔turma e o formato exato exibido no Portal devem ser conferidos antes do envio.

## Outras persistências

O SQL Server em `database/sqlserver/` pertence ao domínio .NET e não integra a entrega técnica Oracle/MongoDB desta disciplina. Cada API permanece dona de seus dados.
