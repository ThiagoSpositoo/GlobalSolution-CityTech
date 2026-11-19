# Backlog inicial — CityTech

**Etapa 3B — planejamento, 17/11/2026.** Este backlog é local e ainda **não foi importado para o Azure Boards**. IDs `E`, `F` e `PBI` são identificadores de planejamento; não são Work Items e não comprovam a entrega de QA. A importação e os vínculos com commits/PRs dependem de autorização e acesso ao Azure DevOps.

Fonte de requisitos: [matriz acadêmica](requisitos-global-solution.md). Decisões de arquitetura: [arquitetura](arquitetura.md). Contratos: [contratos de API](contratos-api.md). Modelo: [modelo de domínio](modelo-dominio.md). Testes: [rastreabilidade](rastreabilidade.md).

## 1. Como ler e priorizar

- **P0 — bloqueador do fluxo mínimo:** sem o item, a demonstração principal ou uma disciplina fica inviável.
- **P1 — obrigatório pontuado:** exigido pelo PDF ou necessário para a integração completa; pode entrar depois do P0.
- **P2 — melhoria:** útil, mas não deve consumir o tempo do P0/P1. Fotos completas, mapas, push e refresh token estão aqui.

**Pronto para iniciar (Definition of Ready):** requisito e critério de aceite compreendidos; contrato/modelo acordado; dependência disponível ou simulada de forma declarada; dados de teste definidos; papel/autorização claro.

**Concluído (Definition of Done):** critérios de aceite verificados; testes automatizados e/ou manuais pertinentes aprovados; Swagger/OpenAPI atualizado quando houver endpoint; erros e autorização tratados; nenhum segredo no código/log; documentação e evidência atualizadas; sem regressão conhecida. “Documentado” não é o mesmo que “implementado” ou “verificado”.

## 2. Personas e fluxos principais

| Persona | Necessidade | Fluxo mínimo |
|---|---|---|
| Cidadão | Registrar e acompanhar problemas urbanos | cadastrar → entrar → criar ocorrência → consultar detalhe/IA → acompanhar → cancelar ou confirmar encerramento |
| Gestor | Triar, priorizar e acompanhar a zeladoria | entrar → ver fila → triar categoria/prioridade → mudar status → consultar indicadores |
| Equipe | Demonstrar e defender a solução | executar o fluxo real, mostrar APIs, testes, dados, pipelines e limitações |

## 3. Visão dos épicos

| Épico | Nome | Prioridade | Disciplinas principais | Requisitos |
|---|---|---|---|---|
| E1 | Identidade e acesso | P0 | .NET, Mobile | NET-01/03/05/06/07/08/09, MOB-05 |
| E2 | Ocorrências urbanas | P0 | Java, Mobile, Banco | JAV-02/03/07, MOB-03 |
| E3 | Acompanhamento cidadão | P0 | .NET, Mobile | NET-01/03/05, MOB-03 |
| E4 | Gestão e indicadores | P1 | Java, Mobile | JAV-04/07, MOB-03 |
| E5 | IA assistiva e evento assíncrono | P1 | Java, IA | JAV-05/06, IA-01 a IA-06 |
| E6 | Aplicativo Mobile integrado | P0 | Mobile | MOB-01 a MOB-13 |
| E7 | Dados, PL/SQL e MongoDB | P1 | Banco | DB-01 a DB-10 |
| E8 | Qualidade, DevOps e entrega | P0 | QA, DevOps, todas | QA-01 a QA-10, DEV-01 a DEV-20, GER-07/08/11 |

## 4. Épicos, Features e PBIs

### E1 — Identidade e acesso (.NET)

**Objetivo:** permitir cadastro e login reais, emitir JWT confiável e proteger os dois backends sem duplicar credenciais.

#### F1.1 — Cadastro de cidadão

**Descrição:** cadastro público cria exclusivamente contas `CIDADAO`, com e-mail único e senha protegida. Gestores não são criados por esse fluxo.

