#requires -Version 5.1
<#
    Azure CLI falso, usado SOMENTE pelos testes locais de scripts/provision-azure.ps1.

    Não conversa com o Azure. Lê o estado simulado de $env:AZMOCK_STATE, registra cada
    chamada em $env:AZMOCK_LOG e simula criação/alteração de recursos para que o script
    possa ser testado com recursos existentes, inexistentes e erros reais.

    Formato do estado (JSON):
    {
      "subscriptionId": "...",
      "rgExists": false, "planExists": false, "sqlExists": false,
      "fwExists": false, "dbExists": false, "webExists": false,
      "fwStart": "0.0.0.0", "fwEnd": "0.0.0.0",
      "inject": { "match": "sql server show", "stderr": "ERROR: ...", "exit": 1 },
      "warn":   { "match": "group create", "message": "WARNING: aviso do Azure CLI" }
    }
#>
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$statePath = $env:AZMOCK_STATE
$logPath = $env:AZMOCK_LOG
if ([string]::IsNullOrWhiteSpace($statePath) -or -not (Test-Path -LiteralPath $statePath)) {
    [Console]::Error.WriteLine('AZMOCK_STATE ausente ou inválido.')
    exit 90
}

$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
$invocation = ($args -join ' ')

if (-not [string]::IsNullOrWhiteSpace($logPath)) {
    Add-Content -LiteralPath $logPath -Value $invocation -Encoding UTF8
}

function Save-State {
    param([object]$State)
    $json = $State | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText($statePath, $json, (New-Object Text.UTF8Encoding($false)))
}

function Get-StateValue {
    param([object]$Object, [string]$Name, [object]$Default = $false)
    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $Default }
    return $property.Value
}

function Fail {
    param([string]$Code, [string]$Message, [int]$ExitCode = 3)
    [Console]::Error.WriteLine("ERROR: ($Code) $Message")
    exit $ExitCode
}

function Emit {
    param([object]$Payload)
    Write-Output ($Payload | ConvertTo-Json -Depth 6 -Compress)
    exit 0
}

# --- injeção de erro real (testa se o script NÃO mascara falhas) -----------------
$inject = Get-StateValue $state 'inject' $null
if ($null -ne $inject) {
    $injectMatch = [string](Get-StateValue $inject 'match' '')
    if ($injectMatch -and $invocation -like "*$injectMatch*") {
        $injectText = [string](Get-StateValue $inject 'stderr' 'ERROR: falha injetada')
        $injectExit = [int](Get-StateValue $inject 'exit' 1)
        [Console]::Error.WriteLine($injectText)
        exit $injectExit
    }
}

# --- aviso em stderr com sucesso (regressão: não pode virar exceção) --------------
$warn = Get-StateValue $state 'warn' $null
if ($null -ne $warn) {
    $warnMatch = [string](Get-StateValue $warn 'match' '')
    if ($warnMatch -and $invocation -like "*$warnMatch*") {
        [Console]::Error.WriteLine([string](Get-StateValue $warn 'message' 'WARNING: aviso simulado'))
    }
}

$outputJson = ($args -contains 'json')
$subscriptionId = [string](Get-StateValue $state 'subscriptionId' '11111111-1111-1111-1111-111111111111')

# --- account ---------------------------------------------------------------------
if ($invocation -like 'account show*') {
    if ($outputJson) {
        Emit ([ordered]@{
                user   = [ordered]@{ name = 'teste@citytech.local' }
                name   = 'Assinatura CityTech (simulada)'
                id     = $subscriptionId
                state  = 'Enabled'
                tenantId = '00000000-0000-0000-0000-000000000000'
            })
    }
    exit 0
}
if ($invocation -like 'account set*') {
    # Simula assinatura inexistente quando o ID pedido difere do ID da conta.
    $requested = ''
    for ($index = 0; $index -lt $args.Count; $index++) {
        if ($args[$index] -eq '--subscription' -and ($index + 1) -lt $args.Count) {
            $requested = [string]$args[$index + 1]
        }
    }
    if ($requested -and $requested -ne $subscriptionId) {
        Fail 'SubscriptionNotFound' "The subscription '$requested' could not be found." 1
    }
    exit 0
}

# --- politicas -------------------------------------------------------------------
if ($invocation -like 'policy assignment list*') {
    $allowed = Get-StateValue $state 'allowedLocations' $null
    if ($null -eq $allowed) {
        Write-Output '[]'
        exit 0
    }
    # Uma única atribuição com a lista completa (como a política real da assinatura).
    $values = (@($allowed) | ForEach-Object { '"' + [string]$_ + '"' }) -join ','
    $entry = '{"name":"sys.regionrestriction","displayName":"Allowed resource deployment regions",' +
        '"policyDefinitionId":"/providers/Microsoft.Authorization/policyDefinitions/b86dabb9-b578-4d7b-b842-3b45e95769a1",' +
        '"parameters":{"listOfAllowedLocations":{"value":[' + $values + ']}}}'
    Write-Output ('[' + $entry + ']')
    exit 0
}

# --- providers -------------------------------------------------------------------
if ($invocation -like 'provider show*') {
    $namespace = ''
    for ($index = 0; $index -lt $args.Count; $index++) {
        if ($args[$index] -eq '--namespace' -and ($index + 1) -lt $args.Count) {
            $namespace = [string]$args[$index + 1]
        }
    }

    $default = @('Brazil South', 'East US', 'East US 2', 'Canada Central', 'North Central US', 'South Central US')
    $locations = $default
    if ($namespace -eq 'Microsoft.Sql') {
        $locations = Get-StateValue $state 'sqlLocations' $default
    } elseif ($namespace -eq 'Microsoft.Web') {
        $locations = Get-StateValue $state 'webLocations' $default
    }

    $quoted = @(@($locations) | ForEach-Object { '"' + [string]$_ + '"' }) -join ','
    Write-Output ('[[' + $quoted + ']]')
    exit 0
}

