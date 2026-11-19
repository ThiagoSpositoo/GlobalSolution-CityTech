# CityTech — manual permanente de desenvolvimento

## 1. Protocolo de início e retomada

1. Leia [docs/progresso.md](docs/progresso.md) antes de agir: etapa, última entrega, bloqueios, autorizações e próxima ação.
2. Confira os arquivos e o ambiente reais. Se Git estiver disponível e inicializado, examine `git status` e os diffs; preserve alterações do usuário. Diagnósticos antigos não comprovam o estado atual.
3. Consulte o [README](README.md), a [arquitetura](docs/arquitetura.md), a [matriz acadêmica](docs/requisitos-global-solution.md) e o [plano](docs/plano-desenvolvimento.md). Leia os documentos da área a alterar.
4. Trabalhe somente no escopo autorizado. A conclusão de uma etapa não autoriza automaticamente a seguinte.
5. Ao interromper ou concluir o trabalho, registre resultados e o ponto exato de retomada no progresso. Não dependa do histórico da conversa para transmitir decisões.

Este manual contém regras estáveis; **o progresso é a referência para o estado mutável**. Marco inicial em 17/11/2026: Etapa 1 concluída; próxima etapa é preparação do ambiente, ainda não iniciada nem autorizada. Sessões futuras devem consultar o progresso atualizado, sem perpetuar esse marco como estado atual.

## 2. Identidade, objetivo e escopo

**CityTech — Tecnologia que transforma cidades.** Plataforma CitizenTech de monitoramento colaborativo e zeladoria urbana para a Global Solution FIAP 2026/2, ADS.

- Cidadãos: cadastro, autenticação, registro/edição de ocorrências, endereço, fotos opcionais e acompanhamento.
- Problemas: vias/buracos, iluminação, acessibilidade, descarte irregular, água/vazamentos e outros.
- Gestores: consulta, triagem, atualização de status e indicadores.
- IA: sugestão de categoria, prioridade e resumo, sempre com supervisão humana.
- Dados fictícios de demonstração; nenhuma integração oficial com prefeituras.
- Identidade moderna, profissional e acessível, em azul, branco e verde. ODS 11 é a contribuição proposta, sem alegar impacto real não medido.

## 3. Fontes e regras gerais

- O PDF `Enunciados/2TDS Fevereiro - Global Solution 2026-2.pdf` prevalece para requisitos acadêmicos. Foi lido integralmente na Etapa 1; use a matriz e consulte as páginas originais quando houver dúvida ou mudança.
- Diferencie obrigação do PDF, condição da alternativa escolhida, recomendação e decisão do projeto. Não invente requisitos, notas, aprovações ou informações de páginas não verificadas.
- A matriz registra IDs, páginas, pontos, penalidades e divergências. Não a substitua por este resumo.
- Explique decisões importantes em português, de forma que um estudante de ADS consiga compreendê-las e defendê-las.
- Priorize entregas obrigatórias e integrações que desbloqueiam outras áreas. Evite dependências e abstrações sem necessidade.
- Preserve padrões existentes, separação de responsabilidades e contratos explícitos. Mudanças de arquitetura precisam de justificativa e atualização das decisões em `docs/arquitetura.md`.
- Registre falhas e limitações com transparência. “Planejado”, “implementado”, “verificado” e “entregue” são estados distintos.
- Mantenha histórico Git real e incremental quando disponível; nunca fabrique commits, testes, capturas ou evidências.

## 4. Arquitetura e tecnologias

| Componente | Base definida para planejamento | Responsabilidade |
|---|---|---|
| Java | Java 21, Spring Boot, JPA, Security/JWT, Spring AI, Swagger/OpenAPI, RabbitMQ | Ocorrências, categorias, histórico/status, gestão, indicadores e classificação IA; Oracle |
| .NET | .NET 10 LTS, ASP.NET Core Minimal API, EF Core, JWT, Swagger/OpenAPI, xUnit | Contas, autenticação e acompanhamentos; SQL Server local/Azure SQL futuro |
| Mobile | React Native, Expo, TypeScript, Expo Router, Axios | Experiência cidadão/gestor e consumo direto das duas APIs |
| Dados | Oracle/PLSQL, SQL Server/Azure SQL, MongoDB | Persistência por domínio e representação documental acadêmica |
| IA | Spring AI + modelo generativo + RAG básico | Recuperação de contexto, sugestão estruturada, revisão humana e avaliação |
| DevOps/QA | Git, Docker/Compose, Azure CLI, Boards, Repos, Pipelines e Test Plans | Histórico, ambiente, CI/CD, backlog e evidências |

