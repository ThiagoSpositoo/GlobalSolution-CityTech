#requires -Version 5.1
<#
.SYNOPSIS
    Testes locais de scripts/provision-azure.ps1 com um Azure CLI simulado.

.DESCRIPTION
    Executa o provisionamento contra um `az` falso (scripts/tests/az-mock.ps1), sem
    nenhuma chamada ao Azure real. Cobre:

      T1  nenhum recurso existe            -> cria tudo e confirma no final
      T2  todos os recursos existem        -> não recria nada (idempotência)
      T3  retomada após falha parcial      -> preserva o que existe e cria o resto
      T4  aviso em stderr com exit 0       -> NÃO pode virar exceção (regressão)
      T5  AuthorizationFailed              -> deve falhar com erro real
      T6  sem login                        -> deve pedir az login
      T7  ResourceGroupNotFound em filho   -> deve falhar (inconsistência real)
      T8  dry-run                          -> não pode chamar o Azure
      T9  assinatura inexistente           -> deve falhar com erro real
      T10 firewall com intervalo diferente -> converge para 0.0.0.0/0.0.0.0
      T11 login admin divergente           -> avisa e não altera a senha
      T12 região bloqueada por política     -> falha ANTES de criar qualquer recurso
      T13 região sem App Service            -> falha ANTES de criar qualquer recurso

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\tests\Invoke-ProvisionAzureMockTests.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsDir = Split-Path -Parent $scriptDir
$root = Split-Path -Parent $scriptsDir
$provisionScript = Join-Path $scriptsDir 'provision-azure.ps1'
$mockSource = Join-Path $scriptDir 'az-mock.ps1'

if (-not (Test-Path -LiteralPath $provisionScript)) { throw "Script não encontrado: $provisionScript" }
if (-not (Test-Path -LiteralPath $mockSource)) { throw "Mock não encontrado: $mockSource" }

