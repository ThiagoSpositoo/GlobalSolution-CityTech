# Matriz de Features e Test Cases

IDs e relações obtidos pelo inventário REST de 19/11/2026.

| ID | Feature Azure | Positivo | Negativo | Estado |
|---:|---|---|---|---|
| 7 | FEA-01 Cadastro de Usuário | TC-REG-01 | TC-REG-02 | planejado |
| 8 | FEA-02 Login e Autenticação | TC-AUTH-01 | TC-AUTH-02 | planejado |
| 9 | FEA-03 Cadastro de Ocorrência | TC-OCC-01 | TC-OCC-02 | planejado |
| 10 | FEA-04 Anexo de Imagens | TC-IMG-01 | TC-IMG-02 | planejado; execução bloqueada pela ausência da funcionalidade |
| 11 | FEA-05 Geolocalização e Endereço | TC-LOC-01 | TC-LOC-02 | planejado; endereço textual implementado |
| 12 | FEA-06 Classificação Automática | TC-CAT-01 | TC-CAT-02 | planejado |
| 13 | FEA-07 Priorização Automática | TC-PRI-01 | TC-PRI-02 | planejado |
| 14 | FEA-08 Resumo Automático | TC-SUM-01 | TC-SUM-02 | planejado |
| 15 | FEA-09 Consulta de Ocorrências | TC-QUERY-01 | TC-QUERY-02 | planejado |
| 16 | FEA-10 Atualização de Status | TC-STATUS-01 | TC-STATUS-02 | planejado |
| 17 | FEA-11 Dashboard Gerencial | TC-DASH-01 | TC-DASH-02 | planejado; sem gráficos avançados |
| 18 | FEA-12 Relatórios Operacionais | TC-REPORT-01 | TC-REPORT-02 | planejado; execução bloqueada pela ausência de exportação |

Detalhes de objetivo, preparação, entradas, saída e passos estão em `qa/data/test-cases.json`. A cobertura deve ser ajustada se as 12 Features reais tiverem outra decomposição; não se força vínculo por similaridade de título.
