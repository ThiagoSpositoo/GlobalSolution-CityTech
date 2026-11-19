# Rastreabilidade e casos de teste — Etapa 3B

**17/11/2026 — planejamento.** Nenhum caso foi executado. Os IDs `TC-*` são locais; os IDs reais de Test Plans/Boards serão criados após autorização e não podem ser inventados. Este documento liga requisitos da [matriz](requisitos-global-solution.md) ao [backlog](backlog.md), aos critérios de aceite e às evidências futuras.

## 1. Como usar

- Cada Feature/PBI tem critérios de aceite no [backlog](backlog.md); cada caso abaixo verifica um comportamento observável.
- Casos **positivos** comprovam o caminho feliz; **negativos** comprovam validação, autorização e falhas.
- A execução manual final deve ocorrer no Azure Test Plans, com Summary, Steps e resultado real. Este catálogo é a base; não substitui as capturas exigidas por QA-04/05/07/08.
- Um requisito só pode ser marcado “verificado” após execução real com evidência. “Planejado” e “documentado” não são “implementado”.
- Testes automatizados (xUnit/Maven) não substituem os testes manuais de caixa-preta do Test Plans, e vice-versa.

## 2. Cobertura por disciplina

### 2.1 .NET

| Requisito | Feature/PBI | Casos planejados | Evidência principal |
|---|---|---|---|
| NET-01 | E1/E3; F1.1, F3.1 | TC-AUTH-01/04, TC-FOLLOW-01, TC-MOB-01 | API consumida pelo app; Swagger |
| NET-02 | E1/E3; F1.1, F3.1 | TC-AUTH-01, TC-FOLLOW-01 | Minimal API + EF Core; migração aplicada |
| NET-03 | E1/E3; F1.1–F1.3, F3.1 | TC-AUTH-02/03, TC-FOLLOW-01/02/06 | respostas HTTP válidas/inválidas; Swagger |
| NET-04 | E1; F1.3 | TC-OPS-02 | OpenAPI/Swagger interativo |
| NET-05 | E1/E3; F1.2, F3.1 | TC-AUTH-04/05/06/07/08, TC-FOLLOW-06 | 200/401/403; claims e papéis |
| NET-06 | E1/E3; F1.3, F3.1 | TC-FOLLOW-07/08 | repetição sem duplicar; conflito de chave |
| NET-07 | E1; F1.3 | TC-AUTH-09 | 429 + `Retry-After` |
| NET-08 | E1/E3; F1.1–F1.3, F3.1 | TC-AUTH-03, TC-FOLLOW-07, TC-OPS-01 | xUnit unitário/integração no CI |
| NET-09 | E1/E3; F1.3 | TC-OPS-01 | health live/ready; dependência Java |
| NET-10/11 | E8; F8.3 | TC-QA-03/TC-DEV-05 | GitHub/README/TXT; slides se houver |

### 2.2 QA

| Requisito | Feature/PBI | Casos planejados | Evidência principal |
|---|---|---|---|
| QA-01 | E8/F8.1.1 | TC-QA-01 | Boards Epic→Feature→PBI |
| QA-02 | E8/F8.1.1 | TC-QA-01/02 | descrição/aceite de cada Feature e PBI |
| QA-03 | E8/F8.1.2 | TC-QA-02 | Test Cases positivos/negativos por Feature |
| QA-04/05 | E8/F8.1.2 | TC-QA-02 | Summary e Steps |
| QA-06 | E8/F8.1.1/2 | TC-QA-01/02 | Azure DevOps usado, não Excel isolado |
| QA-07 | E8/F8.1.3 | TC-QA-03 | PDF com link e professor ADMIN |
| QA-08 | E8/F8.1.3 | TC-QA-03 | capturas de Test Cases/Summary/Steps |
| QA-09/10 | E8/F8.1.3 | TC-QA-03 | execução manual e relatório analítico |

### 2.3 DevOps

