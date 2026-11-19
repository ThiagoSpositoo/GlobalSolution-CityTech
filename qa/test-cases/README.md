# Test Cases — catálogo planejado

**Estado: 59 casos planejados na Etapa 3B; nenhum executado.** O catálogo completo, com preparação, passos e resultado esperado, está em [docs/rastreabilidade.md](../../docs/rastreabilidade.md), seção 3.

## Campos obrigatórios no Azure Test Plans

- ID real, título, Feature/PBI e requisito da matriz.
- Tipo: positivo ou negativo; técnica de caixa-preta utilizada.
- Summary/objetivo.
- Preparação: usuário/papel, estado, dados, ambiente/versão/commit.
- Inputs e outputs esperados.
- Steps numerados: ação do testador e resposta esperada do sistema.
- Resultado real, aprovado/reprovado/bloqueado, evidência e bug vinculado.

## Distribuição planejada

| Área | Prefixo | Casos |
|---|---|---:|
| Autenticação e operação .NET | `TC-AUTH`, `TC-OPS` | 11 |
| Ocorrências Java | `TC-OCC` | 10 |
| Acompanhamentos .NET | `TC-FOLLOW` | 8 |
| Gestão e indicadores | `TC-MGR` | 4 |
| IA e evento | `TC-AI` | 5 |
| Mobile | `TC-MOB` | 7 |
| Dados Oracle/Mongo | `TC-DATA` | 6 |
| DevOps, QA e entrega | `TC-DEV`, `TC-QA` | 8 |

Os prefixos são identificadores locais de planejamento. A execução manual no Test Plans é obrigatória para QA; testes xUnit/Maven não a substituem. Cobrir autenticação/permissão, validações, CRUD persistido, falhas de rede, idempotência, rate limit e revisão de IA quando pertinente.
