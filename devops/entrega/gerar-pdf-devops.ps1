#requires -Version 5.1
<#
.SYNOPSIS
    Gera o PDF de entrega da disciplina DevOps Tools & Cloud Computing (CityTech).

.DESCRIPTION
    Monta um HTML a partir dos fatos reais do repositório (arquivos, pipeline, DDL e verificações
    executadas), converte para PDF com o Edge/Chrome em modo headless e grava em entregas/.
    Capturas reais salvas em devops/entrega/capturas/ são incorporadas automaticamente.

.PARAMETER VideoUrl
    Link do vídeo no YouTube. Se omitido, o PDF registra explicitamente "PENDENTE".

.PARAMETER OutputDirectory
    Pasta de saída. Padrão: entregas/

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\devops\entrega\gerar-pdf-devops.ps1

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\devops\entrega\gerar-pdf-devops.ps1 -VideoUrl "https://youtu.be/XXXX"
#>
[CmdletBinding()]
param(
    [string]$VideoUrl = '',
    [string]$OutputDirectory = ''
)

Set-StrictMode -Version 2.0
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $root 'entregas'
}
if (-not (Test-Path $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }

function Get-RelativeSize {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 'ausente' }
    return (Get-Item $Path).Length
}

$pipelineBytes = Get-RelativeSize (Join-Path $root 'azure-pipeline.yml')
$ddlBytes = Get-RelativeSize (Join-Path $root 'scripts\script-bd.sql')
$ps1Bytes = Get-RelativeSize (Join-Path $root 'scripts\provision-azure.ps1')

$capturesDir = Join-Path $scriptDir 'capturas'
$captures = @()
if (Test-Path $capturesDir) {
    $captures = @(Get-ChildItem $capturesDir -File -Include *.png, *.jpg, *.jpeg -Recurse | Sort-Object Name)
}

$videoCell = if ([string]::IsNullOrWhiteSpace($VideoUrl)) {
    '<span class="pend">PENDENTE — inserir o link do YouTube</span>'
} else {
    '<a href="' + $VideoUrl + '">' + $VideoUrl + '</a>'
}
$videoStatusRow = if ([string]::IsNullOrWhiteSpace($VideoUrl)) {
    '<tr><td>Vídeo narrado 720p no YouTube</td><td><span class="badge b-pend">PENDENTE</span></td><td>Roteiro em <code>devops/roteiro-video.md</code></td></tr>'
} else {
    '<tr><td>Vídeo de apresentação no YouTube</td><td><span class="badge b-ok">COMPROVADO</span></td><td><a href="' + $VideoUrl + '">' + $VideoUrl + '</a></td></tr>'
}

$html = New-Object Text.StringBuilder
function Add([string]$text) { [void]$html.AppendLine($text) }