| Requisito | Feature/PBI | Casos planejados | Evidência principal |
|---|---|---|---|
| DEV-01/02 | E8/F8.2.3 | TC-DEV-02/03 | App Service + Azure SQL via CLI |
| DEV-03 | E8/F8.2.1 | TC-DEV-04 | professor Basic/Project Admin |
| DEV-04/05 | E8/F8.2.1 | TC-DEV-01 | Repos privado, tarefa e branch |
| DEV-06/07 | E8/F8.2.1/2 | TC-DEV-01/04 | main protegida, PR obrigatório |
| DEV-08 | E8/F8.2.2 | TC-DEV-01 | build/testes/artefato |
| DEV-09 | E8/F8.2.4 | TC-DEV-02 | CD automático do mesmo artefato |
| DEV-10/11 | E8/F8.2.3 | TC-DEV-02/03 | App Service/Azure SQL |
| DEV-12/13 | E8/F8.2.3 | TC-DEV-03 | scripts CLI e `script-bd.sql` |
| DEV-14/15/16 | E8/F8.2 | TC-DEV-01/03 | Dockerfiles/JSON condicionais; YAML na raiz |
| DEV-17 | E8/F8.2.3 | TC-DEV-03 | variáveis/secrets sem exposição |
| DEV-18 | E8/F8.3.1 | TC-QA-03 | diagrama com legenda |
| DEV-19 | — | — | permissão; não é obrigação de autoaprovação |
| DEV-20 | E8/F8.2.3 | TC-DEV-03 | CRUD + SELECT de duas tabelas no cloud |
| DEV-V01–V08 | E8/F8.2.4 | TC-DEV-05 | vídeo ≥720p, narrado, fluxo completo |

### 2.4 IA

| Requisito | Feature/PBI | Casos planejados | Evidência principal |
|---|---|---|---|
| IA-01 | E5/F5.2 | TC-AI-01/02 | classificação assistida no fluxo |
| IA-02 | E5/F5.1/5.2 | TC-AI-01/02/03 | LLM integrado, não chat isolado |
| IA-03 | E5/F5.2 | TC-AI-02/05 | RAG com recuperação e fontes |
| IA-04 | E5/F5.1/5.2 | TC-AI-02 | corpus, fluxo e modelo documentados |
| IA-05 | E5/F5.3.2 | TC-AI-05 | casos representativos/falhas e métricas |
| IA-06 | E5/F5.3.2 | TC-AI-04/05 | credenciais protegidas e limitações |
| IA-07 | E8/F8.3.1 | TC-QA-03 | README/README de IA no repo |
| IA-08 | E5/F5.3.2 | TC-AI-05 | casos/resultados em `ai/evaluation/` |
| IA-09 | E8/F8.3.3 | TC-QA-03 | TXT específico da IA |

### 2.5 Java

| Requisito | Feature/PBI | Casos planejados | Evidência principal |
|---|---|---|---|
| JAV-01 | E2/E5; F2.1–F2.3, F5.1 | build + TC-OCC-01, TC-AI-01 | Spring Boot/JPA/Security/AI |
| JAV-02 | E2; F2.1–F2.3 | TC-OCC-01..10 | 3 entidades, CRUD, paginação |
| JAV-03 | E2; F2.2.4 | TC-OCC-02/10 | Bean Validation + erros globais |
| JAV-04 | E1/E4; F1.2, F4.1 | TC-AUTH-06/07/08, TC-MGR-01/02/04 | JWT, papéis, 401/403 |
| JAV-05 | E5; F5.2/5.3 | TC-AI-02/03/04 | Spring AI no fluxo |
| JAV-06 | E5; F5.1 | TC-AI-01/02 | evento publicado e consumido |
| JAV-07 | E2/E4/E6; F2.2, F4.1, F6.2 | TC-OCC-01, TC-MGR-01, TC-MOB-02 | Swagger + app |
| JAV-08 | E8; F8.3 | TC-QA-03/TC-DEV-05 | GitHub público/README |
| JAV-09/10/11 | E8; F8.3 | TC-DEV-05 | ZIP/pitch ≤5 min |

### 2.6 Banco

