#requires -Version 5.1
<#
.SYNOPSIS
    Provisiona a infraestrutura Azure da API .NET do CityTech (App Service Linux + Azure SQL).

.DESCRIPTION
    Lê um arquivo de configuração local (não versionado) e garante:
      - Resource Group
      - App Service Plan Linux B1
      - Azure SQL Server + regra de firewall dos serviços Azure + banco Basic
      - App Service Linux (.NET 10)
      - Configurações de aplicação (conexão, chaves JWT, ambiente)

    Sem -Approved o script apenas mostra o plano (dry-run) e não chama o Azure.
    Com -Approved é idempotente: consulta cada recurso antes de criar, preserva o que já
    existe e pode ser reexecutado quantas vezes for necessário após uma falha parcial.

    Diagnóstico: uma consulta que responde "recurso não encontrado" é tratada como
    "ainda não existe" e o recurso é criado. Erros reais (login, permissão, assinatura,
    região, quota, SKU, rede) interrompem a execução com mensagem explícita.
    Nenhum erro real é convertido em "recurso inexistente".

.PARAMETER ConfigPath
    Caminho do JSON de configuração. Use scripts/azure-config.example.json como modelo.

.PARAMETER Approved
    Confirma a criação/alteração de recursos pagos. Sem este switch nada é criado.

.EXAMPLE
    .\scripts\provision-azure.ps1 -ConfigPath .\scripts\azure-config.local.json

.EXAMPLE
    .\scripts\provision-azure.ps1 -ConfigPath .\scripts\azure-config.local.json -Approved
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

    [switch]$Approved
)

Set-StrictMode -Version 2.0
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$ErrorActionPreference = 'Stop'

# Códigos/mensagens que o Azure CLI usa quando o recurso simplesmente não existe.
# Qualquer outro erro é tratado como falha real e interrompe o script.
$script:NotFoundCodes = @(
    'ResourceNotFound',
    'ParentResourceNotFound',
    'DeploymentNotFound',
    'EntityNotFound',
    '(NotFound)'
)

# Falhas que NUNCA podem ser confundidas com "recurso inexistente".
$script:HardErrorPatterns = @(
    "Please run 'az login'",
    'AuthenticationFailed',
    'InvalidAuthenticationToken',
    'ExpiredAuthenticationToken',
    'AuthorizationFailed',
    'InsufficientPermissions',
    'AccountIsDisabled',
    'SubscriptionNotFound',
    'InvalidSubscriptionId',
    'LocationNotAvailableForResourceType',
    'InvalidResourceLocation',
    'QuotaExceeded',
    'SkuNotAvailable',
    'InvalidTemplateDeployment',
    'RequestDisallowedByPolicy'
)

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Gray
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    ATENCAO: $Message" -ForegroundColor Yellow
}

function Assert-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Comando '$Name' não encontrado. Instale o Azure CLI e reabra o terminal."
    }
}

function Get-AzValue {
    <#
        Lê uma propriedade de um objeto vindo do JSON do Azure sem estourar sob StrictMode
        quando a propriedade não existe.
    #>
    param(
        [object]$Object,
        [string]$Name,
        [object]$Default = $null
    )
    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $Default }
    if ($null -eq $property.Value) { return $Default }
    return $property.Value
}

