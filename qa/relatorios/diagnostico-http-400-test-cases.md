# Diagnóstico do HTTP 400 na criação de Test Cases

Data: **19/11/2026**.

## Execução confirmada

- A documentação de 49 Work Items, IDs 9 a 57, foi atualizada no Azure pelo usuário.
- A criação do primeiro Test Case falhou com HTTP 400.
- Um POST manual com somente `System.Title` e `validateOnly=true` retornou HTTP 200 e não criou item.
- Nenhum Test Case foi confirmado como criado.

## Corpo anteriormente enviado

O script enviava cinco operações JSON Patch: título, descrição, passos TCM, tags e vínculo `Microsoft.VSTS.Common.TestedBy-Reverse` com a Feature. Não havia campo de estado nem `AutomationStatus`.

## Causa local identificada

**Atualização do diagnóstico:** a alteração do XML abaixo não comprovou a causa do HTTP 400. O usuário posteriormente confirmou rejeição dos 24 documentos completos e cumulativos com `You must pass a valid patch document in the body of the request`. O transporte foi corrigido para `Invoke-WebRequest` com bytes UTF-8 explícitos e raiz array validada. Os 27 testes HTTP em loopback passaram; a aceitação remota ainda precisa ser confirmada, sem atribuir o erro conclusivamente ao XML.

O XML de `Microsoft.VSTS.TCM.Steps` numerava passos a partir de `1` e definia `last` como a quantidade. O formato TCM usado pelo Azure reserva esse identificador: passos devem começar em `2`, e `last` deve conter o último ID utilizado. Para três passos, por exemplo, o formato corrigido usa IDs `2`, `3`, `4` e `last="4"`.

Também foi eliminado o risco de divergência entre dry-run, validação e Apply: os três caminhos agora usam `New-CityTechTestCasePatch`.

## Verificação remota pendente

O processo do OpenCode não possui `AZURE_DEVOPS_PAT`; portanto, os 24 patches completos ainda não foram enviados ao endpoint de validação. Execute:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Validate-AzureDevOpsTestCases.ps1
```

O comando usa exclusivamente `validateOnly=true`, não cria Work Items e gera `qa/relatorios/test-case-validation.json`. Se houver falha:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Validate-AzureDevOpsTestCases.ps1 -DiagnoseFields
```

O segundo comando valida cumulativamente as cinco operações para identificar o primeiro campo rejeitado. Mensagens HTTP são registradas sem credenciais ou cabeçalhos.

### Correção de compatibilidade PowerShell 5.1

Uma primeira execução do validador encontrou `PropertyNotFoundStrict` ao acessar `$existingIds.Count`. Quando não havia Test Case existente, o ramo condicional com `@()` não emitia valor e a variável tornava-se `$null`. O código agora inicializa explicitamente o array e usa `Get-CityTechCollectionCount`, que trata `$null` como zero, objeto único como um e arrays pela quantidade real. Os demais acessos diretos a `.Count` no validador e nos fluxos compartilhados foram normalizados sem remover `StrictMode`.

## Aplicação posterior

Como as revisões 9–57 mudaram, gere inventário novo e revise o dry-run antes de qualquer Apply. O script não reutilizará o inventário anterior e não duplicará códigos de Test Case existentes. Um item existente só é ignorado se for único e já estiver ligado à Feature correta.