| Requisito | Feature/PBI | Casos planejados | Evidência principal |
|---|---|---|---|
| DB-01 | E7/F7.1.1 | TC-DATA-01/02 | ≥3 tabelas + 2 blocos |
| DB-02 | E7/F7.1.2 | TC-DATA-02 | 2 funções + 2 procedimentos |
| DB-03 | E7/F7.1.3 | TC-DATA-03 | 2 triggers, auditoria |
| DB-04 | E7/F7.1.3 | TC-DATA-04 | 2 pacotes + testes |
| DB-05 | E7/F7.2.1 | TC-DATA-05 | 2 collections, ≥10 docs |
| DB-06 | E7/F7.2.2 | TC-DATA-06 | 3 consultas, 1 aggregate, comparação |
| DB-07 | E7/F7.2.2 | TC-DATA-06 | mapa relacional→documental |
| DB-08/09 | E7/F7.1/7.2 | TC-DATA-01/05 | scripts SQL/JS reproduzíveis |
| DB-10 | E7/F7.2.2 | TC-DATA-06 | README/PDF/evidências |
| DB-11 | E8/F8.3.3 | TC-QA-03 | formato confirmado |

### 2.7 Mobile

| Requisito | Feature/PBI | Casos planejados | Evidência principal |
|---|---|---|---|
| MOB-01 | E6; F6.1–F6.4 | TC-MOB-01/05 | React Native/Expo |
| MOB-02 | E6; F6.1/F6.4 | TC-MOB-05 | ≥6 telas úteis + Sobre |
| MOB-03 | E6; F6.2/F6.3 | TC-MOB-02/03 | CRUD real nas duas APIs |
| MOB-04 | E6/E8; F6.4 | TC-MOB-06 | backend ativo no APK |
| MOB-05 | E6; F6.1 | TC-MOB-01 | cadastro/login/logout/rotas |
| MOB-06 | E6; F6.4.1 | TC-MOB-05 | identidade visual/guidelines |
| MOB-07 | E6; F6.1–F6.4 | TC-MOB-05 | organização/lint |
| MOB-08 | E6; F6.4.2 | TC-MOB-06 | vídeo ≤5 min |
| MOB-09 | E6; F6.4.2 | TC-MOB-06 | link no README/TXT |
| MOB-10/11 | E6; F6.4.2 | TC-MOB-07 | Firebase + Sobre hash |
| MOB-12 | E8/F8.3 | TC-QA-03 | GitHub/histórico |
| MOB-13 | E8/F8.3.3 | TC-QA-03 | TXT de entrega |
| MOB-14 | E6; F6.4.2 | TC-MOB-06 | narração opcional |

### 2.8 Requisitos gerais e entrega

| Requisito | Cobertura | Evidência |
|---|---|---|
| GER-01/02 | README, pitch, demonstração | problema/benefício/tecnologias |
| GER-03 | ODS 11 na arquitetura/pitch | metas e limitações |
| GER-04 | monorepo e contratos comuns | sete disciplinas na mesma solução |
| GER-05/06 | cadastro do grupo | confirmar situação no Portal |
| GER-07/08/11 | checklist de entrega | sete entradas, TXT e comprovantes |
| GER-09/10 | ensaio e declaração de IA | roteiro e README |
| GER-12/13/14/15 | contexto/pesquisa | não são funcionalidades |

## 3. Catálogo de casos de teste planejados

### 3.1 Autenticação e operação (.NET)

| ID | Feature | Tipo | Objetivo | Preparação e passos essenciais | Resultado esperado |
|---|---|---|---|---|---|
| TC-AUTH-01 | F1.1 | + | Cadastro válido | Banco ativo; `POST /auth/register` com nome/e-mail/senha válidos e `Idempotency-Key`; consultar banco | `201`, conta criada, papel `CIDADAO`, sem senha/hash na resposta; linha persistida |
| TC-AUTH-02 | F1.1 | − | E-mail duplicado | Cadastrar o mesmo e-mail duas vezes | Segundo `409 EMAIL_ALREADY_EXISTS`; uma conta |
| TC-AUTH-03 | F1.1 | − | Cadastro inválido | Enviar nome curto, e-mail inválido e senha fraca | `400 VALIDATION_ERROR` com `errors[]`; nada persistido |
| TC-AUTH-04 | F1.2 | + | Login e token | Conta ativa; `POST /auth/login` correto; chamar `/auth/me` | `200`, token Bearer, claims/`roles` corretos; `/me` retorna usuário |
| TC-AUTH-05 | F1.2 | − | Credencial inválida | Senha errada e e-mail inexistente | `401` genérico; sem token; mesma mensagem nos dois casos |
| TC-AUTH-06 | F1.2 | − | Sem token | Chamar `/auth/me` e rota protegida sem header | `401 UNAUTHORIZED`; sem dados |
| TC-AUTH-07 | F1.2 | − | Papel insuficiente | Token `CIDADAO` em rota de gestor | `403 FORBIDDEN`; sem efeito |
| TC-AUTH-08 | F1.2 | − | Token inválido/expirado | Assinatura alterada, `aud` errada e token expirado | `401`; Java e .NET rejeitam |
| TC-AUTH-09 | F1.3 | − | Rate limit | Repetir login acima do limite configurado | `429 RATE_LIMITED` com `Retry-After`; credencial correta não passa durante bloqueio |
| TC-OPS-01 | F1.3 | +/− | Health | `/health/live`; `/health/ready` com DB/Java up; derrubar dependência de teste | live `200`; ready `200` saudável e `503` com dependência crítica fora; sem chamar LLM |
| TC-OPS-02 | F1.3 | + | Swagger/OpenAPI | Abrir `/swagger` e `/swagger/v1/swagger.json`; comparar endpoints | UI interativa e schema com DTOs/erros reais |

