# Backend Java — ocorrências, RabbitMQ e classificação assistida

API Spring Boot 4.1.2/Java 21 responsável por categorias, ocorrências, histórico, indicadores e sugestões de classificação. Autenticação é feita com JWT RS256 emitido exclusivamente pelo backend .NET.

## Estado verificado

- CRUD/paginação de categorias e ocorrências, histórico append-only e indicadores.
- Bean Validation, erros padronizados, propriedade, papéis `CIDADAO`/`GESTOR` e concorrência otimista.
- Validação JWT de assinatura RS256, `alg`, `kid`, emissor, audiência, expiração, `sub` UUID e papéis.
- OpenAPI em `/v3/api-docs`, Swagger em `/swagger-ui.html` e health em `/health/live` e `/health/ready`.
- Outbox transacional, exchange/fila/DLQ RabbitMQ, publicação e consumo idempotente de `OccurrenceCreated.v1`.
- Spring AI 2.0.2 integrado por `ChatModel`, recuperação do corpus e validação da saída estruturada; revisão humana aceita/rejeita a sugestão.
- **41 testes padrão aprovados**, 1 AMQP opt-in ignorado por padrão e JAR empacotado. O teste adicional publicou e consumiu evento no RabbitMQ 4.4.0 real quando habilitado.
- Schema Oracle completo validado em XE 21: scripts PL/SQL aprovados e aplicação iniciada com `ddl-auto: validate` e readiness saudável.

H2 em modo Oracle continua isolado nos testes automatizados. A compatibilidade do DDL foi adicionalmente comprovada em Oracle XE 21 local; a execução no Oracle institucional da FIAP ainda depende de acesso externo.

## Pré-requisitos e configuração

Use o Maven Wrapper; Maven global não é necessário.

Variáveis obrigatórias para execução normal:

```text
ORACLE_JDBC_URL
ORACLE_USERNAME
ORACLE_PASSWORD
JWT_PUBLIC_KEY_PATH
RABBITMQ_USER
RABBITMQ_PASSWORD
```

Variáveis opcionais: `JWT_ISSUER`, `JWT_AUDIENCE`, `JWT_KEY_ID`, `JAVA_SERVER_PORT`, `RABBITMQ_HOST`, `RABBITMQ_PORT`, `OUTBOX_PUBLISHER_ENABLED` e `OUTBOX_PUBLISHER_DELAY_MS`. Para desenvolvimento Web/LAN, ative o profile `local` e, se necessário, defina `CORS_ALLOWED_ORIGINS` como lista separada por vírgulas. O Java não carrega `.env` automaticamente; exporte as variáveis no processo. Nunca versione chaves ou senhas.

O CORS existe somente no profile `local`, aceita loopback em qualquer porta e origens externas explicitamente configuradas, permite qualquer cabeçalho solicitado, não habilita credenciais e expõe `Retry-After`, `Idempotent-Replayed` e `Location`. Produção não recebe essa política implicitamente.

Todos os ambientes usam `spring.jpa.hibernate.ddl-auto=validate`: o backend não cria nem altera silenciosamente o schema Oracle. O DDL oficial é [`../database/oracle/install.sql`](../database/oracle/install.sql), que deve ser aplicado somente em schema vazio. Consulte [`../database/oracle`](../database/oracle) para subir o XE local, aplicar o schema e executar os testes PL/SQL.

## Build e testes

No PowerShell, dentro de `backend-java/`:

```powershell
.\mvnw.cmd test
.\mvnw.cmd package
```

O teste AMQP real é desabilitado por padrão para manter a suíte reproduzível sem broker. Com o RabbitMQ local configurado:

```powershell
$env:CITYTECH_RUN_RABBIT_INTEGRATION = "true"
.\mvnw.cmd -Dtest=RabbitIntegrationTests test
```

Forneça `RABBITMQ_USER`, `RABBITMQ_PASSWORD` e `RABBITMQ_PORT` no ambiente. O teste usa H2 apenas para isolar a prova AMQP e limpa as filas de classificação/DLQ antes e depois do caso.

## Execução

Na raiz do repositório, crie o `.env` a partir do modelo e gere um único par RSA para os dois backends:

```bash
mkdir -p secrets/jwt
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out secrets/jwt/private.pem
openssl pkey -in secrets/jwt/private.pem -pubout -out secrets/jwt/public.pem
chmod 600 secrets/jwt/private.pem
```

O .NET recebe `JWT_PRIVATE_KEY_PATH` e `JWT_PUBLIC_KEY_PATH`; o Java recebe a mesma `JWT_PUBLIC_KEY_PATH`. Emissor e validador também devem compartilhar `JWT_ISSUER`, `JWT_AUDIENCE` e `JWT_KEY_ID`.

Após aplicar o schema Oracle oficial e subir o RabbitMQ, execute no Linux/macOS:

```bash
./backend-java/run-local.sh
```

O script trabalha a partir da raiz, carrega `.env` e depois o `.env.local` opcional para sobrescritas locais, ativa o profile `local` por padrão e chama o Maven Wrapper versionado. Os dois arquivos de ambiente permanecem ignorados pelo Git. No PowerShell, exporte as mesmas variáveis e execute dentro de `backend-java/`:

```powershell
$env:SPRING_PROFILES_ACTIVE = "local"
.\mvnw.cmd spring-boot:run
```

Rotas principais sob `/api/v1`:

- `/categories`
- `/occurrences`
- `/occurrences/{id}/history`
- `/occurrences/{id}/ai-suggestion/review`
- `/manager/indicators`

O cancelamento lógico exige `version` e `reason`. Alterações usam `version` para retornar `409 CONCURRENT_MODIFICATION` diante de dados desatualizados.

## RabbitMQ e IA

Ao criar ocorrência, o serviço grava a ocorrência, histórico e outbox na mesma transação. O publicador envia ao exchange `citytech.occurrences`; o consumidor da fila `citytech.ai.classification.v1` deduplica por `eventId`. Após três falhas de consumo, a mensagem é rejeitada para a DLQ.

O corpus canônico está em [`../ai/corpus`](../ai/corpus) e é incluído no JAR pelo Maven. O adaptador Spring AI só é ativado quando um `ChatModel` autorizado existir. Sem provedor/modelo, o consumidor persiste `FALHOU` com `MODEL_NOT_CONFIGURED`, mantendo classificação manual disponível. Isso não é resultado generativo e não atende sozinho à comprovação acadêmica de LLM real.

Ainda faltam:

1. escolher e configurar um starter/provedor Spring AI, modelo de chat e credencial autorizados;
2. executar casos reais de RAG/LLM e registrar métricas/limitações em `ai/evaluation/`;
3. repetir os scripts no Oracle institucional quando host/servico/credenciais forem fornecidos;
4. executar integração positiva entre processos .NET→Java e, futuramente, consumo Mobile.

Nenhum usuário/senha de teste ou chave privada é versionado. Publicação GitHub, deploy e recursos externos dependem de autorização separada.