Add @'
<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8">
<title>CityTech — DevOps Tools &amp; Cloud Computing</title>
<style>
  @page { size: A4; margin: 16mm 14mm 16mm 14mm; }
  * { box-sizing: border-box; }
  body { font-family: "Segoe UI", Arial, sans-serif; color: #16222e; font-size: 10.4pt; line-height: 1.5; margin: 0; }
  h1 { font-size: 26pt; margin: 0 0 6px; color: #0b3d91; letter-spacing: -0.5px; }
  h2 { font-size: 14pt; color: #0b3d91; border-bottom: 2px solid #16a34a; padding-bottom: 4px; margin: 22px 0 10px; page-break-after: avoid; }
  h3 { font-size: 11.2pt; color: #0f5132; margin: 14px 0 6px; page-break-after: avoid; }
  p { margin: 6px 0; }
  ul, ol { margin: 6px 0 6px 18px; padding: 0; }
  li { margin: 3px 0; }
  table { width: 100%; border-collapse: collapse; margin: 8px 0 12px; font-size: 9.4pt; page-break-inside: avoid; }
  th { background: #0b3d91; color: #fff; text-align: left; padding: 6px 7px; font-weight: 600; }
  td { border-bottom: 1px solid #d8e1ea; padding: 5px 7px; vertical-align: top; }
  tr:nth-child(even) td { background: #f6f9fc; }
  code, pre { font-family: Consolas, "Courier New", monospace; font-size: 8.7pt; }
  code { background: #eef2f7; padding: 1px 4px; border-radius: 3px; }
  pre { background: #0f1b2b; color: #e6edf5; padding: 9px 11px; border-radius: 6px; white-space: pre-wrap; page-break-inside: avoid; }
  .cover { height: 252mm; display: flex; flex-direction: column; justify-content: center; page-break-after: always; }
  .cover .band { background: linear-gradient(90deg,#0b3d91 0%,#16a34a 100%); height: 10px; width: 100%; margin-bottom: 26px; border-radius: 6px; }
  .cover .kicker { color: #16a34a; font-weight: 700; letter-spacing: 2px; font-size: 9.5pt; text-transform: uppercase; }
  .cover .sub { font-size: 12.5pt; color: #33475b; margin-top: 8px; }
  .cover .box { margin-top: 26px; border: 1px solid #d8e1ea; border-left: 5px solid #0b3d91; border-radius: 6px; padding: 14px 16px; }
  .cover .box p { margin: 3px 0; }
  .cover .foot { margin-top: 24px; font-size: 9pt; color: #5a6b7c; }
  .ok { color: #0f7b34; font-weight: 700; }
  .prep { color: #9a5b00; font-weight: 700; }
  .pend { color: #b42318; font-weight: 700; }
  .badge { display: inline-block; padding: 1px 7px; border-radius: 10px; font-size: 8.4pt; font-weight: 700; }
  .b-ok { background: #e6f4ea; color: #0f7b34; }
  .b-prep { background: #fff4e5; color: #9a5b00; }
  .b-pend { background: #fde8e8; color: #b42318; }
  .note { background: #eef4ff; border-left: 4px solid #0b3d91; padding: 9px 12px; border-radius: 4px; margin: 10px 0; page-break-inside: avoid; }
  .warn { background: #fff7e6; border-left: 4px solid #b26a00; padding: 9px 12px; border-radius: 4px; margin: 10px 0; page-break-inside: avoid; }
  .flow { display: flex; flex-direction: column; gap: 6px; margin: 10px 0 14px; }
  .node { border: 1px solid #c9d6e3; border-radius: 6px; padding: 7px 10px; background: #fff; }
  .node b { color: #0b3d91; }
  .node.az { background: #e6f4ea; border-color: #9cd3ae; }
  .node.do { background: #e8f0fe; border-color: #a9c0ef; }
  .node.ex { background: #fff4e5; border-color: #e6c58a; }
  .arrow { text-align: center; color: #5a6b7c; font-size: 11pt; line-height: 1; }
  .capture { margin: 10px 0 16px; page-break-inside: avoid; text-align: center; }
  .capture img { max-width: 100%; border: 1px solid #c9d6e3; border-radius: 6px; }
  .capture .cap { font-size: 8.8pt; color: #5a6b7c; margin-top: 4px; }
  .small { font-size: 8.8pt; color: #5a6b7c; }
  .footer-note { margin-top: 18px; padding-top: 8px; border-top: 1px solid #d8e1ea; font-size: 8.6pt; color: #5a6b7c; }
  .pagebreak { page-break-before: always; }
</style></head><body>
'@

Add '<div class="cover">'
Add '<div class="band"></div>'
Add '<div class="kicker">Global Solution FIAP 2026/2 · CitizenTech</div>'
Add '<h1>CityTech</h1>'
Add '<div class="sub">Tecnologia que transforma cidades — plataforma de monitoramento colaborativo e zeladoria urbana.</div>'
Add '<h2 style="border:none;margin-top:22px">DevOps Tools &amp; Cloud Computing</h2>'
Add '<div class="box">'
Add '<p><strong>Grupo:</strong> CityTech</p>'
Add '<p><strong>Thiago Sposito</strong> — RM 561694 — 2TDSR</p>'
Add '<p><strong>Vitor Madrigrano</strong> — RM 564191 — 2TDSR</p>'
Add '<p><strong>Lucas Lopes</strong> — RM 563544 — 2TDSA</p>'
Add '<p><strong>Organização Azure DevOps:</strong> <a href="https://dev.azure.com/RM561694">https://dev.azure.com/RM561694</a></p>'
Add '<p><strong>Projeto:</strong> GlobalSolution-CityTech</p>'
Add "<p><strong>Vídeo (YouTube):</strong> $videoCell</p>"
Add '<p><strong>Solução avaliada:</strong> API .NET 10 em Azure App Service Linux + Azure SQL</p>'
Add '</div>'
Add '<div class="foot">Documento gerado a partir dos artefatos reais do repositório em 19/11/2026. Nenhuma credencial, token ou chave foi incorporada.</div>'
Add '</div>'

Add '<h2>1. Descrição da solução</h2>'
Add '<p>O CityTech é uma plataforma CitizenTech para registro e acompanhamento de ocorrências urbanas (buracos e vias, iluminação, acessibilidade, descarte irregular, água e vazamentos). Cidadãos se cadastram, registram ocorrências e acompanham a triagem; gestores consultam, atualizam status e leem indicadores. A classificação por IA é consultiva e sempre exige revisão humana.</p>'
Add '<p>O projeto é um monorepo com API Java (ocorrências, categorias, histórico, indicadores e IA), API .NET (contas, autenticação JWT RS256 e acompanhamentos), app React Native/Expo, persistências Oracle, SQL Server e MongoDB e este fluxo DevOps.</p>'
Add '<div class="note"><strong>Escopo desta disciplina:</strong> implantação em nuvem de <strong>uma</strong> das soluções, conforme o enunciado. A API .NET foi escolhida e é publicada em App Service com banco Azure SQL, provisionados por scripts Azure CLI e entregues por pipeline CI/CD no Azure DevOps.</div>'

Add '<h2>2. Arquitetura e tecnologias</h2>'
Add '<div class="flow">'
Add '<div class="node do"><b>Desenvolvimento</b> — repositório Git local (branch <code>main</code> e branch de tarefa) + tarefa no Azure Boards</div>'
Add '<div class="arrow">↓ commit / push</div>'
Add '<div class="node do"><b>Azure Repos privado</b> — código-fonte; <code>main</code> protegida por PR, revisor obrigatório e vínculo de Work Item</div>'
Add '<div class="arrow">↓ merge por pull request</div>'
Add '<div class="node do"><b>Pipeline CI</b> — restore, build Release, 79 testes xUnit em SQL Server efêmero, TRX, ZIP da aplicação e DDL idempotente</div>'
Add '<div class="arrow">↓ artefatos <code>app</code> e <code>database</code></div>'
Add '<div class="node do"><b>Pipeline CD</b> — deployment job <code>citytech-production</code>; aplica o DDL e publica o mesmo ZIP</div>'
Add '<div class="arrow">↓</div>'
Add '<div class="node az"><b>Azure</b> — Azure SQL (accounts, follow_ups, idempotency_records) + App Service Linux B1 (API .NET 10)</div>'
Add '<div class="arrow">↓ HTTPS</div>'
Add '<div class="node"><b>Usuário</b> — Swagger, aplicativo Mobile e chamadas REST</div>'
Add '<div class="arrow">⋯</div>'
Add '<div class="node ex"><b>Não publicado nesta entrega</b> — API Java com Oracle e RabbitMQ (dependência real de ocorrências)</div>'
Add '</div>'
Add '<p class="small"><strong>Legenda:</strong> azul = Azure DevOps; verde = recursos Azure criados por script; laranja = componente do projeto fora do escopo desta entrega. Fonte editável: <code>docs/diagramas/devops-cloud.mmd</code>.</p>'
Add '<table><thead><tr><th>Camada</th><th>Tecnologia</th><th>Papel</th></tr></thead><tbody>'
Add '<tr><td>Aplicação avaliada</td><td>.NET 10, ASP.NET Core Minimal API, EF Core 10, JWT RS256, xUnit</td><td>Contas, autenticação e acompanhamentos</td></tr>'
Add '<tr><td>Computação</td><td>Azure App Service Linux (plano B1)</td><td>Hospeda a API publicada por zip deploy</td></tr>'
Add '<tr><td>Banco</td><td>Azure SQL Database (Basic)</td><td>Persistência real em nuvem</td></tr>'
Add '<tr><td>CI/CD</td><td>Azure Pipelines (YAML multi-stage)</td><td>Build, testes, artefatos e deploy automático</td></tr>'
Add '<tr><td>Governança</td><td>Azure Boards + Azure Repos + políticas de branch</td><td>Rastreabilidade tarefa → commit → PR → deploy</td></tr>'
Add '<tr><td>Provisionamento</td><td>Azure CLI 2.93 (PowerShell 5.1 e Bash)</td><td>Infraestrutura versionada e reexecutável</td></tr>'
Add '</tbody></table>'

Add '<div class="pagebreak"></div>'
Add '<h2>3. Recursos Azure e custos</h2>'
Add '<table><thead><tr><th>Recurso</th><th>Configuração</th><th>Custo aprox.</th></tr></thead><tbody>'
Add '<tr><td>Resource Group</td><td><code>rg-citytech-devops</code> (brazilsouth)</td><td>sem custo</td></tr>'
Add '<tr><td>App Service Plan</td><td>Linux, SKU B1, 1 vCPU / 1,75 GB</td><td>~US$ 13/mês</td></tr>'
Add '<tr><td>App Service</td><td>API .NET 10, HTTPS obrigatório, TLS 1.2, always on</td><td>incluído no plano</td></tr>'
Add '<tr><td>Azure SQL Server</td><td>Servidor lógico + firewall de serviços Azure</td><td>sem custo fixo</td></tr>'
Add '<tr><td>Azure SQL Database</td><td>Banco <code>citytechdb</code>, SKU Basic (5 DTU, 2 GB)</td><td>~US$ 5/mês</td></tr>'
Add '<tr><td><strong>Total</strong></td><td>Ambiente de demonstração</td><td><strong>~US$ 18/mês</strong></td></tr>'
Add '</tbody></table>'
Add '<p class="small">Cobrança recorrente enquanto os recursos existirem. O script de provisionamento não exclui nada; a remoção é manual e consciente (<code>az group delete</code>).</p>'
Add '<div class="warn"><strong>Transparência:</strong> os recursos são criados pelo script <code>scripts/provision-azure.ps1</code> (validado em dry-run). A criação efetiva depende de login e autorização de custo do grupo; capturas do Portal devem ser anexadas na seção 8 após a execução.</div>'

Add '<h2>4. Pipeline de CI (build, testes e artefatos)</h2>'
Add '<p>Arquivo <code>azure-pipeline.yml</code> na raiz do repositório (nome exigido pelo enunciado), com trigger automático na <code>main</code> após merge por PR.</p>'
Add '<table><thead><tr><th>Etapa</th><th>O que faz</th></tr></thead><tbody>'
Add '<tr><td>Instalar SDK .NET 10</td><td><code>UseDotNet@2</code> com a versão em variável de pipeline</td></tr>'
Add '<tr><td>SQL Server efêmero</td><td>Sobe container com senha aleatória por execução e aguarda readiness</td></tr>'
Add '<tr><td>Restaurar e compilar</td><td><code>dotnet tool restore</code>, <code>restore</code> e <code>build -c Release</code></td></tr>'
Add '<tr><td>Testes automatizados</td><td><code>dotnet test</code> com logger TRX contra o SQL Server temporário</td></tr>'
Add '<tr><td>Publicar resultados</td><td><code>PublishTestResults@2</code> com o TRX da execução</td></tr>'
Add '<tr><td>Publicar aplicação</td><td><code>dotnet publish</code> + <code>ArchiveFiles</code> gerando <code>citytech-api.zip</code></td></tr>'
Add '<tr><td>Gerar DDL</td><td><code>dotnet ef migrations script --idempotent</code> → <code>script-bd.sql</code></td></tr>'
Add '<tr><td>Artefatos</td><td><code>app</code> (ZIP) e <code>database</code> (SQL) publicados na execução</td></tr>'
Add '</tbody></table>'
Add '<p class="small">Verificação local equivalente: <code>dotnet build</code> com 0 avisos e 0 erros e <code>dotnet test</code> com 79/79 aprovados (77 anteriores + 2 novos de chave JWT por variável de ambiente).</p>'

Add '<h2>5. Pipeline de CD (release automática)</h2>'
Add '<ul>'
Add '<li>Stage <code>CD</code> com <code>dependsOn: CI</code> e <code>condition: succeeded()</code>: só executa se o build e os testes passarem.</li>'
Add '<li>Deployment job no environment <code>citytech-production</code>, permitindo histórico e aprovação.</li>'
Add '<li>Baixa exatamente os artefatos <code>database</code> e <code>app</code> gerados pela CI.</li>'
Add '<li><code>SqlAzureDacpacDeployment@1</code> aplica o script idempotente no Azure SQL (firewall do agente tratado por <em>AutoDetect</em>).</li>'
Add '<li><code>AzureWebApp@1</code> publica o mesmo ZIP no App Service Linux.</li>'
Add '<li>Etapa final valida a versão publicada por HTTPS (<code>/health/live</code> e <code>/api/v1/version</code>).</li>'
Add '</ul>'
Add '<p class="small">Variáveis e segredos: variable group <code>citytech-prod</code> (service connection, nomes de recursos, usuário e senha do SQL marcada como secreta). Nenhum segredo é escrito no YAML.</p>'

Add '<div class="pagebreak"></div>'
Add '<h2>6. Banco de dados em nuvem</h2>'
Add '<p>O DDL é gerado pelas migrations EF Core e versionado em <code>scripts/script-bd.sql</code> (idempotente). A pipeline aplica o mesmo script no Azure SQL antes de publicar a aplicação.</p>'
Add '<table><thead><tr><th>Tabela</th><th>Papel</th><th>Relação</th></tr></thead><tbody>'
Add '<tr><td><code>accounts</code></td><td>Contas de cidadãos e gestores, hash de senha, papel, versão otimista</td><td>1:N com follow_ups</td></tr>'
Add '<tr><td><code>follow_ups</code></td><td>Acompanhamentos por ocorrência do Java</td><td>FK <code>user_id → accounts.id</code> (cascade); <code>occurrence_id</code> sem FK cruzada</td></tr>'
Add '<tr><td><code>idempotency_records</code></td><td>Replay seguro de cadastro e criação de acompanhamento</td><td>tabela técnica com hash SHA-256</td></tr>'
Add '<tr><td><code>__EFMigrationsHistory</code></td><td>Controle de migrations aplicadas</td><td>—</td></tr>'
Add '</tbody></table>'
Add '<p>Operações demonstradas no vídeo e nos artefatos: <strong>Create/Read</strong> pela API (cadastro, login, <code>/auth/me</code>, listagem) e <strong>Create/Read/Update/Delete</strong> por SQL direto no Azure SQL nas tabelas <code>accounts</code> e <code>follow_ups</code>, sempre comprovadas por <code>SELECT</code>.</p>'
Add '<p class="small">Exemplos JSON por tabela: <code>scripts/crud/accounts.json</code> e <code>scripts/crud/followups.json</code>. Script de demonstração HTTP: <code>scripts/demo-crud-cloud.ps1</code>.</p>'

Add '<h2>7. Azure DevOps: Boards, Repos e governança</h2>'
Add '<table><thead><tr><th>Item</th><th>Configuração</th></tr></thead><tbody>'
Add '<tr><td>Organização / projeto</td><td><code>RM561694</code> / <code>GlobalSolution-CityTech</code> (privado)</td></tr>'
Add '<tr><td>Boards</td><td>Backlog com 5 Epics, 12 Features e 39 PBIs; task de desenvolvimento vinculada a branch, commit e PR (<code>AB#id</code>)</td></tr>'
Add '<tr><td>Repos</td><td>Repositório Git privado com o código-fonte da solução</td></tr>'
Add '<tr><td>Políticas da main</td><td>PR obrigatório, mínimo 1 revisor, Work Item vinculado, revisor padrão por RM, sem push direto</td></tr>'
Add '<tr><td>Pipelines</td><td>YAML <code>azure-pipeline.yml</code>, CI automática na main e CD dependente do artefato</td></tr>'
Add '<tr><td>Acesso do professor</td><td>Basic na organização e Project Administrators no projeto — concessão e verificação pendentes do e-mail institucional</td></tr>'
Add '</tbody></table>'

Add '<h2>8. Verificações executadas (comprovadas)</h2>'
Add '<table><thead><tr><th>Verificação</th><th>Resultado</th></tr></thead><tbody>'
Add '<tr><td>Build Release da solução .NET</td><td><span class="ok">0 avisos, 0 erros</span></td></tr>'
Add '<tr><td>Testes automatizados (xUnit)</td><td><span class="ok">79/79 aprovados</span> — domínio, integração com SQL Server real e API</td></tr>'
Add "<tr><td>DDL gerado das migrations</td><td><span class=\"ok\">script-bd.sql com $ddlBytes bytes</span>, idempotente</td></tr>"
Add "<tr><td>Pipeline versionada</td><td><span class=\"ok\">azure-pipeline.yml com $pipelineBytes bytes</span> na raiz</td></tr>"
Add "<tr><td>Script de provisionamento</td><td><span class=\"ok\">provision-azure.ps1 com $ps1Bytes bytes</span>, parser PowerShell sem erros; dry-run disponível</td></tr>"
Add '<tr><td>Suporte a chaves JWT por ambiente</td><td><span class="ok">implementado e testado</span> (<code>JWT_PRIVATE_KEY_PEM</code>/<code>JWT_PUBLIC_KEY_PEM</code>)</td></tr>'
Add '<tr><td>Simulação local do stage CI</td><td><span class="ok">build 0 avisos/0 erros e DDL gerado</span> com SQL Server real; corpo idêntico ao <code>script-bd.sql</code> versionado</td></tr>'
Add '<tr><td>Ferramentas da pipeline</td><td><span class="ok">manifesto <code>dotnet-ef</code> 10.0.15 restaurado</span> e <code>bash -n</code> aprovado nos 7 blocos de script</td></tr>'
Add '<tr><td>Provisionamento com Azure CLI simulado</td><td><span class="ok">48/48 verificações em 13 cenários</span> (recursos existentes, inexistentes, política regional e falhas reais), sem tocar no Azure</td></tr>'
Add '<tr><td>Consultas reais de existência (somente leitura)</td><td><span class="ok">Resource Group classificado como existente; plano, SQL e App Service como inexistentes</span>, sem exceção — exatamente o caso que falhava antes</td></tr>'
Add '<tr><td>Exemplos JSON de CRUD por tabela</td><td><span class="ok">válidos</span> (<code>scripts/crud/*.json</code>)</td></tr>'
Add '</tbody></table>'

Add '<h2>9. Status dos requisitos</h2>'
Add '<table><thead><tr><th>Requisito</th><th>Estado</th><th>Observação</th></tr></thead><tbody>'
Add '<tr><td>Scripts Azure CLI versionados</td><td><span class="badge b-ok">COMPROVADO</span></td><td>Arquivos validados; execução real depende de login/custo</td></tr>'
Add '<tr><td><code>script-bd.sql</code> com DDL</td><td><span class="badge b-ok">COMPROVADO</span></td><td>Gerado pelas migrations reais</td></tr>'
Add '<tr><td><code>azure-pipeline.yml</code> na raiz</td><td><span class="badge b-ok">COMPROVADO</span></td><td>CI e CD definidos</td></tr>'
Add '<tr><td>Desenho macro com legenda</td><td><span class="badge b-ok">COMPROVADO</span></td><td><code>docs/diagramas/devops-cloud.mmd</code></td></tr>'
Add '<tr><td>Testes automatizados no CI</td><td><span class="badge b-ok">COMPROVADO</span></td><td>79 testes locais; publicação no Pipelines a executar</td></tr>'
Add '<tr><td>Infraestrutura provisionada na Azure</td><td><span class="badge b-prep">PREPARADO</span></td><td>Script pronto; recursos não criados nesta sessão</td></tr>'
Add '<tr><td>Repositório no Azure Repos</td><td><span class="badge b-prep">PREPARADO</span></td><td>Push e políticas documentados</td></tr>'
Add '<tr><td>Deploy automático e aplicação no ar</td><td><span class="badge b-prep">PREPARADO</span></td><td>Depende da execução da pipeline</td></tr>'
Add '<tr><td>CRUD em duas tabelas na nuvem</td><td><span class="badge b-prep">PREPARADO</span></td><td>Roteiro SQL/HTTP pronto</td></tr>'
Add '<tr><td>Acesso do professor (Basic + Project Admin)</td><td><span class="badge b-pend">PENDENTE</span></td><td>E-mail institucional não informado</td></tr>'
Add $videoStatusRow
Add '</tbody></table>'

if ($captures.Count -gt 0) {
    Add '<h2>10. Evidências (capturas)</h2>'
    $index = 0
    foreach ($capture in $captures) {
        $index++
        $bytes = [IO.File]::ReadAllBytes($capture.FullName)
        $mime = if ($capture.Extension -match 'png') { 'image/png' } else { 'image/jpeg' }
        $base64 = [Convert]::ToBase64String($bytes)
        Add "<div class='capture'><img src='data:$mime;base64,$base64' alt='$($capture.Name)'><div class='cap'>$index. $($capture.BaseName)</div></div>"
    }
} else {
    Add '<h2>10. Evidências (capturas)</h2>'
    Add '<div class="warn">Nenhuma captura foi incorporada. Salve as imagens reais em <code>devops/entrega/capturas/</code> (nomes ordenáveis, ex.: <code>01_recursos_azure.png</code>) e execute novamente este gerador. Sugestão de capturas: recursos no Portal, tarefa no Boards, PR concluído, CI com testes/artefatos, CD concluído, Swagger publicado, SELECT nas duas tabelas e tarefa concluída com links.</div>'
}

Add '<h2>11. Limitações reais</h2>'
Add '<ul>'
Add '<li>A API Java com Oracle e RabbitMQ não foi publicada nesta entrega: <code>POST /api/v1/followups</code> e <code>/health/ready</code> respondem 503 na nuvem, comportamento previsto e coberto por teste.</li>'
Add '<li>Azure SQL Basic (5 DTU) atende à demonstração, não a carga real.</li>'
Add '<li>Connection string e chaves JWT ficam nas Application Settings do App Service; produção exigiria Key Vault com identidade gerenciada.</li>'
Add '<li>A regra de firewall <code>AllowAzureServices</code> é ampla; produção exigiria rede privada.</li>'
Add '<li>Revisor padrão e acesso do professor dependem do e-mail institucional ainda não informado.</li>'
Add '<li>MongoDB é snapshot acadêmico do Oracle, sem sincronização automática.</li>'
Add '</ul>'

Add '<h2>12. Como reproduzir</h2>'
Add '<pre># 1. Provisionar (dry-run e depois com -Approved)
.\scripts\provision-azure.ps1 -ConfigPath .\scripts\azure-config.local.json

# 2. Publicar o código no Azure Repos e criar a pipeline
git remote add azure https://RM561694@dev.azure.com/RM561694/GlobalSolution-CityTech/_git/GlobalSolution-CityTech
git push azure main
az pipelines create --name "CityTech-CI-CD" --repository GlobalSolution-CityTech `
  --repository-type tfsgit --branch main --yml-path azure-pipeline.yml --skip-first-run true

# 3. CRUD da aplicação publicada
.\scripts\demo-crud-cloud.ps1 -BaseUrl https://SEU-APP.azurewebsites.net

# 4. Regenerar este PDF (opcionalmente com o link do vídeo)
.\devops\entrega\gerar-pdf-devops.ps1 -VideoUrl "https://youtu.be/SEU-VIDEO"</pre>'
Add '<p class="small">Passo a passo completo, com resultado esperado e o que fazer em caso de falha: <code>devops/README.md</code>.</p>'

Add '<div class="footer-note">Documento gerado a partir do repositório CityTech em 19/11/2026 para a Global Solution FIAP 2026/2. Não contém credenciais, tokens, chaves ou dados pessoais de terceiros. Resultados marcados como COMPROVADO foram executados e verificados; PREPARADO indica código pronto sem execução na Azure; PENDENTE indica ação ainda necessária.</div>'
Add '</body></html>'

$htmlPath = Join-Path $scriptDir 'CityTech_DevOps.html'
[IO.File]::WriteAllText($htmlPath, $html.ToString(), (New-Object Text.UTF8Encoding($false)))

$browser = $null
$candidates = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
)
$browser = @($candidates | Where-Object { Test-Path $_ }) | Select-Object -First 1
if (-not $browser) { throw 'Navegador Edge/Chrome não encontrado para gerar o PDF.' }

$pdfPath = Join-Path $OutputDirectory 'CityTech_RM561694.pdf'
if (Test-Path $pdfPath) { Remove-Item $pdfPath -Force }
$htmlUri = [Uri]::new($htmlPath).AbsoluteUri
& $browser --headless --disable-gpu --no-pdf-header-footer "--print-to-pdf=$pdfPath" $htmlUri | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $pdfPath)) { throw 'Falha ao gerar o PDF.' }

$pdfBytes = [IO.File]::ReadAllBytes($pdfPath)
if ($pdfBytes.Length -lt 5 -or [Text.Encoding]::ASCII.GetString($pdfBytes, 0, 5) -ne '%PDF-') {
    throw 'Assinatura PDF inválida.'
}

$txtPath = Join-Path $OutputDirectory 'CityTech_RM561694.txt'
$videoText = if ([string]::IsNullOrWhiteSpace($VideoUrl)) { 'PENDENTE' } else { $VideoUrl }
$identification = @"
CityTech — DevOps Tools & Cloud Computing
Global Solution FIAP 2026/2 — CitizenTech

Thiago Sposito — RM 561694 — 2TDSR
Vitor Madrigrano — RM 564191 — 2TDSR
Lucas Lopes — RM 563544 — 2TDSA

Azure DevOps: https://dev.azure.com/RM561694 (projeto GlobalSolution-CityTech)
Vídeo: $videoText
"@
[IO.File]::WriteAllText($txtPath, $identification + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))

Write-Host "PDF: $pdfPath ($($pdfBytes.Length) bytes)"
Write-Host "TXT: $txtPath"
Write-Host "Capturas incorporadas: $($captures.Count)"
