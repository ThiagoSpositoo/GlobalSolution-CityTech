# Evidências reproduzíveis — Banco de Dados

Esta pasta reúne somente saídas textuais geradas por comandos reais, sem credenciais.

| Arquivo | Origem | Estado nesta finalização |
|---|---|---|
| `mongodb-run.txt` | schema, seed, consultas e testes via `mongosh` no container | Gerado e aprovado |
| `validacao-estatica.txt` | checagens de sintaxe, estrutura, segurança do pacote e Git | Gerado ao fechar o pacote |

Os testes e relatórios Oracle foram aprovados anteriormente no Oracle XE 21, conforme `docs/progresso.md`. Eles não foram reexecutados nesta finalização porque as variáveis locais exigidas pelo bootstrap não estavam preenchidas; nenhuma credencial foi criada ou alterada. Para gerar evidência atual, execute `06-tests.sql` e `07-reports.sql` conforme `database/oracle/README.md`.

As saídas podem variar em espaçamento, data de execução e quantidade total de dados operacionais. Os relatórios comparativos usam apenas os UUIDs da amostra acadêmica.