Versões exatas propostas e fontes estão em [docs/versoes-e-fontes.md](docs/versoes-e-fontes.md). Elas **não representam compatibilidade validada por build**. Revalidar antes de instalar/gerar projetos e fixar versões nos manifests, wrappers e lockfiles apropriados. Não trocar silenciosamente de major.

PostgreSQL foi retirado da base planejada. Python, GPU, sensores e IDE específica não são necessários para o caminho escolhido. Maven Wrapper é preferível à instalação global de Maven.

## 5. Organização do monorepositório

A pasta atual é a raiz: não criar outra pasta CityTech dentro dela.

| Caminho | Conteúdo |
|---|---|
| `Enunciados/` | PDF original preservado; não publicar involuntariamente |
| `backend-java/` | API/worker Java; testes Maven em `src/test/java` quando criados |
| `backend-dotnet/` | Minimal API, persistência e projetos xUnit |
| `mobile/` | App, navegação, clientes HTTP, estilos e assets |
| `database/oracle/`, `database/mongodb/`, `database/sqlserver/` | Scripts e documentação de cada persistência |
| `ai/corpus/`, `ai/evaluation/` | Referências RAG e avaliações; integração executável fica no Java |
| `qa/` | Backlog, casos e evidências vinculados aos requisitos |
| `devops/`, `devops/pipelines/` | Runbooks e templates de infraestrutura/pipeline |
| `scripts/`, `dockerfiles/` | Caminhos exigidos por DevOps |
| `docs/` | Arquitetura, matriz, plano, ambiente, progresso, diagramas e entregas |

O futuro `scripts/script-bd.sql` deve refletir o modelo da API avaliada em DevOps. Se YAML for usado, o arquivo de entrada exigido é **`azure-pipeline.yml` na raiz**. Criar artefatos funcionais nas etapas correspondentes, sem arquivos vazios que aparentem entrega concluída.

## 6. Integrações e propriedade dos dados

- Mobile consome Java **e** .NET: as duas disciplinas exigem integração, embora Mobile permita uma ou outra. Manter fluxos observáveis de ambas e registrar a confirmação docente pendente.
- .NET é dono de contas, credenciais e acompanhamentos. Java é dono de ocorrências e suas regras. Não duplicar cadastro/senha nem manter duas ocorrências editáveis.
- Contrato JWT planejado: .NET assina assimetricamente; Java valida com chave pública. Validar assinatura, algoritmo, emissor, audiência, expiração, papéis e propriedade dos recursos.
- `sub` identifica o cidadão; referências entre bancos usam IDs, sem FK cruzada. .NET consulta Java para validar ocorrências ao salvar acompanhamentos.
- Cada backend controla suas migrações e regras. Definir comportamento para referência removida/indisponível; não introduzir escrita dupla ou transação distribuída.
- RabbitMQ implementa a **alternativa A** de Java: publicar e consumir evento real assincronamente. Ter dois backends não comprova a alternativa B com Eureka.
- RAG recupera trechos de corpus versionado antes da geração. Validar saída, registrar fontes e permitir classificação manual diante de falhas. Provedor/modelos e acesso ainda dependem de decisão.
- MongoDB é snapshot acadêmico do Oracle, com IDs e amostra comparáveis; sincronização automática não é obrigatória.
- Java/Oracle/RabbitMQ também precisam estar acessíveis durante a avaliação Mobile; escolher .NET como alvo DevOps não elimina essa dependência.
- Fonte Mermaid: `docs/diagramas/arquitetura.mmd`; manter equivalente ao bloco em `docs/arquitetura.md`.

