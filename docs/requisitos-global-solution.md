# Matriz de rastreabilidade — Global Solution FIAP 2026/2

## Fonte, leitura e convenções

- Fonte única dos requisitos acadêmicos: `Enunciados/2TDS Fevereiro - Global Solution 2026-2.pdf`.
- Leitura realizada em 17/11/2026: **97/97 páginas**, com extração nativa do leitor de PDF e inspeção das imagens fornecidas, inclusive as telas das páginas 52–53 e 92–96. Não foi necessário instalar extrator ou OCR.
- As referências abaixo usam a **página física do PDF, começando em 1**, não o contador interno de slides de cada disciplina.
- SHA-256 do original: `D1FDFCD0B1AB5A86DC5C152D23C7FF6E3CD2696CFEC6CA10D57FC5CB3882AE1A`.
- O arquivo original foi preservado. Textos entre colchetes, exemplos e inconsistências editoriais do enunciado são sinalizados, não convertidos em regras inventadas.
- **O** = obrigatório; **C** = condicional à alternativa escolhida; **R** = recomendação/dica do PDF; **P** = escolha do projeto, não exigência literal.
- Pontos são os valores **brutos das respectivas rubricas**. Não somar uma rubrica de 100 com a apresentação de 100: a apresentação tem peso de 30%. DevOps e Banco já apresentam 70 pontos de entrega + 30 de apresentação. QA explicita a entrega com peso de 70%; confirmar com os professores a aplicação dos pesos e descontos nas demais disciplinas.
- **Situação inicial de todos os requisitos de implementação, testes, publicação e entrega: planejado, não implementado/não comprovado.** A existência desta matriz não concede pontos nem substitui evidências.
- A coluna “Destino/evidência planejada” permite relacionar o requisito a componente, teste, captura e entregável futuro. Acrescentar depois IDs reais do Boards/Test Plans e caminhos de evidências, sem inventá-los.

## 1. Regras gerais e resumo do desafio

CityTech se enquadra em zeladoria colaborativa, expressamente citada na p. 8. A proposta deve demonstrar benefício concreto ao cidadão, contexto real, impacto mensurável e uma única solução coerente nas sete disciplinas.

| ID | Tipo | Requisito/condição | Página | Destino/evidência planejada |
|---|---|---|---|---|
| GER-01 | O | Resolver problema real CitizenTech, com cidadão no centro e benefício concreto | 3–7 | README, justificativa do problema, demonstração |
| GER-02 | O | Explicar cidadão beneficiado, problema, funcionamento, tecnologias, ecossistema, medição e ampliação do impacto | 7 | Documentação de produto e pitch |
| GER-03 | O | Identificar ODS e explicar contribuição às metas | 11 | Arquitetura e pitch; ODS 11 proposto |
| GER-04 | O | Mesma solução serve de base às sete disciplinas | 21 | Monorepositório e contratos comuns |
| GER-05 | O | Individual ou grupo de até cinco, permitido reunir turmas e turnos | 13–14 | Identificação do grupo |
| GER-06 | O | Cadastrar grupo até 13/11, com RM, nome completo e turma | 12, 14–15 | Confirmar cadastro; fora do prazo o grupo não aparece no portal |
| GER-07 | O | Entrega em **19/11/2026 até 23h55**, Portal do Aluno, sem prorrogação | 2, 12, 15 | Comprovantes das sete entregas |
| GER-08 | O | Cada ZIP deve conter TXT com RM, nome completo e turma de cada integrante | 15 | Empacotamento por disciplina |
| GER-09 | O | Apresentações em 23–27/11 na aula da disciplina; peso de 30%; participação de todos pode ser definida pelo professor | 12, 16 | Roteiros e divisão da defesa |
| GER-10 | O/R | Uso de IA deve ser compreendido/revisado e declarado; p. 17 apresenta exemplos entre colchetes | 17 | Declaração no README; Java a exige explicitamente na p. 66 |
| GER-11 | O | Acessar Portal → Aulas → Entrega de Trabalhos, selecionar cada disciplina, conferir grupo/prazo/descrição, anexar e conferir arquivo enviado | 92–96 | Sete comprovantes, arquivos reabertos após envio |
| GER-12 | Contexto | GS corresponde a 60% da nota do semestre; kickoff em 04/11; correção até 30/11 | 2, 12 | Planejamento acadêmico |
| GER-13 | C | Premiação: nota ≥90 em todas as disciplinas e no pitch de Java; comissão escolhe um vencedor | 18, 68 | Meta adicional, não condição de entrega |
| GER-14 | R | Observar território, ouvir usuários, prototipar/testar hipóteses; fontes UN-Habitat, FAO, PNUD, ONU | 5, 10 | Fundamentação com fontes reais |
| GER-15 | Contexto | Professores disponíveis nas aulas presenciais/remotas; não haverá chamada durante a GS | 19 | Resolver dúvidas da seção 10 |

