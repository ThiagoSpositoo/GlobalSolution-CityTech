[CmdletBinding()]
param(
    [string]$Organization = 'RM561694',
    [string]$Project = 'GlobalSolution-CityTech',
    [string]$PatEnvironmentVariable = 'AZURE_DEVOPS_PAT',
    [string]$InventoryPath,
    [string]$MappingPath,
    [string]$ContentPath,
    [string]$TestCasesPath,
    [string]$ReportPath,
    [switch]$Apply
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'CityTech.AzureDevOps.psm1') -Force

if ([string]::IsNullOrWhiteSpace($InventoryPath)) {
    $InventoryPath = Join-Path $PSScriptRoot '..\relatorios\azure-work-items.json'
}
if ([string]::IsNullOrWhiteSpace($MappingPath)) {
    $MappingPath = Join-Path $PSScriptRoot '..\data\azure-mapping.json'
}
if ([string]::IsNullOrWhiteSpace($ContentPath)) {
    $ContentPath = Join-Path $PSScriptRoot '..\data\work-item-content.json'
}
if ([string]::IsNullOrWhiteSpace($TestCasesPath)) {
    $TestCasesPath = Join-Path $PSScriptRoot '..\data\test-cases.json'
}
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $PSScriptRoot '..\relatorios\sync-plan.json'
}

foreach ($path in @($InventoryPath, $MappingPath, $ContentPath, $TestCasesPath)) {
    if (-not (Test-Path $path -PathType Leaf)) {
        throw "Arquivo obrigatório ausente: $path"
    }
}

$inventoryDocument = Get-Content -Raw -Path $InventoryPath -Encoding UTF8 | ConvertFrom-Json
$savedItems = @($inventoryDocument.items)
$mapping = Get-Content -Raw -Path $MappingPath -Encoding UTF8 | ConvertFrom-Json
$content = Get-Content -Raw -Path $ContentPath -Encoding UTF8 | ConvertFrom-Json
$catalog = Get-Content -Raw -Path $TestCasesPath -Encoding UTF8 | ConvertFrom-Json
$config = Get-CityTechAzDoConfiguration -Organization $Organization -Project $Project -PatEnvironmentVariable $PatEnvironmentVariable

$expected = @{
    Epic = 5
    Feature = 12
    'Product Backlog Item' = 39
}
foreach ($type in $expected.Keys) {
    $actual = Get-CityTechCollectionCount -Value @($savedItems | Where-Object type -eq $type)
    if ($actual -ne $expected[$type]) {
        throw "Inventário recusado: $type=$actual; esperado=$($expected[$type]). Gere um inventário real e confira a base antes de sincronizar."
    }
}

$documentable = @($savedItems | Where-Object { $_.type -in @('Feature', 'Product Backlog Item') })
$contentItems = @($content.workItems)
$contentItemCount = Get-CityTechCollectionCount -Value $contentItems
if ($contentItemCount -ne 51) {
    throw "Catálogo documental incompleto: $contentItemCount/51 Features+PBIs. O -Apply permanece bloqueado."
}

$savedById = @{}
foreach ($item in $savedItems) {
    $savedById[[int]$item.id] = $item
}

$contentIds = @($contentItems | ForEach-Object { [int]$_.id })
if ((Get-CityTechCollectionCount -Value @($contentIds | Sort-Object -Unique)) -ne 51) {
    throw 'Catálogo documental contém IDs duplicados.'
}
foreach ($item in $documentable) {
    if ([int]$item.id -notin $contentIds) {
        throw "Work Item $($item.id) não possui documentação no catálogo."
    }
}

$featureMappings = @($mapping.features)
$featureMappingCount = Get-CityTechCollectionCount -Value $featureMappings
if ($featureMappingCount -ne 12) {
    throw "Mapeamento incompleto: $featureMappingCount/12 Features."
}
$featureKeys = @($featureMappings | ForEach-Object { [string]$_.featureKey })
if ((Get-CityTechCollectionCount -Value @($featureKeys | Where-Object { [string]::IsNullOrWhiteSpace($_) })) -gt 0) {
    throw 'Mapeamento contém featureKey vazio. Associe explicitamente cada Feature real antes da sincronização.'
}
if ((Get-CityTechCollectionCount -Value @($featureKeys | Sort-Object -Unique)) -ne 12) {
    throw 'Mapeamento contém featureKey duplicado.'
}

