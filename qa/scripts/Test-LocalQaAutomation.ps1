[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'CityTech.AzureDevOps.psm1') -Force

$failures = @()
function Assert-Local {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        $script:failures += $Message
    }
}

$config = Get-CityTechAzDoConfiguration
Assert-Local ($config.Organization -eq 'RM561694') 'Organização padrão incorreta.'
Assert-Local ($config.Project -eq 'GlobalSolution-CityTech') 'Projeto padrão incorreto.'
Assert-Local ($config.ProjectUrl -eq 'https://dev.azure.com/RM561694/GlobalSolution-CityTech') 'URL padrão incorreta.'

# Regressão PowerShell 5.1 + StrictMode: valores nulos, únicos e arrays
# devem ser contados somente depois de normalizados com @(...).
$nullCollection = $null
$singleObject = [pscustomobject]@{ id = 1 }
$emptyCollection = @()
Assert-Local ((Get-CityTechCollectionCount -Value $nullCollection) -eq 0) 'Normalização de coleção nula falhou.'
Assert-Local ((Get-CityTechCollectionCount -Value $singleObject) -eq 1) 'Normalização de objeto único falhou.'
Assert-Local ((Get-CityTechCollectionCount -Value $emptyCollection) -eq 0) 'Normalização de array vazio falhou.'

$steps = @(
    [pscustomobject]@{ action = 'Enviar <payload> válido.'; expected = 'Receber HTTP 201 & Location.' },
    [pscustomobject]@{ action = 'Consultar o recurso.'; expected = 'Visualizar os dados persistidos.' }
)
$xml = ConvertTo-CityTechStepsXml -Steps $steps
Assert-Local ($xml -match '^<steps ') 'XML de passos não começa com steps.'
Assert-Local ($xml -match 'last="3"') 'XML de passos não registra o último id TCM.'
Assert-Local ($xml -match '<step id="2" type="ActionStep">') 'Primeiro passo TCM não começa no id 2.'
Assert-Local ($xml -match '<step id="3" type="ActionStep">') 'Segundo passo TCM não usa o id 3.'
Assert-Local ($xml -match '&lt;payload&gt;') 'XML de passos não escapa conteúdo.'
Assert-Local ($xml -match '&amp;') 'XML de passos não escapa ampersand.'
try {
    [xml]$xml | Out-Null
}
catch {
    $failures += "XML de passos inválido: $($_.Exception.Message)"
}

Assert-Local (Test-CityTechContentMissing '') 'Campo vazio deveria ser pendente.'
Assert-Local (Test-CityTechContentMissing '<p>TODO</p>') 'Placeholder deveria ser pendente.'
Assert-Local (-not (Test-CityTechContentMissing '<p>Descrição específica e verificável do comportamento.</p>')) 'Conteúdo válido foi marcado como pendente.'

$dataDirectory = Join-Path $PSScriptRoot '..\data'
$catalogPath = Join-Path $dataDirectory 'test-cases.json'
$mappingPath = Join-Path $dataDirectory 'azure-mapping.json'
$contentPath = Join-Path $dataDirectory 'work-item-content.json'
foreach ($path in @($catalogPath, $mappingPath, $contentPath)) {
    Assert-Local (Test-Path $path -PathType Leaf) "Arquivo obrigatório ausente: $path"
    if (Test-Path $path -PathType Leaf) {
        try {
            Get-Content -Raw -Path $path -Encoding UTF8 | ConvertFrom-Json | Out-Null
        }
        catch {
            $failures += "JSON inválido: $path. $($_.Exception.Message)"
        }
    }
}