Páginas 1 e 97 abrem/encerram o tema; 8–9 são inspirações, não funcionalidades obrigatórias; 20 e 22/29/36/54/61/70/77 são divisórias. Nenhuma delas estabelece uma stack adicional.

## 2. Advanced Business Development with .NET

Escopo: p. 22–28. Prazo/canal: GER-07. Responsável técnico: `backend-dotnet/`.

| ID | Tipo | Requisito | Página | Pontos (p. 25) | Destino/evidência planejada |
|---|---|---|---|---:|---|
| NET-01 | O | Backend CitizenTech .NET consumido pelo app Mobile, funcionalidade de valor ao cidadão | 23 | Sem item isolado | Mobile → contas/acompanhamentos .NET |
| NET-02 | O | ASP.NET e persistência EF Core ou Dapper; p. 23 admite Web API/Minimal, p. 24 e rubrica especificam **Minimal APIs** | 23–25 | Parte dos 20 | Minimal API + EF Core, arquitetura justificada |
| NET-03 | O | API RESTful funcional, endpoints, validações e códigos HTTP adequados | 24–25 | 20 compartilhados com NET-04 | Swagger e requisições válidas/inválidas |
| NET-04 | O | OpenAPI e Swagger interativo com parâmetros, contratos de entrada/saída e respostas | 24–25 | Incluído em NET-03 | Documento OpenAPI e interface Swagger |
| NET-05 | O | JWT com autenticação, autorização, proteção de endpoints e validação de tokens | 24–25 | 20 | Casos 401/403, cidadão/gestor |
| NET-06 | O | Idempotência: requisições repetidas sem duplicação/efeitos colaterais | 24–25 | 15 | Repetição, concorrência e consulta ao banco |
| NET-07 | O | Rate Limiting com recursos ASP.NET Core e resposta HTTP 429 | 24–25 | 15 | Teste determinístico do limite |
| NET-08 | O | Testes unitários de regras e integração dos endpoints com xUnit.net | 24–25 | 20 | Resultados xUnit e CI |
| NET-09 | O | Health Checks da API, banco e serviços externos utilizados | 24–25 | 10 | API saudável/degradada; dependência Java quando usada |
| NET-10 | O | GitHub com README; ZIP com link do GitHub e TXT de identificação | 27 | Entrega | Link acessível e ZIP validado |
| NET-11 | C | PowerPoint da apresentação “se houver” | 27 | Não isolado | Slides opcionais |

**Penalidades — p. 26:**

| ID | Ocorrência | Consequência |
|---|---|---|
| NET-P01 | Fora do prazo ou Portal | −30 |
| NET-P02 | Arquivo corrompido, incompleto ou sem TXT de identificação | −100 |
| NET-P03 | Sem relação com CitizenTech | −100 |
| NET-P04 | API não executa/falhas impedem uso | −20 |
| NET-P05 | Sem organização mínima, código não estruturado ou credenciais expostas | −20 |

**Apresentação — p. 28, peso 30%:** funcionamento (20), perguntas sobre estrutura (20), descrições/critérios de design (20), fluxos principais (20), explicar componentes .NET (10), relação com o tema (10). Total bruto 100. O título diz **online**, divergindo da regra geral; confirmar modalidade. Janela indicada: 23–27/11.

## 3. Compliance, Quality Assurance & Tests

Escopo: p. 29–35. Prazo/canal: GER-07. Destino: `qa/` e projeto Azure DevOps.

