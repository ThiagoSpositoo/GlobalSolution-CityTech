# Contratos das APIs — CityTech

**Contrato definido na Etapa 3B e atualizado em 17/11/2026.** As APIs .NET/Java e os clientes/telas Mobile estão implementados; .NET e Java foram testados nos limites registrados, o Java iniciou contra Oracle XE 21 e o Mobile passou em tipagem, lint, testes e bundle. A integração positiva completa em dispositivo ainda depende de APIs alcançáveis/CORS. Mudanças exigem atualização conjunta e revisão de compatibilidade.

Escopo: [backlog](backlog.md), [modelo de domínio](modelo-dominio.md), [arquitetura](arquitetura.md) e [integração Mobile](integracao-mobile.md). Requisitos acadêmicos: [matriz](requisitos-global-solution.md).

## 1. Convenções comuns

| Item | Decisão |
|---|---|
| Java (dev) | `http://localhost:8080/api/v1` |
| .NET (dev) | `http://localhost:8081/api/v1` |
| Formato | JSON UTF-8; `Content-Type: application/json` |
| Autenticação | `Authorization: Bearer <JWT>` em rotas protegidas |
| IDs | UUID em string |
| Datas | ISO-8601 UTC com `Z` (ex.: `2026-11-17T14:30:00Z`) |
| Paginação | `page` base 0, `size` 1–100 (padrão 20) |
| Ordenação | `sort=campo,asc|desc`; whitelist por endpoint |
| Versionamento | prefixo `/api/v1`; mudança incompatível exige `/api/v2` |
| OpenAPI Java | `/v3/api-docs` e `/swagger-ui/index.html` |
| OpenAPI .NET | `/swagger/v1/swagger.json` e `/swagger` |
| Erros | envelope único inspirado em RFC 9457 (seção 3) |
| Idioma de erros | mensagens em português; códigos estáveis em inglês |

Respostas de erro **não** incluem stack trace, SQL, token, senha ou detalhe interno. O `traceId` correlaciona log e resposta.

### 1.1 Paginação

Requisição: `GET /occurrences?page=0&size=20&sort=createdAt,desc`.

```json
{
  "items": [],
  "page": 0,
  "size": 20,
  "totalElements": 0,
  "totalPages": 0,
  "first": true,
  "last": true
}
```

`page < 0` ou `size` fora de 1–100 → `400 VALIDATION_ERROR`. `sort` fora da whitelist → `400`.

### 1.2 Idempotência

Obrigatória em `POST /auth/register` e `POST /followups`:

- Header `Idempotency-Key`: 8–128 caracteres; UUID é recomendado.
- Mesma chave + mesmo corpo + mesmo escopo → resposta original, com `Idempotent-Replayed: true`.
- Mesma chave + corpo diferente → `409 IDEMPOTENCY_CONFLICT`.
- Janela mínima: 24 horas.
- Concorrência: apenas um efeito é persistido; a outra requisição recebe a resposta estável.
- A chave não substitui a unicidade de e-mail nem a unicidade (`userId`, `occurrenceId`).

### 1.3 Rate limiting

Valores iniciais configuráveis e testáveis; não são promessa de produção:

| Rota | Limite inicial | Chave |
|---|---|---|
| `POST /auth/login` | 10/min | IP + e-mail normalizado |
| `POST /auth/register` | 5/hora | IP |
| `POST /followups` | 60/min | usuário |
| Demais rotas autenticadas | 120/min | usuário/IP |

Excesso → `429 RATE_LIMITED` com `Retry-After` em segundos. O corpo segue o envelope de erro.

### 1.4 Health checks

| Endpoint | Verificação | Sucesso | Falha |
|---|---|---|---|
| `GET /health/live` | processo vivo | `200 {"status":"UP"}` | sem resposta |
| `GET /health/ready` Java | Oracle + RabbitMQ | `200` com checks | `503` se dependência crítica cair |
| `GET /health/ready` .NET | SQL Server + Java | `200` com checks | `503` se dependência crítica cair |

O health **não** chama LLM pago. Para Java, o estado da IA aparece como configuração/última execução, sem tornar o endpoint dependente de cobrança.

## 2. Autenticação e JWT

### 2.1 Emissão

Somente o .NET emite tokens. Java e .NET validam o mesmo contrato.

