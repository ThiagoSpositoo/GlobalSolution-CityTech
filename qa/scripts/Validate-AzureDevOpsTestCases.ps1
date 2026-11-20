[CmdletBinding()]
param(
    [string]$Organization = 'RM561694',
    [string]$Project = 'GlobalSolution-CityTech',
    [string]$PatEnvironmentVariable = 'AZURE_DEVOPS_PAT',
    [string]$MappingPath,
    [string]$TestCasesPath,
    [string]$ReportPath,
    [switch]$DiagnoseFields
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'CityTech.AzureDevOps.psm1') -Force

if ([string]::IsNullOrWhiteSpace($MappingPath)) {
    $MappingPath = Join-Path $PSScriptRoot '..\data\azure-mapping.json'
}
if ([string]::IsNullOrWhiteSpace($TestCasesPath)) {
    $TestCasesPath = Join-Path $PSScriptRoot '..\data\test-cases.json'
}
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $PSScriptRoot '..\relatorios\test-case-validation.json'
}

foreach ($path in @($MappingPath, $TestCasesPath)) {
    if (-not (Test-Path $path -PathType Leaf)) {
        throw "Arquivo obrigatório ausente: $path"
    }
}

$config = Get-CityTechAzDoConfiguration -Organization $Organization -Project $Project -PatEnvironmentVariable $PatEnvironmentVariable
if (-not $config.HasCredential) {
    throw "Validação bloqueada: defina $PatEnvironmentVariable somente no processo atual. Nenhuma credencial deve ser salva em arquivo."
}

$mapping = Get-Content -Raw -Path $MappingPath -Encoding UTF8 | ConvertFrom-Json
$catalog = Get-Content -Raw -Path $TestCasesPath -Encoding UTF8 | ConvertFrom-Json
$features = @($mapping.features)
$testCases = @($catalog.testCases)
$featureCount = Get-CityTechCollectionCount -Value $features
$testCaseCount = Get-CityTechCollectionCount -Value $testCases
if ($featureCount -ne 12 -or $testCaseCount -ne 24) {
    throw "Catálogo recusado: Features=$featureCount/12; Test Cases=$testCaseCount/24."
}

$featureByKey = @{}
foreach ($feature in $features) {
    $featureByKey[[string]$feature.featureKey] = $feature
}

# A consulta é somente leitura. Os POSTs posteriores usam obrigatoriamente
# validateOnly=true e, portanto, não criam Work Items.
$remoteItems = @(Get-CityTechWorkItemInventory -Organization $Organization -Project $Project -PatEnvironmentVariable $PatEnvironmentVariable -IncludeTestCases)
$remoteById = @{}
foreach ($item in $remoteItems) {
    $remoteById[[int]$item.id] = $item
}

$existingByCode = @{}
foreach ($existing in @($remoteItems | Where-Object type -eq 'Test Case')) {
    if ([string]$existing.title -match '^(TC-[A-Z0-9-]+)\s+-') {
        $code = [string]$matches[1]
        if (-not $existingByCode.ContainsKey($code)) {
            $existingByCode[$code] = @()
        }
        $existingByCode[$code] = @($existingByCode[$code]) + [int]$existing.id
    }
}

function Get-SafeValidationFailure {
    param([Parameter(Mandatory = $true)][Management.Automation.ErrorRecord]$ErrorRecord)

    $statusCode = $null
    $azureMessage = ''
    $azureTypeName = ''
    if ($null -ne $ErrorRecord.Exception) {
        if ($ErrorRecord.Exception.Data.Contains('StatusCode')) {
            $statusCode = [int]$ErrorRecord.Exception.Data['StatusCode']
        }
        if ($ErrorRecord.Exception.Data.Contains('AzureMessage')) {
            $azureMessage = [string]$ErrorRecord.Exception.Data['AzureMessage']
        }
        if ($ErrorRecord.Exception.Data.Contains('AzureTypeName')) {
            $azureTypeName = [string]$ErrorRecord.Exception.Data['AzureTypeName']
        }
    }
    if ([string]::IsNullOrWhiteSpace($azureMessage)) {
        $azureMessage = [string]$ErrorRecord.Exception.Message
    }

    [ordered]@{
        httpStatus = $statusCode
        message = $azureMessage
        typeName = $azureTypeName
    }
}

$validationUri = "$($config.ApiBaseUrl)/wit/workitems/`$Test%20Case?validateOnly=true&api-version=7.1"
if ($validationUri -notmatch '[?&]validateOnly=true(?:&|$)') {
    throw 'Proteção interna: a URI de validação não contém validateOnly=true.'
}