### 3.2 Ocorrências (Java)

| ID | Feature | Tipo | Objetivo | Preparação e passos essenciais | Resultado esperado |
|---|---|---|---|---|---|
| TC-OCC-01 | F2.2 | + | Criar ocorrência | Cidadão autenticado; categoria ativa; payload válido | `201` + `Location`; `status=ABERTA`; histórico `CRIACAO`; evento outbox |
| TC-OCC-02 | F2.2 | − | Campos inválidos | Título curto, descrição vazia, UF inválida, categoria inexistente | `400`/`409` com erros; nada criado |
| TC-OCC-03 | F2.2 | + | Listar/paginar | Criar 25 ocorrências do mesmo cidadão; `page=0&size=10` | `200`, 10 itens, totais corretos, ordem `createdAt,desc` |
| TC-OCC-04 | F2.2 | − | Propriedade | Cidadão B tenta `GET /occurrences/{id}` de A | `404 NOT_FOUND`; sem dados |
| TC-OCC-05 | F2.2 | + | Editar em ABERTA | Dono altera título/descrição/endereço | `200`; `version` incrementa; histórico `EDICAO` |
| TC-OCC-06 | F2.2 | − | Editar após triagem | Gestor move para `EM_TRIAGEM`; dono tenta editar | `409 INVALID_TRANSITION`; dados originais |
| TC-OCC-07 | F2.2 | + | Cancelar logicamente | Dono em `ABERTA` chama `DELETE` com motivo | `204`; status `CANCELADA`; linha/histórico preservados |
| TC-OCC-08 | F2.3 | + | Histórico | Criar, editar e transicionar; consultar histórico | Itens com ator/papel/ação/estados/nota em ordem; sem update/delete |
| TC-OCC-09 | F2.1 | − | Categoria inativa | Desativar categoria; tentar criar ocorrência | `400 INVALID_CATEGORY`/`409`; nada criado |
| TC-OCC-10 | F2.2 | − | Paginação inválida | `page=-1`, `size=0`, `size=101`, `sort` desconhecido | `400 VALIDATION_ERROR`; sem consulta inválida |

### 3.3 Acompanhamentos (.NET)

| ID | Feature | Tipo | Objetivo | Preparação e passos essenciais | Resultado esperado |
|---|---|---|---|---|---|
| TC-FOLLOW-01 | F3.1 | + | Criar acompanhamento | Cidadão com ocorrência visível; `POST /followups` + chave | `201`; .NET chamou Java; registro único |
| TC-FOLLOW-02 | F3.1 | − | Duplicidade | Repetir mesmo `occurrenceId` com chave nova | `409 FOLLOWUP_ALREADY_EXISTS`; um registro |
| TC-FOLLOW-03 | F3.1 | − | Ocorrência invisível | ID inexistente ou de outro cidadão | `404 OCCURRENCE_NOT_FOUND`; nada gravado |
| TC-FOLLOW-04 | F3.1 | − | Java indisponível | Derrubar Java; tentar criar acompanhamento | `503 OCCURRENCE_SERVICE_UNAVAILABLE`; nada gravado; health acusa |
| TC-FOLLOW-05 | F3.1 | + | Editar/remover | Dono altera nota e remove | `200`/`204`; versão atualiza; outro usuário não afeta |
| TC-FOLLOW-06 | F3.1 | − | Propriedade | Cidadão B acessa/edita follow-up de A | `404`; sem dados/alteração |
| TC-FOLLOW-07 | F1.3/F3.1 | + | Idempotência | Repetir `POST` com mesma chave e mesmo corpo | Mesma resposta `201`, header de replay, um registro |
| TC-FOLLOW-08 | F1.3 | − | Conflito de chave | Mesma chave com `occurrenceId`/nota diferente | `409 IDEMPOTENCY_CONFLICT`; sem novo efeito |