**Critérios de aceite da Feature:**
- Cadastro válido retorna `201`, identifica a conta e nunca devolve senha ou hash.
- E-mail duplicado retorna `409`; entrada inválida retorna `400` com erros por campo.
- O corpo não aceita `role`; tentativa de promoção é rejeitada ou ignorada de forma explícita e testada.
- Conta e e-mail normalizado persistem no SQL Server.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-1.1.1 | Modelo `Account` e migração | P0 | Conta com `id` UUID, nome, e-mail normalizado único, hash de senha, papel, ativo, timestamps. Migração EF Core aplica em banco vazio; não existe senha em texto; índice único em e-mail. |
| PBI-1.1.2 | Endpoint de cadastro | P0 | `POST /api/v1/auth/register` valida nome/e-mail/senha, cria somente `CIDADAO` e retorna `201` com a conta criada. E-mail repetido → `409`; payload inválido → `400`; Swagger documenta exemplos. |
| PBI-1.1.3 | Testes de cadastro | P0 | xUnit cobre normalização, senha fraca, e-mail duplicado e corpo com papel indevido; teste de integração confirma persistência e ausência de hash na resposta. |

#### F1.2 — Login, JWT e sessão

**Descrição:** autenticar credenciais e emitir token assimétrico consumível pelo Mobile, Java e .NET.

**Critérios de aceite da Feature:**
- Login válido retorna token `Bearer` e dados públicos do usuário; credencial inválida retorna `401` genérico.
- Token usa RS256, emissor/audiência acordados, `sub` UUID, `roles`, `exp` e `jti`; expiração padrão de 60 minutos.
- Java e .NET rejeitam token ausente, expirado, com assinatura inválida ou algoritmo não permitido.
- Chave privada não está no repositório, logs ou resposta.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-1.2.1 | Hash de senha e seed de gestor | P0 | Senha verificada com hasher maintained do ASP.NET Core; seed cria/atualiza um gestor de demonstração a partir de configuração local, de forma idempotente. Nenhuma senha real é versionada. |
| PBI-1.2.2 | Login, `/auth/me` e emissão JWT | P0 | `POST /auth/login` retorna token e usuário; `GET /auth/me` retorna o usuário autenticado; token inválido/expirado → `401`. Claims conferidas em teste. |
| PBI-1.2.3 | Configuração de chaves e testes JWT | P0 | Chaves carregadas por caminho/configuração fora do Git; `kid` no header; testes cobrem assinatura, `iss`, `aud`, expiração e papel. Java valida a mesma chave pública. |

#### F1.3 — Proteções operacionais do .NET

**Descrição:** atender idempotência, rate limiting, health checks e Swagger de forma demonstrável.

**Critérios de aceite da Feature:**
- Requisição repetida com a mesma chave idempotente não duplica efeito.
- Limite de requisições retorna `429` com `Retry-After` e é testável.
- Health diferencia processo vivo de dependências prontas; Swagger lista os endpoints reais.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-1.3.1 | Idempotência persistida | P0 | `POST /auth/register` e `POST /followups` exigem `Idempotency-Key`. Mesma chave + mesmo corpo devolve a resposta original; mesma chave + corpo diferente → `409 IDEMPOTENCY_CONFLICT`; concorrência gera um único efeito. |
| PBI-1.3.2 | Rate limiting | P0 | Política por rota/usuário/IP; excesso → `429` com `Retry-After`; limites configuráveis e teste determinístico. |
| PBI-1.3.3 | Health checks, Swagger e logs | P0 | `/health/live` responde sem dependências; `/health/ready` verifica SQL Server e Java e retorna `503` quando dependência crítica falha; Swagger interativo disponível; logs não expõem token/senha. |

### E2 — Ocorrências urbanas (Java)

**Objetivo:** ser a fonte única de categorias, ocorrências e histórico, com CRUD paginado, validação e autorização por papel/proprietário.

#### F2.1 — Catálogo de categorias

**Descrição:** categorias estáveis para classificação e filtros; cidadão consulta ativas, gestor administra.

