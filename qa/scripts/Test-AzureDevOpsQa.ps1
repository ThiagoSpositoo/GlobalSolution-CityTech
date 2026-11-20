[CmdletBinding()]
param(
    [string]$Organization = 'RM561694',
    [string]$Project = 'GlobalSolution-CityTech',
    [string]$PatEnvironmentVariable = 'AZURE_DEVOPS_PAT',
    [string]$MappingPath,
    [string]$TestCasesPath,
    [string]$ReportPath
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
    $ReportPath = Join-Path $PSScriptRoot '..\relatorios\verification.json'
}

$mapping = Get-Content -Raw -Path $MappingPath -Encoding UTF8 | ConvertFrom-Json
$catalog = Get-Content -Raw -Path $TestCasesPath -Encoding UTF8 | ConvertFrom-Json
$items = @(Get-CityTechWorkItemInventory -Organization $Organization -Project $Project -PatEnvironmentVariable $PatEnvironmentVariable -IncludeTestCases)

$results = @()
foreach ($item in @($items | Where-Object { $_.type -in @('Feature', 'Product Backlog Item') })) {
    $results += [ordered]@{
        check = 'documentation'
        id = [int]$item.id
        type = [string]$item.type
        title = [string]$item.title
        passed = (-not (Test-CityTechContentMissing $item.description)) -and (-not (Test-CityTechContentMissing $item.acceptanceCriteria))
    }
}

$testCasesByCode = @{}
foreach ($item in @($items | Where-Object type -eq 'Test Case')) {
    if ([string]$item.title -match '^(TC-[A-Z0-9-]+)\s+-') {
        $testCasesByCode[$matches[1]] = $item
    }
}
$featureByKey = @{}
foreach ($feature in @($mapping.features)) {
    $featureByKey[[string]$feature.featureKey] = [int]$feature.id
}

foreach ($planned in @($catalog.testCases)) {
    $code = [string]$planned.code
    $exists = $testCasesByCode.ContainsKey($code)
    $linked = $false
    $id = $null
    if ($exists) {
        $actual = $testCasesByCode[$code]
        $id = [int]$actual.id
        $expectedFeatureId = $featureByKey[[string]$planned.featureKey]
        $linked = $expectedFeatureId -in @($actual.testedFeatureIds)
    }
    $results += [ordered]@{
        check = 'test-case'
        code = $code
        id = $id
        exists = $exists
        linkedToExpectedFeature = $linked
        passed = $exists -and $linked
    }
}

$report = [ordered]@{
    schemaVersion = 1
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    organization = $Organization
    project = $Project
    counts = [ordered]@{
        epics = @($items | Where-Object type -eq 'Epic').Count
        features = @($items | Where-Object type -eq 'Feature').Count
        productBacklogItems = @($items | Where-Object type -eq 'Product Backlog Item').Count
        testCases = @($items | Where-Object type -eq 'Test Case').Count
        passedChecks = @($results | Where-Object passed).Count
        failedChecks = @($results | Where-Object { -not $_.passed }).Count
    }
    results = @($results)
}
Export-CityTechUtf8Json -InputObject $report -Path $ReportPath
Write-Host "Verificação salva em $ReportPath"
Write-Host "Aprovadas: $($report.counts.passedChecks); pendentes/falhas: $($report.counts.failedChecks)"
if ($report.counts.failedChecks -gt 0) {
    exit 2
}