| ID | Tipo | Requisito | Página | Pontos (p. 32) | Destino/evidência planejada |
|---|---|---|---|---:|---|
| QA-01 | O | Backlog com Epics, Features e Product Backlog Items | 30–32 | 20 | Boards, processo Scrum, hierarquia real |
| QA-02 | O | Descrição e critérios de aceite de cada Feature **e PBI** nos padrões da aula | 30–31 | 20 para Features | Capturas de cada Feature/PBI; não omitir PBI |
| QA-03 | O | Todos os testes funcionais de sistema necessários à homologação, positivos/negativos, caixa-preta, por Feature | 30–32 | 20 | Test Cases ligados às Features |
| QA-04 | O | Sumário de cada teste: objetivo, preparação, inputs e outputs esperados | 30–32 | 20 | Captura do Summary |
| QA-05 | O | Passos com ações do testador e respostas esperadas do sistema | 30–32 | 20 | Captura de Steps |
| QA-06 | O | Usar ferramentas/métodos da aula; p. 31 menciona Azure DevOps/Excel, mas entrega exige Azure DevOps | 31, 33–34 | Condição | Confirmar padrão da turma; Excel só como apoio |
| QA-07 | O | PDF com link Azure Boards e professor como ADMIN; print do Backlogs e de cada descrição/aceite de Feature e PBI | 34 | Entrega | PDF do planejamento |
| QA-08 | O | No **mesmo PDF**, print do Boards com Test Cases por Feature e Summary/Steps de cada caso | 34 | Entrega | PDF de planejamento + testes |
| QA-09 | O | ZIP com esse PDF e TXT de identificação | 34 | Entrega | PDF também protege a correção de falhas de acesso |
| QA-10 | O | Executar testes manuais no Azure Test Plans e apresentar relatórios analíticos | 35 | Apresentação | Plano, execuções reais e resultados |

**Entrega:** total bruto 100 com peso explícito de 70% (p. 32).

**Penalidades — p. 33:** QA-P01 fora do prazo/Portal −10; QA-P02 arquivo corrompido/incompleto/sem TXT −10; QA-P03 fora de CitizenTech **zero**; QA-P04 não usar ferramenta e métodos da aula **zero**.

**Apresentação — p. 35, presencial 23–27/11, peso 30%:** operar Azure DevOps (20), estrutura do projeto (20), descrições/critérios Feature/PBI (20), operar Test Plans executando testes manuais (20), relatórios analíticos (20). Total bruto 100.

LGPD genérica **não substitui** backlog, Test Cases, Test Plans ou PDF. Não há exigência de um documento LGPD independente nesta seção do enunciado.

## 4. DevOps Tools & Cloud Computing

Escopo: p. 36–53. Prazo/canal: GER-07. Destinos: `devops/`, `/scripts`, `/dockerfiles` e, futuramente, `/azure-pipeline.yml`.

| ID | Tipo | Requisito | Página | Destino/evidência planejada |
|---|---|---|---|---|
| DEV-01 | O | Implantar em nuvem a solução de **Java OU .NET** usando Boards, Repos e Pipelines | 37 | Seleção inicial: .NET + Azure SQL |
| DEV-02 | O | Provisionar recursos via **scripts Azure CLI**; build/release usam os recursos criados | 37–38 | Scripts versionados e recursos no Portal |
| DEV-03 | O | Novo projeto Azure DevOps; professor com acesso **Basic** na organização e **Project Administrators** no projeto | 38, 52–53 | Convite e permissões; confirmar e-mail da turma |
| DEV-04 | O | Projeto privado, Git, código-fonte no Azure Repos | 38, 40 | Repositório privado e histórico |
| DEV-05 | O | Tarefa inicial no Boards vinculada a commits, branches e PRs | 39–40 | Links de desenvolvimento da tarefa |
| DEV-06 | O | Main protegida: revisor obrigatório, Work Item vinculado e revisor padrão (RM) | 40 | Políticas da branch |
| DEV-07 | O | CI YAML ou Classic; automática na principal **somente após merge por PR** | 39–40 | Trigger em main; políticas impedem push direto |
| DEV-08 | O | Publicar artefato/pacote e resultados de testes; testes automáticos no CI | 39, 42 | Artefatos e relatório real |
| DEV-09 | O | Release/deploy automático após novo artefato da CI | 39–40 | CD dependente da CI bem-sucedida |
| DEV-10 | C | Deploy em container ACI/ACR **ou** Serviço de Aplicativo | 41 | App Service proposto |
| DEV-11 | O/C | Banco em container ACI/ACR **ou** PaaS Azure SQL/Oracle | 41 | Azure SQL proposto; localhost não serve |
| DEV-12 | O | Scripts de infraestrutura no repo; Azure CLI em `/scripts` | 41 | Scripts futuros reais |
| DEV-13 | O | `/scripts/script-bd.sql` com DDL dos objetos de banco | 41 | DDL .NET exportado/validado; ainda não criado |
| DEV-14 | C | Dockerfiles em `/dockerfiles` se usar Docker na solução avaliada | 41 | Reservado; definir escopo com professor |
| DEV-15 | C | Arquivo **`azure-pipeline.yml`** na raiz se YAML | 42 | Nome literal exigido; criar com CI/CD real |
| DEV-16 | C | CRUD JSON no README e arquivos JSON por tabela para API sem Swagger | 42, 48 | Swagger planejado; JSON condicional |
| DEV-17 | O | Variáveis de ambiente nas pipelines; sem senhas expostas | 42, 49 | Configuração e secrets externos |
| DEV-18 | O | Desenho macro com fluxo e legenda | 42, 45 | Diagrama de arquitetura |
| DEV-19 | Permissão | Aluno pode aprovar a própria PR na simulação | 40 | Não é obrigação de autoaprovação |
| DEV-20 | O | Pelo menos duas tabelas; CRUD e persistência demonstrados em nuvem | 43, 48–49 | Contas/acompanhamentos; SQL SELECT, não apenas GET |