# --- resource group --------------------------------------------------------------
if ($invocation -like 'group show*') {
    if (-not (Get-StateValue $state 'rgExists' $false)) {
        Fail 'ResourceGroupNotFound' "Resource group 'rg-citytech-devops' could not be found."
    }
    Emit ([ordered]@{ name = 'rg-citytech-devops'; location = 'brazilsouth' })
}
if ($invocation -like 'group create*') {
    $state.rgExists = $true
    Save-State $state
    exit 0
}

# --- app service plan ------------------------------------------------------------
if ($invocation -like 'appservice plan show*') {
    if (-not (Get-StateValue $state 'planExists' $false)) {
        Fail 'ResourceNotFound' "The Resource 'Microsoft.Web/serverfarms/citytech-api-rm561694-2026-plan' under resource group 'rg-citytech-devops' was not found."
    }
    Emit ([ordered]@{
            name       = 'citytech-api-rm561694-2026-plan'
            location   = 'brazilsouth'
            sku        = [ordered]@{ name = 'B1'; tier = 'Basic' }
            properties = [ordered]@{ reserved = $true }
        })
}
if ($invocation -like 'appservice plan create*') {
    $state.planExists = $true
    Save-State $state
    exit 0
}

# --- sql server ------------------------------------------------------------------
if ($invocation -like 'sql server show*') {
    if (-not (Get-StateValue $state 'sqlExists' $false)) {
        Fail 'ResourceNotFound' "The Resource 'Microsoft.Sql/servers/citytech-sql-rm561694-2026' under resource group 'rg-citytech-devops' was not found."
    }
    Emit ([ordered]@{
            name       = 'citytech-sql-rm561694-2026'
            location   = 'brazilsouth'
            properties = [ordered]@{ administratorLogin = 'citytechadmin' }
        })
}
if ($invocation -like 'sql server create*') {
    $state.sqlExists = $true
    Save-State $state
    exit 0
}

# --- firewall --------------------------------------------------------------------
if ($invocation -like 'sql server firewall-rule show*') {
    if (-not (Get-StateValue $state 'fwExists' $false)) {
        Fail 'ResourceNotFound' "The firewall rule 'AllowAzureServices' does not exist on server 'citytech-sql-rm561694-2026'."
    }
    Emit ([ordered]@{
            name           = 'AllowAzureServices'
            startIpAddress = [string](Get-StateValue $state 'fwStart' '0.0.0.0')
            endIpAddress   = [string](Get-StateValue $state 'fwEnd' '0.0.0.0')
        })
}
if ($invocation -like 'sql server firewall-rule create*' -or $invocation -like 'sql server firewall-rule update*') {
    $state.fwExists = $true
    $state.fwStart = '0.0.0.0'
    $state.fwEnd = '0.0.0.0'
    Save-State $state
    exit 0
}

# --- database --------------------------------------------------------------------
if ($invocation -like 'sql db show*') {
    if (-not (Get-StateValue $state 'dbExists' $false)) {
        Fail 'ResourceNotFound' "The Resource 'Microsoft.Sql/servers/citytech-sql-rm561694-2026/databases/citytechdb' was not found."
    }
    Emit ([ordered]@{
            name                       = 'citytechdb'
            status                     = 'Online'
            currentServiceObjectiveName = 'Basic'
        })
}
if ($invocation -like 'sql db create*') {
    $state.dbExists = $true
    Save-State $state
    exit 0
}

# --- web app ---------------------------------------------------------------------
if ($invocation -like 'webapp list-runtimes*') {
    Emit @('DOTNETCORE:9.0', 'DOTNETCORE:10.0')
}
if ($invocation -like 'webapp show*') {
    if (-not (Get-StateValue $state 'webExists' $false)) {
        Fail 'ResourceNotFound' "The Resource 'Microsoft.Web/sites/citytech-api-rm561694-2026' was not found."
    }
    Emit ([ordered]@{
            name            = 'citytech-api-rm561694-2026'
            state           = 'Running'
            defaultHostName = 'citytech-api-rm561694-2026.azurewebsites.net'
            httpsOnly       = $true
        })
}
if ($invocation -like 'webapp create*') {
    $state.webExists = $true
    Save-State $state
    exit 0
}
if ($invocation -like 'webapp config*' -or $invocation -like 'webapp update*') { exit 0 }

# --- listagem --------------------------------------------------------------------
if ($invocation -like 'resource list*') {
    Write-Output 'Name                              Type                              Location'
    Write-Output '--------------------------------  --------------------------------  ----------'
    Write-Output 'citytech-api-rm561694-2026        Microsoft.Web/sites               brazilsouth'
    Write-Output 'citytech-api-rm561694-2026-plan   Microsoft.Web/serverFarms         brazilsouth'
    Write-Output 'citytech-sql-rm561694-2026        Microsoft.Sql/servers             brazilsouth'
    Write-Output 'citytechdb                        Microsoft.Sql/servers/databases   brazilsouth'
    exit 0
}

[Console]::Error.WriteLine("ERROR: comando nao implementado no mock: $invocation")
exit 91