$operations = @()
$conflicts = @()
foreach ($desired in $contentItems) {
    $id = [int]$desired.id
    if (-not $savedById.ContainsKey($id)) {
        throw "ID $id do catálogo não existe no inventário."
    }
    $current = $savedById[$id]
    if ([string]$current.type -ne [string]$desired.type -or [string]$current.title -ne [string]$desired.title) {
        throw "ID $id mudou de tipo ou título desde o mapeamento. Gere e revise novo inventário."
    }

    $descriptionHtml = ConvertTo-CityTechHtml -Text ([string]$desired.description)
    $acceptanceText = @($desired.acceptanceCriteria | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    $acceptanceHtml = ConvertTo-CityTechHtml -Text $acceptanceText
    if ([string]::IsNullOrWhiteSpace($descriptionHtml) -or (Get-CityTechCollectionCount -Value $desired.acceptanceCriteria) -eq 0) {
        throw "Documentação vazia no Work Item $id."
    }

    $patch = @()
    if (Test-CityTechContentMissing $current.description) {
        $patch += New-CityTechJsonPatchOperation -Operation add -Path '/fields/System.Description' -Value $descriptionHtml
    }
    elseif ((ConvertTo-CityTechPlainText $current.description) -ne (ConvertTo-CityTechPlainText $descriptionHtml)) {
        $conflicts += [ordered]@{ id = $id; field = 'System.Description'; action = 'preserve-existing'; title = $current.title }
    }

    if (Test-CityTechContentMissing $current.acceptanceCriteria) {
        $patch += New-CityTechJsonPatchOperation -Operation add -Path '/fields/Microsoft.VSTS.Common.AcceptanceCriteria' -Value $acceptanceHtml
    }
    elseif ((ConvertTo-CityTechPlainText $current.acceptanceCriteria) -ne (ConvertTo-CityTechPlainText $acceptanceHtml)) {
        $conflicts += [ordered]@{ id = $id; field = 'Microsoft.VSTS.Common.AcceptanceCriteria'; action = 'preserve-existing'; title = $current.title }
    }

    if ((Get-CityTechCollectionCount -Value $patch) -gt 0) {
        $operations += [ordered]@{
            kind = 'update-documentation'
            id = $id
            expectedRev = [int]$current.rev
            title = [string]$current.title
            patch = @($patch)
        }
    }
}

$mappedFeatures = @{}
foreach ($feature in $featureMappings) {
    $id = [int]$feature.id
    if (-not $savedById.ContainsKey($id) -or [string]$savedById[$id].type -ne 'Feature') {
        throw "Mapeamento aponta para Feature inválida: $id."
    }
    if ([string]$savedById[$id].title -ne [string]$feature.title) {
        throw "Título da Feature $id diverge do inventário. Revise o mapeamento."
    }
    $mappedFeatures[[string]$feature.featureKey] = $feature
}

foreach ($testCase in @($catalog.testCases)) {
    $key = [string]$testCase.featureKey
    if (-not $mappedFeatures.ContainsKey($key)) {
        throw "Test Case $($testCase.code) referencia featureKey não mapeada: $key."
    }
    $featureId = [int]$mappedFeatures[$key].id
    $featureTitle = [string]$mappedFeatures[$key].title
    $title = "$($testCase.code) - $($testCase.title)"
    $featureUrl = "$($config.ApiBaseUrl)/wit/workItems/$featureId"
    $operations += [ordered]@{
        kind = 'create-test-case-if-absent'
        code = [string]$testCase.code
        title = $title
        featureId = $featureId
        featureTitle = $featureTitle
        patch = @(New-CityTechTestCasePatch -TestCase $testCase -Title $title -FeatureId $featureId -FeatureTitle $featureTitle -FeatureUrl $featureUrl)
    }
}

$report = [ordered]@{
    schemaVersion = 1
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    mode = if ($Apply) { 'apply-requested' } else { 'dry-run' }
    sourceInventoryGeneratedAtUtc = $inventoryDocument.generatedAtUtc
    organization = $Organization
    project = $Project
    summary = [ordered]@{
        documentationCandidates = Get-CityTechCollectionCount -Value @($operations | Where-Object kind -eq 'update-documentation')
        documentationFieldUpdates = @($operations | Where-Object kind -eq 'update-documentation' | ForEach-Object { Get-CityTechCollectionCount -Value $_.patch } | Measure-Object -Sum).Sum
        testCasesPlanned = Get-CityTechCollectionCount -Value @($operations | Where-Object kind -eq 'create-test-case-if-absent')
        existingContentConflictsPreserved = Get-CityTechCollectionCount -Value $conflicts
        unresolvedConflicts = 0
    }
    conflicts = @($conflicts)
    operations = @($operations)
}
Export-CityTechUtf8Json -InputObject $report -Path $ReportPath
Write-Host "Plano salvo antes de qualquer escrita: $ReportPath"
Write-Host "Documentações candidatas: $($report.summary.documentationCandidates)"
Write-Host "Campos documentais a preencher: $($report.summary.documentationFieldUpdates)"
Write-Host "Test Cases planejados: $($report.summary.testCasesPlanned)"
Write-Host "Conteúdos existentes divergentes preservados: $($report.summary.existingContentConflictsPreserved)"
Write-Host "Conflitos não resolvidos: $($report.summary.unresolvedConflicts)"

if (-not $Apply) {
    Write-Host 'DRY-RUN concluído. Nenhuma chamada remota de escrita foi realizada.'
    return
}

if (-not $config.HasCredential) {
    throw "Apply bloqueado: defina $PatEnvironmentVariable no processo atual."
}

# Reconsulta imediatamente antes da escrita para evitar aplicar sobre inventário antigo.
$freshItems = @(Get-CityTechWorkItemInventory -Organization $Organization -Project $Project -PatEnvironmentVariable $PatEnvironmentVariable -IncludeTestCases)
$freshById = @{}
foreach ($item in $freshItems) {
    $freshById[[int]$item.id] = $item
}

foreach ($saved in $savedItems) {
    if (-not $freshById.ContainsKey([int]$saved.id)) {
        throw "Apply bloqueado: Work Item $($saved.id) não existe mais."
    }
    if ([int]$freshById[[int]$saved.id].rev -ne [int]$saved.rev) {
        throw "Apply bloqueado: Work Item $($saved.id) mudou da revisão $($saved.rev) para $($freshById[[int]$saved.id].rev). Gere novo inventário."
    }
}

$existingTestCodes = @{}
foreach ($existing in @($freshItems | Where-Object type -eq 'Test Case')) {
    if ([string]$existing.title -match '^(TC-[A-Z0-9-]+)\s+-') {
        $code = [string]$matches[1]
        if (-not $existingTestCodes.ContainsKey($code)) {
            $existingTestCodes[$code] = @()
        }
        $existingTestCodes[$code] = @($existingTestCodes[$code]) + $existing
    }
}

foreach ($operation in @($operations | Where-Object kind -eq 'update-documentation')) {
    $patch = @(
        (New-CityTechJsonPatchOperation -Operation test -Path '/rev' -Value ([int]$operation.expectedRev))
    ) + @($operation.patch)
    $uri = "$($config.ApiBaseUrl)/wit/workitems/$($operation.id)?api-version=7.1"
    Invoke-CityTechAzDoRequest -Method PATCH -Uri $uri -Body $patch -ContentType 'application/json-patch+json' -PatEnvironmentVariable $PatEnvironmentVariable | Out-Null
    Write-Host "Documentação preenchida no Work Item $($operation.id)."
}

foreach ($operation in @($operations | Where-Object kind -eq 'create-test-case-if-absent')) {
    if ($existingTestCodes.ContainsKey([string]$operation.code)) {
        $existingMatches = @($existingTestCodes[[string]$operation.code])
        $existingMatchCount = Get-CityTechCollectionCount -Value $existingMatches
        if ($existingMatchCount -ne 1) {
            throw "Criação bloqueada: existem $existingMatchCount Test Cases com o código $($operation.code). Resolva a duplicidade sem criar outro item."
        }
        if ([int]$operation.featureId -notin @($existingMatches[0].testedFeatureIds)) {
            throw "Criação bloqueada: o Test Case $($operation.code) já existe no ID $($existingMatches[0].id), mas não está vinculado à Feature $($operation.featureId)."
        }
        Write-Host "Test Case $($operation.code) já existe no ID $($existingMatches[0].id), vinculado à Feature correta; criação ignorada."
        continue
    }

    $uri = "$($config.ApiBaseUrl)/wit/workitems/`$Test%20Case?api-version=7.1"
    $created = Invoke-CityTechAzDoRequest -Method POST -Uri $uri -Body @($operation.patch) -ContentType 'application/json-patch+json' -PatEnvironmentVariable $PatEnvironmentVariable
    Write-Host "Test Case $($operation.code) criado com ID $($created.id)."
}

Write-Host 'Sincronização concluída. Execute Test-AzureDevOpsQa.ps1 para verificação independente.'
