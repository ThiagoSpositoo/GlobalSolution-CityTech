[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'CityTech.AzureDevOps.psm1') -Force
$modulePath = Join-Path $PSScriptRoot 'CityTech.AzureDevOps.psm1'
$catalog = Get-Content (Join-Path $PSScriptRoot '..\data\test-cases.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$mapping = Get-Content (Join-Path $PSScriptRoot '..\data\azure-mapping.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$cases = @(
    [pscustomobject]@{ name = 'minimum-array'; body = @(@{op='add';path='/fields/System.Title';value='Validação ç 漢字'}) },
    [pscustomobject]@{ name = 'minimum-single'; body = @{op='add';path='/fields/System.Title';value='Validação ç 漢字'} },
    [pscustomobject]@{ name = 'serialized'; body = '[{"op":"add","path":"/fields/System.Title","value":"Validação ç 漢字"}]' }
)
foreach ($tc in $catalog.testCases) {
    $feature = @($mapping.features | Where-Object { $_.featureKey -eq $tc.featureKey })[0]
    $patch = @(New-CityTechTestCasePatch -TestCase $tc -Title $tc.title -FeatureId $feature.id -FeatureTitle $feature.title -FeatureUrl "https://dev.azure.com/RM561694/_apis/wit/workItems/$($feature.id)")
    $cases += [pscustomobject]@{name=$tc.code;body=$patch}
}
$results = @()
foreach ($case in $cases) {
    $expected = if ($case.body -is [string]) { $case.body } else { ConvertTo-Json -InputObject @($case.body) -Depth 100 -Compress }
    $listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $port = $listener.LocalEndpoint.Port
    $job = $null
    $client = $null
    try {
        $job = Start-Job -ArgumentList $modulePath,$port,$expected,$case.name -ScriptBlock {
            param($modulePath,$port,$json,$name)
            Import-Module $modulePath -Force
            # Credencial fictícia exclusiva do processo filho; nunca usa o PAT real.
            $env:CITYTECH_HTTP_FIXTURE = 'local-fixture-not-a-token'
            $body = $json
            if ($name -ne 'serialized') {
                $body = ConvertFrom-Json -InputObject $json
                if ($name -eq 'minimum-single') { $body = @($body)[0] }
                else { $body = @($body) }
            }
            Invoke-CityTechAzDoRequest -Method POST -Uri "http://127.0.0.1:$port/test?validateOnly=true" -Body $body -ContentType 'application/json-patch+json' -PatEnvironmentVariable CITYTECH_HTTP_FIXTURE
        }
        $accept = $listener.AcceptTcpClientAsync()
        if (-not $accept.Wait(30000)) { throw 'Timeout do cliente local.' }
        $client = $accept.Result
        $stream = $client.GetStream()
        $stream.ReadTimeout = 30000
        $headerBytes = New-Object 'System.Collections.Generic.List[byte]'
        do {
            $b = $stream.ReadByte()
            if ($b -lt 0) { throw 'Conexão fechada antes dos headers.' }
            $headerBytes.Add([byte]$b)
            $header = [Text.Encoding]::ASCII.GetString($headerBytes.ToArray())
        } until ($header.EndsWith("`r`n`r`n"))
        if ($header -match '(?im)^Expect:\s*100-continue') {
            $continue = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 100 Continue`r`n`r`n")
            $stream.Write($continue,0,$continue.Length)
        }
        if ($header -notmatch '(?im)^Content-Length:\s*(\d+)') { throw 'Content-Length ausente.' }
        $length = [int]$matches[1]
        $bytes = New-Object byte[] $length
        $offset = 0
        while ($offset -lt $length) {
            $read = $stream.Read($bytes,$offset,$length-$offset)
            if ($read -eq 0) { throw 'Body incompleto.' }
            $offset += $read
        }
        $reply = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Length: 11`r`nConnection: close`r`n`r`n{`"ok`":true}")
        $stream.Write($reply,0,$reply.Length)
        $client.Close()
        if ($header -notmatch '(?im)^Content-Type:\s*application/json-patch\+json\s*\r?$') { throw 'Content-Type incorreto.' }
        $expectedBytes = [Text.Encoding]::UTF8.GetBytes($expected)
        if ([Convert]::ToBase64String($bytes) -cne [Convert]::ToBase64String($expectedBytes)) { throw 'Bytes recebidos divergem do UTF-8 esperado.' }
        $decoded = (New-Object Text.UTF8Encoding($false,$true)).GetString($bytes)
        if (-not $decoded.StartsWith('[')) { throw 'Raiz recebida não é array.' }
        $operations = ConvertFrom-Json -InputObject $decoded
        if ($null -eq (Wait-Job $job -Timeout 30)) { throw 'Timeout da resposta local.' }
        $response = Receive-Job $job -ErrorAction Stop
        if (-not $response.ok) { throw 'Resposta não desserializada.' }
        $results += [pscustomobject]@{case=$case.name;bytes=$length;operations=@($operations).Count;contentType='application/json-patch+json';status='passed'}
    }
    finally {
        if ($null -ne $client) { $client.Close() }
        $listener.Stop()
        if ($null -ne $job) { Remove-Job $job -Force }
    }
}
$results | Format-Table -AutoSize
Write-Host "HTTP real em loopback: $($results.Count) casos aprovados; nenhum acesso ao Azure."
