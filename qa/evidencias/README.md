# Evidências QA — roteiro

Capturas obrigatórias do PDF p. 34:

1. Backlogs com a estrutura Epic/Feature/PBI.
2. Descrição e critérios de aceite de **cada Feature e cada PBI**.
3. Boards com Test Cases por Feature.
4. Summary e Steps de **cada Test Case**.

Somar link do projeto com professor ADMIN no PDF único. Para apresentação (p. 35), registrar execuções manuais e relatórios analíticos reais.

Nome sugerido: `<requisito>_<work-item>_<descricao>_<data>.png`. Guardar versão/commit da aplicação. Revisar capturas para remover tokens/segredos antes de versionar; `raw/` é ignorado no Git para materiais ainda não revisados.

## Capturas versionadas em 19/11/2026

As cinco imagens abaixo são amostras reais do Azure DevOps. Elas comprovam a existência e a estrutura dos itens, mas **não substituem** a captura de cada Feature, PBI e Test Case, nem a execução manual no Test Plans, os relatórios analíticos, os bugs ou a confirmação do professor como ADMIN.

### 1. Hierarquia do backlog

![Backlog com Epics, Features e PBIs](Captura%20de%20tela%202026-11-19%20203218.png)

Visão de Backlogs com a árvore Epic → Feature → PBI. A tela mostra parte da hierarquia; os totais consolidados são 5 Epics, 12 Features e 39 PBIs.

### 2. Feature 7 — descrição e critérios de aceite

![Feature 7 — FEA-01 Cadastro de Usuário](Captura%20de%20tela%202026-11-19%20203244.png)

Feature 7 (FEA-01 Cadastro de Usuário) com descrição, critérios de aceite, Epic pai e PBIs filhos.

### 3. PBI 19 — descrição e critérios de aceite

![PBI 19 — PBI-001 Informar Nome Completo](Captura%20de%20tela%202026-11-19%20203258.png)

PBI 19 (PBI-001 Informar Nome Completo) com descrição, critérios de aceite e vínculo com a Feature 7.

### 4. Test Case 81 — TC-REPORT-02 e Steps

![Test Case 81 — TC-REPORT-02](Captura%20de%20tela%202026-11-19%20203432.png)

Test Case 81 (TC-REPORT-02) com Steps e vínculo com a Feature 18 (FEA-12 Relatórios Operacionais). O caso permanece bloqueado porque a funcionalidade de relatórios não está implementada; não há resultado de execução.

### 5. Lista de Work Items com Test Cases

![Lista de Work Items com Test Cases](Captura%20de%20tela%202026-11-19%20203459.png)

Lista parcial de Work Items com Test Cases da faixa 58–81, estados e tags. A tela não mostra todos os 24 casos simultaneamente.

Ainda faltam capturas das demais Features, PBIs e Test Cases, do Test Plan/Suites, das execuções manuais, dos bugs, dos relatórios analíticos e do professor como ADMIN. O PDF de Compliance registra essas pendências na seção de limitações; nenhum resultado de execução foi inventado.
