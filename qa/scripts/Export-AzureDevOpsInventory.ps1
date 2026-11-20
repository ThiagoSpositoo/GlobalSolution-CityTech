[CmdletBinding()]
param(
    [string]$Organization = 'RM561694',
    [string]$Project = 'GlobalSolution-CityTech',
    [string]$PatEnvironmentVariable = 'AZURE_DEVOPS_PAT',
    [string]$OutputDirectory,
    [switch]$IncludeTestCases
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'CityTech.AzureDevOps.psm1') -Force
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $PSScriptRoot '..\relatorios'
}

$config = Get-CityTechAzDoConfiguration -Organization $Organization -Project $Project -PatEnvironmentVariable $PatEnvironmentVariable
if (-not $config.HasCredential) {
    throw "Inventário não executado: defina $PatEnvironmentVariable somente no processo atual. Nenhuma chamada remota foi realizada."
}

[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$inventory = @(Get-CityTechWorkItemInventory -Organization $Organization -Project $Project -PatEnvironmentVariable $PatEnvironmentVariable -IncludeTestCases:$IncludeTestCases)

$counts = [ordered]@{}
foreach ($group in ($inventory | Group-Object type | Sort-Object Name)) {
    $counts[$group.Name] = $group.Count
}

$document = [ordered]@{
    schemaVersion = 1
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    organization = $Organization
    project = $Project
    projectUrl = $config.ProjectUrl
    counts = $counts
    items = $inventory
}

$jsonPath = Join-Path $OutputDirectory 'azure-work-items.json'
$csvPath = Join-Path $OutputDirectory 'azure-work-items.csv'
Export-CityTechUtf8Json -InputObject $document -Path $jsonPath
$inventory |
    Select-Object id, type, title, state,
        @{ Name = 'parentIds'; Expression = { $_.parentIds -join ';' } },
        @{ Name = 'childIds'; Expression = { $_.childIds -join ';' } },
        @{ Name = 'descriptionMissing'; Expression = { Test-CityTechContentMissing $_.description } },
        @{ Name = 'acceptanceCriteriaMissing'; Expression = { Test-CityTechContentMissing $_.acceptanceCriteria } } |
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Inventário somente leitura concluído: $($inventory.Count) item(ns)."
foreach ($entry in $counts.GetEnumerator()) {
    Write-Host ("- {0}: {1}" -f $entry.Key, $entry.Value)
}
Write-Host "JSON: $jsonPath"
Write-Host "CSV:  $csvPath"