### 3.4 Gestão e indicadores (Java)

| ID | Feature | Tipo | Objetivo | Preparação e passos essenciais | Resultado esperado |
|---|---|---|---|---|---|
| TC-MGR-01 | F4.1 | + | Transição válida | Gestor move `ABERTA→EM_TRIAGEM→EM_ANDAMENTO` | `200`; status/histórico corretos |
| TC-MGR-02 | F4.1 | − | Transição inválida | Tentar `ABERTA→RESOLVIDA` e `ENCERRADA→...` | `409 INVALID_TRANSITION`; sem alteração |
| TC-MGR-03 | F4.1 | + | Filtros do gestor | Criar ocorrências de vários status/categorias; filtrar | Lista completa, filtros/paginação corretos |
| TC-MGR-04 | F4.2 | +/− | Indicadores | Dataset conhecido; gestor consulta; cidadão tenta | Gestor `200` com contagens; cidadão `403`; zero não quebra |

### 3.5 IA e evento

| ID | Feature | Tipo | Objetivo | Preparação e passos essenciais | Resultado esperado |
|---|---|---|---|---|---|
| TC-AI-01 | F5.1 | + | Publicação | Criar ocorrência; inspecionar exchange/fila e outbox | Evento `OccurrenceCreated.v1` publicado; outbox marcado; sem perda |
| TC-AI-02 | F5.1/F5.2 | + | Consumo e sugestão | Consumidor ativo; criar ocorrência; aguardar | `AiSuggestion` `PRONTA`, categoria válida, fontes/modelo/prompt; uma por evento |
| TC-AI-03 | F5.3 | + | Aceitar sugestão | Dono/gestor aceita sugestão pronta | `200`; categoria/prioridade aplicadas; histórico `REVISAO_IA` |
| TC-AI-04 | F5.3 | + | Rejeitar sugestão | Rejeitar sugestão pronta | `200`; dados não mudam; decisão registrada; nova revisão `409` |
| TC-AI-05 | F5.3 | − | Falha/abuso | Derrubar LLM; entrada com instrução maliciosa; corpus ambíguo | `FALHOU`/DLQ; ocorrência triável manualmente; saída validada; nenhuma instrução executada; métricas registradas |

### 3.6 Mobile

| ID | Feature | Tipo | Objetivo | Preparação e passos essenciais | Resultado esperado |
|---|---|---|---|---|---|
| TC-MOB-01 | F6.1 | +/− | Cadastro/login/logout | Abrir app; cadastrar; entrar; fechar/reabrir; sair; tentar rota protegida | Sessão segura; logout limpa token; rota bloqueada; erros exibidos |
| TC-MOB-02 | F6.2 | + | CRUD ocorrência | Criar, listar, detalhar, editar e cancelar | Chamadas Java reais; UI reflete `201/200/204`; validação por campo |
| TC-MOB-03 | F6.3 | + | Acompanhamento | Acompanhar no detalhe; listar; editar nota; remover | .NET persiste; duplicidade tratada; detalhe atual vem do Java |
| TC-MOB-04 | F6.3 | + | Gestão | Login gestor; filtrar, triar, mudar status e ver indicadores | Ações permitidas; cidadão não vê a área |
| TC-MOB-05 | F6.1/F6.4 | + | Navegação/estilo | Percorrer 6+ telas úteis + Sobre; verificar contraste/estados | Navegação fluida, sem placeholder; identidade visual; acessibilidade básica |
| TC-MOB-06 | F6.4 | + | Backend ativo/vídeo | Instalar APK em dispositivo; executar fluxo com URLs de avaliação; assistir vídeo | Backends respondem; vídeo ≤5 min mostra funcionalidades reais |
| TC-MOB-07 | F6.4 | + | Firebase/hash | Publicar APK; convidar tester; abrir Sobre; comparar commit | Instalação pelo Firebase; hash exibido = commit do fonte |