**Pontuação — p. 45:** arquitetura macro 10; Boards/Repos 10; Build 25; Release 25. Total **70 pontos**.

### Vídeo obrigatório e evidências

| ID | Tipo | Item | Página |
|---|---|---|---|
| DEV-V01 | O | YouTube; resolução mínima 720p; áudio claro; explicação narrada por voz, legendas não substituem narração | 43, 47–48, 50 |
| DEV-V02 | O | Mostrar README, conceito e arquitetura; recursos criados pelos scripts no Portal Azure | 43 |
| DEV-V03 | O | Criar tarefa no Boards, branch nova e alteração **no código-fonte**, não README | 43, 49 |
| DEV-V04 | O | Merge na Main; execução completa automática de Build + Release; artefatos/pacote/testes publicados | 43 |
| DEV-V05 | O | Comprovar alteração publicada na nuvem | 43 |
| DEV-V06 | O | CRUD de pelo menos duas tabelas; p. 48 cobra operações de **cada tabela** diretamente no banco e persistência por SELECT | 43, 48 |
| DEV-V07 | O | Encerrar com tarefa concluída e links commits/PR | 43 |
| DEV-V08 | R | Gravação contínua, sem cortes, resultados diretamente no banco; assistir ao vídeo já publicado antes da entrega | 44 |

Não foi definido limite de duração do vídeo DevOps. O limite de 5 minutos de Java/Mobile não deve ser transferido para ele.

### Penalidades

| ID | Ocorrência | Página | Consequência literal |
|---|---|---|---|
| DEV-P01 | Sem código-fonte no repositório | 46 | −70 |
| DEV-P02 | Sem azure-pipeline.yml quando YAML | 46 | −70 |
| DEV-P03 | Aplicativo ou banco em localhost, sem nuvem | 46 | −70 |
| DEV-P04 | Sem acesso a qualquer um de Boards, Repos ou Pipelines | 46 | −70 |
| DEV-P05 | Sem Azure DevOps | 46 | −70 |
| DEV-P06 | Plágio/cópia entre equipes | 47 | Texto: zero para envolvidos; coluna: −70 |
| DEV-P07 | Fora de data/horário | 47 | Não corrigido; coluna: −70 |
| DEV-P08 | Sem narração, ou legendas substituindo voz | 47 | −30 |
| DEV-P09 | Sem script-bd.sql | 47 | −10 |
| DEV-P10 | Sem Dockerfiles quando containerizado | 47 | −30 |
| DEV-P11 | Sem JSONs CRUD por tabela quando sem Swagger | 48 | −10 |
| DEV-P12 | Sem scripts Azure CLI | 48 | −30 |
| DEV-P13 | Item obrigatório omitido no vídeo | 48 | −20 por item |
| DEV-P14 | Vídeo abaixo de 720p ou áudio sem clareza | 48 | −30 |
| DEV-P15 | Falta de qualquer operação CRUD de cada tabela diretamente no banco em nuvem; GET não prova persistência | 48 | −30 |
| DEV-P16 | Sem variáveis de ambiente ou senha desprotegida no código | 49 | −20 |
| DEV-P17 | Main sem políticas de proteção | 49 | −20 |
| DEV-P18 | Não criar branch para tarefa | 49 | −10 |
| DEV-P19 | Apenas uma tabela | 49 | −30 |
| DEV-P20 | Alteração simulada só no README | 49 | −20 |
| DEV-P21 | Falta da pasta scripts ou dockerfiles quando Docker | 49 | −10 |
| DEV-P22 | Sem testes automáticos no CI | 49 | −20 |