**Critérios de aceite da Feature:**
- Seis categorias iniciais existem por seed e têm código único.
- Cidadão autenticado lista categorias ativas; gestor cria, edita e desativa.
- Categoria em uso não é apagada fisicamente; `DELETE` desativa e preserva ocorrências.
- Categoria inativa não pode ser usada em nova ocorrência.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-2.1.1 | Entidade, repositório e seed | P0 | `Category` com `id`, `code`, `name`, `description`, `active`, timestamps; seed idempotente com `VIAS`, `ILUMINACAO`, `ACESSIBILIDADE`, `DESCARTE`, `AGUA`, `OUTROS`. |
| PBI-2.1.2 | Endpoints de categoria | P0 | `GET` autenticado; `POST`/`PUT`/`DELETE` somente `GESTOR`; `DELETE` apenas desativa e é idempotente; Swagger e validação. |
| PBI-2.1.3 | Testes de categoria | P1 | Testes de código duplicado, criação por cidadão (`403`), desativação e uso de categoria inativa (`400`/`409`). |

#### F2.2 — Registro e consulta de ocorrências

**Descrição:** cidadão registra problema com endereço e categoria; consulta somente o que pode ver; gestor consulta a fila completa. O endereço é textual; mapa/GPS fica fora do MVP.

**Critérios de aceite da Feature:**
- Criação válida retorna `201` com UUID e `Location`; campos inválidos retornam `400` com erros por campo.
- Cidadão vê/edita apenas ocorrências próprias; outro cidadão recebe `404` (não revelando existência).
- Edição de campos do cidadão só é permitida em `ABERTA`; depois disso, `409`.
- Listagem pagina, filtra e ordena; gestor vê todas e cidadão vê as próprias.
- `DELETE` é cancelamento lógico e registra histórico; não apaga a trilha.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-2.2.1 | Modelo `Occurrence` e migração Oracle | P0 | Ocorrência relaciona `citizen_id`, `category_id`, título, descrição, prioridade, status, endereço, timestamps e versão. FKs internas Oracle; sem FK para SQL Server. |
| PBI-2.2.2 | Criar, listar e detalhar | P0 | `POST`, `GET` de lista e `GET /{id}`; `201`/`200`; paginação `page/size`; filtros `status`, `categoryId`, `priority`, `q`; cidadão restrito ao próprio `sub`; gestor vê todas. |
| PBI-2.2.3 | Editar e cancelar | P0 | `PUT` do proprietário em `ABERTA`; `DELETE` lógico conforme estado; `409` para estado inválido; histórico registra alteração/cancelamento. |
| PBI-2.2.4 | Validação e erros globais | P0 | Bean Validation nos DTOs; `@RestControllerAdvice` produz envelope comum; `400`, `401`, `403`, `404`, `409` e `traceId`; sem stack trace na resposta. |
| PBI-2.2.5 | Testes de ocorrência | P0 | Testes de criação, campos inválidos, paginação, propriedade, edição após triagem, cancelamento e filtros; integração com Oracle real/equivalente. |

#### F2.3 — Histórico e auditoria de ocorrência

**Descrição:** trilha append-only de criação, edição, triagem, transições e decisão de IA.

**Critérios de aceite da Feature:**
- Toda mudança relevante gera registro com ator, papel, ação, estado anterior/novo, nota e timestamp.
- Histórico é somente leitura; não há endpoint de edição/exclusão.
- Cidadão vê histórico da própria ocorrência; gestor vê de qualquer uma; terceiro recebe `404`.
- Registros aparecem em ordem cronológica decrescente e paginados.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-2.3.1 | Entidade e gravação automática | P0 | `StatusHistory` relaciona ocorrência; criação, edição, triagem, transição e aceite de IA gravam registro na mesma transação da mudança. |
| PBI-2.3.2 | Consulta paginada do histórico | P0 | `GET /occurrences/{id}/history` com `page/size`, `200`, ordenação decrescente; `404` para ocorrência invisível; sem update/delete. |

### E3 — Acompanhamento cidadão (.NET)

