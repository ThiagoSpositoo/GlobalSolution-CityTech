Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-CityTechAzDoConfiguration {
    [CmdletBinding()]
    param(
        [string]$Organization = 'RM561694',
        [string]$Project = 'GlobalSolution-CityTech',
        [string]$PatEnvironmentVariable = 'AZURE_DEVOPS_PAT'
    )

    $pat = [Environment]::GetEnvironmentVariable($PatEnvironmentVariable)
    [pscustomobject]@{
        Organization = $Organization
        Project = $Project
        ProjectUrl = "https://dev.azure.com/$Organization/$Project"
        ApiBaseUrl = "https://dev.azure.com/$Organization/$([Uri]::EscapeDataString($Project))/_apis"
        PatEnvironmentVariable = $PatEnvironmentVariable
        HasCredential = -not [string]::IsNullOrWhiteSpace($pat)
    }
}

function Get-CityTechAzDoAuthorizationHeader {
    [CmdletBinding()]
    param([string]$PatEnvironmentVariable = 'AZURE_DEVOPS_PAT')

    $pat = [Environment]::GetEnvironmentVariable($PatEnvironmentVariable)
    if ([string]::IsNullOrWhiteSpace($pat)) {
        throw "A variável de ambiente $PatEnvironmentVariable não está definida no processo."
    }

    $bytes = [Text.Encoding]::ASCII.GetBytes(":$pat")
    "Basic $([Convert]::ToBase64String($bytes))"
}

function Invoke-CityTechAzDoRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateSet('GET', 'POST', 'PATCH')][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [object]$Body,
        [string]$ContentType = 'application/json',
        [string]$PatEnvironmentVariable = 'AZURE_DEVOPS_PAT'
    )

    $headers = @{
        Authorization = Get-CityTechAzDoAuthorizationHeader -PatEnvironmentVariable $PatEnvironmentVariable
        Accept = 'application/json'
    }

    $parameters = @{
        Method = $Method
        Uri = $Uri
        Headers = $headers
        ContentType = $ContentType
        UseBasicParsing = $true
    }

    if ($null -ne $Body) {
        if ($Body -is [string]) {
            $json = $Body
        }
        else {
            if ($ContentType -eq 'application/json-patch+json') {
                $json = ConvertTo-Json -InputObject @($Body) -Depth 100 -Compress
            }
            else {
                $json = ConvertTo-Json -InputObject $Body -Depth 100 -Compress
            }
        }
        if ($ContentType -eq 'application/json-patch+json') {
            if (-not $json.TrimStart().StartsWith('[')) {
                throw 'JSON Patch recusado localmente: a raiz deve ser um array JSON.'
            }
            $parsed = ConvertFrom-Json -InputObject $json -ErrorAction Stop
            if (@($parsed).Count -eq 0) { throw 'JSON Patch vazio.' }
            foreach ($operation in $parsed) {
                if (-not $operation.op -or -not $operation.path) { throw 'Operação JSON Patch inválida.' }
            }
        }
        # Byte[] explícito evita a codificação implícita de strings do PS 5.1.
        # Não passar bytes pelo pipeline nem serializar novamente este corpo.
        $parameters.Body = [Text.Encoding]::UTF8.GetBytes($json)
    }

    try {
        $response = Invoke-WebRequest @parameters
        if (-not [string]::IsNullOrWhiteSpace([string]$response.Content)) {
            ConvertFrom-Json -InputObject $response.Content
        }
    }
    catch {
        $status = $null
        $responseBody = ''
        if ($null -ne $_.ErrorDetails) { $responseBody = [string]$_.ErrorDetails.Message }
        if ($null -ne $_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
            if ([string]::IsNullOrWhiteSpace($responseBody)) {
                try {
                    $stream = $_.Exception.Response.GetResponseStream()
                    if ($null -ne $stream) {
                        $reader = New-Object IO.StreamReader($stream)
                        try {
                            $responseBody = $reader.ReadToEnd()
                        }
                        finally {
                            $reader.Dispose()
                        }
                    }
                }
                catch {
                    $responseBody = ''
                }
            }
        }

        $serviceMessage = ''
        $serviceType = ''
        if (-not [string]::IsNullOrWhiteSpace($responseBody)) {
            try {
                $serviceError = $responseBody | ConvertFrom-Json
                $serviceMessage = [string](Get-CityTechPropertyValue -InputObject $serviceError -Name 'message' -DefaultValue '')
                $serviceType = [string](Get-CityTechPropertyValue -InputObject $serviceError -Name 'typeName' -DefaultValue '')
            }
            catch {
                $serviceMessage = ($responseBody -replace '\s+', ' ').Trim()
            }
        }

        # Nunca inclua cabeçalhos no erro. Remova também o PAT e qualquer valor Basic
        # caso um proxy ou uma mensagem excepcional os repita no corpo.
        $pat = [Environment]::GetEnvironmentVariable($PatEnvironmentVariable)
        $authorizationValue = if ([string]::IsNullOrWhiteSpace($pat)) {
            ''
        }
        else {
            "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat")))"
        }
        foreach ($secret in @($pat, $authorizationValue)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$secret)) {
                $serviceMessage = $serviceMessage.Replace([string]$secret, '[REDACTED]')
            }
        }
        $serviceMessage = $serviceMessage -replace '(?i)\bBasic\s+[A-Za-z0-9+/=]+', 'Basic [REDACTED]'

        $suffix = if ($null -ne $status) { " (HTTP $status)" } else { '' }
        $detail = if (-not [string]::IsNullOrWhiteSpace($serviceMessage)) {
            " Mensagem do Azure: $serviceMessage"
        }
        else {
            " $($_.Exception.Message)"
        }
        $wrapped = New-Object Exception("Falha na API Azure DevOps$suffix. Método: $Method. URI: $Uri. Credenciais e cabeçalhos não foram exibidos.$detail", $_.Exception)
        if ($null -ne $status) {
            $wrapped.Data['StatusCode'] = $status
        }
        if (-not [string]::IsNullOrWhiteSpace($serviceMessage)) {
            $wrapped.Data['AzureMessage'] = $serviceMessage
        }
        if (-not [string]::IsNullOrWhiteSpace($serviceType)) {
            $wrapped.Data['AzureTypeName'] = $serviceType
        }
        throw $wrapped
    }
}

