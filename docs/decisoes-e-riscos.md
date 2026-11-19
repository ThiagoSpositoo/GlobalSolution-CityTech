# Decisões e riscos de integração — Etapa 3B

**17/11/2026 — planejamento.** Este documento complementa os ADR-001 a ADR-007 de [arquitetura](arquitetura.md). Nenhuma decisão aqui foi validada por build ou aprovada por professor; são a base para a implementação e devem ser revalidadas antes de codificar.

## 1. Decisões (ADR-008 a ADR-016)

### ADR-008 — Contrato primeiro, versionado em `/api/v1`

**Contexto:** Java, .NET e Mobile serão implementados em paralelo e por pessoas diferentes.

**Decisão:** contratos REST documentados em [contratos-api.md](contratos-api.md), com envelope de erro comum, UUID, datas UTC, paginação e enums estáveis. Mudanças incompatíveis exigem `/v2`; mudanças aditivas permanecem em `/v1`. OpenAPI gerado é a fonte executável.

**Consequências:** DTOs e erros precisam ser revisados conjuntamente; o Mobile tolera campos desconhecidos; testes de contrato entram cedo. Evita que cada backend invente nomes/status diferentes.

**Alternativas descartadas:** contract-last (mais rápido no início, mais caro na integração); GraphQL (fora do escopo e sem ganho para o prazo).

### ADR-009 — JWT RS256 emitido pelo .NET, validado pelos dois backends

**Contexto:** o PDF exige JWT nos dois backends e o Mobile precisa de uma única sessão.

**Decisão:** .NET assina RS256 com chave privada fora do Git; Java valida com a chave pública configurada. Claims `sub`, `iss`, `aud`, `exp`, `iat`, `jti` e `roles`; validade de 60 minutos; sem refresh no MVP. Java não emite token nem guarda senha.

**Consequências:** uma conta serve aos dois serviços; a disponibilidade do .NET é necessária para login. Rotação de chave exige atualização coordenada. Token vazado vale até expirar; validade curta e armazenamento seguro mitigam. Não há revogação server-side no MVP.

**Alternativas descartadas:** dois logins/dois tokens (duplicaria credenciais); chave simétrica compartilhada (pior separação); refresh token agora (custo/teste adicionais).

### ADR-010 — Ocorrência com máquina de estados explícita e cancelamento lógico

**Contexto:** o PDF exige CRUD e histórico; apagar fisicamente destruiria auditoria e referências do .NET.