if (Test-Path $catalogPath -PathType Leaf) {
    $catalog = Get-Content -Raw -Path $catalogPath -Encoding UTF8 | ConvertFrom-Json
    $codes = @($catalog.testCases | ForEach-Object { $_.code })
    Assert-Local ($codes.Count -ge 24) 'O catálogo precisa de pelo menos dois casos por cada uma das 12 Features.'
    Assert-Local (($codes | Sort-Object -Unique).Count -eq $codes.Count) 'Há códigos de Test Case duplicados.'
    foreach ($testCase in @($catalog.testCases)) {
        Assert-Local (-not [string]::IsNullOrWhiteSpace([string]$testCase.featureKey)) "Feature ausente em $($testCase.code)."
        Assert-Local (-not [string]::IsNullOrWhiteSpace([string]$testCase.objective)) "Objetivo ausente em $($testCase.code)."
        Assert-Local (-not [string]::IsNullOrWhiteSpace([string]$testCase.preconditions)) "Preparação ausente em $($testCase.code)."
        Assert-Local (-not [string]::IsNullOrWhiteSpace([string]$testCase.inputs)) "Inputs ausentes em $($testCase.code)."
        Assert-Local (-not [string]::IsNullOrWhiteSpace([string]$testCase.expectedOutput)) "Output ausente em $($testCase.code)."
        Assert-Local (@($testCase.steps).Count -ge 2) "Menos de dois passos em $($testCase.code)."
        foreach ($step in @($testCase.steps)) {
            Assert-Local (-not [string]::IsNullOrWhiteSpace([string]$step.action)) "Ação vazia em $($testCase.code)."
            Assert-Local (-not [string]::IsNullOrWhiteSpace([string]$step.expected)) "Resultado de passo vazio em $($testCase.code)."
        }
    }
}

$mapping = Get-Content -Raw -Path $mappingPath -Encoding UTF8 | ConvertFrom-Json
$content = Get-Content -Raw -Path $contentPath -Encoding UTF8 | ConvertFrom-Json
Assert-Local (@($mapping.epics).Count -eq 5) 'O mapeamento canônico precisa conter 5 Epics.'
Assert-Local (@($mapping.features).Count -eq 12) 'O mapeamento canônico precisa conter 12 Features.'
Assert-Local (@($mapping.productBacklogItems).Count -eq 39) 'O mapeamento canônico precisa conter 39 PBIs.'
Assert-Local (@($content.workItems).Count -eq 51) 'O catálogo documental precisa conter 51 Features+PBIs.'

foreach ($item in @($content.workItems)) {
    Assert-Local (-not [string]::IsNullOrWhiteSpace([string]$item.description)) "Descrição vazia no Work Item $($item.id)."
    Assert-Local (@($item.acceptanceCriteria).Count -ge 3) "Menos de três critérios no Work Item $($item.id)."
}

$testGroups = @($catalog.testCases | Group-Object featureKey)
foreach ($feature in @($mapping.features)) {
    $group = @($testGroups | Where-Object { $_.Name -eq $feature.featureKey })
    Assert-Local ($group.Count -eq 1 -and $group[0].Count -eq 2) "A Feature $($feature.id) não possui exatamente dois Test Cases."
    if ($group.Count -eq 1) {
        Assert-Local (@($group[0].Group.type | Sort-Object -Unique).Count -eq 2) "A Feature $($feature.id) não possui casos positivo e negativo."
    }
}

$firstTestCase = @($catalog.testCases)[0]
$firstFeature = @($mapping.features | Where-Object { $_.featureKey -eq $firstTestCase.featureKey })[0]
$testCasePatch = @(New-CityTechTestCasePatch `
    -TestCase $firstTestCase `
    -Title "$($firstTestCase.code) - $($firstTestCase.title)" `
    -FeatureId ([int]$firstFeature.id) `
    -FeatureTitle ([string]$firstFeature.title) `
    -FeatureUrl "https://dev.azure.com/RM561694/GlobalSolution-CityTech/_apis/wit/workItems/$($firstFeature.id)")
Assert-Local ($testCasePatch.Count -eq 5) 'Patch completo de Test Case precisa ter cinco operações.'
Assert-Local ((@($testCasePatch.path) -join '|') -eq '/fields/System.Title|/fields/System.Description|/fields/Microsoft.VSTS.TCM.Steps|/fields/System.Tags|/relations/-') 'Ordem/campos do patch de Test Case divergiram.'
Assert-Local ([string]$testCasePatch[4].value.rel -eq 'Microsoft.VSTS.Common.TestedBy-Reverse') 'Relação Test Case → Feature está incorreta.'
try {
    $serializedPatch = ConvertTo-Json -InputObject $testCasePatch -Depth 100 -Compress
    $roundTripPatch = $serializedPatch | ConvertFrom-Json
    Assert-Local (@($roundTripPatch).Count -eq 5) 'Serialização JSON do patch não preservou as cinco operações.'
}
catch {
    $failures += "Serialização JSON Patch inválida: $($_.Exception.Message)"
}

if ($failures.Count -gt 0) {
    Write-Error ("Validação local falhou:`n- " + ($failures -join "`n- "))
}

Write-Host 'Validação local concluída sem chamadas remotas e sem alterações no Azure.'