**Objetivo:** dar ao .NET uma funcionalidade real de valor: o cidadão salva ocorrências para acompanhar, com anotação e preferências locais, sem duplicar a ocorrência do Java.

#### F3.1 — CRUD de acompanhamentos

**Descrição:** `FollowUp` guarda `userId`, `occurrenceId`, nota e timestamps. O status real continua no Java e não é copiado.

**Critérios de aceite da Feature:**
- Criar acompanhamento válido retorna `201`; duplicidade do mesmo usuário/ocorrência retorna `409`.
- O .NET valida a ocorrência no Java com o token do usuário antes de gravar; Java indisponível retorna `503` e **não** grava.
- Cidadão lista, edita nota e remove somente os próprios acompanhamentos; outro usuário recebe `404`.
- A listagem devolve IDs/notas, sem copiar status; o Mobile consulta o detalhe atual no Java.
- Requisição repetida com a mesma `Idempotency-Key` não duplica.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-3.1.1 | Modelo `FollowUp` e migração | P0 | Tabela com `id`, `user_id`, `occurrence_id`, `note`, timestamps; FK interna para `Account`; índice único (`user_id`, `occurrence_id`). É a segunda tabela de negócio do .NET. |
| PBI-3.1.2 | Endpoints e validação no Java | P0 | `GET`/`POST`/`PATCH`/`DELETE`; criação idempotente; `POST` chama `GET /occurrences/{id}` no Java com Bearer do usuário; `404`/`503` não gravam; `PATCH` só altera nota. |
| PBI-3.1.3 | Testes e modo degradado | P1 | Testes de propriedade, duplicidade, timeout do Java, resposta `503` sem persistência e repetição idempotente; health reflete a dependência. |

### E4 — Gestão e indicadores (Java)

**Objetivo:** permitir triagem, mudança de estado e leitura de indicadores por gestores.

#### F4.1 — Triagem e ciclo de status

**Descrição:** gestor classifica categoria/prioridade, registra nota e conduz a ocorrência pelas transições permitidas. Cidadão só confirma encerramento ou reabre quando o estado permite.