### 3.7 Dados

| ID | Feature | Tipo | Objetivo | Preparação e passos essenciais | Resultado esperado |
|---|---|---|---|---|---|
| TC-DATA-01 | F7.1 | + | Schema/seed Oracle | Executar scripts em schema autorizado; consultar tabelas | Tabelas relacionadas, FKs e dados fictícios; sem erro |
| TC-DATA-02 | F7.1 | + | Blocos/funções/procedimentos | Executar entradas válidas/inválidas; conferir saídas | 2 blocos, 2 funções, 2 procedimentos com regras reais; resultados registrados |
| TC-DATA-03 | F7.1 | + | Triggers/auditoria | Executar INSERT/UPDATE/DELETE; consultar auditoria | 2 triggers; auditoria com data/operação/antigo/novo; segundo trigger justificado |
| TC-DATA-04 | F7.1 | + | Pacotes/testes | Executar specification/body e script de testes | 2 pacotes; testes com saídas; sem lógica divergente do Java |
| TC-DATA-05 | F7.2 | + | Mongo collections | Executar `.js` no mongosh; contar documentos | 2 collections, ≥10 docs, IDs/snapshot; sem apagar existentes |
| TC-DATA-06 | F7.2 | + | Consultas/comparação | Executar 3 consultas (1 aggregate); comparar Oracle | Resultados demonstráveis, mapa e justificativa; mesma amostra |

### 3.8 DevOps, QA e entrega

| ID | Feature | Tipo | Objetivo | Preparação e passos essenciais | Resultado esperado |
|---|---|---|---|---|---|
| TC-DEV-01 | F8.2 | + | CI | Criar branch/PR; merge na main; acompanhar pipeline | Build/testes/artefato publicados; falha bloqueia; trigger correto |
| TC-DEV-02 | F8.2 | + | CD | Novo artefato aprovado; acompanhar release | Deploy automático do mesmo artefato; app responde |
| TC-DEV-03 | F8.2/F8.2.3 | + | Cloud/CRUD | Executar scripts Azure; CRUD nas duas tabelas; SELECT no banco cloud | Recursos criados por CLI; persistência comprovada por SELECT; sem localhost |
| TC-DEV-04 | F8.2.1 | + | Governança | Conferir main, PR, work item, acessos do professor | Políticas ativas; professor Basic/Project Admin; branch por tarefa |
| TC-DEV-05 | F8.2.4 | + | Vídeo DevOps | Gravar fluxo contínuo; assistir ao vídeo publicado | ≥720p, voz clara, todos os itens obrigatórios; links funcionando |
| TC-QA-01 | F8.1.1 | + | Boards | Abrir Backlogs; conferir hierarquia e descrições/aceite | Epic→Feature→PBI; cada item com descrição/aceite; vínculos reais |
| TC-QA-02 | F8.1.2 | + | Test Cases | Abrir Test Plans; conferir casos por Feature | Positivos/negativos, Summary e Steps completos |
| TC-QA-03 | F8.1.3 | + | Execução/PDF | Executar casos; capturar; gerar PDF/TXT; validar acesso | Resultados reais, evidências sem segredos, PDF único, professor ADMIN |

## 4. Regras de execução e evidência

1. Criar dados de teste fictícios e isolados; não usar produção nem dados pessoais reais.
2. Registrar ambiente, versão/commit, usuário/papel e pré-condições em cada execução.
3. Para cada caso: resultado real, aprovado/reprovado/bloqueado, evidência e bug vinculado quando houver.
4. Testar primeiro os caminhos P0; depois negativos e integrações; não marcar “aprovado” sem saída real.
5. Capturas de tela devem ocultar tokens, senhas e dados pessoais; revisar antes de versionar.
6. Repetir casos afetados após correção; registrar regressão.
7. A contagem final de casos depende das Features implementadas; este catálogo é a linha de base, não um número inventado de aprovação.
8. Test Plans/Boards só serão preenchidos após autorização e acesso; IDs locais não substituem Work Items.
