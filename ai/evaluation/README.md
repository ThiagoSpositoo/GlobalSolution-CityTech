# CityTech — Avaliação da Inteligência Artificial Generativa

## 1. Objetivo

Avaliar o uso de IA generativa na triagem assistida de ocorrências urbanas, verificando a classificação de categoria, a prioridade sugerida, a justificativa, a recuperação de conhecimento e a tolerância a falhas.

A IA fornece recomendações revisáveis. A decisão final permanece com um responsável humano.

## 2. Ambiente e arquitetura

- Linguagem: Java 21
- Framework: Spring Boot 4.1.2
- Integração LLM: Spring AI 2.0.2
- Provedor: Google Gemini
- Modelo testado: gemini-3.1-flash-lite
- Recuperação de conhecimento: RAG lexical com corpus local versionado
- Mensageria: RabbitMQ
- Persistência: Oracle Database
- Versão observada do prompt: rag-v1

O backend recupera informações do corpus, prepara o contexto para o modelo, solicita uma classificação estruturada e persiste a sugestão gerada. O processamento é assíncrono.

## 3. Metodologia

Os testes descritos abaixo correspondem a comportamentos efetivamente observados durante a execução local do CityTech.

Foram examinados dois cenários:

1. Execução sem modelo de linguagem disponível.
2. Execução com Gemini configurado e integração funcional.

Foram considerados:
- Estado final da sugestão.
- Categoria e prioridade propostas.
- Presença de justificativa.
- Referência à fonte recuperada.
- Registro de erro quando aplicável.
- Persistência do resultado no Oracle.

Não foi executada uma avaliação estatística com dataset rotulado de grande escala.

## 4. Resultados observados

### Caso 1 — Ausência de modelo configurado

Entrada: ocorrência fictícia relacionada a poste de iluminação apagado.

Resultado observado:
- O processamento não produziu uma classificação generativa válida.
- O sistema registrou o código MODEL_NOT_CONFIGURED.
- A falha foi representada explicitamente, em vez de apresentar uma classificação fictícia.

Interpretação: o mecanismo de fallback demonstrou capacidade de identificar indisponibilidade de configuração do modelo.

Limitação: esse cenário não mede qualidade de classificação.

### Caso 2 — Classificação real com Gemini

Entrada: ocorrência fictícia descrevendo buraco profundo em via pública.

Resultado observado:
- O evento foi processado pelo fluxo assíncrono.
- O Gemini foi acionado por meio do Spring AI.
- Categoria sugerida: VIAS.
- Prioridade sugerida: ALTA.
- Justificativa relacionada ao risco de acidentes.
- Fonte recuperada: citytech-corpus/prioridade.md#alta.
- Versão do prompt: rag-v1.
- Status persistido no Oracle: PRONTA.
- Código de erro: NULL.

Interpretação: a classificação foi coerente com o risco descrito no caso e demonstrou integração efetiva entre recuperação de contexto, modelo generativo, mensageria e banco de dados.

A classificação é uma recomendação e não substitui a avaliação humana.

## 5. Resumo quantitativo da execução observada

- Cenários documentados: 2.
- Cenários com inferência real bem-sucedida: 1.
- Cenários de fallback por ausência de modelo: 1.

Essas contagens descrevem apenas os cenários acima.

Não foram calculadas taxas de acurácia, precisão, recall ou latência média. Não há amostra representativa suficiente para estimar essas métricas.

## 6. Critérios para avaliação ampliada

Uma avaliação futura deverá utilizar ocorrências rotuladas por humanos, contemplando todas as categorias, diferentes níveis de prioridade, descrições ambíguas, dados incompletos e falhas de provedor.

Métricas propostas:
- Acurácia de categoria.
- Concordância de prioridade.
- Fidelidade do resumo à descrição original.
- Relevância dos documentos recuperados.
- Validade do formato estruturado.
- Taxa de falhas e comportamento de fallback.
- Latência de ponta a ponta.

Essas métricas são propostas, não resultados já medidos.

## 7. Limitações

A recuperação atual é lexical, sem busca vetorial por embeddings.

O corpus é relativamente pequeno e pode não representar toda a variedade de ocorrências urbanas.

O modelo pode sugerir prioridades inadequadas, produzir justificativas imprecisas ou falhar por indisponibilidade do provedor.

O sistema depende de infraestrutura externa e de configuração válida das credenciais. A decisão final deve ser humana.

## 8. Reprodutibilidade

1. Configurar Oracle, RabbitMQ e a aplicação Java conforme os READMEs do projeto.
2. Configurar a chave GEMINI_API_KEY no ambiente, sem publicá-la.
3. Habilitar o provedor Google GenAI no Spring AI.
4. Iniciar o backend Java e o processamento assíncrono.
5. Autenticar-se usando um JWT válido.
6. Criar uma ocorrência de teste pela API.
7. Consultar a sugestão gerada e seu registro no Oracle.
8. Conferir categoria, prioridade, justificativa, fonte recuperada e eventuais erros.

Não incluir tokens, senhas ou chaves privadas nas evidências.

## 9. Conclusão

Os testes observados demonstram viabilidade técnica do módulo de triagem assistida com Gemini, recuperação lexical de contexto, RabbitMQ e Oracle.

A integração funcional foi comprovada em um caso real de inferência, e o tratamento de ausência do modelo foi observado em outro cenário.

A qualidade geral da classificação ainda depende de avaliação com uma base maior de exemplos rotulados.
