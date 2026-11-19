# MongoDB — representação documental

**Estado: implementado e validado localmente em MongoDB 8.0.38.** Os scripts reproduzem no banco `citytech_demo` a amostra determinística do Oracle: 6 categorias, 12 ocorrências, 12 históricos/eventos e 3 sugestões de IA. A execução real aprovou 25 assertions e a repetição não criou duplicatas.

## Arquivos

| Arquivo | Responsabilidade |
|---|---|
| `01-schema.js` | Seleciona o database com `db.getSiblingDB`, cria/atualiza collections, `$jsonSchema` estrito e índices |
| `02-seed.js` | Insere os IDs ausentes com `insertMany` e sincroniza somente os documentos determinísticos já existentes |
| `03-queries.js` | Executa dois `find` e seis pipelines `aggregate`, incluindo os três relatórios comparáveis ao Oracle |
| `04-tests.js` | Valida collections, validators, seed, índices, rejeição de documento inválido e resultados Oracle↔Mongo |
| `run-mongodb.sh` | Executa os quatro scripts pelo `mongosh` do container sem expor a senha na linha de comando |

Nenhum script usa `drop`, remove collection, apaga volume ou exclui documentos externos. O seed controla apenas seus `_id` determinísticos: documentos novos são inseridos e documentos da amostra são substituídos pela versão canônica.

## Modelo documental

### `categorias`

Um documento por categoria Oracle. `_id` e `oracleId` preservam o UUID de origem; `code` é único. A collection permanece separada porque categorias possuem identidade, descrição e ciclo de vida próprios e podem ser consultadas sem ler ocorrências.

Índices: `oracleId` único, `code` único e (`active`, `name`).

### `ocorrencias`

Snapshot orientado à leitura, com a categoria resumida, endereço, histórico cronológico e sugestão de IA incorporados. O embedding evita joins nas telas/relatórios e mantém uma visão autocontida da ocorrência. A duplicação é deliberada e identificada por `origem: "oracle"` e `snapshotVersao` BSON Date.

Índices: `oracleId` único, (`category.code`, `status`), (`status`, `priority`), `address.district`, `createdAt` e `aiSuggestion.status` parcial.

### `eventos_triagem`

Visão append-only dos mesmos 12 registros de `status_history`, com categoria e bairro desnormalizados para análise operacional. Ela demonstra o padrão de log/evento e permite agrupar ações sem desenrolar o array incorporado de todas as ocorrências.

Índices: `oracleId` único, (`occurrenceId`, `createdAt`) e (`action`, `categoryCode`, `createdAt`).

Todas as collections usam `validationLevel: "strict"`, `validationAction: "error"`, UUID textual normalizado, enums alinhados ao Java/Oracle e datas BSON. A validação rejeita campos não declarados.

## Oracle versus MongoDB

| Conceito | Oracle relacional | MongoDB documental | Decisão |
|---|---|---|---|
| Categoria | `categories`, FK em `occurrences` | collection `categorias` + resumo em `ocorrencias.category` | Referência lógica preserva identidade; resumo reduz lookup |
| Ocorrência/endereço | colunas em `occurrences` | documento e subdocumento `address` | Endereço pertence à ocorrência e é lido junto |
| Histórico | `status_history`, uma linha por ação | `history[]` incorporado + `eventos_triagem` analítico | Array favorece detalhe; log favorece séries operacionais |
| Sugestão IA | `ai_suggestions`, relação 1:1 | `aiSuggestion` incorporada ou `null` | Ciclo atual da IA é parte da visão da ocorrência |
| Integridade | PK, FK, checks e triggers | `$jsonSchema`, índices únicos e teste automatizado | Mongo não simula FK; rastreabilidade usa UUID/origem/snapshot |
| Atualização | fonte transacional do backend Java | snapshot acadêmico reproduzível | Oracle continua fonte de verdade; não há escrita dupla |

Os três relatórios equivalentes de `database/oracle/07-reports.sql` produziram os mesmos resultados:

1. Categoria: 2 ocorrências para cada um dos 6 códigos.
2. Fila não terminal: `CRITICA=2`, `ALTA=4`, `MEDIA=3`; `BAIXA` não aparece.
3. Categoria/status: 12 combinações, uma ocorrência em cada combinação da massa.

As agregações adicionais mostram distribuição por bairro/status, situação da IA (`PRONTA=1`, `ACEITA=1`, `FALHOU=1`) e eventos por ação/papel.

## Execução

Preencha `MONGODB_ROOT_PASSWORD` no `.env` ignorado pelo Git. `MONGODB_DATABASE` é opcional e usa `citytech_demo` por padrão.

```bash
docker compose --profile database up -d --wait mongodb
./database/mongodb/run-mongodb.sh
docker compose stop mongodb
```

O runner autentica com as variáveis internas do container. Para executar um arquivo isolado, use o mesmo padrão sem imprimir credenciais:

```bash
docker compose exec -T mongodb sh -lc \
  'exec mongosh --quiet --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --file /dev/stdin' \
  < database/mongodb/04-tests.js
```

Resultado verificado em 17/11/2026: container healthy, schema aplicado, 30 documentos do snapshot, consultas demonstráveis e **25/25 assertions aprovadas**. Na segunda execução: 0 inseridos e 30 sincronizados, comprovando idempotência. Integração automática Oracle→MongoDB não é exigida; qualquer atualização do seed Oracle deve ser refletida conscientemente neste snapshot e nos testes comparativos.
