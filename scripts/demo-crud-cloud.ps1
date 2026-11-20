#requires -Version 5.1
<#
.SYNOPSIS
    Executa o CRUD real da API CityTech publicada na Azure e imprime status/JSON de cada chamada.

.DESCRIPTION
    Serve como evidência objetiva para o vídeo e para o PDF da disciplina DevOps:
      1. GET  /                      (aplicação publicada)
      2. GET  /health/live           (processo vivo)
      3. POST /api/v1/auth/register  (CREATE em accounts)
      4. POST /api/v1/auth/login     (leitura/autenticação)
      5. GET  /api/v1/auth/me        (READ da conta autenticada)
      6. POST /api/v1/followups      (CREATE em follow_ups - exige Java alcançável)
      7. GET  /api/v1/followups      (READ)
      8. PATCH /api/v1/followups/id  (UPDATE com controle de versão)
      9. DELETE /api/v1/followups/id (DELETE)
    Nenhuma credencial é gravada em arquivo; a senha informada é apenas usada na chamada.

.PARAMETER BaseUrl
    URL pública da API, por exemplo https://citytech-api-xxx.azurewebsites.net

.PARAMETER Email
    E-mail fictício usado na demonstração. Padrão: cidadao.demo@citytech.local

.PARAMETER Password
    Senha fictícia (8-128 caracteres, com letra e número).

.PARAMETER OccurrenceId
    GUID de uma ocorrência existente no Java. Sem ele, o passo de criação de acompanhamento é
    apenas informado como indisponível (a API .NET valida a ocorrência no Java antes de gravar).

.EXAMPLE
    .\scripts\demo-crud-cloud.ps1 -BaseUrl https://citytech-api-xxx.azurewebsites.net
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [string]$Email = 'cidadao.demo@citytech.local',
    [string]$Password = 'CityTech2026Demo',
    [string]$OccurrenceId = ''
)

Set-StrictMode -Version 2.0
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BaseUrl = $BaseUrl.TrimEnd('/')
$script:token = $null
$script:failures = 0

function Invoke-CityTech {
    param(
        [string]$Method,
        [string]$Path,
        [object]$Body = $null,
        [hashtable]$Headers = @{},
        [switch]$AllowFailure
    )

    $uri = "$BaseUrl$Path"
    $params = @{
        Method      = $Method
        Uri         = $uri
        Headers     = $Headers
        UseBasicParsing = $true
        TimeoutSec  = 60
    }
    if ($null -ne $Body) {
        $params['ContentType'] = 'application/json; charset=utf-8'
        $params['Body'] = ($Body | ConvertTo-Json -Depth 6 -Compress)
    }

    $status = 0
    $content = ''
    try {
        $response = Invoke-WebRequest @params
        $status = [int]$response.StatusCode
        $content = $response.Content
    } catch {
        if ($null -eq $_.Exception.Response) { throw }
        $status = [int]$_.Exception.Response.StatusCode
        $reader = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
        $content = $reader.ReadToEnd()
        if (-not $AllowFailure) {
            Write-Host ("    corpo: " + $content) -ForegroundColor DarkGray
        }
    }

    $summary = if ([string]::IsNullOrWhiteSpace($content)) { '' } else { $content }
    if ($summary.Length -gt 400) { $summary = $summary.Substring(0, 400) + '...' }
    $color = if ($status -ge 200 -and $status -lt 300) { 'Green' } else { 'Yellow' }
    Write-Host ("    {0} {1} -> {2}" -f $Method, $Path, $status) -ForegroundColor $color
    if ($summary) { Write-Host "    $summary" -ForegroundColor DarkGray }

    [pscustomobject]@{ Status = $status; Content = $content }
}

Write-Host ''
Write-Host '=== CityTech - CRUD da API publicada ===' -ForegroundColor Cyan
Write-Host "Base: $BaseUrl"

Write-Host ''
Write-Host '[1] Aplicação publicada'
$root = Invoke-CityTech -Method 'GET' -Path '/'

Write-Host ''
Write-Host '[2] Liveness (processo)'
$live = Invoke-CityTech -Method 'GET' -Path '/health/live'