**Entrega — p. 50:** PDF chamado com grupo e RM do representante (exemplo `Grupo1_rm9999.pdf`), capa com grupo/RMs/nomes completos, link da organização Azure DevOps e vídeo YouTube. Não converter automaticamente em ZIP: a regra específica pede PDF.

**Apresentação — p. 51, presencial 23–27/11:** aplicação funcionando 10, arquitetura 10, perguntas de construção/uso do Azure DevOps 10; total **30 pontos**.

## 5. Disruptive Architectures: IoT, IoB & Generative IA

Escopo: p. 54–60. Prazo/canal: GER-07. Destinos: `ai/` e implementação Spring AI futura em `backend-java/`.

| ID | Tipo | Requisito | Página | Pontos (p. 57) | Evidência planejada |
|---|---|---|---|---:|---|
| IA-01 | O | Funcionalidade, público e benefício CitizenTech definidos | 55–56 | 10 | Classificação assistida de ocorrências |
| IA-02 | O | Modelo generativo funcionando no fluxo da aplicação, API ou local | 55–56 | 25 | App → Java → LLM → sugestão revisável |
| IA-03 | O/Escolha | Aprofundamento em RAG básico, ML, DL **e/ou** visão; justificar escolha, não precisa usar todos | 55–56 | 25 | **RAG básico** proposto, recuperação demonstrada |
| IA-04 | O | Fontes, preparação de dados e fluxo aplicação/modelos/serviços | 56 | 15 | Corpus versionado e diagrama |
| IA-05 | O | Testar entradas representativas e falhas, métricas/critérios adequados e interpretação | 56–57 | 15 | Casos rotulados, resultados reais, análise |
| IA-06 | O | Código, execução reproduzível, proteção de credenciais/dados pessoais e limitações explícitas | 56 | 10 | README, exemplos sem segredos |
| IA-07 | O | GitHub com fontes, dependências, configurações e materiais; README com integrantes, funcionalidade, execução, modelos, justificativas e diagrama | 59 | Entrega | Seção IA acessível no monorepo |
| IA-08 | O | Dados ou acesso às fontes, casos, resultados, métricas/critérios e limitações | 59 | Evidências | `ai/evaluation/` |
| IA-09 | O | Enviar **APENAS TXT** com RM/nome completo e link GitHub | 59 | Formato | TXT específico da disciplina |

**Penalidades — p. 58:** IA-P01 fora do prazo/Portal **zero**; IA-P02 arquivo corrompido ou links inacessíveis que impeçam avaliação **zero**; IA-P03 identificação ausente/incompleta −10; IA-P04 fora do tema −40; IA-P05 credenciais/dados pessoais sem cuidados −10. Requisito não atendido perde seus pontos **sem desconto adicional pelo mesmo motivo**.

**Apresentação — p. 60, peso 30%, data a alinhar com professor:** funcionamento integrado 25; domínio de arquitetura/fluxo/limitações 25; explicar adaptação a mudança proposta 25; participação dos integrantes 25. Total bruto 100.

IoT físico, sensores, Python, treinamento próprio e GPU não são exigidos por este enunciado. RAG é a escolha CityTech dentre os aprofundamentos permitidos; **usar só LLM sem aprofundamento não atende IA-03**.

## 6. Java Advanced

Escopo: p. 61–69. Prazo/canal: GER-07. Destino: `backend-java/`.

| ID | Tipo | Requisito | Página | Pontos (p. 64) | Evidência planejada |
|---|---|---|---|---:|---|
| JAV-01 | O | Backend Java com Spring Boot, Spring Data JPA, Spring Security/JWT e Spring AI | 62 | Distribuído abaixo | Dependências e execução |
| JAV-02 | O | Ao menos **3 entidades relacionadas**, CRUD JPA e paginação | 63 | 20 | Categoria, Ocorrência, Histórico; CRUDs/documentação |
| JAV-03 | O | Bean Validation nos DTOs, tratamento global com `@RestControllerAdvice`, respostas padronizadas | 63 | 10 | Testes de validação e erros |
| JAV-04 | O | JWT e pelo menos dois papéis, endpoints protegidos por papel | 63 | 20 | CIDADÃO/GESTOR, 401/403 e autorização por proprietário |
| JAV-05 | O | Spring AI com LLM integrado ao fluxo; não chat genérico desconectado | 62–63 | 20 | Classificação assistida no Mobile |
| JAV-06 | O/Escolha | **A:** RabbitMQ/Kafka, evento publicado e consumido assincronamente; **e/ou B:** ≥2 microsserviços, Eureka e OpenFeign/RestClient/WebClient | 63 | 20 | Escolha A: RabbitMQ, prova de produtor + consumidor |
| JAV-07 | O | Swagger/OpenAPI, README de execução e API consumida pelo Mobile | 62–63 | 10 | CRUD Mobile Java e evidência HTTP |
| JAV-08 | O | **GitHub público**; README com execução, usuários de teste, endpoints, opção distribuída, deploy se houver, declaração IA | 66 | Entrega | Publicação futura depende de autorização |
| JAV-09 | O | ZIP com identificação, link repo e link pitch | 66 | Formato | ZIP validado |
| JAV-10 | O | Pitch até 5 minutos; excedente não avaliado; YouTube público/não listado ou Drive aberto; testar acesso anônimo | 66, 68 | Sem divisão específica | Vídeo funcionando, link na entrega Java |
| JAV-11 | R | Roteiro do pitch: problema com dado/evidência, solução, demo real, negócio/ecossistema/sustentação/escala, impacto/ODS | 69 | Orientação de defesa | Roteiro até 5 min |