**Decisão:** estados `ABERTA`, `EM_TRIAGEM`, `EM_ANDAMENTO`, `RESOLVIDA`, `ENCERRADA`, `CANCELADA`; transições da tabela do [modelo](modelo-dominio.md#5-estados-e-transições). `DELETE` é cancelamento lógico com motivo e histórico; histórico é append-only.

**Consequências:** Mobile demonstra “excluir” sem perder trilha; .NET pode referenciar ocorrência cancelada (mostrar indisponível). Exige confirmação docente sobre a interpretação de exclusão.

**Alternativas descartadas:** hard delete (perde auditoria); status livre (divergência entre serviços).

### ADR-011 — Acompanhamento .NET referencia a ocorrência, sem copiar estado

**Contexto:** o .NET precisa de funcionalidade real e o Java é dono do status.

**Decisão:** `FollowUp` guarda `userId`, `occurrenceId`, nota e timestamps; não copia status/categoria/descrição. Na criação, .NET valida a ocorrência no Java usando o Bearer do próprio usuário; falha do Java não grava. Na lista, o Mobile busca o detalhe atual no Java.

**Consequências:** sem sincronização/estado duplicado; uma chamada extra na criação e N consultas na lista (limitar concorrência). Se o Java cair, acompanhamentos continuam listáveis, mas detalhes ficam indisponíveis.

**Alternativas descartadas:** copiar status (stale); .NET como proxy de ocorrência (duplicaria domínio); fila de sincronização (complexidade desnecessária).

### ADR-012 — IA consultiva via outbox + RabbitMQ + RAG

**Contexto:** Java exige Spring AI e a alternativa distribuída A; IA exige aprofundamento e revisão humana.

**Decisão:** criação grava `OutboxEvent` na mesma transação e publica `OccurrenceCreated.v1`; consumidor idempotente recupera corpus, chama o modelo e persiste `AiSuggestion` com status. A sugestão não altera a ocorrência até revisão humana; falha vai para DLQ e mantém triagem manual.

**Consequências:** prova real de publicação/consumo; latência assíncrona e custo de LLM; necessidade de corpus/avaliação. Health não chama LLM pago.

**Alternativas descartadas:** chamada síncrona no request (acopla disponibilidade/custo); evento sem outbox (perda entre commit e publish); consumidor não idempotente (duplicidade).

### ADR-013 — Idempotência do .NET com chave + escopo + hash

**Contexto:** NET-06 exige repetição sem duplicação; duplicidade de cadastro/acompanhamento é o caso real.

**Decisão:** `POST /auth/register` e `POST /followups` exigem `Idempotency-Key`; persistir escopo, chave, hash do corpo, status e resposta por 24 h. Mesmo corpo → replay; corpo diferente → `409`; concorrência → um efeito. Unicidade de e-mail e (`userId`,`occurrenceId`) reforça no banco.

**Consequências:** tabela técnica e limpeza periódica; respostas não podem conter segredo; testes de concorrência são obrigatórios.

**Alternativas descartadas:** idempotência só em memória (perde no restart); confiar apenas em unique constraint (não devolve resposta estável).

### ADR-014 — Gestor criado por seed controlado

**Contexto:** o cadastro público não pode permitir autoelevação; a avaliação precisa de um gestor.

**Decisão:** seed/migration/comando idempotente cria gestor a partir de configuração local; credenciais não são versionadas. Nenhum endpoint público aceita `role`.

**Consequências:** o ambiente de demonstração precisa de um passo documentado; o professor tester recebe credenciais por canal seguro. Testar que `role` no corpo de cadastro não promove.

**Alternativas descartadas:** promover o primeiro usuário (inseguro); endpoint administrativo sem autenticação (inaceitável).

### ADR-015 — Categoria é desativada, não apagada

**Contexto:** ocorrências históricas referenciam categorias; apagar quebraria relatórios.

**Decisão:** `DELETE /categories/{id}` desativa (`active=false`) e preserva a linha; categoria inativa não é usada em novas ocorrências, mas continua legível no histórico.

**Consequências:** CRUD demonstrável sem perda de integridade; filtros precisam considerar `active`.

### ADR-016 — Fotos, mapas, GPS e push ficam em P2

**Contexto:** o PDF não exige fotos/mapas/push; o prazo é curto e o caminho mínimo já é amplo.

**Decisão:** o MVP usa endereço textual e não bloqueia o fluxo por upload. Fotos só entram se o núcleo estiver estável, com limites/validação/armazenamento definidos. Mapas/GPS/push ficam fora do MVP.

**Consequências:** menos risco; a proposta ainda atende ao produto. Se fotos forem incluídas, criar entidade e contrato próprios, sem alterar a tabela de ocorrência de forma improvisada.

## 2. Riscos de integração

| ID | Risco | Prob. | Impacto | Mitigação | Sinal de alerta |
|---|---|---|---|---|---|
| R-01 | Mobile consumir só uma API | Média | Alto (NET/JAV) | Fluxos visíveis nas duas; testes E2E; confirmar divisão com professor | Tela de acompanhamento vazia ou só mock |
| R-02 | JWT incompatível entre Java/.NET | Média | Alto | Chave pública comum, claims testadas, `kid`, relógio; teste cruzado cedo | Java 401 em token válido do .NET |
| R-03 | Oracle indisponível/sem versão | Alta | Alto (Java/Banco) | Confirmar acesso institucional; DDL conceitual; testar cedo | Sem conexão/schema na véspera |
| R-04 | Java indisponível durante avaliação Mobile | Média | Alto (MOB-04) | Hospedagem estável/decisão de deploy; health; URLs no APK | App funciona só no PC do desenvolvedor |
| R-05 | Status divergente entre bancos | Baixa | Alto | .NET não copia status; Java é fonte única | Follow-up mostrando status antigo |
| R-06 | Transição inválida/histórico inconsistente | Média | Médio | Máquina de estados centralizada; testes de matriz; transação | Histórico sem ator ou status pulado |
| R-07 | Idempotência concorrente falha | Média | Médio (NET-06) | Unique + hash + teste concorrente | Duplicata após duplo clique/retry |
| R-08 | Rate limit bloqueia demonstração | Baixa | Médio | Limites configuráveis; teste determinístico; mensagem clara | 429 inesperado em fluxo normal |
| R-09 | LLM lento/caro/indisponível | Alta | Médio (IA) | Assíncrono, timeout, fallback manual, orçamento/autorização | Ocorrência presa em PENDENTE |
| R-10 | RAG sem recuperação real | Média | Alto (IA-03) | Corpus versionado, top-k, fontes, avaliação; não usar prompt fixo | Resposta sem fontes/IDs |
| R-11 | Injeção de prompt no texto da ocorrência | Média | Médio | Tratar como dado; validar saída; não executar instruções; casos adversariais | Modelo obedece texto do usuário |
| R-12 | Azure/Test Plans sem acesso ou crédito | Alta | Alto (DEV/QA) | Confirmar contas/licenças; scripts; orçamento; não ativar cobrança sem autorização | Sem projeto/boards na reta final |
| R-13 | Pipeline/CD divergente do artefato | Média | Alto (DEV-08/09) | CD consome artefato da CI; versionar; testar release | Deploy recompila outra versão |
| R-14 | Banco cloud em localhost | Baixa | Alto (DEV-P03) | Azure SQL/App Service; SELECT no cloud; checklist | Connection string local no deploy |
| R-15 | APK/Firebase diferente do commit | Média | Alto (MOB-11) | Sobre com hash; build do commit; publicar após tag; conferir | Hash da tela ≠ commit do fonte |
| R-16 | Menos de 6 telas úteis | Média | Alto (MOB-09) | Navegação mínima de 9 telas; Sobre não conta; revisão | Telas duplicadas/placeholder |
| R-17 | Oracle/Mongo sem comparação justa | Média | Médio (DB-06) | Amostra congelada, IDs preservados, 3 consultas; mapa | Números divergentes sem explicação |
| R-18 | Histórico imutável não demonstrar CRUD | Média | Médio (DB/JAV) | Confirmar com professor; demonstrar criação/consulta e cancelamento | Exigência de update/delete de histórico |
| R-19 | Credenciais em logs/capturas | Média | Alto (penalidades) | `.gitignore`, revisão de diff, sanitização de evidências | Token/senha visível em print |
| R-20 | Prazo de 19/11 insuficiente | Alta | Alto | Priorizar P0, reduzir P2, registrar pendências; não simular | Nenhum fluxo E2E na véspera |

## 3. Dependências críticas

1. **Oracle institucional** — versão, host/porta/serviço, VPN e credenciais. Sem isso, Java e Banco ficam limitados a um ambiente local a confirmar.
2. **Provedor/modelo de IA** — acesso, custo, limites e suporte Spring AI. Sem isso, a sugestão não pode ser demonstrada de verdade.
3. **Azure DevOps/Test Plans** — projeto, licenças e professor ADMIN. Sem isso, QA e DevOps não pontuam integralmente.
4. **Azure** — assinatura/créditos e autorização de custos. Sem isso, não há deploy/banco cloud.
5. **Firebase/Android** — conta, tester e toolchain de build. Sem isso, não há APK publicado.
6. **GitHub público Java** — autorização de publicação. Sem isso, a entrega Java fica incompleta.

## 4. Perguntas a confirmar com os professores

1. Consumir as duas APIs no mesmo app satisfaz simultaneamente .NET (p. 23) e Java (p. 62), considerando a alternativa “Java ou .NET” de Mobile (p. 81)?
2. .NET será avaliado online ou presencial? A divergência entre p. 16/22 e p. 28 precisa de confirmação.
3. O CRUD de histórico pode ser demonstrado por criação/consulta imutável, ou o professor espera update/delete?
4. O cancelamento lógico atende ao requisito de “excluir” do Mobile?
5. Quais tabelas técnicas contam no CRUD de duas tabelas do DevOps?
6. Qual formato final de Banco (ZIP+TXT é exemplo entre colchetes) e de QA/DevOps?
7. Qual acesso/licença de Test Plans está disponível sem custo?
8. Qual versão/ambiente Oracle será usado e como o professor acessará as evidências?
9. Qual provedor de IA é aceitável e há limite de custo?
10. O APK pode ser construído localmente ou exige EAS? Como o professor receberá o tester no Firebase?

## 5. Critérios para reabrir uma decisão

Reabrir ADR se: um requisito do PDF for interpretado de forma diferente; um teste real mostrar incompatibilidade; o professor exigir outro formato; o custo/acesso externo inviabilizar a escolha; ou o prazo exigir redução de escopo. Registrar a mudança em [arquitetura](arquitetura.md) e atualizar contratos, backlog e testes afetados. Não trocar tecnologia silenciosamente.
