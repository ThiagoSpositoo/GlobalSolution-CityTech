# Relatório de preparação da sincronização QA

Data: **19/11/2026**. Modo: **dry-run**. Nenhuma escrita remota foi executada.

## Inventário real

- Organização/projeto: `RM561694/GlobalSolution-CityTech`.
- 56 Work Items: 5 Epics, 12 Features e 39 Product Backlog Items.
- Hierarquia validada: todos os Epics, Features e PBIs do inventário possuem os pais/filhos esperados no mapeamento canônico.
- Fonte: `qa/relatorios/azure-work-items.json`.

## Preparação canônica

- `qa/data/azure-mapping.json`: 5 Epics, 12 Features e 39 PBIs mapeados por ID, título, revisão e relacionamento real.
- `qa/data/work-item-content.json`: 51 descrições e conjuntos de critérios de aceite, cada item com pelo menos três critérios.
- `qa/data/test-cases.json`: 24 casos, sendo um positivo e um negativo por Feature, com objetivo, preparação, entradas, saída e três passos estruturados.

## Resultado do dry-run

| Métrica | Quantidade |
|---|---:|
| Work Items com pelo menos um campo a preencher | 49 |
| Campos documentais a preencher | 95 |
| Test Cases a criar, se futuramente autorizado | 24 |
| Conteúdos válidos divergentes preservados | 7 |
| Conflitos não resolvidos | **0** |

Os 95 campos correspondem a 17 campos ausentes nas Features e 78 campos ausentes nos PBIs. As Features 7 e 8 já possuem descrição e aceite válidos; as Features 9, 10 e 11 já possuem descrição válida. Esses sete campos não serão sobrescritos.

## Conteúdos preservados

| ID | Work Item | Campo |
|---:|---|---|
| 7 | FEA-01 Cadastro de Usuário | Descrição |
| 7 | FEA-01 Cadastro de Usuário | Critérios de aceite |
| 8 | FEA-02 Login e Autenticação | Descrição |
| 8 | FEA-02 Login e Autenticação | Critérios de aceite |
| 9 | FEA-03 Cadastro de Ocorrência | Descrição |
| 10 | FEA-04 Anexo de Imagens | Descrição |
| 11 | FEA-05 Geolocalização e Endereço | Descrição |

## Limitações registradas

- Anexos de imagem, recuperação de senha, notificações push, gráficos avançados e exportação de relatórios não estão implementados.
- Geolocalização atual significa endereço textual; não há GPS, mapa ou geocodificação.
- Pipeline de IA/RAG e fallback existem, mas LLM externo não foi validado.
- TC-IMG-01/02 e TC-REPORT-01/02 deverão ficar `Bloqueado` enquanto as respectivas funcionalidades não existirem.
- Nenhum Test Case foi executado; não há resultado Passed/Failed, captura ou relatório analítico inventado.

Plano técnico completo: `qa/relatorios/sync-plan.json`.
