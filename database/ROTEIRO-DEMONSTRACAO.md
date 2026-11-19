# Roteiro de demonstração — Banco de Dados

Roteiro curto para a apresentação presencial. Use somente ambiente de desenvolvimento e não exponha credenciais na tela.

## 1. Problema e modelo Oracle

1. Explique que o CityTech registra ocorrências urbanas e acompanha triagem/resolução.
2. Mostre `01-schema.sql`: `categories` → `occurrences` → `status_history`, sugestão de IA, outbox e auditoria.
3. Destaque PKs/FKs, checks, UUID `RAW(16)` e compatibilidade com o backend Java.

## 2. Função e procedure

No SQLcl/SQL*Plus, com `SERVEROUTPUT` habilitado:

```sql
SELECT pkg_citytech_reports.fn_occurrence_count('ABERTA') AS abertas
FROM dual;

DECLARE
    v_total NUMBER;
    v_active NUMBER;
BEGIN
    pkg_citytech_reports.pr_category_summary(
        HEXTORAW('11111111111111111111111111111111'),
        v_total,
        v_active
    );
    DBMS_OUTPUT.PUT_LINE('VIAS total=' || v_total || ', ativas=' || v_active);
END;
/
```

Explique validação de status, parâmetros `OUT` e tratamento de categoria inexistente.

## 3. Triggers, auditoria e packages

Execute `06-tests.sql`. Mostre:

- auditoria após `UPDATE`, com operação, data/usuário e valores antigo/novo;
- rejeição de `UPDATE` em `status_history`;
- dois packages com specification e body;
- rollback final, que não deixa alteração de teste na massa.

## 4. Collections e carga MongoDB

Execute `run-mongodb.sh` e mostre:

- `createCollection` e validators em `01-schema.js`;
- `insertMany` e seed determinístico em `02-seed.js`;
- contagens: 6 categorias + 12 ocorrências + 12 eventos;
- `_id`, `oracleId`, `origem` e `snapshotVersao`.

## 5. Três relatórios

1. Ocorrências por categoria.
2. Fila não terminal por prioridade.
3. Categoria/status.

Execute `07-reports.sql` no Oracle e `03-queries.js` no MongoDB. Compare:

- 2 ocorrências por cada categoria;
- `CRITICA=2`, `ALTA=4`, `MEDIA=3`;
- 12 combinações categoria/status, cada uma com contagem 1.

## 6. Justificativa da transição

- Oracle permanece fonte transacional por integridade, relacionamentos e concorrência.
- MongoDB é snapshot acadêmico orientado a leitura, não uma segunda fonte de verdade.
- Endereço, histórico e IA são incorporados por pertencerem ao agregado da ocorrência.
- Categorias e eventos também possuem collections próprias por identidade e consulta independente.
- Não há sincronização automática porque ela não é exigida e criaria complexidade/escrita dupla sem benefício para a demonstração.

Finalize abrindo `04-tests.js` e a saída de 25 assertions. Declare a limitação: a execução atual no Oracle institucional depende de schema vazio e autorização.