**Penalidades — p. 65:** JAV-P01 fora do prazo/Portal −100; JAV-P02 arquivo corrompido/incompleto/sem TXT −10; JAV-P03 fora do tema −40; JAV-P04 não compila/sobe seguindo README −30; JAV-P05 problema grave de segurança/arquitetura −10 **por ocorrência**.

**Apresentação — p. 67, presencial 23–27/11, peso 30%:** ponta a ponta com Mobile 20; modelagem/relacionamentos 15; JWT 20; Spring AI 15; arquitetura distribuída escolhida 15; benefício cidadão 15. Total bruto 100.

RabbitMQ não é universalmente obrigatório; passa a ser necessário **pela alternativa A escolhida**. Dois backends Java/.NET por si só não substituem as condições da alternativa B. Deploy Java não é exigência isolada de p. 66, mas disponibilidade do backend durante avaliação Mobile é obrigatória (p. 81).

## 7. Mastering Relational and Non-Relational Database

Escopo: p. 70–76. Prazo/canal: GER-07. Destinos: `database/oracle/` e `database/mongodb/`.

| ID | Tipo | Requisito | Página | Pontos (p. 73) | Evidência planejada |
|---|---|---|---|---:|---|
| DB-01 | O | Oracle: ≥2 tabelas relacionadas, dados de teste e **2 blocos PL/SQL** com decisão, repetição ou cursor | 71–72 | 10 | DDL/INSERT/blocos executados |
| DB-02 | O | **2 funções e 2 procedimentos PL/SQL** com regras reais da solução | 72 | 15 | Código e execução, entradas/saídas |
| DB-03 | O | **2 gatilhos**, ≥1 de auditoria com data/operação/valores antigo e novo | 72 | 10 | DML e SELECT da auditoria |
| DB-04 | O | Funções/procedimentos em ≥**2 pacotes**, specification/body, com testes | 72 | 10 | Scripts de pacote e testes |
| DB-05 | O | MongoDB: selecionar/criar database, **2 collections**, ≥**10 documentos no total** | 72 | 10 | `.js` reproduzível e contagens |
| DB-06 | O | Mapa relacional→documental, **3 consultas MongoDB, ≥1 agregação**, resultados equivalentes/comparados | 71–72 | 15 | Mapeamento de IDs, resultados lado a lado |
| DB-07 | O | Justificar referências versus documentos incorporados e correspondência Oracle/Mongo | 71 | Parte de DB-06 | Documento de modelagem |
| DB-08 | O | Oracle `.sql`: DDL, INSERT, blocos, funções, procedimentos, triggers, pacotes e testes | 75 | Entrega | Scripts ordenados |
| DB-09 | O | Mongo `.js`: use/seleção DB, createCollection, insertMany, find, aggregate e dados exemplo | 75 | Entrega | Execução pelo mongosh |
| DB-10 | O | README/PDF: problema, mapeamento, três relatórios, evidências e execução | 75 | Entrega | Documentação reproduzível |
| DB-11 | Exemplo | Formato indicado como **“[ex.: um .zip com o código-fonte e o .txt de identificação do grupo]”** | 75 | Confirmar | Planejar ZIP+TXT; validar descrição do Portal |

Total entrega: **70 pontos**. **Integração automática Oracle↔MongoDB não é exigida** (p. 71); scripts e comparação são suficientes.

