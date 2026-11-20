# Backlog QA — ligação com o backlog real

**Estado: inventário REST confirmado com 5 Epics, 12 Features e 39 PBIs; mapeamento completo em `qa/data/azure-mapping.json`.**

O backlog funcional completo está em [docs/backlog.md](../../docs/backlog.md): 8 épicos, 21 Features e 60 PBIs com descrições, prioridades P0/P1/P2 e critérios de aceite verificáveis. A [rastreabilidade](../../docs/rastreabilidade.md) liga cada requisito da matriz aos casos de teste planejados.

## Estrutura

```text
Epic → Feature → Product Backlog Item → Test Case → Execução no Test Plans
```

| Epic local | Features | Disciplinas |
|---|---|---|
| E1 Identidade e acesso | F1.1–F1.3 | .NET, Mobile |
| E2 Ocorrências urbanas | F2.1–F2.3 | Java, Mobile, Banco |
| E3 Acompanhamento cidadão | F3.1 | .NET, Mobile |
| E4 Gestão e indicadores | F4.1–F4.2 | Java, Mobile |
| E5 IA assistiva e evento | F5.1–F5.3 | Java, IA |
| E6 Aplicativo Mobile | F6.1–F6.4 | Mobile |
| E7 Dados, PL/SQL e MongoDB | F7.1–F7.2 | Banco |
| E8 Qualidade, DevOps e entrega | F8.1–F8.3 | QA, DevOps |

## Pendências reais

1. Capturar evidências reais da hierarquia, descrições, aceites e vínculos.
2. Confirmar Test Plan, Suites e atribuições, se a licença permitir.
3. Executar os casos implementáveis manualmente e registrar resultados reais.
4. Manter bloqueados TC-IMG-01/02 e TC-REPORT-01/02 enquanto as funcionalidades correspondentes não existirem.
5. Confirmar e evidenciar o professor como ADMIN, sem expor dados pessoais desnecessários.

Critérios de aceite definem entrada, ação e resultado observável, sem exigir conhecer a implementação. Não registrar item “concluído” apenas porque a documentação existe.
