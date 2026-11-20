[CmdletBinding()]
param(
    [string]$InventoryPath,
    [string]$OutputDirectory
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'CityTech.AzureDevOps.psm1') -Force
if ([string]::IsNullOrWhiteSpace($InventoryPath)) {
    $InventoryPath = Join-Path $PSScriptRoot '..\relatorios\azure-work-items.json'
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $PSScriptRoot '..\relatorios'
}

if (-not (Test-Path $InventoryPath -PathType Leaf)) {
    throw "Inventário ausente: $InventoryPath. Execute Export-AzureDevOpsInventory.ps1 primeiro."
}

$inventory = Get-Content -Raw -Path $InventoryPath -Encoding UTF8 | ConvertFrom-Json
$items = @($inventory.items)
$counts = @{
    Epic = @($items | Where-Object type -eq 'Epic').Count
    Feature = @($items | Where-Object type -eq 'Feature').Count
    'Product Backlog Item' = @($items | Where-Object type -eq 'Product Backlog Item').Count
}

if ($counts.Epic -ne 5 -or $counts.Feature -ne 12 -or $counts.'Product Backlog Item' -ne 39) {
    throw "Inventário incompatível com a base declarada. Encontrado: Epics=$($counts.Epic), Features=$($counts.Feature), PBIs=$($counts.'Product Backlog Item'). Esperado: 5/12/39."
}

[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$mapping = [ordered]@{
    schemaVersion = 1
    sourceGeneratedAtUtc = $inventory.generatedAtUtc
    organization = $inventory.organization
    project = $inventory.project
    expectedCounts = [ordered]@{ epics = 5; features = 12; productBacklogItems = 39 }
    features = @($items | Where-Object type -eq 'Feature' | Sort-Object id | ForEach-Object {
        [ordered]@{
            featureKey = $null
            id = [int]$_.id
            title = [string]$_.title
            rev = [int]$_.rev
        }
    })
}

$content = [ordered]@{
    schemaVersion = 1
    sourceGeneratedAtUtc = $inventory.generatedAtUtc
    workItems = @($items |
        Where-Object { $_.type -in @('Feature', 'Product Backlog Item') } |
        Sort-Object id |
        ForEach-Object {
            [ordered]@{
                id = [int]$_.id
                type = [string]$_.type
                title = [string]$_.title
                sourceRev = [int]$_.rev
                description = ''
                acceptanceCriteria = @()
            }
        })
}

$mappingPath = Join-Path $OutputDirectory 'azure-mapping.generated.json'
$contentPath = Join-Path $OutputDirectory 'work-item-content.generated.json'
Export-CityTechUtf8Json -InputObject $mapping -Path $mappingPath
Export-CityTechUtf8Json -InputObject $content -Path $contentPath

Write-Host 'Templates gerados sem alterar os arquivos canônicos:'
Write-Host "- $mappingPath"
Write-Host "- $contentPath"
Write-Host 'Revise os títulos/relacionamentos e preencha featureKey, descrições e critérios antes de copiar para qa/data/.'