**Critérios de aceite da Feature:**
- Transições obedecem à tabela do [modelo de domínio](modelo-dominio.md#5-estados-e-transições).
- Transição inválida retorna `409 INVALID_TRANSITION`; papel inadequado retorna `403`.
- Toda transição/triagem gera histórico com ator e nota.
- Cidadão não altera categoria/prioridade após a triagem; gestor pode ajustar com registro.
- Estados terminais não aceitam novas transições.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-4.1.1 | Serviço de máquina de estados | P0 | Regras centralizadas no domínio Java; tabela de transições; `version` otimista; conflito concorrente → `409`. |
| PBI-4.1.2 | Endpoints de triagem e status | P0 | `PATCH /occurrences/{id}/triage` (categoria/prioridade/nota) e `PATCH /occurrences/{id}/status`; `200`, `409`, `403`, `404`; histórico na mesma transação. |
| PBI-4.1.3 | Fila e filtros do gestor | P1 | `GET /occurrences` para gestor com filtros de status/categoria/prioridade, busca e paginação; cidadão não recebe a fila completa. |
| PBI-4.1.4 | Testes da matriz de transições | P0 | Casos positivos e negativos para cada aresta; pelo menos um teste de concorrência/versão e um de autorização por papel. |

#### F4.2 — Indicadores

**Descrição:** painel agregado para demonstrar gestão por dados, sem afirmar impacto real.

**Critérios de aceite da Feature:**
- `GET /manager/indicators` é exclusivo de `GESTOR` e retorna totais por status/categoria, tempo médio de triagem e estatísticas de IA.
- Números conferem com uma amostra semeada e não quebram com zero ocorrências.
- Consulta não expõe dados pessoais além do necessário.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-4.2.1 | Consultas e endpoint de indicadores | P1 | Agregações em SQL/JPA; resposta documentada; `200`; cidadão → `403`; `generatedAt` UTC. |
| PBI-4.2.2 | Testes de indicadores | P1 | Dataset fixo com contagens conhecidas; teste de zero ocorrências; teste de autorização. |

### E5 — IA assistiva e evento assíncrono (Java)

**Objetivo:** atender Spring AI, RAG e a alternativa distribuída A com um fluxo real: ocorrência criada → evento → sugestão revisável.

#### F5.1 — Evento assíncrono com RabbitMQ

**Descrição:** publicar `OccurrenceCreated.v1` após a criação e consumir em worker para gerar sugestão, com idempotência, retry e DLQ.

**Critérios de aceite da Feature:**
- Criação de ocorrência grava outbox e publica evento; evento contém `eventId`, `occurrenceId`, `occurredAt`, `schemaVersion`.
- Consumidor processa cada `eventId` uma vez; repetição não duplica sugestão.
- Falha transitória tem retry limitado; falha permanente vai para DLQ e a ocorrência continua disponível para triagem manual.
- A demonstração prova publicação **e** consumo, não apenas a existência do container.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-5.1.1 | Outbox e publicador | P1 | Tabela de outbox na mesma transação da ocorrência; publicador envia ao exchange; evento persistido antes do envio; falha de broker não perde a ocorrência. |
| PBI-5.1.2 | Consumidor idempotente e DLQ | P1 | Fila dedicada, `eventId` único, retry com limite, DLX/DLQ; status da sugestão `PENDENTE`/`FALHOU`; logs sem descrição sensível. |
| PBI-5.1.3 | Teste real do broker | P1 | Teste de integração publica e consome via RabbitMQ; verifica `eventId`, uma sugestão por evento e DLQ em falha simulada. |

#### F5.2 — Sugestão com RAG

**Descrição:** recuperar trechos do corpus e gerar sugestão estruturada de categoria, prioridade, resumo, justificativa e fontes.

**Critérios de aceite da Feature:**
- Corpus versionado tem taxonomia, critérios de prioridade e fontes; recuperação top-k é demonstrável.
- Saída é JSON validado contra enums/limites; categoria fora da lista é rejeitada.
- Sugestão é persistida com modelo, versão do prompt, fontes e status; não altera a ocorrência automaticamente.
- Timeout/erro/baixa adequação resultam em `FALHOU`, sem bloquear a ocorrência.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-5.2.1 | Corpus e taxonomia | P1 | Documentos pequenos e versionados em `ai/corpus/`; seis categorias; critérios de prioridade; identificação de fonte/versão. |
| PBI-5.2.2 | Recuperação e saída estruturada | P1 | Spring AI recupera top-k; prompt inclui trechos/IDs; resposta validada; nenhuma instrução do texto é executada; timeout configurado. |
| PBI-5.2.3 | Persistência da sugestão | P1 | `AiSuggestion` guarda ocorrência, categoria/prioridade sugeridas, resumo, justificativa, fontes, modelo, prompt e status; consulta no detalhe. |

#### F5.3 — Revisão humana e avaliação

**Descrição:** cidadão/gestor decide aceitar ou rejeitar; a decisão humana fica registrada e a classificação manual continua possível.

**Critérios de aceite da Feature:**
- Aceitar aplica categoria/prioridade sugeridas e registra histórico; rejeitar mantém os dados e registra decisão.
- Sugestão já revisada não pode ser revisada novamente sem regra explícita (`409`).
- Falha da IA não impede triagem manual.
- Avaliação cobre casos ambíguos, fora do escopo, curtos, com instrução maliciosa e indisponibilidade.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-5.3.1 | Aceite/rejeição da sugestão | P1 | `POST /occurrences/{id}/ai-suggestion/review`; `ACEITAR`/`REJEITAR`; autorização por papel/propriedade; `200`/`409`; histórico. |
| PBI-5.3.2 | Casos e métricas de avaliação | P1 | Conjunto rotulado em `ai/evaluation/`; registrar acurácia/F1, concordância de prioridade, validade JSON, latência e falhas; limitações explícitas. |

### E6 — Aplicativo Mobile integrado (React Native/Expo)

**Objetivo:** entregar experiência cidadão/gestor com pelo menos seis telas úteis, autenticação real e consumo direto das duas APIs.

#### F6.1 — Navegação, cadastro, login e sessão

**Descrição:** sessão baseada no JWT do .NET, armazenada com segurança e aplicada aos dois clientes HTTP.

**Critérios de aceite da Feature:**
- Cadastro e login validam formulário, mostram loader/erro e permitem nova tentativa.
- Token é armazenado em armazenamento seguro, não em texto simples; logout limpa sessão e bloqueia rotas.
- `401` limpa a sessão e leva ao login; `403` mostra ausência de permissão sem quebrar o app.
- Rotas de gestor só aparecem para `GESTOR`; a API também autoriza no servidor.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-6.1.1 | Telas de cadastro/login/logout | P0 | Formulários com validação, erros, loaders e navegação; logout limpa token; sem credenciais fixas no código. |
| PBI-6.1.2 | Clientes HTTP e interceptores | P0 | Dois clientes com `EXPO_PUBLIC_*`; Bearer automático; timeout; tratamento de `401/403/404/409/429/503`; nenhum segredo no bundle. |

#### F6.2 — Telas de ocorrências

**Descrição:** listar, criar, detalhar, editar e cancelar ocorrências via Java, com sugestão de IA visível.

**Critérios de aceite da Feature:**
- Lista mostra estado, categoria, prioridade e paginação/refresh; detalhe mostra endereço, descrição, histórico e sugestão.
- Criação/edição enviam os campos do contrato e refletem `201`/`200`; erros de validação aparecem por campo.
- Cidadão não vê ações de edição após triagem; o servidor também bloqueia.
- Aceitar/rejeitar sugestão atualiza a tela e o histórico.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-6.2.1 | Lista, filtros e detalhe | P0 | Consumo paginado do Java; estados vazio/erro/loading; pull-to-refresh; detalhe com histórico e IA. |
| PBI-6.2.2 | Criar, editar e cancelar | P0 | Formulário com categoria/endereço/descrição; validação; chamadas Java; confirmação de cancelamento; atualização da lista. |
| PBI-6.2.3 | Revisão da sugestão IA | P1 | Exibe status `PENDENTE`/`PRONTA`/`FALHOU`; botões aceitar/rejeitar; fallback de triagem manual; sem executar texto do modelo. |

#### F6.3 — Acompanhamentos e gestão

**Descrição:** usar o .NET para acompanhar ocorrências e o Java para a operação de gestão.

**Critérios de aceite da Feature:**
- Cidadão salva/remove acompanhamento e edita nota; duplicidade e indisponibilidade do Java são tratadas.
- Lista de acompanhamentos mostra ocorrência atual consultada no Java; se indisponível, mostra estado degradado e permite remover.
- Gestor vê fila, aplica triagem/status e consulta indicadores; cidadão não acessa essas rotas.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-6.3.1 | Meus acompanhamentos | P0 | CRUD .NET; botão de acompanhar no detalhe; lista com IDs/notas; remoção; erros `409`/`503`. |
| PBI-6.3.2 | Área do gestor | P1 | Lista filtrável, triagem, mudança de status e indicadores; guarda de rota por papel. |

#### F6.4 — Identidade visual, acessibilidade e publicação

**Descrição:** aplicar a identidade CityTech, garantir usabilidade e publicar o APK correspondente ao commit.

**Critérios de aceite da Feature:**
- Pelo menos seis telas úteis além de Sobre; navegação e estados consistentes.
- Cores azul/branco/verde com contraste validado; status não depende só de cor; textos e alvos de toque acessíveis.
- Lint/formatter e organização por responsabilidade; bibliotecas justificadas.
- APK publicado no Firebase App Distribution com professor tester; tela Sobre mostra o hash do commit compilado.
- Vídeo ≤5 minutos mostra o app real e todas as funcionalidades principais.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-6.4.1 | Design system e acessibilidade | P1 | Tokens de cor/tipografia, componentes reutilizáveis, contraste, rótulos e estados de erro; sem depender apenas de cor. |
| PBI-6.4.2 | Build, Firebase e Sobre | P1 | APK assinado do commit; Firebase App Distribution; hash exibido em Sobre igual ao commit; README/vídeo/TXT. |

### E7 — Dados, PL/SQL e MongoDB

**Objetivo:** atender os objetos Oracle e a representação documental comparável, usando o mesmo domínio.

#### F7.1 — Oracle e PL/SQL

**Descrição:** schema do domínio Java com objetos PL/SQL reais, scripts ordenados e testes executáveis.

**Critérios de aceite da Feature:**
- Pelo menos três tabelas relacionadas com dados fictícios; FKs e integridade.
- Dois blocos PL/SQL, duas funções, dois procedimentos, dois triggers (um de auditoria) e dois pacotes com specification/body.
- Regras não duplicadas entre Java e PL/SQL: o Java invoca o pacote quando a regra pertence ao banco.
- Scripts executam em ambiente autorizado e produzem resultados registrados.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-7.1.1 | Schema, seed e relacionamentos | P1 | `Category`, `Occurrence`, `StatusHistory` (e `AiSuggestion` se necessária) com FKs, índices e dados fictícios; script ordenado. |
| PBI-7.1.2 | Blocos, funções e procedimentos | P1 | Duas funções e dois procedimentos com regras reais (prioridade/triagem/relatórios); entradas inválidas testadas. |
| PBI-7.1.3 | Triggers, pacotes e testes | P1 | Trigger de auditoria com data/operação/valores antigo e novo; segundo trigger com regra justificada; dois pacotes; script de testes com saídas. |

#### F7.2 — MongoDB e comparação

**Descrição:** snapshot acadêmico do Oracle, com IDs preservados e consultas comparáveis.

**Critérios de aceite da Feature:**
- Duas collections (`ocorrencias`, `categorias`) com pelo menos dez documentos no total.
- Documentos preservam `oracleId`, versão/data do snapshot e histórico incorporado quando fizer sentido.
- Três consultas, pelo menos uma agregação, com resultados demonstráveis.
- Mapa relacional→documental e comparação com Oracle sobre a mesma amostra congelada.
- Script `.js` reproduzível no `mongosh`, sem apagar coleções existentes.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-7.2.1 | Collections e dados fictícios | P1 | `createCollection`, `insertMany`, IDs e snapshot; ≥10 documentos; justificativa de embed/referência. |
| PBI-7.2.2 | Consultas, agregação e comparação | P1 | Três consultas, uma `aggregate`; resultados lado a lado com Oracle; README/evidência. |

### E8 — Qualidade, DevOps e entrega

**Objetivo:** transformar o produto em entrega verificável: Boards/Test Plans, CI/CD, nuvem, evidências e arquivos corretos.

#### F8.1 — QA e Test Plans

**Descrição:** hierarquia Epic→Feature→PBI, critérios, casos manuais e execução real.

**Critérios de aceite da Feature:**
- Azure Boards contém a hierarquia e descrição/aceite de cada Feature e PBI.
- Cada Feature tem Test Cases positivos e negativos de caixa-preta, com Summary e Steps.
- Execução manual registrada no Test Plans, com resultados e bugs reais.
- PDF único com capturas e link do projeto; professor ADMIN.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-8.1.1 | Boards: Epics, Features e PBIs | P0 | Importar este backlog após autorização; preencher descrição/aceite; vincular commits/branches/PRs; não inventar IDs. |
| PBI-8.1.2 | Test Cases e Test Plans | P0 | Casos por Feature com Summary/Steps; positivos/negativos; dados e resultados esperados; plano de execução. |
| PBI-8.1.3 | Execução, evidências e PDF | P0 | Executar manualmente, anexar evidências revisadas sem segredos, gerar PDF único e TXT; professor com acesso. |

#### F8.2 — Azure DevOps, CI/CD e nuvem

**Descrição:** versionar, construir, testar e publicar .NET + Azure SQL com automação real.

**Critérios de aceite da Feature:**
- Repositório privado, main protegida, PR com Work Item e revisor.
- CI automática após merge em main: restore/build/test, artefato e resultados publicados.
- CD automático consome o mesmo artefato e publica no App Service.
- Azure CLI/scripts criam os recursos; `scripts/script-bd.sql` existe.
- CRUD de duas tabelas e persistência comprovados por SELECT no banco cloud.
- Vídeo ≥720p narrado mostra o fluxo completo.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-8.2.1 | Projeto, Repos e políticas | P0 | Projeto privado, código no Repos, branch main protegida, PR/work item; professor com acessos exigidos. |
| PBI-8.2.2 | Pipeline CI | P0 | `azure-pipeline.yml` na raiz; trigger em main; build/test/artefato; falha bloqueia merge/publicação. |
| PBI-8.2.3 | Scripts Azure e banco cloud | P0 | Azure CLI em `/scripts`; App Service + Azure SQL; variáveis/secrets; `script-bd.sql`; SELECT de persistência. |
| PBI-8.2.4 | CD e vídeo DevOps | P0 | Release automático do artefato aprovado; deploy verificável; vídeo com todos os itens obrigatórios. |

#### F8.3 — Documentação e entrega acadêmica

**Descrição:** permitir que avaliadores reproduzam e encontrem cada evidência.

**Critérios de aceite da Feature:**
- README com execução, arquitetura, usuários de teste (sem segredos), links e limitações.
- Vídeos/pitch/PDF/TXT/ZIP conferidos e acessíveis; nada publicado sem autorização.
- Sete entradas do Portal conferidas, arquivos reabertos e comprovantes guardados.

**PBIs:**

| ID | PBI | Prioridade | Descrição e critérios de aceite |
|---|---|---|---|
| PBI-8.3.1 | README e runbooks reproduzíveis | P0 | Instruções testadas em ambiente limpo; endpoints, papéis, variáveis e dependências documentados. |
| PBI-8.3.2 | Evidências e vídeos | P0 | Capturas/execuções reais, sem tokens/segredos; links de vídeo testados anonimamente. |
| PBI-8.3.3 | Checklist do Portal | P0 | Sete formatos corretos, identificação completa, links/acessos e comprovantes. |

## 5. Sequência recomendada

| Onda | Conteúdo | Motivo |
|---|---|---|
| 1 — fundação | E1, F2.1, F2.2, F3.1, schema Oracle inicial, F8.1.1/F8.2.1 | Desbloqueia autenticação, ocorrências, acompanhamento e Boards. |
| 2 — operação | F2.3, E4, F6.1–F6.3, CI inicial | Entrega o fluxo cidadão/gestor demonstrável e o primeiro build no pipeline. |
| 3 — diferenciais | E5, F7.1/F7.2, F6.4, F8.2, F8.3 | IA/RAG, PL/SQL/Mongo, publicação e evidências finais. |

A ordem não autoriza implementação. Cada onda depende de autorização da etapa correspondente e de contratos estáveis.

## 6. Dependências e riscos do backlog

- E1 é pré-requisito de E3, E4, E5 e E6; sem JWT não há integração segura.
- E2 é pré-requisito de E3 (validação de ocorrência), E5 (evento) e E6 (telas).
- E7 depende do modelo Oracle estável; Mongo depende da amostra Oracle.
- E8.2 depende de conta/custos Azure e autorização; E8.1 depende de acesso ao Boards/Test Plans.
- Oracle institucional, provedor de IA, Firebase e toolchain Android são bloqueios externos registrados em [decisões e riscos](decisoes-e-riscos.md).

## 7. Itens fora do MVP

Fotos com armazenamento definitivo, mapas/GPS, push, painel web separado, refresh token/revogação, integração oficial com prefeitura e uso de dados reais ficam em P2 ou fora do escopo. Não são necessários para o fluxo mínimo e não devem atrasar P0/P1.