Write-Host ''
Write-Host '[3] CREATE - cadastro de cidadão (accounts)'
$registerHeaders = @{ 'Idempotency-Key' = [Guid]::NewGuid().ToString() }
$register = Invoke-CityTech -Method 'POST' -Path '/api/v1/auth/register' -Headers $registerHeaders -AllowFailure -Body @{
    name     = 'Cidadão Demonstração'
    email    = $Email
    password = $Password
}
if ($register.Status -eq 409) {
    Write-Host '    Conta já existente de execução anterior; seguindo para o login.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '[4] LOGIN - emissão do JWT'
$login = Invoke-CityTech -Method 'POST' -Path '/api/v1/auth/login' -AllowFailure -Body @{
    email    = $Email
    password = $Password
}
if ($login.Status -ne 200) {
    Write-Host '    Login falhou; encerrando a demonstração.' -ForegroundColor Red
    exit 1
}
$loginJson = $login.Content | ConvertFrom-Json
$script:token = $loginJson.accessToken
$authHeaders = @{ Authorization = "Bearer $script:token" }

Write-Host ''
Write-Host '[5] READ - /auth/me'
Invoke-CityTech -Method 'GET' -Path '/api/v1/auth/me' -Headers $authHeaders | Out-Null

Write-Host ''
Write-Host '[6] CREATE - acompanhamento (follow_ups)'
$followUpId = $null
if ([string]::IsNullOrWhiteSpace($OccurrenceId)) {
    Write-Host '    Ocorrência não informada (-OccurrenceId).' -ForegroundColor Yellow
    Write-Host '    A API .NET valida a ocorrência no Java; sem Java publicado este passo retorna 503.' -ForegroundColor Yellow
    Write-Host '    Para a evidência de CRUD em follow_ups, use o SQL do README (INSERT/SELECT/UPDATE/DELETE).' -ForegroundColor Yellow
} else {
    $create = Invoke-CityTech -Method 'POST' -Path '/api/v1/followups' -Headers (@{
        Authorization     = "Bearer $script:token"
        'Idempotency-Key' = [Guid]::NewGuid().ToString()
    }) -AllowFailure -Body @{ occurrenceId = $OccurrenceId; note = 'Acompanhamento criado na demonstração DevOps.' }
    if ($create.Status -eq 201) {
        $followUpId = ($create.Content | ConvertFrom-Json).id
    } elseif ($create.Status -eq 409) {
        Write-Host '    Já existe acompanhamento para esta ocorrência; usando o existente na listagem.' -ForegroundColor Yellow
    } else {
        Write-Host '    Criação indisponível (Java não publicado).' -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '[7] READ - listagem de acompanhamentos'
$list = Invoke-CityTech -Method 'GET' -Path '/api/v1/followups?page=0&size=20' -Headers $authHeaders
if ([string]::IsNullOrWhiteSpace($followUpId)) {
    try {
        $page = $list.Content | ConvertFrom-Json
        if ($page.items -and $page.items.Count -gt 0) { $followUpId = $page.items[0].id }
    } catch { }
}

if ($followUpId) {
    Write-Host ''
    Write-Host '[8] UPDATE - PATCH do acompanhamento'
    $current = Invoke-CityTech -Method 'GET' -Path "/api/v1/followups/$followUpId" -Headers $authHeaders -AllowFailure
    if ($current.Status -eq 200) {
        $version = ($current.Content | ConvertFrom-Json).version
        Invoke-CityTech -Method 'PATCH' -Path "/api/v1/followups/$followUpId" -Headers $authHeaders -AllowFailure -Body @{
            note    = 'Observação atualizada na demonstração DevOps.'
            version = $version
        } | Out-Null

        Write-Host ''
        Write-Host '[9] DELETE - remoção do acompanhamento'
        Invoke-CityTech -Method 'DELETE' -Path "/api/v1/followups/$followUpId" -Headers $authHeaders -AllowFailure | Out-Null
    }
} else {
    Write-Host ''
    Write-Host '[8][9] UPDATE/DELETE não executados: nenhum acompanhamento disponível.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '[10] Versão publicada (endpoint adicionado na tarefa do Boards)'
Invoke-CityTech -Method 'GET' -Path '/api/v1/version' -AllowFailure | Out-Null

Write-Host ''
Write-Host '=== Fim. Confirme a persistência com SELECT no Azure SQL (Query Editor do Portal). ===' -ForegroundColor Cyan