**Penalidades — p. 74:** DB-P01 fora do prazo/Portal −50; DB-P02 corrompido/incompleto/sem TXT até 20; DB-P03 fora do tema **zero**; DB-P04 objetos Oracle/scripts Mongo não executam até 50; DB-P05 relatórios sem resultados/transição não explicada até 30. “Até” não significa desconto fixo.

**Apresentação — p. 76, presencial 23–27/11:** problema/modelagem Oracle 5; executar função/procedimento 5; trigger/auditoria/pacotes 5; criar collections/inserir documentos 5; três relatórios e comparação Oracle 5; justificar transição/perguntas 5. Total **30 pontos**.

## 8. Mobile Application Development

Escopo: p. 77–91. Prazo/canal: GER-07. Destino: `mobile/`.

| ID | Tipo | Requisito | Página | Pontos (p. 87) | Evidência planejada |
|---|---|---|---|---:|---|
| MOB-01 | O | Aplicativo **React Native** | 78 | Base | Expo/React Native |
| MOB-02 | O | ≥**6 telas distintas**, navegação React Navigation ou Expo Router, fluidez/usabilidade/acessibilidade | 79–80 | 10 | Seis telas úteis + Sobre separada |
| MOB-03 | O | CRUD completo via API **Java ou .NET**, Axios ou Fetch, persistência backend e tratamento de erro/feedback/loaders | 79, 81 | 30 | CRUD ocorrências Java + acompanhamento .NET |
| MOB-04 | O | Backend **ativo durante o período de avaliação** | 81 | Condição | URLs acessíveis no APK pelo professor |
| MOB-05 | O | Cadastro, login real, logout limpando sessão/bloqueando rotas, formulários validados, erros/loaders | 82 | 20 | JWT pela API .NET; Firebase Auth seria alternativa |
| MOB-06 | O | Cores, fontes, imagens personalizadas; design consistente e guidelines Apple/Google | 79, 83 | 5 | Identidade CityTech e arquivos próprios |
| MOB-07 | O | Organização por responsabilidade, nomes claros, formatação, lint/formatter e bibliotecas atuais/justificadas | 79, 84 | 20 | Estrutura, ESLint/Prettier e revisão |
| MOB-08 | O | Vídeo de todas as funcionalidades, app real em dispositivo/emulador, ≤5 minutos, YouTube público/não listado | 79, 85 | 10 | Autenticação, navegação, CRUD e usabilidade |
| MOB-09 | O | Link vídeo no TXT de entrega e no README | 85 | Parte de MOB-08 | Links conferidos |
| MOB-10 | O | Publicação no **Firebase App Distribution**, professor como tester | 79, 86 | 5 | APK distribuído e convite |
| MOB-11 | O | Tela **Sobre o App** com hash do commit de referência; versão publicada exatamente igual ao fonte enviado | 86 | Parte de MOB-10 | Commit compilado no artefato; Sobre não conta nas 6 telas |
| MOB-12 | O | GitHub com professor leitor/colaborador; README; histórico Git coerente, sequencial e evolutivo | 88, 90 | Condição | Commits reais incrementais e acesso |
| MOB-13 | O | Entrega **TXT** com grupo, integrantes, link vídeo e GitHub | 90 | Formato | Acrescentar RM/turma para identificação geral |
| MOB-14 | Opcional | Narração do vídeo | 85 | Não isolado | Pode narrar; clareza obrigatória |

Total entrega: rubrica bruta 100. Firebase App Distribution é exigência; **Expo Go/QR code/EAS Update isolados não a atendem**.

### Penalidades

| ID | Ocorrência | Página | Desconto |
|---|---|---|---:|
| MOB-P01 | Fora do prazo/Portal | 88 | 30 |
| MOB-P02 | Corrompido/incompleto/sem identificação TXT | 88 | 30 |
| MOB-P03 | Fora do tema | 88 | 30 |
| MOB-P04 | Sem GitHub ou professor sem acesso leitor/colaborador | 88 | 20 |
| MOB-P05 | Sem README | 88 | 10 |
| MOB-P06 | App fora do escopo das aulas | 88 | 60 |
| MOB-P07 | Histórico Git incoerente/confuso, sem construção real e envolvimento prático | 88 | 50 |
| MOB-P08 | Não publicar ou publicação diferente do código | 89 | 20 |
| MOB-P09 | Menos de seis telas | 89 | 30 |
| MOB-P10 | Sem estilização/visual incompatível | 89 | 20 |
| MOB-P11 | Sem link YouTube | 89 | 20 |

