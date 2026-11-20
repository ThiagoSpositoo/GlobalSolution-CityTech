# Test Cases — catálogo planejado

**Estado: 59 cenários amplos na Etapa 3B e 24 casos estruturados/revisados contra as 12 Features reais, criados no Azure com IDs 58–81; nenhum resultado manual está disponível nos artefatos locais.** O catálogo usado pelos scripts está em [`qa/data/test-cases.json`](../data/test-cases.json), com um positivo e um negativo por Feature. TC-IMG-01/02 e TC-REPORT-01/02 estão bloqueados por funcionalidades não implementadas.

## Campos obrigatórios no Azure Test Plans

- ID real, título, Feature/PBI e requisito da matriz.
- Tipo: positivo ou negativo; técnica de caixa-preta utilizada.
- Summary/objetivo.
- Preparação: usuário/papel, estado, dados, ambiente/versão/commit.
- Inputs e outputs esperados.
- Steps numerados: ação do testador e resposta esperada do sistema.
- Resultado real, aprovado/reprovado/bloqueado, evidência e bug vinculado.

## Distribuição do catálogo automatizável

| Área | Prefixo | Casos |
|---|---|---:|
| Cadastro/autenticação/proteções | `TC-REG`, `TC-AUTH`, `TC-PROT` | 6 |
| Categorias/ocorrências/histórico | `TC-CAT`, `TC-OCC`, `TC-HIST` | 6 |
| Acompanhamento/gestão/indicadores | `TC-FOL`, `TC-MGR`, `TC-IND` | 6 |
| IA/Mobile/qualidade | `TC-AI`, `TC-MOB`, `TC-QA` | 6 |

Os prefixos são identificadores locais de planejamento. A execução manual no Test Plans é obrigatória para QA; testes xUnit/Maven não a substituem. Cobrir autenticação/permissão, validações, CRUD persistido, falhas de rede, idempotência, rate limit e revisão de IA quando pertinente.
