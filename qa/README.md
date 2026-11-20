# Compliance, Quality Assurance & Tests — preparação

**Estado: inventário final confirmado com 5 Epics, 12 Features, 39 PBIs e 24 Test Cases (IDs 58–81). A verificação estrutural aprovou 75 checks, sem falhas ou documentação pendente. O PDF/TXT/ZIP foi gerado; execução manual, capturas, Test Plans/Suites, relatórios e permissão ADMIN ainda não possuem evidência local.** Fonte: p. 30–35 do PDF, requisitos QA-01 a QA-10.

O backlog funcional amplo está em [docs/backlog.md](../docs/backlog.md), mas não corresponde diretamente à decomposição Azure. IDs e relações reais foram consolidados em [`data/azure-mapping.json`](data/azure-mapping.json). O catálogo possui [24 casos estruturados](data/test-cases.json); nenhum resultado manual foi registrado nos artefatos locais. Quatro casos permanecem bloqueados por funcionalidades não implementadas: TC-IMG-01/02 e TC-REPORT-01/02.

## Fluxo de trabalho

1. Confirmar padrões da aula, token com escopo mínimo e acesso ao Azure Test Plans.
2. Inventariar o projeto existente e validar a hierarquia **Epic → Feature → Product Backlog Item**, sem criar outro projeto.
3. Mapear os 56 itens por ID/título/relação e completar descrição/aceite sem sobrescrever conteúdo válido.
4. Preparar Test Cases positivos e negativos de caixa-preta por Feature.
5. Executar testes manuais a cada incremento, registrar resultados e bugs, apresentar relatórios analíticos.
6. Capturar evidências durante o trabalho; gerar um PDF único de planejamento + testes.

## Áreas

- [Backlog](backlog/README.md): divergência entre planejamento local e base Azure.
- [Test Cases](test-cases/README.md): catálogo automatizável de 24 casos; nenhum executado.
- [Evidências](evidencias/README.md): roteiro de capturas exigidas.
- [Scripts](scripts/README.md): inventário REST, dry-run, sincronização protegida e verificação.
- [Entrega](entrega/README.md): documentos e estrutura do PDF/TXT.

Professor deverá ser ADMIN no projeto, conforme PDF; conta/e-mail e convite dependem de autorização. Acesso Basic do DevOps não garante por si só todas as funções de Test Plans; confirmar licença acadêmica/avaliação sem iniciar cobrança automaticamente.

A entrega é ZIP com PDF e TXT de identificação. Segurança/privacidade são transversais, mas não substituem Boards/Test Plans, critérios de aceite e capturas.