- Algoritmo: **RS256** (RSA 2048+). `none`, `HS256` e algoritmos não previstos são rejeitados.
- Emissor: `citytech-identity`.
- Audiência: `citytech-api`.
- Validade: 60 minutos (configurável).
- `kid` no header, correspondente à chave pública configurada.
- Chave privada: somente .NET, fora do Git. Chave pública: Java e .NET, por caminho/configuração.
- Clock skew máximo: 60 segundos.
- Sem refresh token no MVP; expiração leva o app ao login. Revogação/refresh é P2.

### 2.2 Claims

| Claim | Tipo | Regra |
|---|---|---|
| `sub` | string UUID | ID da conta; vira `citizen_id`/`actor_id` no Java |
| `iss` | string | `citytech-identity` |
| `aud` | string | `citytech-api` |
| `exp` | number | expiração Unix UTC |
| `iat` | number | emissão |
| `jti` | string UUID | identificador do token |
| `roles` | array | `["CIDADAO"]` ou `["GESTOR"]` |
| `name` | string | nome de exibição |
| `email` | string | e-mail; não usar para autorização |

Exemplo de payload (sem assinatura real):

```json
{
  "sub": "0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0",
  "iss": "citytech-identity",
  "aud": "citytech-api",
  "exp": 1795000000,
  "iat": 1794996400,
  "jti": "9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d",
  "roles": ["CIDADAO"],
  "name": "Pessoa Exemplo",
  "email": "pessoa@example.test"
}
```

### 2.3 Validação

Java e .NET devem validar: assinatura, `kid`, algoritmo, `iss`, `aud`, `exp`, `nbf` quando presente, formato de `sub` e presença de papel conhecido. Token inválido/expirado → `401 UNAUTHORIZED`. Papel insuficiente → `403 FORBIDDEN`. Recurso de outro proprietário → `404 NOT_FOUND` (não revelar existência).

### 2.4 Cadastro e gestor

- `POST /auth/register` cria apenas `CIDADAO`; o corpo não contém `role`.
- Gestor é criado por seed/configuração local controlada, de forma idempotente; não há endpoint público de promoção.
- Login não revela se o e-mail existe: credencial inválida sempre retorna a mesma mensagem.

## 3. Envelope de erro

```json
{
  "type": "https://citytech.example/errors/validacao",
  "title": "Requisição inválida",
  "status": 400,
  "detail": "O campo title deve ter entre 5 e 120 caracteres.",
  "instance": "/api/v1/occurrences",
  "code": "VALIDATION_ERROR",
  "traceId": "b1e2d3c4-5f60-4718-9a2b-3c4d5e6f7081",
  "errors": [
    { "field": "title", "message": "deve ter entre 5 e 120 caracteres" }
  ]
}
```

`type` é um identificador documental; não é necessário que a URL externa exista. `code` é o valor usado por testes e pelo Mobile. `errors` só aparece em validação.

| HTTP | `code` | Quando |
|---:|---|---|
| 400 | `VALIDATION_ERROR` | JSON malformado, campo inválido, paginação inválida |
| 400 | `INVALID_CATEGORY` | categoria inexistente/inativa na criação ou triagem |
| 401 | `UNAUTHORIZED` | token ausente, inválido, expirado ou algoritmo recusado |
| 403 | `FORBIDDEN` | autenticado, mas papel sem permissão |
| 404 | `NOT_FOUND` | recurso inexistente ou invisível ao chamador |
| 404 | `OCCURRENCE_NOT_FOUND` | .NET não encontrou a ocorrência no Java |
| 409 | `EMAIL_ALREADY_EXISTS` | e-mail já cadastrado |
| 409 | `FOLLOWUP_ALREADY_EXISTS` | acompanhamento duplicado |
| 409 | `INVALID_TRANSITION` | transição de status não permitida |
| 409 | `CONCURRENT_MODIFICATION` | `version` desatualizada |
| 409 | `IDEMPOTENCY_CONFLICT` | chave repetida com corpo diferente |
| 409 | `ALREADY_REVIEWED` | sugestão de IA já decidida |
| 429 | `RATE_LIMITED` | limite excedido; inclui `Retry-After` |
| 503 | `DEPENDENCY_UNAVAILABLE` | banco/broker/Java indisponível |
| 503 | `OCCURRENCE_SERVICE_UNAVAILABLE` | .NET não conseguiu validar no Java |
| 500 | `INTERNAL_ERROR` | falha inesperada, sem detalhe sensível |

