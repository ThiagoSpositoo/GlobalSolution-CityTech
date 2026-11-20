# Automação Azure DevOps — QA CityTech

Scripts compatíveis com **Windows PowerShell 5.1**. A organização e o projeto padrão são:

- Organização: `RM561694`
- Projeto: `GlobalSolution-CityTech`
- URL: <https://dev.azure.com/RM561694/GlobalSolution-CityTech>

## Segurança e comportamento

- O token é lido somente de `AZURE_DEVOPS_PAT` no processo.
- Nenhum script grava ou imprime o token.
- `Sync-AzureDevOpsQa.ps1` é **dry-run por padrão** e exige `-Apply`.
- `Validate-AzureDevOpsTestCases.ps1` envia o patch completo somente com `validateOnly=true`; ele não cria Test Cases.
- Antes de qualquer escrita, o plano é salvo em `qa/relatorios/sync-plan.json`.
- O Apply exige inventário com exatamente 5 Epics, 12 Features e 39 PBIs, 51 documentos completos e mapeamento explícito das 12 Features por ID.
- Conteúdo existente considerado válido é preservado e registrado como conflito para revisão manual.
- Nenhum script apaga Work Items, muda estado para `Done`, cria Test Plan/Suite, executa testes ou fabrica resultados.

## Permissões mínimas

| Ação | Escopo PAT | Permissão no projeto |
|---|---|---|
| Inventário e verificação | Work Items: Read (`vso.work`) | View work items |
| Atualizar documentação/criar e vincular Test Cases | Work Items: Read & write (`vso.work_write`) | Edit work items in this node; criar Test Cases |
| Executar no Test Plans futuramente | Test Management: Read & write (`vso.test_write`) | licença/acesso ao Test Plans |

Convite do professor como ADMIN, alteração de permissões e criação de Plan/Suite não fazem parte destes scripts e exigem autorização separada.

## Fluxo seguro

No mesmo PowerShell, sem salvar o PAT em arquivo nem digitá-lo no histórico, use uma leitura temporária:

```powershell
$secure = Read-Host 'PAT Azure DevOps' -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try { $env:AZURE_DEVOPS_PAT = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
```

Depois:

```powershell
# 2. Inventário somente leitura.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Export-AzureDevOpsInventory.ps1

# 3. Gerar templates com IDs/títulos reais, sem sobrescrever qa/data.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/New-AzureDevOpsMappingTemplate.ps1

# 4. Revisar relações, preencher os 51 documentos e associar os 12 featureKey.
# Só então copiar os arquivos revisados para qa/data/.

# 5. Validar e produzir o plano local, sem escrita.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Test-LocalQaAutomation.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Sync-AzureDevOpsQa.ps1

# 6. Validar remotamente os 24 patches completos, sem criar itens.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Validate-AzureDevOpsTestCases.ps1

# Se algum patch falhar, repetir com diagnóstico cumulativo por campo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Validate-AzureDevOpsTestCases.ps1 -DiagnoseFields

# 7. Após aprovação explícita separada, sincronizar.
# Antes, exportar inventário novo para refletir as revisões já alteradas.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Export-AzureDevOpsInventory.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Sync-AzureDevOpsQa.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Sync-AzureDevOpsQa.ps1 -Apply

# 8. Reconsultar e verificar.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Test-AzureDevOpsQa.ps1

# 9. Remover o segredo do processo.
Remove-Item Env:AZURE_DEVOPS_PAT
```

O relatório seguro da validação é gravado em `qa/relatorios/test-case-validation.json`. Erros HTTP registram status, mensagem e tipo retornados pelo Azure, sem PAT ou cabeçalhos de autenticação.

## Corpo exato dos Test Cases

### Verificação do transporte HTTP

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Test-HttpTransport.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/Validate-AzureDevOpsTestCases.ps1 -DiagnoseFields
```

O primeiro comando captura requisições reais em TCP loopback, sem PAT real nem Azure, verificando Content-Type, raiz array e bytes UTF-8 de 27 casos. O segundo valida remotamente primeiro um patch mínimo e depois os 24 completos, sempre com `validateOnly=true`. Se o mínimo falhar, interrompe antes dos demais. O módulo usa `Invoke-WebRequest`, uma única serialização e corpo `byte[]` UTF-8; JSON já serializado é validado sem nova serialização.

O mesmo `New-CityTechTestCasePatch` é usado no plano, na validação e no `-Apply`. O JSON Patch contém, nesta ordem:

1. `add /fields/System.Title`;
2. `add /fields/System.Description`;
3. `add /fields/Microsoft.VSTS.TCM.Steps`;
4. `add /fields/System.Tags`;
5. `add /relations/-`, com `Microsoft.VSTS.Common.TestedBy-Reverse` apontando do Test Case para a Feature.

Não são enviados `System.State`, `Microsoft.VSTS.TCM.AutomationStatus` ou campos de responsável. O XML TCM usa `<steps id="0" last="N+1">` e passos `ActionStep` numerados de `2` a `N+1`.