function ConvertTo-CityTechPlainText {
    [CmdletBinding()]
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ''
    }

    $text = [string]$Value
    $text = [Net.WebUtility]::HtmlDecode(($text -replace '<[^>]+>', ' '))
    ($text -replace '\s+', ' ').Trim()
}

function Get-CityTechPropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowNull()][object]$DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }
    return $property.Value
}

function Get-CityTechCollectionCount {
    [CmdletBinding()]
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return 0
    }
    return @($Value).Count
}

function ConvertTo-CityTechHtml {
    [CmdletBinding()]
    param([AllowNull()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $paragraphs = $Text -split "(`r`n|`n|`r){2,}"
    $html = foreach ($paragraph in $paragraphs) {
        $encoded = [Net.WebUtility]::HtmlEncode(($paragraph.Trim()))
        "<p>$($encoded -replace "(`r`n|`n|`r)", '<br>')</p>"
    }
    $html -join ''
}

function ConvertTo-CityTechStepsXml {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object[]]$Steps)

    $stepCount = Get-CityTechCollectionCount -Value $Steps
    if ($stepCount -eq 0) {
        throw 'Um Test Case precisa ter pelo menos um passo.'
    }

    $builder = New-Object Text.StringBuilder
    # O schema TCM reserva o id 1. Os passos começam em 2 e `last`
    # identifica o último id usado, não apenas a quantidade de passos.
    $lastId = $stepCount + 1
    [void]$builder.Append("<steps id=`"0`" last=`"$lastId`">")
    $id = 1
    foreach ($step in $Steps) {
        $id++
        $action = [Security.SecurityElement]::Escape([string]$step.action)
        $expected = [Security.SecurityElement]::Escape([string]$step.expected)
        [void]$builder.Append("<step id=`"$id`" type=`"ActionStep`">")
        [void]$builder.Append("<parameterizedString isformatted=`"true`">&lt;DIV&gt;$action&lt;/DIV&gt;</parameterizedString>")
        [void]$builder.Append("<parameterizedString isformatted=`"true`">&lt;DIV&gt;$expected&lt;/DIV&gt;</parameterizedString>")
        [void]$builder.Append('<description/>')
        [void]$builder.Append('</step>')
    }
    [void]$builder.Append('</steps>')
    $builder.ToString()
}

function New-CityTechTestCasePatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$TestCase,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][int]$FeatureId,
        [Parameter(Mandatory = $true)][string]$FeatureTitle,
        [Parameter(Mandatory = $true)][string]$FeatureUrl
    )

    $summary = @"
<p><strong>Objetivo:</strong> $([Net.WebUtility]::HtmlEncode([string]$TestCase.objective))</p>
<p><strong>Preparação:</strong> $([Net.WebUtility]::HtmlEncode([string]$TestCase.preconditions))</p>
<p><strong>Entradas:</strong> $([Net.WebUtility]::HtmlEncode([string]$TestCase.inputs))</p>
<p><strong>Saída esperada:</strong> $([Net.WebUtility]::HtmlEncode([string]$TestCase.expectedOutput))</p>
"@

    @(
        (New-CityTechJsonPatchOperation -Operation add -Path '/fields/System.Title' -Value $Title),
        (New-CityTechJsonPatchOperation -Operation add -Path '/fields/System.Description' -Value $summary),
        (New-CityTechJsonPatchOperation -Operation add -Path '/fields/Microsoft.VSTS.TCM.Steps' -Value (ConvertTo-CityTechStepsXml -Steps @($TestCase.steps))),
        (New-CityTechJsonPatchOperation -Operation add -Path '/fields/System.Tags' -Value "CityTech; QA-FIAP; $($TestCase.code); $($TestCase.type)"),
        (New-CityTechJsonPatchOperation -Operation add -Path '/relations/-' -Value ([ordered]@{
            rel = 'Microsoft.VSTS.Common.TestedBy-Reverse'
            url = $FeatureUrl
            attributes = [ordered]@{ comment = "Testa a Feature $FeatureId - $FeatureTitle" }
        }))
    )
}