$workDir = Join-Path $env:TEMP 'opencode\citytech-azmock'
if (Test-Path -LiteralPath $workDir) { Remove-Item -LiteralPath $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

# --- mock de az + chaves PEM descartáveis ----------------------------------------
Copy-Item -LiteralPath $mockSource -Destination (Join-Path $workDir 'az-mock.ps1') -Force
$shim = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0az-mock.ps1`" %*`r`nexit /b %ERRORLEVEL%`r`n"
[IO.File]::WriteAllText((Join-Path $workDir 'az.cmd'), $shim, [Text.Encoding]::ASCII)

$privatePem = Join-Path $workDir 'test-private.pem'
$publicPem = Join-Path $workDir 'test-public.pem'
[IO.File]::WriteAllText($privatePem, "-----BEGIN PRIVATE KEY-----`nTESTE`n-----END PRIVATE KEY-----`n", (New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText($publicPem, "-----BEGIN PUBLIC KEY-----`nTESTE`n-----END PUBLIC KEY-----`n", (New-Object Text.UTF8Encoding($false)))

$script:passed = 0
$script:failed = 0
$script:results = @()

function Assert-That {
    param(
        [string]$Scenario,
        [string]$Name,
        [bool]$Condition,
        [string]$Detail = ''
    )
    if ($Condition) {
        $script:passed++
        $script:results += [pscustomobject]@{ Cenario = $Scenario; Verificacao = $Name; Resultado = 'OK'; Detalhe = '' }
    } else {
        $script:failed++
        $script:results += [pscustomobject]@{ Cenario = $Scenario; Verificacao = $Name; Resultado = 'FALHOU'; Detalhe = $Detail }
        Write-Host "  [FALHOU] $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "           $Detail" -ForegroundColor DarkGray }
    }
}

function Invoke-Scenario {
    param(
        [string]$Name,
        [hashtable]$State,
        [string]$SubscriptionId = '11111111-1111-1111-1111-111111111111',
        [switch]$DryRun
    )

    $statePath = Join-Path $workDir "$Name.state.json"
    $logPath = Join-Path $workDir "$Name.log"
    $configPath = Join-Path $workDir "$Name.config.json"

    $base = [ordered]@{
        subscriptionId = $SubscriptionId
        rgExists       = $false
        planExists     = $false
        sqlExists      = $false
        fwExists       = $false
        dbExists       = $false
        webExists      = $false
        fwStart        = '0.0.0.0'
        fwEnd          = '0.0.0.0'
    }
    foreach ($key in $State.Keys) { $base[$key] = $State[$key] }

    [IO.File]::WriteAllText($statePath, ($base | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))

    $config = [ordered]@{
        subscriptionId    = $SubscriptionId
        resourceGroup     = 'rg-citytech-devops'
        location          = 'brazilsouth'
        webAppName        = 'citytech-api-rm561694-2026'
        sqlServerName     = 'citytech-sql-rm561694-2026'
        sqlDatabaseName   = 'citytechdb'
        sqlAdminUser      = 'citytechadmin'
        sqlAdminPassword  = 'SenhaDeTeste123!'
        jwtPrivateKeyPath = $privatePem
        jwtPublicKeyPath  = $publicPem
        jwtIssuer         = 'citytech-identity'
        jwtAudience       = 'citytech-api'
        jwtKeyId          = 'citytech-cloud-v1'
        javaApiBaseUrl    = ''
    }
    [IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))

    $env:AZMOCK_STATE = $statePath
    $env:AZMOCK_LOG = $logPath
    $originalPath = $env:PATH
    $env:PATH = "$workDir;$originalPath"

    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $provisionScript, '-ConfigPath', $configPath)
    if (-not $DryRun) { $arguments += '-Approved' }

    try {
        # Mesma técnica do script: 'Continue' durante a chamada nativa e separação
        # por tipo, porque o filho escreve erros reais em stderr nos cenários negativos.
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $items = @(& powershell.exe @arguments 2>&1)
            $exitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previous
        }
        $output = ($items | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { [string]$_ }
            }) -join "`n"
    } finally {
        $env:PATH = $originalPath
        Remove-Item Env:\AZMOCK_STATE -ErrorAction SilentlyContinue
        Remove-Item Env:\AZMOCK_LOG -ErrorAction SilentlyContinue
    }

    $log = @()
    if (Test-Path -LiteralPath $logPath) {
        $log = @(Get-Content -LiteralPath $logPath -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    return [pscustomobject]@{
        Name     = $Name
        ExitCode = $exitCode
        Output   = $output
        Log      = $log
        LogText  = ($log -join "`n")
    }
}

Write-Host ''
Write-Host '=== Testes locais do provisionamento (Azure CLI simulado) ===' -ForegroundColor Cyan
Write-Host "Mock: $workDir"
Write-Host 'Nenhum comando real do Azure é executado.'

# --- T1: nada existe --------------------------------------------------------------
Write-Host ''
Write-Host '[T1] Nenhum recurso existe: deve criar tudo e confirmar no Azure'
$t1 = Invoke-Scenario -Name 'T1' -State @{}
Assert-That 'T1' 'exit code 0' ($t1.ExitCode -eq 0) "exit $($t1.ExitCode) | $($t1.Output)"
foreach ($cmd in @('group create', 'appservice plan create', 'sql server create', 'firewall-rule create', 'sql db create', 'webapp create')) {
    Assert-That 'T1' "executou '$cmd'" ($t1.LogText -like "*$cmd*")
}
Assert-That 'T1' 'confirmação final impressa' ($t1.Output -match 'Infraestrutura confirmada')
Assert-That 'T1' 'não declarou deploy de código' ($t1.Output -match 'o código é publicado pela pipeline')

# --- T2: tudo existe --------------------------------------------------------------
Write-Host ''
Write-Host '[T2] Todos os recursos existem: não pode recriar nada'
$t2 = Invoke-Scenario -Name 'T2' -State @{
    rgExists = $true; planExists = $true; sqlExists = $true
    fwExists = $true; dbExists = $true; webExists = $true
}
Assert-That 'T2' 'exit code 0' ($t2.ExitCode -eq 0) "exit $($t2.ExitCode) | $($t2.Output)"
Assert-That 'T2' 'nenhum comando de criação' (-not ($t2.LogText -match '\screate\s')) $t2.LogText
Assert-That 'T2' 'preservou o plano' ($t2.Output -match 'Plano já existe')
Assert-That 'T2' 'preservou o banco' ($t2.Output -match 'Banco já existe')
Assert-That 'T2' 'preservou o App Service' ($t2.Output -match 'App Service já existe')
Assert-That 'T2' 'reaplicou as configurações' ($t2.LogText -match 'appsettings set')

# --- T3: retomada após falha parcial ----------------------------------------------
Write-Host ''
Write-Host '[T3] Retomada: grupo e plano existem, restante não'
$t3 = Invoke-Scenario -Name 'T3' -State @{ rgExists = $true; planExists = $true }
Assert-That 'T3' 'exit code 0' ($t3.ExitCode -eq 0) "exit $($t3.ExitCode) | $($t3.Output)"
Assert-That 'T3' 'não recriou o Resource Group' (-not ($t3.LogText -match 'group create'))
Assert-That 'T3' 'não recriou o plano' (-not ($t3.LogText -match 'appservice plan create'))
Assert-That 'T3' 'criou o servidor SQL' ($t3.LogText -match 'sql server create')
Assert-That 'T3' 'criou o banco' ($t3.LogText -match 'sql db create')

# --- T4: aviso em stderr com sucesso (regressão do bug original) -------------------
Write-Host ''
Write-Host '[T4] Aviso do Azure CLI em stderr com exit 0: não pode interromper o script'
$t4 = Invoke-Scenario -Name 'T4' -State @{
    warn = @{ match = 'group create'; message = 'WARNING: Aviso simulado do Azure CLI' }
}
Assert-That 'T4' 'exit code 0 apesar do stderr' ($t4.ExitCode -eq 0) "exit $($t4.ExitCode) | $($t4.Output)"
Assert-That 'T4' 'seguiu para o App Service' ($t4.LogText -match 'webapp create')

# --- T5: erro real de permissão ---------------------------------------------------
Write-Host ''
Write-Host '[T5] AuthorizationFailed ao consultar o SQL: deve falhar, não criar'
$t5 = Invoke-Scenario -Name 'T5' -State @{
    rgExists = $true; planExists = $true
    inject   = @{ match = 'sql server show'; stderr = "ERROR: (AuthorizationFailed) The client does not have authorization to perform action 'Microsoft.Sql/servers/read'."; exit = 1 }
}
Assert-That 'T5' 'exit code diferente de 0' ($t5.ExitCode -ne 0) "exit $($t5.ExitCode)"
Assert-That 'T5' 'mensagem identifica falha real' ($t5.Output -match 'falha real')
Assert-That 'T5' 'não tentou criar o SQL' (-not ($t5.LogText -match 'sql server create'))

# --- T6: sem login ---------------------------------------------------------------
Write-Host ''
Write-Host '[T6] Azure CLI sem login: deve orientar az login'
$t6 = Invoke-Scenario -Name 'T6' -State @{
    inject = @{ match = 'account show'; stderr = "ERROR: Please run 'az login' to setup account."; exit = 1 }
}
Assert-That 'T6' 'exit code diferente de 0' ($t6.ExitCode -ne 0) "exit $($t6.ExitCode)"
Assert-That 'T6' 'orienta az login' ($t6.Output -match 'az login')
Assert-That 'T6' 'não criou nada' (-not ($t6.LogText -match '\screate\s'))

# --- T7: ResourceGroupNotFound em recurso filho -----------------------------------
Write-Host ''
Write-Host '[T7] ResourceGroupNotFound ao consultar recurso filho: deve falhar'
$t7 = Invoke-Scenario -Name 'T7' -State @{
    rgExists = $true
    inject   = @{ match = 'appservice plan show'; stderr = "ERROR: (ResourceGroupNotFound) Resource group 'rg-citytech-devops' could not be found."; exit = 3 }
}
Assert-That 'T7' 'exit code diferente de 0' ($t7.ExitCode -ne 0) "exit $($t7.ExitCode)"
Assert-That 'T7' 'explica inconsistência do grupo' ($t7.Output -match 'não existe nesta assinatura')
Assert-That 'T7' 'não criou o plano' (-not ($t7.LogText -match 'appservice plan create'))

# --- T8: dry-run -----------------------------------------------------------------
Write-Host ''
Write-Host '[T8] Dry-run: nenhum comando do Azure'
$t8 = Invoke-Scenario -Name 'T8' -State @{} -DryRun
Assert-That 'T8' 'exit code 0' ($t8.ExitCode -eq 0) "exit $($t8.ExitCode) | $($t8.Output)"
Assert-That 'T8' 'nenhuma chamada ao az' ($t8.Log.Count -eq 0) ("chamadas: " + $t8.LogText)
Assert-That 'T8' 'informa DRY-RUN' ($t8.Output -match 'DRY-RUN')

# --- T9: assinatura inexistente ---------------------------------------------------
Write-Host ''
Write-Host '[T9] Assinatura informada não existe: deve falhar'
$t9 = Invoke-Scenario -Name 'T9' -State @{ subscriptionId = '11111111-1111-1111-1111-111111111111' } -SubscriptionId '22222222-2222-2222-2222-222222222222'
Assert-That 'T9' 'exit code diferente de 0' ($t9.ExitCode -ne 0) "exit $($t9.ExitCode)"
Assert-That 'T9' 'explica assinatura inacessível' ($t9.Output -match 'não existe ou não está acessível')
Assert-That 'T9' 'não criou o grupo' (-not ($t9.LogText -match 'group create'))

# --- T10: firewall divergente -----------------------------------------------------
Write-Host ''
Write-Host '[T10] Regra de firewall existente com intervalo diferente: deve convergir'
$t10 = Invoke-Scenario -Name 'T10' -State @{
    rgExists = $true; planExists = $true; sqlExists = $true
    fwExists = $true; fwStart = '10.0.0.0'; fwEnd = '10.0.0.255'
    dbExists = $true; webExists = $true
}
Assert-That 'T10' 'exit code 0' ($t10.ExitCode -eq 0) "exit $($t10.ExitCode) | $($t10.Output)"
Assert-That 'T10' 'atualizou a regra' ($t10.LogText -match 'firewall-rule update')
Assert-That 'T10' 'não recriou a regra' (-not ($t10.LogText -match 'firewall-rule create'))

# --- T11: login admin divergente --------------------------------------------------
Write-Host ''
Write-Host '[T11] Login admin do SQL divergente: deve avisar sem alterar'
$t11 = Invoke-Scenario -Name 'T11' -State @{
    rgExists = $true; planExists = $true; sqlExists = $true
    fwExists = $true; dbExists = $true; webExists = $true
}
Assert-That 'T11' 'exit code 0' ($t11.ExitCode -eq 0) "exit $($t11.ExitCode) | $($t11.Output)"
Assert-That 'T11' 'reconhece o login existente' ($t11.Output -match 'login admin: citytechadmin')

# --- T12: região bloqueada pela política -----------------------------------------
Write-Host ''
Write-Host '[T12] Região bloqueada pela política: deve falhar antes de criar'
$t12 = Invoke-Scenario -Name 'T12' -State @{
    allowedLocations = @('eastus', 'eastus2', 'canadacentral')
}
Assert-That 'T12' 'exit code diferente de 0' ($t12.ExitCode -ne 0) "exit $($t12.ExitCode)"
Assert-That 'T12' 'lista as regiões permitidas' ($t12.Output -match 'eastus, eastus2, canadacentral')
Assert-That 'T12' 'não criou nenhum recurso' (-not ($t12.LogText -match '\screate\s')) $t12.LogText

# --- T13: região sem App Service --------------------------------------------------
Write-Host ''
Write-Host '[T13] Região sem App Service: deve falhar antes de criar'
$t13 = Invoke-Scenario -Name 'T13' -State @{
    webLocations = @('East US')
    sqlLocations = @('Brazil South', 'East US')
}
Assert-That 'T13' 'exit code diferente de 0' ($t13.ExitCode -ne 0) "exit $($t13.ExitCode)"
Assert-That 'T13' 'identifica indisponibilidade do App Service' ($t13.Output -match 'App Service não está disponível')
Assert-That 'T13' 'não criou nenhum recurso' (-not ($t13.LogText -match '\screate\s')) $t13.LogText

# --- resumo ----------------------------------------------------------------------
Write-Host ''
Write-Host '=== Resumo ===' -ForegroundColor Cyan
$script:results | Format-Table -AutoSize | Out-String | Write-Host
Write-Host ("Aprovadas: {0} | Falhas: {1}" -f $script:passed, $script:failed) -ForegroundColor $(if ($script:failed -eq 0) { 'Green' } else { 'Red' })

if ($script:failed -gt 0) { exit 1 }
exit 0
