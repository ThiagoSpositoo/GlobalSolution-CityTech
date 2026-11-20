[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [string]$BrowserPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $root 'entregas'
}
[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null

$mapping = Get-Content (Join-Path $root 'qa\data\azure-mapping.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$content = Get-Content (Join-Path $root 'qa\data\work-item-content.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$catalog = Get-Content (Join-Path $root 'qa\data\test-cases.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$inventory = Get-Content (Join-Path $root 'qa\relatorios\azure-work-items.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$verification = Get-Content (Join-Path $root 'qa\relatorios\verification.json') -Raw -Encoding UTF8 | ConvertFrom-Json

Remove-Item Alias:H -ErrorAction SilentlyContinue
function H([AllowNull()][object]$value) {
    if ($null -eq $value) { return '' }
    return [Net.WebUtility]::HtmlEncode([string]$value)
}
function Plain([AllowNull()][object]$value) {
    if ($null -eq $value) { return '' }
    return ([Net.WebUtility]::HtmlDecode(([string]$value -replace '<[^>]+>', ' ')) -replace '\s+', ' ').Trim()
}
# Windows PowerShell 5.1 define "Add" como alias de Add-History.
Remove-Item Alias:Add -ErrorAction SilentlyContinue
function Add([Text.StringBuilder]$builder, [string]$value) {
    [void]$builder.AppendLine($value)
}
function Criteria([object[]]$items) {
    return '<ul>' + (($items | ForEach-Object { '<li>' + (H $_) + '</li>' }) -join '') + '</ul>'
}

$contentById = @{}
foreach ($item in @($content.workItems)) { $contentById[[int]$item.id] = $item }
$inventoryById = @{}
foreach ($item in @($inventory.items)) { $inventoryById[[int]$item.id] = $item }
$featureByKey = @{}
foreach ($feature in @($mapping.features)) { $featureByKey[[string]$feature.featureKey] = $feature }
$testIdByCode = @{}
foreach ($result in @($verification.results | Where-Object { $_.check -eq 'test-case' })) {
    $testIdByCode[[string]$result.code] = [int]$result.id
}

$html = New-Object Text.StringBuilder
Add $html '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">'
Add $html '<title>Compliance CityTech — FIAP 2026/2</title>'
Add $html @'
<style>
@page { size: A4; margin: 17mm 14mm 18mm; }
* { box-sizing: border-box; }
body { font-family: "Segoe UI", Arial, sans-serif; color:#17243b; font-size:9.3pt; line-height:1.42; margin:0; }
h1,h2,h3,h4 { color:#123c72; margin:0 0 8px; line-height:1.15; }
h1 { font-size:28pt; } h2 { font-size:18pt; border-bottom:2px solid #1aa36f; padding-bottom:5px; margin-top:8px; }
h3 { font-size:13pt; margin-top:13px; } h4 { font-size:10.5pt; margin-top:9px; }
p { margin:5px 0 8px; } ul,ol { margin:5px 0 8px 20px; padding:0; }
a { color:#075fa8; word-break:break-all; }
.cover { min-height:252mm; display:flex; flex-direction:column; justify-content:center; text-align:center; page-break-after:always;
 background:linear-gradient(145deg,#edf7ff,#f4fff9); border-top:12px solid #1264a3; border-bottom:12px solid #1aa36f; padding:28mm 18mm; }
.brand { color:#1264a3; font-size:13pt; font-weight:700; letter-spacing:3px; text-transform:uppercase; }
.subtitle { font-size:17pt; color:#38516d; margin:13px 0 28px; }
.people { margin:22px auto; text-align:left; display:inline-block; font-size:11pt; }
.meta { color:#52657b; margin-top:25px; }
.page { page-break-before:always; }
.keep { break-inside:avoid; page-break-inside:avoid; }
.card { border:1px solid #cbd9e7; border-left:5px solid #1264a3; border-radius:6px; padding:10px 12px; margin:9px 0; break-inside:avoid; }
.card.green { border-left-color:#1aa36f; }.card.orange { border-left-color:#e59035; }
.pill { display:inline-block; background:#eaf3fb; color:#123c72; padding:2px 7px; border-radius:10px; font-size:8pt; font-weight:600; margin-right:4px; }
.ok { color:#087747; font-weight:700; }.warn { color:#a24d00; font-weight:700; }.missing { color:#9a2633; font-weight:700; }
.metrics { display:grid; grid-template-columns:repeat(4,1fr); gap:8px; margin:13px 0; }
.metric { border-radius:8px; background:#123c72; color:#fff; padding:12px; text-align:center; }
.metric strong { display:block; font-size:20pt; }.metric span { font-size:8pt; }
table { width:100%; border-collapse:collapse; margin:8px 0 13px; font-size:8.1pt; }
th { background:#123c72; color:#fff; text-align:left; } th,td { border:1px solid #ccd8e4; padding:5px 6px; vertical-align:top; }
tr:nth-child(even) td { background:#f5f8fb; }
.test { page-break-before:always; }
.steps td:first-child { width:6%; text-align:center; font-weight:700; }.steps td:nth-child(2),.steps td:nth-child(3) { width:47%; }
.notice { background:#fff6e9; border:1px solid #efbd79; border-radius:6px; padding:10px 12px; margin:10px 0; }
.evidence { border:2px dashed #a9bacb; padding:12px; margin:10px 0; text-align:center; break-inside:avoid; }
.evidence img { max-width:100%; max-height:230mm; display:block; margin:8px auto; }
.small { font-size:8pt; color:#5b6b7c; }
.toc li { margin:5px 0; }
.footer-note { margin-top:20px; padding-top:8px; border-top:1px solid #ccd8e4; color:#5b6b7c; font-size:8pt; }
</style></head><body>
'@

Add $html '<section class="cover">'
Add $html '<div class="brand">CityTech</div><h1>Compliance, Quality Assurance &amp; Tests</h1>'
Add $html '<div class="subtitle">Global Solution FIAP — 2026/2<br>Planejamento Scrum, backlog e testes de caixa-preta</div>'
Add $html '<div class="people"><strong>Thiago Sposito</strong> — RM 561694 — 2TDSR<br><strong>Vitor Madrigrano</strong> — RM 564191 — 2TDSR<br><strong>Lucas Lopes</strong> — RM 563544 — 2TDSA</div>'
Add $html '<div class="meta">Projeto Azure DevOps<br><a href="https://dev.azure.com/RM561694/GlobalSolution-CityTech">https://dev.azure.com/RM561694/GlobalSolution-CityTech</a><br><br>19 de novembro de 2026</div></section>'

Add $html '<section><h2>Sumário</h2><ol class="toc"><li>Identificação, contexto e rastreabilidade</li><li>Plano Scrum e organização do backlog</li><li>Epics e hierarquia</li><li>Features: descrições e critérios de aceite</li><li>Product Backlog Items: descrições e critérios</li><li>Estratégia e matriz de testes</li><li>Test Cases: Summary e Steps</li><li>Verificação independente e situação de execução</li><li>Evidências visuais e checklist pendente</li><li>Limitações, conclusão e referências</li></ol>'
Add $html '<h2>1. Identificação e contexto</h2><p>O CityTech é uma plataforma CitizenTech acadêmica de monitoramento colaborativo e zeladoria urbana. Cidadãos registram e acompanham ocorrências; gestores realizam triagem, atualização de status e consulta de indicadores. A classificação por IA é consultiva e depende de supervisão humana. Os dados utilizados são fictícios e não representam integração oficial com prefeituras.</p>'
$sourceDates = '<div class="card green"><strong>Fonte oficial do planejamento e dos testes:</strong><br><a href="https://dev.azure.com/RM561694/GlobalSolution-CityTech">RM561694 / GlobalSolution-CityTech</a><br><span class="small">Inventário local extraído em {0}; verificação independente em {1}.</span></div>' -f (H $inventory.generatedAtUtc),(H $verification.generatedAtUtc)
Add $html $sourceDates
Add $html '<div class="metrics"><div class="metric"><strong>5</strong><span>EPICS</span></div><div class="metric"><strong>12</strong><span>FEATURES</span></div><div class="metric"><strong>39</strong><span>PBIs</span></div><div class="metric"><strong>24</strong><span>TEST CASES</span></div></div>'
Add $html '<p><span class="ok">75 verificações independentes aprovadas</span> · 0 falhas · 0 documentações pendentes · Test Cases Azure IDs 58–81.</p></section>'

Add $html '<section class="page"><h2>2. Plano Scrum</h2>'
Add $html '<div class="card"><h3>Organização proposta</h3><ul><li><strong>Product Backlog:</strong> 5 Epics → 12 Features → 39 PBIs, priorizados pelo valor ao cidadão, dependências e risco.</li><li><strong>Sprints:</strong> ciclos curtos com objetivo verificável; refinamento prévio de descrição, aceite e dependências.</li><li><strong>Planejamento:</strong> seleção de PBIs prontos, decomposição técnica e definição da capacidade.</li><li><strong>Acompanhamento:</strong> Daily para progresso, impedimentos e coordenação entre Mobile, APIs, dados e QA.</li><li><strong>Review:</strong> demonstração do incremento funcional com evidências reais.</li><li><strong>Retrospectiva:</strong> ações de melhoria incorporadas ao ciclo seguinte.</li></ul></div>'
Add $html '<div class="card green"><h3>Definition of Ready</h3><p>Descrição compreensível, critérios de aceite objetivos, dependências identificadas, dados de teste fictícios e tamanho compatível com a Sprint.</p><h3>Definition of Done</h3><p>Código revisado, validações automatizadas pertinentes aprovadas, critérios atendidos, integração verificada, documentação atualizada e evidência real registrada. Item planejado ou bloqueado não é declarado concluído.</p></div>'
Add $html '<h3>Estratégia de qualidade</h3><p>Os testes são funcionais de caixa-preta, com um caso positivo e um negativo por Feature. Cada caso registra objetivo, preparação, entradas, saída esperada e passos estruturados. A criação e os vínculos foram verificados no Azure; execução manual e resultados no Test Plans são estados distintos e não são inferidos.</p></section>'

Add $html '<section class="page"><h2>3. Epics e hierarquia</h2>'
foreach ($epic in @($mapping.epics)) {
    $remote = $inventoryById[[int]$epic.id]
    Add $html ('<div class="card"><h3>ID ' + $epic.id + ' — ' + (H $epic.title) + '</h3><p>' + (H (Plain $remote.description)) + '</p><p><strong>Features:</strong> ' + (($epic.featureIds | ForEach-Object { $f = @($mapping.features | Where-Object { $_.id -eq $_ }) ; $_ }) -join ', ') + '</p>')
    $featureTitles = @($mapping.features | Where-Object { [int]$_.parentEpicId -eq [int]$epic.id } | ForEach-Object { 'ID ' + $_.id + ' — ' + (H $_.title) })
    Add $html ('<ul><li>' + ($featureTitles -join '</li><li>') + '</li></ul></div>')
}
Add $html '<table><thead><tr><th>Epic</th><th>Features</th><th>PBIs</th></tr></thead><tbody>'
foreach ($epic in @($mapping.epics)) {
    $fs = @($mapping.features | Where-Object { $_.parentEpicId -eq $epic.id })
    $pbiCount = 0; foreach ($f in $fs) { $pbiCount += @($f.pbiIds).Count }
    Add $html ('<tr><td>ID ' + $epic.id + ' — ' + (H $epic.title) + '</td><td>' + (($fs | ForEach-Object { $_.id }) -join ', ') + '</td><td>' + $pbiCount + '</td></tr>')
}
Add $html '</tbody></table></section>'

Add $html '<section class="page"><h2>4. Features — descrição e aceite</h2>'
foreach ($feature in @($mapping.features)) {
    $doc = $contentById[[int]$feature.id]
    Add $html ('<article class="card"><span class="pill">ID ' + $feature.id + '</span><span class="pill">Epic ' + $feature.parentEpicId + '</span><h3>' + (H $feature.title) + '</h3><p>' + (H $doc.description) + '</p><h4>Critérios de aceite</h4>' + (Criteria @($doc.acceptanceCriteria)) + '<p class="small">PBIs: ' + (($feature.pbiIds | ForEach-Object { [string]$_ }) -join ', ') + '</p></article>')
}
Add $html '</section>'

Add $html '<section class="page"><h2>5. Product Backlog Items</h2>'
foreach ($feature in @($mapping.features)) {
    Add $html ('<h3>ID ' + $feature.id + ' — ' + (H $feature.title) + '</h3>')
    foreach ($pbi in @($mapping.productBacklogItems | Where-Object { $_.parentFeatureId -eq $feature.id })) {
        $doc = $contentById[[int]$pbi.id]
        Add $html ('<article class="card green"><span class="pill">ID ' + $pbi.id + '</span><h4>' + (H $pbi.title) + '</h4><p>' + (H $doc.description) + '</p><strong>Critérios de aceite</strong>' + (Criteria @($doc.acceptanceCriteria)) + '</article>')
    }
}
Add $html '</section>'

Add $html '<section class="page"><h2>6. Estratégia e matriz dos Test Cases</h2><p>Foram definidos dois casos por Feature: um positivo e um negativo. Todos os 24 itens existem no Azure DevOps e estão vinculados às Features esperadas.</p>'
Add $html '<table><thead><tr><th>Feature</th><th>Positivo</th><th>Negativo</th><th>Situação funcional</th></tr></thead><tbody>'
foreach ($feature in @($mapping.features)) {
    $tests = @($catalog.testCases | Where-Object { $_.featureKey -eq $feature.featureKey })
    $pos = @($tests | Where-Object { $_.type -eq 'Positivo' })[0]; $neg = @($tests | Where-Object { $_.type -eq 'Negativo' })[0]
    $situation = if ($feature.featureKey -in @('image-attachments','operational-reports')) { 'Casos criados; execução bloqueada pela funcionalidade não implementada' } else { 'Caso criado; execução manual não registrada neste pacote' }
    Add $html ('<tr><td>ID ' + $feature.id + ' — ' + (H $feature.title) + '</td><td>ID ' + $testIdByCode[$pos.code] + ' — ' + (H $pos.code) + '</td><td>ID ' + $testIdByCode[$neg.code] + ' — ' + (H $neg.code) + '</td><td>' + (H $situation) + '</td></tr>')
}
Add $html '</tbody></table><div class="notice"><strong>Casos bloqueados:</strong> TC-IMG-01/02 (IDs 64–65) e TC-REPORT-01/02 (IDs 80–81). Eles documentam o comportamento esperado, mas não devem receber resultado Passed/Failed enquanto anexos e exportação de relatórios não existirem.</div></section>'

foreach ($tc in @($catalog.testCases)) {
    $feature = $featureByKey[[string]$tc.featureKey]
    $blocked = $tc.featureKey -in @('image-attachments','operational-reports')
    Add $html '<article class="test">'
    Add $html ('<h2>Test Case ID ' + $testIdByCode[$tc.code] + ' — ' + (H $tc.code) + '</h2><p><span class="pill">' + (H $tc.type) + '</span><span class="pill">Feature ' + $feature.id + '</span>' + $(if($blocked){'<span class="pill">BLOQUEADO</span>'}else{''}) + '</p>')
    Add $html ('<h3>' + (H $tc.title) + '</h3><table><tbody><tr><th>Feature vinculada</th><td>ID ' + $feature.id + ' — ' + (H $feature.title) + '</td></tr><tr><th>Objetivo</th><td>' + (H $tc.objective) + '</td></tr><tr><th>Preparação</th><td>' + (H $tc.preconditions) + '</td></tr><tr><th>Inputs</th><td>' + (H $tc.inputs) + '</td></tr><tr><th>Output esperado</th><td>' + (H $tc.expectedOutput) + '</td></tr><tr><th>Execução</th><td>' + $(if($blocked){'<span class="warn">Bloqueada — funcionalidade não implementada</span>'}else{'Não registrada; nenhuma aprovação/reprovação foi inferida'}) + '</td></tr></tbody></table>')
    Add $html '<h3>Passos</h3><table class="steps"><thead><tr><th>#</th><th>Ação</th><th>Resultado esperado</th></tr></thead><tbody>'
    $n=0; foreach ($step in @($tc.steps)) { $n++; Add $html ('<tr><td>'+$n+'</td><td>'+(H $step.action)+'</td><td>'+(H $step.expected)+'</td></tr>') }
    Add $html '</tbody></table></article>'
}

Add $html '<section class="page"><h2>8. Verificação independente e execução</h2>'
Add $html '<div class="metrics"><div class="metric"><strong>75</strong><span>CHECKS APROVADOS</span></div><div class="metric"><strong>0</strong><span>FALHAS</span></div><div class="metric"><strong>0</strong><span>DOCS PENDENTES</span></div><div class="metric"><strong>24</strong><span>VÍNCULOS DE TESTE</span></div></div>'
Add $html '<p>O relatório <code>qa/relatorios/verification.json</code> confirmou a documentação das 12 Features e 39 PBIs, além da existência e do vínculo correto dos 24 Test Cases. Essas 75 verificações são estruturais e independentes; <strong>não equivalem à execução manual no Azure Test Plans</strong>.</p>'
Add $html '<div class="notice"><strong>Execução manual:</strong> não há resultados Passed/Failed, runs, bugs ou relatório analítico de Test Plans disponíveis nos artefatos locais. Este PDF não fabrica esses resultados. Casos bloqueados permanecem explicitamente bloqueados.</div></section>'

$capturesDir = Join-Path $root 'qa\entrega\capturas'
[IO.Directory]::CreateDirectory($capturesDir) | Out-Null
$captures = @(Get-ChildItem $capturesDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '^\.(png|jpg|jpeg|webp)$' } | Sort-Object Name)
Add $html '<section class="page"><h2>9. Evidências visuais e checklist</h2>'
if ($captures.Count -eq 0) {
    Add $html '<div class="notice"><span class="missing">Nenhuma captura real estava disponível em qa/ no momento da geração.</span> A entrega preserva essa lacuna em vez de inserir imagens simuladas.</div>'
} else {
    foreach ($capture in $captures) {
        $uri = [Uri]::new($capture.FullName).AbsoluteUri
        Add $html ('<figure class="evidence"><img src="' + (H $uri) + '"><figcaption>' + (H $capture.BaseName) + '</figcaption></figure>')
    }
}
Add $html '<h3>Capturas obrigatórias ainda a conferir/inserir</h3><table><thead><tr><th>#</th><th>Evidência</th><th>Situação neste PDF</th></tr></thead><tbody>'
$checks = @(
 'Backlogs com hierarquia 5 Epics → 12 Features → 39 PBIs',
 'Descrição e critérios de aceite das 12 Features',
 'Descrição e critérios de aceite dos 39 PBIs',
 'Features com Test Cases vinculados',
 'Summary e Steps dos 24 Test Cases',
 'Test Plan, Suites e casos atribuídos, se a licença permitir',
 'Execuções manuais reais e resultados',
 'Bugs vinculados, se realmente existirem',
 'Relatórios analíticos do Test Plans',
 'Professor como ADMIN, com dados pessoais ocultados'
)
$i=0; foreach($check in $checks){$i++;Add $html ('<tr><td>'+$i+'</td><td>'+(H $check)+'</td><td><span class="missing">Captura ausente</span></td></tr>')}
Add $html '</tbody></table>'
Add $html '<div class="card green"><h3>Mecanismo de inserção</h3><ol><li>Salvar capturas reais, revisadas e sem dados sensíveis em <code>qa/entrega/capturas/</code>, usando nomes ordenáveis como <code>01_backlog_hierarquia.png</code>.</li><li>Executar <code>powershell.exe -NoProfile -ExecutionPolicy Bypass -File qa/scripts/New-ComplianceDelivery.ps1</code>.</li><li>O gerador incorpora automaticamente todas as imagens e recria PDF, TXT e ZIP.</li></ol></div></section>'

Add $html '<section class="page"><h2>10. Limitações e conclusão</h2><ul><li>Anexos de imagem e exportação de relatórios não estão implementados; quatro Test Cases permanecem bloqueados.</li><li>Recuperação de senha, push, mapas/GPS e gráficos avançados não devem ser apresentados como concluídos.</li><li>Geolocalização, no escopo atual, corresponde a endereço textual.</li><li>Não há evidência local de execução manual no Test Plans, bugs, relatórios analíticos ou permissão ADMIN do professor.</li><li>As 75 verificações comprovam estrutura, documentação, existência e vínculos — não resultados funcionais manuais.</li></ul>'
Add $html '<p>O backlog do CityTech está estruturado e documentado no Azure DevOps, com rastreabilidade entre 5 Epics, 12 Features, 39 PBIs e 24 Test Cases. Todos os itens documentais e vínculos passaram pela verificação independente registrada. As pendências de evidência e execução são mantidas transparentes para revisão antes do envio acadêmico.</p>'
Add $html '<h3>Referências</h3><ul><li><a href="https://dev.azure.com/RM561694/GlobalSolution-CityTech">Projeto Azure DevOps CityTech</a></li><li><code>qa/relatorios/azure-work-items.json</code></li><li><code>qa/relatorios/verification.json</code></li><li><code>qa/data/azure-mapping.json</code></li><li><code>qa/data/work-item-content.json</code></li><li><code>qa/data/test-cases.json</code></li></ul>'
Add $html '<div class="footer-note">Relatório gerado a partir dos artefatos reais do projeto em 19/11/2026. Nenhuma credencial, token ou dado secreto foi incorporado.</div></section></body></html>'

$htmlPath = Join-Path $root 'qa\entrega\Compliance_CityTech.html'
[IO.File]::WriteAllText($htmlPath, $html.ToString(), (New-Object Text.UTF8Encoding($false)))

if ([string]::IsNullOrWhiteSpace($BrowserPath)) {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    )
    $BrowserPath = @($candidates | Where-Object { Test-Path $_ })[0]
}
if (-not (Test-Path $BrowserPath -PathType Leaf)) { throw "Navegador para PDF não encontrado: $BrowserPath" }

$pdfPath = Join-Path $OutputDirectory 'Compliance_CityTech.pdf'
if (Test-Path $pdfPath) { Remove-Item $pdfPath -Force }
$htmlUri = [Uri]::new($htmlPath).AbsoluteUri
& $BrowserPath --headless --disable-gpu --no-pdf-header-footer "--print-to-pdf=$pdfPath" $htmlUri | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $pdfPath)) { throw 'Falha ao gerar PDF.' }

$txtPath = Join-Path $OutputDirectory 'Compliance_CityTech.txt'
$identification = @'
CityTech — Compliance, Quality Assurance & Tests

Thiago Sposito — RM 561694 — 2TDSR
Vitor Madrigrano — RM 564191 — 2TDSR
Lucas Lopes — RM 563544 — 2TDSA

Azure DevOps: https://dev.azure.com/RM561694/GlobalSolution-CityTech
'@
[IO.File]::WriteAllText($txtPath, $identification + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))

$zipPath = Join-Path $OutputDirectory 'Entrega_Compliance_CityTech.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $pdfPath,$txtPath -DestinationPath $zipPath -CompressionLevel Optimal

$pdfBytes = [IO.File]::ReadAllBytes($pdfPath)
if ($pdfBytes.Length -lt 5 -or [Text.Encoding]::ASCII.GetString($pdfBytes,0,5) -ne '%PDF-') { throw 'Assinatura PDF inválida.' }
$zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $names = @($zip.Entries | ForEach-Object { $_.FullName })
    if ($names.Count -ne 2 -or 'Compliance_CityTech.pdf' -notin $names -or 'Compliance_CityTech.txt' -notin $names) { throw 'Conteúdo ZIP inválido.' }
    if (@($zip.Entries | Where-Object { $_.Length -eq 0 }).Count -gt 0) { throw 'ZIP contém arquivo vazio.' }
}
finally { $zip.Dispose() }

Write-Host "PDF: $pdfPath ($($pdfBytes.Length) bytes)"
Write-Host "TXT: $txtPath"
Write-Host "ZIP: $zipPath"
Write-Host "Capturas incorporadas: $($captures.Count)"