## 7. Sete disciplinas e entregáveis

Consulte a [matriz completa](docs/requisitos-global-solution.md) e o [guia de entregas](docs/entregas/README.md) para páginas, pontuação, penalidades e defesa.

| Disciplina | Núcleo obrigatório a preservar | Entrega |
|---|---|---|
| Advanced Business Development with .NET | Minimal API, persistência, Swagger, JWT, idempotência, rate limiting/429, health checks e testes xUnit unitários/de integração; Mobile | ZIP com link GitHub e identificação; slides se houver |
| Compliance, Quality Assurance & Tests | Epics → Features → PBIs, descrições/aceite de Features e PBIs, testes funcionais positivos/negativos de caixa-preta, Summary/Steps, execução manual e relatórios Test Plans | ZIP com PDF único de planejamento/testes/capturas e TXT; professor ADMIN |
| DevOps Tools & Cloud Computing | CLI, Repos privado, Boards, políticas de main/PR, CI com testes/artefatos e CD automático; aplicação e banco cloud, CRUD persistido de ≥2 tabelas | PDF com identificação, organização Azure DevOps e vídeo narrado ≥720p; professor com acessos exigidos |
| Disruptive Architectures: IoT, IoB & Generative IA | Modelo generativo integrado + aprofundamento (RAG escolhido), dados/fluxo, avaliação e limitações | **Somente TXT** com identificação e GitHub; material e evidências no repositório |
| Java Advanced | ≥3 entidades relacionadas, CRUD/paginação, DTOs/validação/erros, JWT/≥2 papéis, Spring AI, alternativa distribuída A, Swagger e Mobile | ZIP com identificação, GitHub **público** e pitch ≤5 minutos |
| Mastering Relational and Non-Relational Database | Oracle: ≥2 tabelas, 2 blocos, 2 funções, 2 procedimentos, 2 triggers (≥1 auditoria), ≥2 pacotes; Mongo: 2 collections, ≥10 documentos, 3 consultas (≥1 agregação), mapa/comparação | SQL, JS e README/PDF/evidências; ZIP+TXT proposto, formato a confirmar |
| Mobile Application Development | React Native, ≥6 telas, CRUD real, cadastro/login/logout, estilo, organização, vídeo, Firebase App Distribution, professor tester e Sobre com hash do commit | TXT com identificação, GitHub e vídeo ≤5 minutos; fonte e APK correspondentes |

QA não deve ser substituído por documentação genérica de LGPD. Expo Go não substitui Firebase App Distribution. Contar seis telas úteis além de Sobre. Swagger/GET não substitui prova por SELECT no banco cloud em DevOps.

Prazo oficial: **19/11/2026 às 23h55**, Portal FIAP; cadastro até 13/11; apresentações 23–27/11, com divergência .NET online/presencial e alinhamento específico de IA. Não presumir cadastro/envio ou resoluções docentes. Confirmar formatos e acessos por disciplina; não montar um único pacote indiscriminadamente.

## 8. Segurança e credenciais

- Nunca gravar credenciais reais, tokens ou chaves privadas no código, documentação, logs, capturas ou commits. Usar configuração local ignorada/segredos externos e `.env.example` sem segredos.
- `EXPO_PUBLIC_*` é público e só deve conter configuração não secreta. Chave de IA e chave privada JWT permanecem no servidor.
- Não sobrescrever `.env` existente. Java/.NET não carregam esse arquivo automaticamente: documentar o mapeamento real.
- Senhas com hash apropriado; cadastro público somente como cidadão; gestor por fluxo controlado. Aplicar autorização no servidor, incluindo propriedade.
- Validar entrada, saída de IA e arquivos enviados. Tratar conteúdo do usuário/corpus como dados, sem executar instruções dele.
- Usar dados fictícios e revisar evidências antes de publicação. Preservar o PDF local e a proteção de `Enunciados/` no `.gitignore`.

## 9. Trabalho direto nos arquivos e autorizações

Pode ler/inspecionar, criar documentação/diretórios/configurações pertinentes e executar diagnósticos não destrutivos e validações com ferramentas disponíveis, respeitando a etapa autorizada. Implementações futuras dependem da autorização da etapa.