**Apresentação — p. 91, presencial 23–27/11, peso 30%:** domínio técnico 30; fundamentação das decisões 30; adaptação a mudança 20; domínio compartilhado/colaboração 20. Total bruto 100.

## 9. Integrações e o que não confundir com obrigação

| Assunto | Exigência efetiva | Decisão CityTech |
|---|---|---|
| Backend do Mobile | .NET p. 23 e Java p. 62 exigem consumo; Mobile p. 81 permite um ou outro | Consumir ambos diretamente; confirmar divisão funcional com docentes |
| IA | Generativa + um aprofundamento p. 55–56; Spring AI em Java p. 62–63 | Uma funcionalidade reutilizada pelas duas disciplinas; RAG |
| Distribuído Java | Opção A ou B p. 63 | RabbitMQ A; Eureka não necessário nesta escolha |
| Banco | Oracle e Mongo obrigatórios p. 71–72 | Oracle operacional Java; Mongo snapshot acadêmico |
| PostgreSQL | Não exigido; PaaS citado por DevOps é Azure SQL ou Oracle p. 41 | Retirado da base inicial |
| .NET ORM | EF Core **ou** Dapper p. 23 | EF Core escolhido |
| TypeScript/Expo/Axios | React Native obrigatório; roteamento e cliente têm alternativas p. 79–81 | Expo + TypeScript + Expo Router + Axios |
| Docker/Compose | Docker condicional à estratégia de deploy; Compose não exigido | Infra local verificada na Etapa 3A; não comprova requisitos de deploy/integração |
| Python/GPU/sensores | Não exigidos | Dispensados para o RAG Java planejado |
| Fotos/mapas/GPS/push | Não constam como obrigação específica | Fotos opcionais do produto; mapa/GPS/push fora da prioridade inicial |
| Segurança/LGPD | Proteção de dados/credenciais transversal e específica em algumas rubricas | Boas práticas com dados fictícios; não substituem QA |

## 10. Divergências e perguntas acadêmicas pendentes

1. **Integração Mobile dupla** (23, 62 versus 81): confirmar que domínios distintos consumidos pelo mesmo app satisfazem ambos os backends; não assumir dispensa de .NET.
2. **.NET Minimal versus Web API** (23–25): adotar Minimal, que atende a formulação mais específica.
3. **.NET online versus presencial** (16, 22, 28): confirmar com o professor.
4. **Formatos**: p. 15 orienta TXT em ZIP; IA p. 59 pede somente TXT, Mobile p. 90 TXT e DevOps p. 50 PDF. Aplicar instrução específica, confirmar Portal; Banco p. 75 é exemplo entre colchetes.
5. **CRUD DevOps**: p. 43 pede ≥2 tabelas; p. 48 penaliza falta em qualquer tabela. Planejar demonstração de todas as tabelas de negócio da solução escolhida e perguntar sobre tabelas técnicas (migrações/idempotência/auditoria).
6. **CI por commit versus só após PR** (39–40): trigger em main + políticas de PR, sem push direto. Não disparar a CI avaliada nas feature branches.
7. **GitHub público Java versus Azure privado** (40, 66): usar dois remotos com o mesmo histórico; Azure é a origem de colaboração; publicação GitHub depende de autorização do usuário.
8. **QA Azure/Excel** (31 versus 34–35): entregar Azure Boards/Test Plans e PDF; confirmar padrões da aula, acesso/licença Test Plans e e-mails.
9. **Datas**: em 17/11 o cadastro de 13/11 já encerrou. Confirmar situação sem presumir que o grupo esteja cadastrado.
10. **Pesos**: esclarecer como rubricas de 100, pesos de 70/30 e descontos são aplicados; não prometer notas.
11. **Slides com restos de modelo**: p. 17 traz exemplos; p. 26/46–49/74 têm frases de instrução editorial; p. 86 repete o bloco de vídeo de p. 85. O requisito de Firebase/hash está explícito e permanece válido.
12. **Oracle e materiais de aula**: obter ambiente/versão e confirmar regras de avaliação de objetos dentro de pacotes e do CRUD de histórico com trilha imutável.

## 11. Registro futuro de comprovação

Para cada ID acima, adicionar ao backlog: responsável, Work Item, aceite, Test Case, evidência, commit/release e situação (`planejado`, `em desenvolvimento`, `verificado`, `entregue`). Somente marcar verificado após execução real. Datas, notas e acessos externos não foram confirmados em contas nesta etapa.