$results = @()
$minimumPatch = @(
    (New-CityTechJsonPatchOperation -Operation add -Path '/fields/System.Title' -Value 'CityTech - validação de transporte')
)
# Mesmo transporte dos patches completos; nenhum item é persistido.
Invoke-CityTechAzDoRequest -Method POST -Uri $validationUri -Body $minimumPatch -ContentType 'application/json-patch+json' -PatEnvironmentVariable $PatEnvironmentVariable | Out-Null
Write-Host 'Patch mínimo aceito com validateOnly=true.'
foreach ($testCase in $testCases) {
    $code = [string]$testCase.code
    $key = [string]$testCase.featureKey
    if (-not $featureByKey.ContainsKey($key)) {
        throw "Test Case $code referencia featureKey inexistente: $key."
    }

    $feature = $featureByKey[$key]
    $featureId = [int]$feature.id
    if (-not $remoteById.ContainsKey($featureId) -or [string]$remoteById[$featureId].type -ne 'Feature') {
        throw "Feature remota $featureId do Test Case $code não foi encontrada."
    }
    if ([string]$remoteById[$featureId].title -ne [string]$feature.title) {
        throw "Feature remota $featureId mudou de título; revise o mapeamento antes de validar."
    }

    $title = "$code - $($testCase.title)"
    $featureUrl = "$($config.ApiBaseUrl)/wit/workItems/$featureId"
    $patch = @(New-CityTechTestCasePatch -TestCase $testCase -Title $title -FeatureId $featureId -FeatureTitle ([string]$feature.title) -FeatureUrl $featureUrl)
    $existingIds = @()
    if ($existingByCode.ContainsKey($code)) {
        $existingIds = @($existingByCode[$code])
    }
    $existingIdCount = Get-CityTechCollectionCount -Value $existingIds
    $patchCount = Get-CityTechCollectionCount -Value $patch
    $result = [ordered]@{
        code = $code
        title = $title
        featureId = $featureId
        featureTitle = [string]$feature.title
        existingIds = @($existingIds)
        duplicateExistingCode = $existingIdCount -gt 1
        operationCount = $patchCount
        paths = @($patch | ForEach-Object { [string]$_.path })
        steps = Get-CityTechCollectionCount -Value $testCase.steps
        status = 'failed'
        httpStatus = $null
        message = ''
        typeName = ''
        diagnostics = @()
    }

    try {
        Invoke-CityTechAzDoRequest -Method POST -Uri $validationUri -Body $patch -ContentType 'application/json-patch+json' -PatEnvironmentVariable $PatEnvironmentVariable | Out-Null
        $result.status = 'validated'
        $result.httpStatus = 200
        $result.message = 'Patch completo aceito com validateOnly=true; nenhum Work Item foi criado.'
        Write-Host "$code validado (HTTP 200, sem criação)."
    }
    catch {
        $failure = Get-SafeValidationFailure -ErrorRecord $_
        $result.httpStatus = $failure.httpStatus
        $result.message = $failure.message
        $result.typeName = $failure.typeName
        Write-Warning "$code rejeitado: $($failure.message)"

        if ($DiagnoseFields) {
            $diagnostics = @()
            for ($count = 1; $count -le $patchCount; $count++) {
                $partialPatch = @($patch[0..($count - 1)])
                $diagnostic = [ordered]@{
                    operationCount = $count
                    addedPath = [string]$patch[$count - 1].path
                    status = 'failed'
                    httpStatus = $null
                    message = ''
                }
                try {
                    Invoke-CityTechAzDoRequest -Method POST -Uri $validationUri -Body $partialPatch -ContentType 'application/json-patch+json' -PatEnvironmentVariable $PatEnvironmentVariable | Out-Null
                    $diagnostic.status = 'validated'
                    $diagnostic.httpStatus = 200
                    $diagnostic.message = 'Patch cumulativo aceito.'
                }
                catch {
                    $partialFailure = Get-SafeValidationFailure -ErrorRecord $_
                    $diagnostic.httpStatus = $partialFailure.httpStatus
                    $diagnostic.message = $partialFailure.message
                }
                $diagnostics += $diagnostic
            }
            $result.diagnostics = @($diagnostics)
        }
    }

    $results += [pscustomobject]$result
}

$report = [ordered]@{
    schemaVersion = 1
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    mode = 'validate-only'
    organization = $Organization
    project = $Project
    remoteMutation = $false
    minimumPatchValidated = $true
    request = [ordered]@{
        method = 'POST'
        workItemType = 'Test Case'
        validateOnly = $true
        contentType = 'application/json-patch+json'
        fields = @('System.Title', 'System.Description', 'Microsoft.VSTS.TCM.Steps', 'System.Tags')
        relation = 'Microsoft.VSTS.Common.TestedBy-Reverse'
    }
    summary = [ordered]@{
        total = Get-CityTechCollectionCount -Value $results
        validated = Get-CityTechCollectionCount -Value @($results | Where-Object status -eq 'validated')
        failed = Get-CityTechCollectionCount -Value @($results | Where-Object status -eq 'failed')
        codesAlreadyExisting = Get-CityTechCollectionCount -Value @($results | Where-Object { (Get-CityTechCollectionCount -Value $_.existingIds) -gt 0 })
        duplicateExistingCodes = Get-CityTechCollectionCount -Value @($results | Where-Object duplicateExistingCode)
    }
    results = @($results)
}
Export-CityTechUtf8Json -InputObject $report -Path $ReportPath
Write-Host "Relatório de validação salvo em: $ReportPath"
Write-Host "Validados: $($report.summary.validated)/$($report.summary.total); falhas: $($report.summary.failed); itens criados: 0."

if ($report.summary.failed -gt 0 -or $report.summary.duplicateExistingCodes -gt 0) {
    exit 1
}