function Get-CityTechRelationId {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Url)

    $match = [regex]::Match($Url, '/workItems/(\d+)$', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($match.Success) {
        return [int]$match.Groups[1].Value
    }
    return $null
}

function Get-CityTechWorkItemInventory {
    [CmdletBinding()]
    param(
        [string]$Organization = 'RM561694',
        [string]$Project = 'GlobalSolution-CityTech',
        [string]$PatEnvironmentVariable = 'AZURE_DEVOPS_PAT',
        [switch]$IncludeTestCases
    )

    $config = Get-CityTechAzDoConfiguration -Organization $Organization -Project $Project -PatEnvironmentVariable $PatEnvironmentVariable
    $types = @('Epic', 'Feature', 'Product Backlog Item')
    if ($IncludeTestCases) {
        $types += 'Test Case'
    }

    $quotedTypes = ($types | ForEach-Object { "'$($_ -replace "'", "''")'" }) -join ','
    $escapedProject = $Project -replace "'", "''"
    $wiql = @{
        query = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '$escapedProject' AND [System.WorkItemType] IN ($quotedTypes) ORDER BY [System.Id]"
    }
    $queryUri = "$($config.ApiBaseUrl)/wit/wiql?api-version=7.1"
    $queryResult = Invoke-CityTechAzDoRequest -Method POST -Uri $queryUri -Body $wiql -PatEnvironmentVariable $PatEnvironmentVariable
    $ids = @((Get-CityTechPropertyValue -InputObject $queryResult -Name 'workItems' -DefaultValue @()) | ForEach-Object { [int]$_.id })
    $idCount = Get-CityTechCollectionCount -Value $ids
    if ($idCount -eq 0) {
        return @()
    }

    $items = @()
    for ($offset = 0; $offset -lt $idCount; $offset += 200) {
        $last = [Math]::Min($offset + 199, $idCount - 1)
        $batch = @($ids[$offset..$last])
        $uri = "$($config.ApiBaseUrl)/wit/workitems?ids=$($batch -join ',')&`$expand=relations&api-version=7.1"
        $result = Invoke-CityTechAzDoRequest -Method GET -Uri $uri -PatEnvironmentVariable $PatEnvironmentVariable
        $items += @($result.value)
    }

    foreach ($item in ($items | Sort-Object id)) {
        $fields = $item.fields
        $parentIds = @()
        $childIds = @()
        $testedFeatureIds = @()
        foreach ($relation in @(Get-CityTechPropertyValue -InputObject $item -Name 'relations' -DefaultValue @())) {
            $relatedId = Get-CityTechRelationId -Url $relation.url
            if ($null -eq $relatedId) {
                continue
            }
            switch ($relation.rel) {
                'System.LinkTypes.Hierarchy-Reverse' { $parentIds += $relatedId }
                'System.LinkTypes.Hierarchy-Forward' { $childIds += $relatedId }
                'Microsoft.VSTS.Common.TestedBy-Reverse' { $testedFeatureIds += $relatedId }
            }
        }

        [pscustomobject]@{
            id = [int]$item.id
            type = [string](Get-CityTechPropertyValue $fields 'System.WorkItemType' '')
            title = [string](Get-CityTechPropertyValue $fields 'System.Title' '')
            state = [string](Get-CityTechPropertyValue $fields 'System.State' '')
            areaPath = [string](Get-CityTechPropertyValue $fields 'System.AreaPath' '')
            iterationPath = [string](Get-CityTechPropertyValue $fields 'System.IterationPath' '')
            description = [string](Get-CityTechPropertyValue $fields 'System.Description' '')
            acceptanceCriteria = [string](Get-CityTechPropertyValue $fields 'Microsoft.VSTS.Common.AcceptanceCriteria' '')
            tags = [string](Get-CityTechPropertyValue $fields 'System.Tags' '')
            parentIds = @($parentIds | Sort-Object -Unique)
            childIds = @($childIds | Sort-Object -Unique)
            testedFeatureIds = @($testedFeatureIds | Sort-Object -Unique)
            url = [string]$item.url
            rev = [int]$item.rev
        }
    }
}

function Test-CityTechContentMissing {
    [CmdletBinding()]
    param([AllowNull()][object]$Value)

    $plain = ConvertTo-CityTechPlainText -Value $Value
    [string]::IsNullOrWhiteSpace($plain) -or $plain.Length -lt 20 -or $plain -match '^(todo|tbd|a definir|pendente|descri[cç][aã]o)$'
}

function New-CityTechJsonPatchOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateSet('add', 'replace', 'test')][string]$Operation,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][object]$Value
    )

    [ordered]@{ op = $Operation; path = $Path; value = $Value }
}

function Export-CityTechUtf8Json {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$InputObject,
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Depth = 100
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        [IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    $json = ConvertTo-Json -InputObject $InputObject -Depth $Depth
    [IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
}

Export-ModuleMember -Function @(
    'ConvertTo-CityTechHtml',
    'ConvertTo-CityTechPlainText',
    'ConvertTo-CityTechStepsXml',
    'Export-CityTechUtf8Json',
    'Get-CityTechAzDoConfiguration',
    'Get-CityTechCollectionCount',
    'Get-CityTechWorkItemInventory',
    'Invoke-CityTechAzDoRequest',
    'New-CityTechJsonPatchOperation',
    'New-CityTechTestCasePatch',
    'Test-CityTechContentMissing'
)