## 4. API Java — ocorrências, gestão e IA

Base: `/api/v1`. Todas as rotas exigem JWT, salvo health.

### 4.1 Resumo dos endpoints

| Método | Caminho | Papel | Objetivo |
|---|---|---|---|
| GET | `/categories` | autenticado | listar categorias ativas (gestor pode incluir inativas) |
| POST | `/categories` | `GESTOR` | criar categoria |
| PUT | `/categories/{id}` | `GESTOR` | editar categoria |
| DELETE | `/categories/{id}` | `GESTOR` | desativar categoria |
| POST | `/occurrences` | `CIDADAO` | criar ocorrência |
| GET | `/occurrences` | autenticado | listar conforme papel |
| GET | `/occurrences/{id}` | proprietário/`GESTOR` | detalhe + sugestão IA |
| PUT | `/occurrences/{id}` | proprietário em `ABERTA` | editar conteúdo |
| DELETE | `/occurrences/{id}` | proprietário/`GESTOR` conforme estado | cancelar logicamente |
| PATCH | `/occurrences/{id}/triage` | `GESTOR` | categoria, prioridade e nota |
| PATCH | `/occurrences/{id}/status` | conforme transição | mudar status |
| GET | `/occurrences/{id}/history` | proprietário/`GESTOR` | histórico paginado |
| POST | `/occurrences/{id}/ai-suggestion/review` | proprietário/`GESTOR` | aceitar/rejeitar sugestão |
| GET | `/manager/indicators` | `GESTOR` | indicadores agregados |
| GET | `/health/live`, `/health/ready` | público | saúde |

### 4.2 Categorias

**`GET /categories?includeInactive=false`** → `200` com array:

```json
[
  { "id": "uuid", "code": "VIAS", "name": "Vias e buracos", "description": "Buracos, pavimentação e calçadas", "active": true }
]
```

Cidadão não pode usar `includeInactive=true` (`403`). Gestor pode.

**`POST /categories`** — `GESTOR`:

```json
{ "code": "ILUMINACAO", "name": "Iluminação pública", "description": "Lâmpadas e postes" }
```

`201` com o recurso criado. Código duplicado → `409`; inválido → `400`.

**`PUT /categories/{id}`** — `GESTOR`: mesmos campos; `200`. **`DELETE /categories/{id}`** — desativa (`active=false`) e retorna `204`; repetir a operação é idempotente e preserva a linha e as ocorrências históricas.

### 4.3 Criar ocorrência

**`POST /occurrences`** — `CIDADAO`:

```json
{
  "title": "Buraco na faixa da direita",
  "description": "Buraco profundo após a faixa de pedestres, com risco para motos.",
  "categoryId": "0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0",
  "priority": "MEDIA",
  "address": {
    "street": "Rua Exemplo",
    "number": "100",
    "complement": null,
    "district": "Centro",
    "city": "São Paulo",
    "state": "SP",
    "postalCode": "01000-000"
  }
}
```

Regras: `title` 5-120; `description` 20-2000; categoria ativa; `priority` opcional (padrão `MEDIA`); endereço obrigatório; `state` UF; `postalCode` opcional. Resposta `201` + `Location` + detalhe. Efeito: `status=ABERTA`, histórico `CRIACAO` e evento no outbox; o consumidor cria a sugestão como `PENDENTE` e depois a marca `PRONTA` ou `FALHOU`.

### 4.4 Listar e detalhar

**`GET /occurrences`** — query:

| Parâmetro | Valores | Efeito |
|---|---|---|
| `status` | enum | filtra |
| `categoryId` | UUID | filtra |
| `priority` | enum | filtra |
| `q` | texto 1–120 | busca em título/descrição |
| `page`, `size`, `sort` | ver convenções | paginação |

Cidadão vê somente `citizen_id = sub`; gestor vê todas. `sort` permitido: `createdAt`, `updatedAt`, `priority`, `status`, `title`. Resposta `200` com `PageResponse<OccurrenceSummary>`.

