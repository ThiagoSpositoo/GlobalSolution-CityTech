# Verificação da Etapa 1

Data: **17/11/2026**. Este relatório distingue inspeções executadas de testes bloqueados.

## Escopo entregue

Leitura do enunciado, matriz das sete disciplinas, diagnóstico, arquitetura, planejamento, estrutura modular, README por área, diagrama Mermaid, configurações de edição/Git, `.env.example` e Compose local parcial.

Foram criados somente documentos e configurações. Não há backends, telas, endpoints, dados de domínio, integração IA, recursos cloud ou testes de aplicação implementados.

## Verificações executadas

| Conferência | Resultado real |
|---|---|
| Inventário antes de criar diretórios | Apenas `Enunciados/` com o PDF oficial; nenhum AGENTS.md encontrado na árvore |
| Leitura do PDF | 97/97 páginas com leitor nativo; imagens relevantes inspecionadas |
| Diagnóstico local | PATH, registro, diretórios padrão, serviços, SO/hardware/permissões consultados |
| Arquivos novos | **38**, todos documentos/configurações; nenhum arquivo preexistente sobrescrito |
| Links Markdown locais | **26 verificados, zero quebrados** |
| Variáveis de interpolação Compose | **13**, todas presentes em `.env.example` |
| Chaves duplicadas no `.env.example` | **Zero** |
| Campos PASSWORD/API_KEY/DB_CONNECTION/PRIVATE_KEY_PATH preenchidos no exemplo | **Zero** |
| Codificação UTF-8 dos arquivos novos | **38 válidos** |
| Arquivos novos vazios | **Zero** |
| Diagrama no Markdown versus `.mmd` | **Conteúdo idêntico** |
| Hash do PDF antes/depois | **Idêntico**, SHA-256 abaixo |
| Diretório `.git` | Ausente, coerente com Git não instalado |
| Comando de conferência PowerShell | Concluído sem falhas |

SHA-256 confirmado do original:

```text
D1FDFCD0B1AB5A86DC5C152D23C7FF6E3CD2696CFEC6CA10D57FC5CB3882AE1A
```

A conferência das variáveis é textual; **não equivale a parsing YAML, execução de Compose, teste de login nos bancos nem auditoria completa de segredos**. A equivalência do Mermaid não comprova renderização.

## Arquivos criados

```text
.editorconfig
.env.example
.gitattributes
.gitignore
docker-compose.yml
README.md
ai/README.md
ai/corpus/README.md
ai/evaluation/README.md
backend-dotnet/README.md
backend-dotnet/src/README.md
backend-dotnet/tests/README.md
backend-java/README.md
backend-java/src/README.md
backend-java/tests/README.md
database/README.md
database/mongodb/README.md
database/oracle/README.md
database/sqlserver/README.md
devops/README.md
devops/pipelines/README.md
dockerfiles/README.md
docs/ambiente-desenvolvimento.md
docs/arquitetura.md
docs/plano-desenvolvimento.md
docs/requisitos-global-solution.md
docs/verificacao-etapa-1.md
docs/versoes-e-fontes.md
docs/diagramas/arquitetura.mmd
docs/entregas/README.md
mobile/README.md
mobile/src/README.md
mobile/assets/README.md
qa/README.md
qa/backlog/README.md
qa/test-cases/README.md
qa/evidencias/README.md
scripts/README.md
```

Arquivos preexistentes modificados: **nenhum**. A pasta preservada chama-se `Enunciados` com E maiúsculo, e não foi renomeada. O `.gitignore` exclui seu conteúdo de futura publicação Git por padrão, sem remover o arquivo local.

## Validações pendentes e motivos

| Validação | Estado/motivo | Como desbloquear |
|---|---|---|
| `git status`, `git check-ignore`, histórico | Git ausente; pasta ainda não inicializada | Instalar Git com autorização; iniciar na raiz |
| Maven/build Java/compatibilidade efetiva dos pacotes | JDK/Maven ausentes e projeto não implementado | Etapa 2, Wrapper e scaffold autorizado |
| .NET restore/build/xUnit | SDK ausente; não há projeto de aplicação | Instalar SDK 10 e implementar etapa posterior |
| npm/Expo/lint/TypeScript/APK | Node/npm ausentes; não há app | Node 24, scaffold e toolchain Android/build autorizado |
| Parsing YAML por Compose e `docker compose config` | Docker/Compose ausentes; PowerShell padrão não possui parser YAML usado aqui | Instalar Docker/WSL e validar config |
| Pull de imagens/digests/healthchecks/volumes | Engine ausente; nenhum serviço iniciado | Etapa 2 e teste real dos profiles |
| Oracle SQL/PLSQL/JPA | Sem cliente/servidor/conta confirmados | Confirmar ambiente da disciplina |
| MongoDB/SQL Server | Serviços/clientes ausentes, scripts não implementados | Disponibilizar bancos e implementar scripts |
| Renderização do Mermaid | Fonte textual inspecionada; renderizador não executado | Abrir em renderizador Markdown/Mermaid local compatível |
| Modelo IA/RAG/métricas | Sem implementação/provedor selecionado | Autorizar etapa IA e acesso adequado |
| Azure/Test Plans/GitHub/Firebase | Nenhuma operação em conta externa | Confirmar contas/permissões e autorizações específicas |
| Nota/aceite acadêmico | Não há entrega avaliada | Implementar/evidenciar e resolver dúvidas com professores |

## Erros e limitações registrados

- Página comercial Oracle Free respondeu **403**; referência PL/SQL 19c acessível separadamente. Imagem/versão do ambiente Free não presumidas.
- `wsl --status` informou WSL não instalado. A saída tem caracteres NUL por codificação, mas a mensagem foi legível.
- A primeira consulta combinada de hardware/diretórios teve formatação incompleta; consulta repetida com `Format-List` confirmou os dados.
- `python.exe`/`python3.exe` no WindowsApps são aliases de 0 bytes; não foram classificados como Python instalado.
- WMI informou SLAT falso com hipervisor presente; compatibilidade Docker necessita validação adicional.
- Tags do Compose ainda são por família e mutáveis; reprodução por digest aguarda pull/validação.

## Limite da etapa

Nenhum programa foi instalado; nenhuma configuração do Windows/credencial/permissão foi alterada; nenhum recurso pago, deploy, publicação, convite ou envio acadêmico foi efetuado. O original foi mantido em `Enunciados/`, com sua capitalização existente.

A próxima etapa depende da autorização do usuário.