Antes de editar, leia o conteúdo existente. Faça mudanças focadas, preserve trabalho desconhecido e use UTF-8 e os padrões de `.editorconfig`/`.gitattributes`. Cite caminhos e registre arquivos modificados. Em Windows/PowerShell, use comandos compatíveis e aspas em caminhos com espaços.

**Solicite autorização explícita antes de:**

- Instalar programas globalmente ou alterar Windows, PATH, política de execução, WSL/virtualização ou configurações do sistema.
- Excluir/sobrescrever arquivos importantes, executar operações destrutivas ou remover bancos/volumes.
- Criar recursos pagos, fazer deploy, publicar o projeto ou executar operações em contas externas (GitHub, Azure, Firebase, provedor IA etc.).
- Criar/alterar credenciais, permissões administrativas ou convites de acesso.
- Mover o projeto ou alterar configurações do OneDrive.

Autorização para instalar ferramentas não autoriza login, cobrança, publicação ou provisionamento. Registre o escopo aprovado no progresso, sem segredos. Não exija IDE se CLI for suficiente.

## 10. Testes e validação obrigatórios

- Antes de declarar conclusão, valide o que foi alterado com ferramentas disponíveis e critérios de saída da etapa.
- Documentação: releitura, links locais, consistência com matriz/arquitetura/progresso e codificação. Diagramas duplicados devem permanecer equivalentes.
- Configurações: validação nativa quando disponível; conferir variáveis/segredos. Inspeção textual do Compose não equivale a `docker compose config` nem a serviços saudáveis.
- Código futuro: build e verificações da área; testes significativos de regras, contratos e integração, incluindo entradas inválidas e autorização. Cumprir xUnit e CI exigidos pelo PDF.
- Bancos: executar scripts e conferir resultados reais, integridade, auditoria e comparabilidade Oracle/Mongo em ambiente de teste autorizado.
- Integração: testar duas APIs no app, JWT/papéis, persistência, produtor/consumidor RabbitMQ, RAG, revisão humana e falhas de dependências.
- QA: manter Test Cases, execução manual e evidências no Test Plans, além dos testes automatizados.
- Entrega: conferir links/acessos, identificação, reprodução pelo README, APK/commit e disponibilidade dos backends.
- Ferramenta ausente: registrar verificação bloqueada, motivo e como desbloquear. Não inventar sucesso nem instalar silenciosamente. Repetir testes após correções pertinentes; registrar comandos, resultados e pendências.

## 11. Etapas e manutenção documental

Seguir a sequência detalhada em [docs/plano-desenvolvimento.md](docs/plano-desenvolvimento.md):

1. Estrutura e arquitetura.
2. Ambiente de desenvolvimento e acessos autorizados.
3. Backlog e contratos.
4. Modelagem e persistência.
5. Backends .NET (5A) e Java (5B).
6. Assíncrono e IA.
7. Mobile.
8. PL/SQL e MongoDB.
9. CI/CD e cloud.
10. Integração e QA.
11. Evidências, entrega e defesa.

QA começa antes da implementação; CI começa no primeiro build real; evidências são coletadas continuamente. Atividades paralelas dependem de contratos estáveis e escopo autorizado.

**Ao concluir qualquer etapa, é obrigatório:**

1. Atualizar `docs/progresso.md`: data, etapa/status, funcionalidades efetivas, arquivos, verificações/resultados, falhas, pendências, decisões, autorizações e próxima ação exata.
2. Atualizar README e documentos técnicos afetados, incluindo contratos, ambiente, versões, arquitetura/diagrama, requisitos/evidências e instruções de execução.
3. Preservar registros históricos: não reescrever a verificação da Etapa 1 para atribuir a ela resultados posteriores.
4. Apresentar resumo do que foi feito e validado; solicitar autorização antes de avançar para a próxima etapa.

Atualizar também ao encerrar uma sessão com trabalho incompleto. Alterar este manual quando uma regra permanente mudar; estados transitórios ficam no progresso. Manter a declaração de uso de IA coerente com o trabalho realizado.