```json
{
  "id": "uuid",
  "title": "Buraco na faixa da direita",
  "category": { "id": "uuid", "code": "VIAS", "name": "Vias e buracos" },
  "priority": "MEDIA",
  "status": "ABERTA",
  "address": { "district": "Centro", "city": "São Paulo", "state": "SP" },
  "createdAt": "2026-11-17T14:30:00Z",
  "updatedAt": "2026-11-17T14:30:00Z",
  "aiSuggestionStatus": "PENDENTE"
}
```

**`GET /occurrences/{id}`** → `200` com detalhe completo (descrição, endereço completo, `version`, `citizenId`, `aiSuggestion`). Proprietário ou gestor; outro cidadão → `404`.

```json
{
  "id": "uuid",
  "citizenId": "uuid",
  "title": "Buraco na faixa da direita",
  "description": "Buraco profundo após a faixa de pedestres, com risco para motos.",
  "category": { "id": "uuid", "code": "VIAS", "name": "Vias e buracos" },
  "priority": "MEDIA",
  "status": "ABERTA",
  "address": {
    "street": "Rua Exemplo", "number": "100", "complement": null,
    "district": "Centro", "city": "São Paulo", "state": "SP", "postalCode": "01000-000"
  },
  "version": 0,
  "createdAt": "2026-11-17T14:30:00Z",
  "updatedAt": "2026-11-17T14:30:00Z",
  "aiSuggestion": {
    "status": "PRONTA",
    "suggestedCategory": { "id": "uuid", "code": "VIAS", "name": "Vias e buracos" },
    "suggestedPriority": "ALTA",
    "summary": "Buraco em via com risco para motociclistas.",
    "justification": "A descrição indica profundidade e risco.",
    "sources": ["corpus/taxonomia.md#vias", "corpus/prioridade.md#alto-risco"],
    "model": "modelo-configurado",
    "promptVersion": "rag-v1",
    "reviewedAt": null,
    "decision": null
  }
}
```

`aiSuggestion` pode ser `null` (ainda não criada) ou ter `status=FALHOU` com `errorCode`.

### 4.5 Editar e cancelar

**`PUT /occurrences/{id}`** — proprietário, somente `ABERTA`; mesmos campos da criação, exceto `status`, mais `version` obrigatório no corpo. `200`; estado inválido → `409 INVALID_TRANSITION`; versão divergente → `409 CONCURRENT_MODIFICATION`.

**`DELETE /occurrences/{id}?version=<n>&reason=<texto>`** — proprietário em `ABERTA` ou gestor em estado não terminal. Aplica cancelamento lógico; `version` e `reason` são obrigatórios na query string (`reason` com 1–255 caracteres, codificado na URL). `204`; versão divergente → `409 CONCURRENT_MODIFICATION`; estado inválido → `409 INVALID_TRANSITION`.

### 4.6 Triagem e status

**`PATCH /occurrences/{id}/triage`** — `GESTOR`:

```json
{ "version": 0, "categoryId": "uuid", "priority": "ALTA", "note": "Risco imediato; encaminhado à equipe de vias." }
```

`version` é obrigatório. Pelo menos um entre `categoryId`, `priority` e `note` deve estar presente; `note` até 500. `200` com detalhe atualizado; versão divergente → `409 CONCURRENT_MODIFICATION`. Histórico `TRIAGEM`.

**`PATCH /occurrences/{id}/status`**:

```json
{ "version": 1, "status": "EM_TRIAGEM", "note": "Triagem iniciada.", "reason": null }
```

