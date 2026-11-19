# IA — classificação assistida com RAG

**Estado: pipeline local implementado; modelo real ainda não configurado/chamado.** Requisitos IA-01 a IA-09 e JAV-05. Fluxo assíncrono e sugestão revisável definidos na Etapa 3B em [backlog](../docs/backlog.md), [contrato do evento](../docs/contratos-api.md#6-contrato-do-evento-rabbitmq) e [integração Mobile](../docs/integracao-mobile.md#7-fluxo-de-ia).

Benefício: reduzir esforço de triagem de problemas urbanos sugerindo categoria, prioridade e resumo compreensível. A decisão final será humana.

O código Spring AI ficará no backend Java; esta área organiza corpus, justificativas e avaliação. Não criar outro microserviço Python apenas para separar a disciplina.

- [Corpus](corpus/README.md): taxonomia e critérios de demonstração com fontes/versões.
- [Avaliação](evaluation/README.md): casos rotulados, critérios, resultados e limitações.

O backend Java inclui o corpus no JAR, recupera trechos versionados, monta prompt defensivo, chama um `ChatModel` Spring AI quando disponível, valida JSON/enums/fontes e persiste sugestão revisável. Sem `ChatModel`, registra `MODEL_NOT_CONFIGURED` e mantém fallback manual. O adaptador foi testado com modelo controlado, mas **nenhum resultado de LLM externo foi produzido**.

Modelo de chat, embeddings, provedor, autorização e orçamento ainda pendentes. A recuperação atual é lexical e reproduzível; a etapa acadêmica de RAG ainda precisa selecionar embeddings compatíveis, executar modelo real e registrar casos/métricas em [evaluation](evaluation/README.md). Não apresentar os testes controlados como inferência real.

A futura entrega IA é **apenas TXT** com identificação e link GitHub; README deve incluir execução, modelos, justificativa, diagrama e evidências de avaliação. Não atribuir resultados fictícios ao modelo.