function Invoke-AzNative {
    <#
        Executa o Azure CLI capturando stdout e stderr SEPARADAMENTE e sem deixar que
        mensagens de stderr virem exceção.

        Por que não usar "2> arquivo" ou "2>&1" com $ErrorActionPreference = 'Stop':
        no PowerShell 5.1 o stderr de um comando nativo é convertido em ErrorRecord e,
        com 'Stop', isso dispara uma exceção mesmo quando o Azure CLI retorna sucesso
        (avisos) ou quando o recurso apenas não existe. Aqui o 'Continue' é aplicado
        somente durante a chamada, e os dois fluxos são separados pelo tipo do objeto:
        ErrorRecord = stderr, string = stdout.
    #>
    param([string[]]$Arguments)

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $items = @()
    $exitCode = 0
    try {
        $items = @(& az @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }

    $stdout = ($items | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | Out-String).Trim()
    $stderr = ($items |
        Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } |
        ForEach-Object { $_.ToString() } |
        Out-String).Trim()

    $combined = (@($stdout, $stderr) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n"
    return [pscustomobject]@{
        ExitCode = $exitCode
        StdOut   = $stdout
        StdErr   = $stderr
        Output   = $combined
    }
}

function Invoke-Az {
    <#
        Executa o Azure CLI e falha (throw) quando o código de saída é diferente de zero.
        A senha administrativa é mascarada na mensagem de erro.
    #>
    param([string[]]$Arguments)

    $result = Invoke-AzNative -Arguments $Arguments
    if ($result.ExitCode -ne 0) {
        $safe = ($Arguments -join ' ') -replace '(?i)(--admin-password|--sql-password)(\s+|=)\S+', '$1 ***'
        $hint = ''
        if ($result.Output -match 'RequestDisallowedByAzure|disallowed by Azure|denied by the following policy') {
            $hint = "`n    MOTIVO: a assinatura tem política que bloqueia esta região/recurso." +
                " Consulte as regiões permitidas com: az policy assignment show --name sys.regionrestriction --query parameters.listOfAllowedLocations.value" +
                " e ajuste o campo 'location' do arquivo de configuração."
        }
        throw "Falha ao executar 'az $safe' (exit $($result.ExitCode)). Saída: $($result.Output)$hint"
    }
    return $result.StdOut
}

function Get-AzJson {
    param([string[]]$Arguments)
    $raw = Invoke-Az -Arguments ($Arguments + @('--output', 'json'))
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    return ($raw | ConvertFrom-Json)
}

function Test-AzResourceExists {
    <#
        Verifica se um recurso existe.

        Retorna $true  -> existe (exit 0)
        Retorna $false -> NÃO existe (NotFound do Azure)
        Lança exceção  -> qualquer outro erro (login, permissão, assinatura, região,
                          quota, SKU, política) ou resposta inesperada.

        -MissingResourceGroupIsExpected só é usado na checagem do próprio Resource Group.
        Nos recursos filhos, ResourceGroupNotFound é tratado como erro real, porque o
        grupo é garantido antes e o contrário indicaria configuração inconsistente.
    #>
    param(
        [string[]]$Arguments,
        [string]$Description,
        [string[]]$NotFoundCodes = $script:NotFoundCodes,
        [switch]$MissingResourceGroupIsExpected
    )

    $result = Invoke-AzNative -Arguments ($Arguments + @('--output', 'none'))
    if ($result.ExitCode -eq 0) { return $true }

    $text = $result.Output

    foreach ($pattern in $script:HardErrorPatterns) {
        if ($text -match [regex]::Escape($pattern)) {
            throw "$Description`: falha real ao consultar o Azure [$pattern]. Saída: $text"
        }
    }

    if (-not $MissingResourceGroupIsExpected -and $text -match 'ResourceGroupNotFound') {
        throw "$Description`: o Resource Group informado não existe nesta assinatura. Saída: $text"
    }

    foreach ($code in $NotFoundCodes) {
        if ($text -match [regex]::Escape($code)) { return $false }
    }

    if ($MissingResourceGroupIsExpected -and $text -match 'ResourceGroupNotFound') { return $false }

    if ($text -match 'was not found|could not be found|does not exist|não foi encontrado|não existe') {
        return $false
    }

    # O Azure CLI devolve exit code 3 para recurso inexistente.
    if ($result.ExitCode -eq 3) { return $false }

    throw "$Description`: resposta inesperada do Azure CLI (exit $($result.ExitCode)). Saída: $text"
}

function Assert-AzLogin {
    <#
        Confere login e assinatura ANTES de qualquer criação, com mensagem específica
        para cada tipo de falha (não logado, assinatura inexistente, sem permissão).
    #>
    param([string]$SubscriptionId)

    $result = Invoke-AzNative -Arguments @('account', 'show', '--output', 'json')
    if ($result.ExitCode -ne 0) {
        if ($result.Output -match "Please run 'az login'|az login to setup") {
            throw "Azure CLI sem sessão. Execute 'az login' (ou 'az login --use-device-code') e repita."
        }
        throw "Não foi possível consultar a assinatura atual. Saída: $($result.Output)"
    }

    $account = $null
    try { $account = $result.StdOut | ConvertFrom-Json } catch { $account = $null }
    if ($null -eq $account) {
        throw "Resposta inesperada de 'az account show'. Saída: $($result.Output)"
    }

    $userName = [string](Get-AzValue $account 'user.name' '?')
    $subscriptionName = [string](Get-AzValue $account 'name' '?')
    $currentId = [string](Get-AzValue $account 'id' '')
    $state = [string](Get-AzValue $account 'state' '')

    Write-Info "Conta: $userName"
    Write-Info "Assinatura atual: $subscriptionName ($currentId)"

    if ($state -and $state -ne 'Enabled') {
        throw "A assinatura '$subscriptionName' está com estado '$state'. Ative-a antes de provisionar."
    }

    if ($SubscriptionId -and $currentId -and ($currentId -ne $SubscriptionId)) {
        $setResult = Invoke-AzNative -Arguments @('account', 'set', '--subscription', $SubscriptionId)
        if ($setResult.ExitCode -ne 0) {
            if ($setResult.Output -match "SubscriptionNotFound|doesn't exist|does not exist|could not be found|was not found") {
                throw "A assinatura '$SubscriptionId' não existe ou não está acessível para esta conta. Saída: $($setResult.Output)"
            }
            throw "Falha ao selecionar a assinatura '$SubscriptionId'. Saída: $($setResult.Output)"
        }
        Write-Info "Assinatura selecionada: $SubscriptionId"
    }

    return $account
}

function Get-PolicyAllowedLocations {
    <#
        Lê as regiões permitidas pelas políticas de "allowed locations" da assinatura.
        Retorna lista vazia quando não há restrição (ou quando não foi possível consultar).
        Atribuições com listas diferentes são combinadas por interseção: vale o mais restritivo.
    #>
    param()

    $result = Invoke-AzNative -Arguments @('policy', 'assignment', 'list', '--output', 'json')
    if ($result.ExitCode -ne 0) {
        Write-Warn "Não foi possível consultar as políticas da assinatura; seguindo sem verificar a região. Saída: $($result.Output)"
        return @()
    }

    $assignments = @()
    try {
        # No PowerShell 5.1, ConvertFrom-Json mantém o array JSON como um único
        # Object[] no pipeline. O foreach explícito normaliza cada atribuição.
        $parsedAssignments = $result.StdOut | ConvertFrom-Json
        foreach ($item in $parsedAssignments) { $assignments += $item }
    } catch { return @() }

    $effective = $null
    foreach ($assignment in $assignments) {
        $parameters = Get-AzValue -Object $assignment -Name 'parameters'
        if ($null -eq $parameters) { continue }
        $allowedParameter = Get-AzValue -Object $parameters -Name 'listOfAllowedLocations'
        if ($null -eq $allowedParameter) { continue }
        $values = Get-AzValue -Object $allowedParameter -Name 'value'
        if ($null -eq $values) { continue }

        $list = @(@($values) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
        if ($list.Count -eq 0) { continue }

        if ($null -eq $effective) {
            $effective = $list
        } else {
            $effective = @($effective | Where-Object { $list -contains $_ })
        }
    }

    if ($null -eq $effective) { return @() }
    return @($effective)
}

function Get-ProviderLocations {
    <#
        Regiões em que um tipo de recurso existe, segundo o provider (consulta de leitura).
        Nomes vêm como "East US 2"; a comparação normaliza espaços e caixa.
    #>
    param(
        [string]$Namespace,
        [string]$ResourceType
    )

    $result = Invoke-AzNative -Arguments @(
        'provider', 'show',
        '--namespace', $Namespace,
        '--query', "resourceTypes[?resourceType=='$ResourceType'].locations | [0]",
        '--output', 'json'
    )
    if ($result.ExitCode -ne 0) { return @() }
    if ([string]::IsNullOrWhiteSpace($result.StdOut)) { return @() }
    try {
        $parsedLocations = $result.StdOut | ConvertFrom-Json
        $locations = @()
        foreach ($item in $parsedLocations) { $locations += [string]$item }
        return @($locations)
    } catch { return @() }
}

function Assert-LocationAllowed {
    <#
        Impede a criação em uma região bloqueada pela política da assinatura.
        Sem isso, o erro só apareceria no meio do provisionamento (RequestDisallowedByAzure),
        depois de o usuário já ter esperado e às vezes com recursos parciais criados.
    #>
    param([string]$Location)

    $allowed = @(Get-PolicyAllowedLocations)
    if ($allowed.Count -eq 0) {
        Write-Info 'Nenhuma política de regiões restringe esta assinatura.'
        return
    }

    if ($allowed -contains $Location) {
        Write-Info "Região '$Location' permitida pela política da assinatura."
        return
    }

    $hint = ''
    $supported = Get-RecommendedLocations -Allowed $allowed
    if ($supported.Count -gt 0) { $hint = " Regiões que também suportam App Service e Azure SQL: $($supported -join ', ')." }

    throw ("A política 'Allowed resource deployment regions' da assinatura não permite '$Location'." +
        " Regiões permitidas: $($allowed -join ', ').$hint" +
        " Altere o campo 'location' em $ConfigPath e repita. Nada foi criado.")
}

function Get-RecommendedLocations {
    <#
        Interseção entre as regiões permitidas pela política e as que suportam
        App Service (Microsoft.Web/serverFarms) e Azure SQL (Microsoft.Sql/servers).
    #>
    param([string[]]$Allowed)

    $web = @(Get-ProviderLocations -Namespace 'Microsoft.Web' -ResourceType 'serverFarms' | ForEach-Object { ($_ -replace '\s', '').ToLower() })
    $sql = @(Get-ProviderLocations -Namespace 'Microsoft.Sql' -ResourceType 'servers' | ForEach-Object { ($_ -replace '\s', '').ToLower() })

    $result = @()
    foreach ($location in $Allowed) {
        $normalized = ($location -replace '\s', '').ToLower()
        if ($web.Count -gt 0 -and -not ($web -contains $normalized)) { continue }
        if ($sql.Count -gt 0 -and -not ($sql -contains $normalized)) { continue }
        $result += $location
    }
    return @($result)
}

function Assert-LocationSupportsServices {
    <#
        Falha cedo quando a região não oferece App Service Linux ou Azure SQL.
        Evita criar o Resource Group e só então descobrir a indisponibilidade.
    #>
    param([string]$Location)

    $target = ($Location -replace '\s', '').ToLower()
    $services = @(
        @{ Namespace = 'Microsoft.Web'; Type = 'serverFarms'; Label = 'App Service' },
        @{ Namespace = 'Microsoft.Sql'; Type = 'servers'; Label = 'Azure SQL' }
    )

    foreach ($service in $services) {
        $locations = @(Get-ProviderLocations -Namespace $service.Namespace -ResourceType $service.Type)
        if ($locations.Count -eq 0) {
            Write-Warn "Não foi possível listar as regiões de $($service.Label); seguindo sem esta verificação."
            continue
        }

        $found = $locations | Where-Object { ($_ -replace '\s', '').ToLower() -eq $target } | Select-Object -First 1
        if (-not $found) {
            throw ("$($service.Label) não está disponível em '$Location' para esta assinatura." +
                " Nada foi criado. Escolha outra região em 'location' no arquivo de configuração.")
        }
    }

    Write-Info "Região '$Location' oferece App Service e Azure SQL."
}

function Confirm-AzResource {
    <#
        Confirma no Azure, por consulta real, que o recurso existe.
        Usado no final: o script nunca declara sucesso baseado apenas no que pediu.
    #>
    param(
        [string[]]$Arguments,
        [string]$Description
    )

    $result = Invoke-AzNative -Arguments ($Arguments + @('--output', 'json'))
    if ($result.ExitCode -ne 0) {
        return [pscustomobject]@{
            Recurso  = $Description
            Confirmado = $false
            Detalhe  = $result.Output
            Dados    = $null
        }
    }

    $data = $null
    try { $data = $result.StdOut | ConvertFrom-Json } catch { $data = $null }
    if ($null -eq $data) {
        return [pscustomobject]@{
            Recurso  = $Description
            Confirmado = $false
            Detalhe  = "Resposta vazia ou inválida ao confirmar $Description."
            Dados    = $null
        }
    }

    return [pscustomobject]@{
        Recurso  = $Description
        Confirmado = $true
        Detalhe  = 'confirmado pelo Azure'
        Dados    = $data
    }
}

# ---------------------------------------------------------------------------
# Configuração
# ---------------------------------------------------------------------------

Assert-Command -Name 'az'

if (-not (Test-Path -Path $ConfigPath -PathType Leaf)) {
    throw "Configuração não encontrada: $ConfigPath. Copie scripts/azure-config.example.json e preencha."
}

$config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

$required = @(
    'subscriptionId', 'resourceGroup', 'location', 'webAppName',
    'sqlServerName', 'sqlDatabaseName', 'sqlAdminUser', 'sqlAdminPassword',
    'jwtPrivateKeyPath', 'jwtPublicKeyPath'
)
foreach ($name in $required) {
    $value = Get-AzValue -Object $config -Name $name -Default ''
    if ([string]::IsNullOrWhiteSpace([string]$value)) {
        throw "Campo obrigatório ausente no JSON de configuração: $name"
    }
}

$privateKeyPath = (Resolve-Path -Path ([string]$config.jwtPrivateKeyPath)).Path
$publicKeyPath = (Resolve-Path -Path ([string]$config.jwtPublicKeyPath)).Path
$privatePem = Get-Content -Path $privateKeyPath -Raw
$publicPem = Get-Content -Path $publicKeyPath -Raw

if ($privatePem -notmatch 'PRIVATE KEY' -or $publicPem -notmatch 'PUBLIC KEY') {
    throw 'Os arquivos JWT informados não parecem ser PEM válidos.'
}

$javaBaseUrl = [string](Get-AzValue -Object $config -Name 'javaApiBaseUrl' -Default '')
$javaDisplay = if ([string]::IsNullOrWhiteSpace($javaBaseUrl)) {
    'não informado (readiness e criação de acompanhamentos indisponíveis)'
} else {
    $javaBaseUrl
}

$planNameOverride = [string](Get-AzValue -Object $config -Name 'appServicePlanName' -Default '')
$planName = if ([string]::IsNullOrWhiteSpace($planNameOverride)) {
    "$($config.webAppName)-plan"
} else {
    $planNameOverride
}

$connectionString = "Server=tcp:$($config.sqlServerName).database.windows.net,1433;" +
    "Database=$($config.sqlDatabaseName);User ID=$($config.sqlAdminUser);" +
    "Password=$($config.sqlAdminPassword);Encrypt=True;TrustServerCertificate=False;" +
    "Connection Timeout=30"

Write-Step 'Plano de provisionamento (revise custos e nomes antes de aprovar)'
[pscustomobject]@{
    Assinatura      = $config.subscriptionId
    ResourceGroup   = "$($config.resourceGroup) ($($config.location))"
    PlanoAppService = "$planName (Linux B1)"
    AppService      = $config.webAppName
    ServidorSQL     = "$($config.sqlServerName).database.windows.net"
    BancoSQL        = "$($config.sqlDatabaseName) (Basic)"
    JavaAPI         = $javaDisplay
} | Format-List

Write-Host 'Custo estimado (preços públicos de referência, variam por região/câmbio):' -ForegroundColor Yellow
Write-Host '  App Service Linux B1 ....... ~US$ 13/mês'
Write-Host '  Azure SQL Basic ............ ~US$ 5/mês'
Write-Host '  Total aproximado ........... ~US$ 18/mês enquanto os recursos existirem'

if (-not $Approved) {
    Write-Host ''
    Write-Host 'DRY-RUN: nada foi criado e nenhum comando do Azure foi executado.' -ForegroundColor Yellow
    Write-Host 'Revise o plano e repita com -Approved para provisionar.' -ForegroundColor Yellow
    return
}

# ---------------------------------------------------------------------------
# Autenticação
# ---------------------------------------------------------------------------

Write-Step 'Conferindo autenticação e assinatura'
Assert-AzLogin -SubscriptionId ([string]$config.subscriptionId) | Out-Null
Write-Ok 'Login e assinatura confirmados.'

Write-Step "Conferindo região '$($config.location)' (política e disponibilidade)"
Assert-LocationAllowed -Location ([string]$config.location)
Assert-LocationSupportsServices -Location ([string]$config.location)
Write-Ok 'Região aprovada pelas políticas e pelos providers.'

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

Write-Step "Resource Group $($config.resourceGroup)"
$rgExists = Test-AzResourceExists `
    -Arguments @('group', 'show', '--name', $config.resourceGroup) `
    -Description 'Resource Group' `
    -NotFoundCodes @('ResourceGroupNotFound') `
    -MissingResourceGroupIsExpected

if ($rgExists) {
    $rg = Get-AzJson -Arguments @('group', 'show', '--name', $config.resourceGroup)
    $rgLocation = [string](Get-AzValue $rg 'location' '?')
    Write-Ok "Resource Group já existe (região $rgLocation); preservado."
    if ($rgLocation -and $rgLocation -ne $config.location) {
        Write-Warn "O grupo está em '$rgLocation' e a configuração pede '$($config.location)'. O grupo NÃO será movido; os recursos serão criados em '$($config.location)'."
    }
} else {
    Invoke-Az -Arguments @(
        'group', 'create',
        '--name', $config.resourceGroup,
        '--location', $config.location,
        '--output', 'none'
    ) | Out-Null
    Write-Ok "Resource Group criado em $($config.location)."
}

# ---------------------------------------------------------------------------
# App Service Plan
# ---------------------------------------------------------------------------

Write-Step "App Service Plan $planName (Linux B1)"
$planExists = Test-AzResourceExists `
    -Arguments @('appservice', 'plan', 'show', '--resource-group', $config.resourceGroup, '--name', $planName) `
    -Description "App Service Plan '$planName'"

if ($planExists) {
    $plan = Get-AzJson -Arguments @('appservice', 'plan', 'show', '--resource-group', $config.resourceGroup, '--name', $planName)
    $planSku = [string](Get-AzValue (Get-AzValue $plan 'sku' $null) 'name' '?')
    $planLinux = Get-AzValue (Get-AzValue $plan 'properties' $null) 'reserved' $null
    Write-Ok "Plano já existe (SKU $planSku); preservado."
    if ($planSku -and $planSku -ne 'B1') {
        Write-Warn "O plano existente está em SKU '$planSku' e a configuração espera 'B1'. O SKU NÃO será alterado; ajuste manualmente se necessário."
    }
    if ($planLinux -eq $false) {
        Write-Warn 'O plano existente não está marcado como Linux. O App Service .NET Linux pode não funcionar nele; nada foi alterado.'
    }
} else {
    Invoke-Az -Arguments @(
        'appservice', 'plan', 'create',
        '--resource-group', $config.resourceGroup,
        '--name', $planName,
        '--location', $config.location,
        '--is-linux',
        '--sku', 'B1',
        '--output', 'none'
    ) | Out-Null
    Write-Ok 'Plano criado (Linux B1).'
}

# ---------------------------------------------------------------------------
# Azure SQL Server
# ---------------------------------------------------------------------------

Write-Step "Azure SQL Server $($config.sqlServerName)"
$sqlExists = Test-AzResourceExists `
    -Arguments @('sql', 'server', 'show', '--resource-group', $config.resourceGroup, '--name', $config.sqlServerName) `
    -Description "Azure SQL Server '$($config.sqlServerName)'"

if ($sqlExists) {
    $sqlServer = Get-AzJson -Arguments @('sql', 'server', 'show', '--resource-group', $config.resourceGroup, '--name', $config.sqlServerName)
    $adminLogin = [string](Get-AzValue (Get-AzValue $sqlServer 'properties' $null) 'administratorLogin' '?')
    Write-Ok "Servidor SQL já existe (login admin: $adminLogin); senha preservada."
    if ($adminLogin -and $adminLogin -ne $config.sqlAdminUser) {
        Write-Warn "O login administrador do servidor é '$adminLogin' e a configuração usa '$($config.sqlAdminUser)'. A senha NÃO é alterada pelo script; ajuste o JSON para o login existente ou redefina a senha no Portal."
    }
} else {
    Invoke-Az -Arguments @(
        'sql', 'server', 'create',
        '--resource-group', $config.resourceGroup,
        '--name', $config.sqlServerName,
        '--location', $config.location,
        '--admin-user', $config.sqlAdminUser,
        '--admin-password', $config.sqlAdminPassword,
        '--output', 'none'
    ) | Out-Null
    Write-Ok 'Servidor SQL criado.'
}

# ---------------------------------------------------------------------------
# Firewall do SQL (serviços Azure)
# ---------------------------------------------------------------------------

Write-Step 'Regra de firewall do SQL (AllowAzureServices)'
$firewallName = 'AllowAzureServices'
$firewallExists = Test-AzResourceExists `
    -Arguments @(
        'sql', 'server', 'firewall-rule', 'show',
        '--resource-group', $config.resourceGroup,
        '--server', $config.sqlServerName,
        '--name', $firewallName) `
    -Description "Regra de firewall '$firewallName'"

if ($firewallExists) {
    $rule = Get-AzJson -Arguments @(
        'sql', 'server', 'firewall-rule', 'show',
        '--resource-group', $config.resourceGroup,
        '--server', $config.sqlServerName,
        '--name', $firewallName)
    $startIp = [string](Get-AzValue $rule 'startIpAddress' '?')
    $endIp = [string](Get-AzValue $rule 'endIpAddress' '?')

    if ($startIp -eq '0.0.0.0' -and $endIp -eq '0.0.0.0') {
        Write-Ok "Regra já existe ($startIp - $endIp); preservada."
    } else {
        Write-Warn "Regra existente com intervalo $startIp - $endIp. Ajustando para 0.0.0.0 - 0.0.0.0 (serviços Azure)."
        Invoke-Az -Arguments @(
            'sql', 'server', 'firewall-rule', 'update',
            '--resource-group', $config.resourceGroup,
            '--server', $config.sqlServerName,
            '--name', $firewallName,
            '--start-ip-address', '0.0.0.0',
            '--end-ip-address', '0.0.0.0',
            '--output', 'none'
        ) | Out-Null
        Write-Ok 'Regra ajustada.'
    }
} else {
    Invoke-Az -Arguments @(
        'sql', 'server', 'firewall-rule', 'create',
        '--resource-group', $config.resourceGroup,
        '--server', $config.sqlServerName,
        '--name', $firewallName,
        '--start-ip-address', '0.0.0.0',
        '--end-ip-address', '0.0.0.0',
        '--output', 'none'
    ) | Out-Null
    Write-Ok 'Regra criada (necessária para o Query Editor do Portal e para o deploy da pipeline).'
}

# ---------------------------------------------------------------------------
# Banco de dados
# ---------------------------------------------------------------------------

Write-Step "Banco $($config.sqlDatabaseName) (Basic)"
$dbExists = Test-AzResourceExists `
    -Arguments @(
        'sql', 'db', 'show',
        '--resource-group', $config.resourceGroup,
        '--server', $config.sqlServerName,
        '--name', $config.sqlDatabaseName) `
    -Description "Banco '$($config.sqlDatabaseName)'"

if ($dbExists) {
    $db = Get-AzJson -Arguments @(
        'sql', 'db', 'show',
        '--resource-group', $config.resourceGroup,
        '--server', $config.sqlServerName,
        '--name', $config.sqlDatabaseName)
    $dbSku = [string](Get-AzValue $db 'currentServiceObjectiveName' (Get-AzValue $db 'sku.name' '?'))
    $dbStatus = [string](Get-AzValue $db 'status' '?')
    Write-Ok "Banco já existe (SKU $dbSku, status $dbStatus); preservado."
    if ($dbSku -and $dbSku -ne 'Basic') {
        Write-Warn "O banco existente está em '$dbSku' e a configuração espera 'Basic'. O SKU NÃO será alterado."
    }
} else {
    Invoke-Az -Arguments @(
        'sql', 'db', 'create',
        '--resource-group', $config.resourceGroup,
        '--server', $config.sqlServerName,
        '--name', $config.sqlDatabaseName,
        '--edition', 'Basic',
        '--service-objective', 'Basic',
        '--output', 'none'
    ) | Out-Null
    Write-Ok 'Banco criado (Basic).'
}

# ---------------------------------------------------------------------------
# App Service
# ---------------------------------------------------------------------------

Write-Step "App Service $($config.webAppName)"
$webExists = Test-AzResourceExists `
    -Arguments @('webapp', 'show', '--resource-group', $config.resourceGroup, '--name', $config.webAppName) `
    -Description "App Service '$($config.webAppName)'"

if ($webExists) {
    $webApp = Get-AzJson -Arguments @('webapp', 'show', '--resource-group', $config.resourceGroup, '--name', $config.webAppName)
    $webState = [string](Get-AzValue $webApp 'state' '?')
    Write-Ok "App Service já existe (estado $webState); preservado."
} else {
    $runtimes = @()
    $runtimeResult = Invoke-AzNative -Arguments @('webapp', 'list-runtimes', '--os', 'linux', '--output', 'json')
    if ($runtimeResult.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($runtimeResult.StdOut)) {
        try { $runtimes = @($runtimeResult.StdOut | ConvertFrom-Json) } catch { $runtimes = @() }
    } else {
        Write-Warn "Não foi possível listar os runtimes disponíveis; usando DOTNETCORE:10.0 como padrão. Saída: $($runtimeResult.Output)"
    }

    $dotnetRuntime = ($runtimes | Where-Object { $_ -match '^DOTNETCORE:10\.' } | Sort-Object -Descending | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($dotnetRuntime)) { $dotnetRuntime = 'DOTNETCORE:10.0' }
    Write-Info "Runtime selecionado: $dotnetRuntime"

    Invoke-Az -Arguments @(
        'webapp', 'create',
        '--resource-group', $config.resourceGroup,
        '--plan', $planName,
        '--name', $config.webAppName,
        '--runtime', $dotnetRuntime,
        '--output', 'none'
    ) | Out-Null
    Write-Ok 'App Service criado.'
}

# ---------------------------------------------------------------------------
# Configurações de aplicação
# ---------------------------------------------------------------------------

Write-Step 'Configurando variáveis de ambiente do App Service'
$settings = @(
    "DOTNET_DB_CONNECTION=$connectionString",
    "JWT_PRIVATE_KEY_PEM=$privatePem",
    "JWT_PUBLIC_KEY_PEM=$publicPem",
    "JWT_ISSUER=$([string](Get-AzValue $config 'jwtIssuer' ''))",
    "JWT_AUDIENCE=$([string](Get-AzValue $config 'jwtAudience' ''))",
    "JWT_KEY_ID=$([string](Get-AzValue $config 'jwtKeyId' ''))",
    "ASPNETCORE_ENVIRONMENT=Production",
    "ASPNETCORE_URLS=http://0.0.0.0:8080",
    "WEBSITES_PORT=8080"
)
if (-not [string]::IsNullOrWhiteSpace($javaBaseUrl)) {
    $settings += "JAVA_API_BASE_URL=$javaBaseUrl"
}

# As configurações são enviadas por arquivo temporário para não expor segredos na linha de comando.
$settingsFile = Join-Path $env:TEMP ("citytech-settings-" + [Guid]::NewGuid().ToString('N') + '.json')
try {
    $settingsJson = ConvertTo-Json -InputObject @($settings) -Compress
    [IO.File]::WriteAllText($settingsFile, $settingsJson, (New-Object Text.UTF8Encoding($false)))
    Invoke-Az -Arguments @(
        'webapp', 'config', 'appsettings', 'set',
        '--resource-group', $config.resourceGroup,
        '--name', $config.webAppName,
        '--settings', "@$settingsFile",
        '--output', 'none'
    ) | Out-Null
} finally {
    if (Test-Path -LiteralPath $settingsFile) { Remove-Item -LiteralPath $settingsFile -Force }
}
Write-Ok 'Application settings aplicadas (nenhum segredo foi exibido).'

Invoke-Az -Arguments @(
    'webapp', 'config', 'set',
    '--resource-group', $config.resourceGroup,
    '--name', $config.webAppName,
    '--always-on', 'true',
    '--min-tls-version', '1.2',
    '--output', 'none'
) | Out-Null
Write-Ok 'Always On e TLS 1.2 garantidos.'

Invoke-Az -Arguments @(
    'webapp', 'update',
    '--resource-group', $config.resourceGroup,
    '--name', $config.webAppName,
    '--https-only', 'true',
    '--output', 'none'
) | Out-Null
Write-Ok 'HTTPS obrigatório garantido.'

# ---------------------------------------------------------------------------
# Confirmação real no Azure
# ---------------------------------------------------------------------------

Write-Step 'Confirmação final no Azure (consulta real, não presunção)'

$confirmations = @(
    (Confirm-AzResource -Arguments @('group', 'show', '--name', $config.resourceGroup) -Description 'Resource Group'),
    (Confirm-AzResource -Arguments @('appservice', 'plan', 'show', '--resource-group', $config.resourceGroup, '--name', $planName) -Description 'App Service Plan'),
    (Confirm-AzResource -Arguments @('sql', 'server', 'show', '--resource-group', $config.resourceGroup, '--name', $config.sqlServerName) -Description 'Azure SQL Server'),
    (Confirm-AzResource -Arguments @('sql', 'server', 'firewall-rule', 'show', '--resource-group', $config.resourceGroup, '--server', $config.sqlServerName, '--name', $firewallName) -Description 'Regra de firewall'),
    (Confirm-AzResource -Arguments @('sql', 'db', 'show', '--resource-group', $config.resourceGroup, '--server', $config.sqlServerName, '--name', $config.sqlDatabaseName) -Description 'Azure SQL Database'),
    (Confirm-AzResource -Arguments @('webapp', 'show', '--resource-group', $config.resourceGroup, '--name', $config.webAppName) -Description 'App Service')
)

$failed = @()
foreach ($item in $confirmations) {
    if ($item.Confirmado) {
        $detail = switch ($item.Recurso) {
            'Resource Group'      { [string](Get-AzValue $item.Dados 'location' '?') }
            'App Service Plan'    { "$([string](Get-AzValue (Get-AzValue $item.Dados 'sku' $null) 'name' '?')) / $([string](Get-AzValue $item.Dados 'location' '?'))" }
            'Azure SQL Server'    { "$([string](Get-AzValue $item.Dados 'location' '?')) / login $([string](Get-AzValue (Get-AzValue $item.Dados 'properties' $null) 'administratorLogin' '?'))" }
            'Regra de firewall'   { "$([string](Get-AzValue $item.Dados 'startIpAddress' '?')) - $([string](Get-AzValue $item.Dados 'endIpAddress' '?'))" }
            'Azure SQL Database'  { "$([string](Get-AzValue $item.Dados 'status' '?')) / $([string](Get-AzValue $item.Dados 'currentServiceObjectiveName' '?'))" }
            'App Service'         { "$([string](Get-AzValue $item.Dados 'state' '?')) / httpsOnly $([string](Get-AzValue $item.Dados 'httpsOnly' '?'))" }
            default               { 'confirmado' }
        }
        Write-Ok "$($item.Recurso): $detail"
    } else {
        $failed += $item
        Write-Host "    FALHOU: $($item.Recurso) -> $($item.Detalhe)" -ForegroundColor Red
    }
}

if ($failed.Count -gt 0) {
    throw "Confirmação no Azure falhou para $($failed.Count) recurso(s). Nada foi declarado como concluído. Verifique as mensagens acima."
}

Write-Step 'Recursos no Resource Group'
Invoke-Az -Arguments @(
    'resource', 'list',
    '--resource-group', $config.resourceGroup,
    '--query', '[].{Nome:name,Tipo:type,Local:location}',
    '--output', 'table'
) | ForEach-Object { Write-Host $_ }

$hostName = [string](Get-AzValue ((Confirm-AzResource -Arguments @('webapp', 'show', '--resource-group', $config.resourceGroup, '--name', $config.webAppName) -Description 'App Service')).Dados 'defaultHostName' "$($config.webAppName).azurewebsites.net")

Write-Host ''
Write-Host "Infraestrutura confirmada. URL da aplicação: https://$hostName" -ForegroundColor Green
Write-Host 'IMPORTANTE: este script cria/garante INFRAESTRUTURA. O código é publicado pela pipeline azure-pipeline.yml.' -ForegroundColor Yellow
Write-Host 'Até a primeira execução da pipeline, a URL responde 503 (nenhum código publicado).' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Próximos passos:'
Write-Host '  1. Criar a service connection citytech-azure e o variable group citytech-prod no Azure DevOps.'
Write-Host '  2. Enviar o código ao Azure Repos e criar a pipeline apontando para azure-pipeline.yml.'
Write-Host '  3. Executar a pipeline e validar /health/live e /api/v1/version.'