`version` é obrigatório. `reason` é obrigatório para `CANCELADA`. A matriz de transições está no [modelo de domínio](modelo-dominio.md#5-estados-e-transições). `200` com detalhe; inválida → `409 INVALID_TRANSITION`; versão divergente → `409 CONCURRENT_MODIFICATION`.

### 4.7 Histórico

**`GET /occurrences/{id}/history?page=0&size=20`** → `200`:

```json
{
  "items": [
    {
      "id": "uuid",
      "action": "TRANSICAO",
      "fromStatus": "ABERTA",
      "toStatus": "EM_TRIAGEM",
      "actorId": "uuid",
      "actorRole": "GESTOR",
      "note": "Triagem iniciada.",
      "createdAt": "2026-11-17T15:00:00Z"
    }
  ],
  "page": 0, "size": 20, "totalElements": 1, "totalPages": 1, "first": true, "last": true
}
```

Ordenação padrão `createdAt,desc`. Sem endpoints de update/delete.

### 4.8 Revisão da sugestão de IA

**`POST /occurrences/{id}/ai-suggestion/review`**:

```json
{ "version": 0, "decision": "ACEITAR", "note": "Sugestão coerente com a descrição." }
```

- `ACEITAR`: aplica categoria/prioridade sugeridas, grava histórico `REVISAO_IA` e status `ACEITA`.
- `REJEITAR`: mantém os dados atuais, grava decisão e status `REJEITADA`.
- `version` é obrigatório; divergência → `409 CONCURRENT_MODIFICATION`.
- Sem sugestão `PRONTA` → `409`; já revisada → `409 ALREADY_REVIEWED`.
- Cidadão só na própria ocorrência; gestor em qualquer uma; outro cidadão → `404`.

### 4.9 Indicadores

**`GET /manager/indicators`** — `GESTOR`; `200`:

```json
{
  "totalOccurrences": 42,
  "byStatus": { "ABERTA": 8, "EM_TRIAGEM": 6, "EM_ANDAMENTO": 10, "RESOLVIDA": 9, "ENCERRADA": 7, "CANCELADA": 2 },
  "byCategory": [
    { "categoryId": "uuid", "code": "VIAS", "name": "Vias e buracos", "count": 12 }
  ],
  "averageTriageHours": 18.5,
  "ai": { "suggestions": 30, "accepted": 18, "rejected": 7, "failed": 5, "acceptanceRate": 0.6 },
  "generatedAt": "2026-11-17T16:00:00Z"
}
```

Zero ocorrências deve retornar zeros, não `null`/erro. Cidadão → `403`.

## 5. API .NET — identidade e acompanhamentos

Base: `/api/v1`. Rotas de health são públicas; as demais exigem JWT, exceto register/login.

### 5.1 Resumo dos endpoints

| Método | Caminho | Papel | Objetivo |
|---|---|---|---|
| POST | `/auth/register` | público | cadastrar cidadão (idempotente) |
| POST | `/auth/login` | público | autenticar e emitir JWT |
| GET | `/auth/me` | autenticado | dados públicos da conta |
| GET | `/followups` | autenticado | listar acompanhamentos do usuário |
| GET | `/followups/{id}` | proprietário | detalhe do acompanhamento |
| POST | `/followups` | autenticado | criar acompanhamento (idempotente) |
| PATCH | `/followups/{id}` | proprietário | editar nota |
| DELETE | `/followups/{id}` | proprietário | remover acompanhamento |
| GET | `/health/live`, `/health/ready` | público | saúde |

### 5.2 Cadastro

**`POST /auth/register`** — headers `Idempotency-Key` obrigatório:

```json
{ "name": "Pessoa Exemplo", "email": "pessoa@example.test", "password": "SenhaForte123" }
```

Regras: nome 2-120; e-mail válido/único (normalizado); senha 8-128 com letra e número. `201` com a conta criada (sem `Location`, pois não há recurso individual de conta exposto):

```json
{ "id": "uuid", "name": "Pessoa Exemplo", "email": "pessoa@example.test", "role": "CIDADAO", "createdAt": "2026-11-17T14:00:00Z" }
```

`409 EMAIL_ALREADY_EXISTS`; `400 VALIDATION_ERROR`; corpo com `role` não promove ninguém. Não retorna token; o app faz login em seguida.

### 5.3 Login e sessão

**`POST /auth/login`**:

```json
{ "email": "pessoa@example.test", "password": "SenhaForte123" }
```

`200`:

```json
{
  "accessToken": "<jwt>",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": { "id": "uuid", "name": "Pessoa Exemplo", "email": "pessoa@example.test", "role": "CIDADAO" }
}
```

Credencial inválida/conta inativa → `401 UNAUTHORIZED` com mensagem genérica. **`GET /auth/me`** → mesmo objeto `user`.

Logout é local no app (descartar token); não há endpoint de revogação no MVP. O token continua válido até `exp`, por isso a validade curta é obrigatória.

### 5.4 Acompanhamentos

**`GET /followups?page=0&size=20&sort=createdAt,desc`** → `200`:

```json
{
  "items": [
    { "id": "uuid", "occurrenceId": "uuid", "note": "Acompanhar a triagem.", "createdAt": "2026-11-17T15:00:00Z", "updatedAt": "2026-11-17T15:00:00Z", "version": 0 }
  ],
  "page": 0, "size": 20, "totalElements": 1, "totalPages": 1, "first": true, "last": true
}
```

Não há status/categoria copiados. O Mobile busca o detalhe atual no Java.

**`POST /followups`** — `Idempotency-Key` obrigatório:

```json
{ "occurrenceId": "uuid", "note": "Acompanhar a triagem." }
```

Fluxo do .NET:
1. Valida o corpo e o usuário.
2. Chama `GET {JAVA_API_BASE_URL}/api/v1/occurrences/{occurrenceId}` com o Bearer do usuário.
3. `200` → grava `FollowUp` (`201` + `Location`); `404`/`403` do Java → `404 OCCURRENCE_NOT_FOUND`; `503`/timeout → `503 OCCURRENCE_SERVICE_UNAVAILABLE` sem gravar.
4. Duplicidade → `409 FOLLOWUP_ALREADY_EXISTS`.

**`GET /followups/{id}`** → `200` ou `404` se não for do usuário. **`PATCH /followups/{id}`**:

```json
{ "version": 0, "note": "Prioridade alta; acompanhar hoje." }
```

`version` é obrigatório. `200` com `version` incrementada; conflito → `409 CONCURRENT_MODIFICATION`. **`DELETE /followups/{id}`** → `204`; repetição idempotente pode retornar `204`.

## 6. Contrato do evento RabbitMQ

| Item | Valor |
|---|---|
| Exchange | `citytech.occurrences` (topic, durável) |
| Routing key | `occurrence.created.v1` |
| Fila | `citytech.ai.classification.v1` (durável) |
| Dead letter exchange | `citytech.occurrences.dlx` |
| Dead letter queue | `citytech.ai.classification.dlq` |
| Schema | `OccurrenceCreated`, versão `1` |

```json
{
  "eventId": "uuid",
  "eventType": "OccurrenceCreated",
  "schemaVersion": 1,
  "occurredAt": "2026-11-17T14:30:00Z",
  "occurrenceId": "uuid",
  "citizenId": "uuid",
  "categoryId": "uuid",
  "title": "Buraco na faixa da direita",
  "description": "Buraco profundo após a faixa de pedestres, com risco para motos.",
  "priority": "MEDIA",
  "address": { "district": "Centro", "city": "São Paulo", "state": "SP" }
}
```

Regras:

- O evento é gravado no outbox na mesma transação da ocorrência; o publicador pode repetir o envio.
- Consumidor deduplica por `eventId`; falha transitória tem retry limitado; falha permanente vai para DLQ.
- Consumidor não executa instruções do título/descrição; trata como dados.
- A sugestão nasce `PENDENTE`, vira `PRONTA` ou `FALHOU`; o consumidor não muda o status da ocorrência.
- Logs não incluem descrição completa nem credenciais.

## 7. Exemplos de uso

Login:

```bash
curl -X POST http://localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"pessoa@example.test","password":"<SENHA_LOCAL>"}'
```

Criar ocorrência:

```bash
curl -X POST http://localhost:8080/api/v1/occurrences \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Buraco na via","description":"Buraco profundo na faixa da direita.","categoryId":"<UUID>","address":{"street":"Rua Exemplo","number":"100","district":"Centro","city":"São Paulo","state":"SP"}}'
```

Criar acompanhamento:

```bash
curl -X POST http://localhost:8081/api/v1/followups \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Idempotency-Key: 3f2a1b4c-5d6e-7f80-9a1b-2c3d4e5f6071" \
  -H "Content-Type: application/json" \
  -d '{"occurrenceId":"<UUID>","note":"Acompanhar triagem."}'
```

## 8. Compatibilidade e evolução

- Mudanças aditivas (novo campo opcional, novo valor de enum) permanecem em `/v1`; o Mobile deve tolerar campos desconhecidos.
- Remoção/renomeação/alteração de tipo exige `/v2` e período de transição.
- OpenAPI gerado é a fonte executável; este documento explica regras que o schema não expressa.
- Erros e enums são parte do contrato; alteração exige atualização de testes e do app.
- Nenhum contrato está aprovado por professor; a divisão de responsabilidades precisa de confirmação docente registrada na matriz.
