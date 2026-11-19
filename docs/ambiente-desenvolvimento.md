# Diagnóstico do computador e preparação

Inspeções e preparação em **17/11/2026**. **Etapa 2 concluída no escopo das ferramentas. Etapa 3A concluiu Git e serviços locais. Etapas 4A/5A concluíram .NET; Java e Oracle XE 21 local também foram validados.** Oracle institucional e rota Android/acessos externos permanecem pendentes. Histórico abaixo; infraestrutura em [verificação 3A](verificacao-etapa-3a.md) e backends em seus READMEs.

## 1. Resultado observado — histórico da Etapa 1

| Item | Estado/versão encontrada | Método |
|---|---|---|
| Sistema | Windows 11 Pro, versão 10.0.26300, build 26300, 64 bits | Win32_OperatingSystem |
| Arquitetura | x64 | RuntimeInformation |
| Shell | Windows PowerShell Desktop 5.1.26100.9818 | PSVersionTable |
| CPU | AMD Ryzen 5 5500X3D, 6-Core Processor | Win32_Processor |
| RAM | 15,93 GiB | Win32_ComputerSystem |
| Espaço livre C: | 217,57 GiB no diagnóstico | Get-PSDrive |
| Virtualização firmware | True | Win32_Processor |
| Hipervisor presente | True | Win32_ComputerSystem |
| SLAT informado por WMI | False | Win32_Processor; resultado inconclusivo sob hipervisor, revalidar antes do Docker |
| Administrador na sessão | **Não** | WindowsPrincipal.IsInRole |
| WinGet | **1.29.380** | `winget --version` |
| OpenCode | **2.3.0** | Registro de programas instalados |
| Edge | **157.0.4341.60** | Registro de programas |
| Git | Não encontrado | PATH, registro e diretório padrão |
| Java / javac (JDK) | Não encontrado | PATH, registro, diretórios Java/Adoptium |
| Maven / Gradle | Não encontrados | PATH e registro |
| .NET SDK | Não encontrado | PATH, registro e `C:\Program Files\dotnet` ausente |
| Node.js / npm | Não encontrados | PATH, registro e diretório padrão |
| Docker / Docker Compose | Não encontrados | PATH, registro, diretórios e serviços |
| Python | **Somente aliases WindowsApps**, executáveis de 0 bytes; interpretador não confirmado | Get-Command, Get-Item, registro, Get-AppxPackage e diretório padrão |
| Azure CLI | Não encontrada | PATH, registro e diretório padrão |
| WSL | **Não instalado**, mensagem explícita de `wsl --status` | Consulta sem instalação |
| VS Code / IntelliJ / Visual Studio | Não encontrados | PATH, registro e diretórios padrão |
| sqlplus / SQLcl / mongosh / sqlcmd / adb | Não encontrados no PATH | Get-Command |
| Serviços SQL Server / Oracle / Mongo / PostgreSQL | Não encontrados | Get-Service |
| pdftotext / mutool / tesseract | Não encontrados no PATH | Leitor PDF nativo foi suficiente |

“Não encontrado” significa ausência nas localizações consultadas, **não** prova de inexistência de um executável portátil em qualquer pasta do disco. Nenhuma versão foi inventada para ferramentas ausentes. O CLR usado pelo PowerShell **não é .NET SDK**.

O primeiro diagnóstico combinou objetos com formatos diferentes e exibiu campos em branco na saída. As informações de hardware e diretórios foram consultadas novamente com `Format-List`, produzindo os valores acima; campos em branco não foram tratados como ausência.

## 2. PATH e permissões

PATH observado:

```text
C:\WINDOWS\system32
C:\WINDOWS
C:\WINDOWS\System32\Wbem
C:\WINDOWS\System32\WindowsPowerShell\v1.0\
C:\WINDOWS\System32\OpenSSH\
C:\Program Files\NVIDIA Corporation\NVIDIA App\NvDLISR
C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common
C:\Users\sposi\AppData\Local\Microsoft\WindowsApps
```

Não há entradas de Git/JDK/SDKs/Node/Docker. `JAVA_HOME`, `JDK_HOME`, `MAVEN_HOME`, `M2_HOME`, `GRADLE_HOME`, `DOTNET_ROOT`, `ANDROID_HOME` e `ANDROID_SDK_ROOT` não estavam definidas na sessão.

`Get-ExecutionPolicy -List`: todos os escopos retornaram `Undefined`; isso não comprova que qualquer script será autorizado pela política efetiva. Não alterar política global para contornar problemas; após instalar Node, `npm.cmd`/`npx.cmd` podem ser usados quando o wrapper `.ps1` estiver bloqueado.

ACL da raiz: usuário atual tem permissão de controle total e existe negação herdada de `DeleteSubdirectoriesAndFiles` para Todos. Não alteramos ACLs. A criação de arquivos da Etapa 1 comprova a capacidade de gravação, não autoriza exclusões.

## 3. Plano de instalação — autorizado; resultados na seção 7

Comandos do plano original; execução efetiva registrada nas seções 7 e 8. Não reinstalar ferramentas verificadas. Antes de futuras instalações, conferir pacote/publicador/versão e permitir elevação somente quando necessária e autorizada.

### Prioridade 1: desenvolvimento e histórico

```powershell
winget install --id Git.Git --exact --version 2.56.0.4 --source winget
winget install --id EclipseAdoptium.Temurin.21.JDK --exact --version 21.0.13.9 --source winget
winget install --id Microsoft.DotNet.SDK.10 --exact --version 10.0.404 --source winget
```

- JDK **21.0.13+9 LTS** para Java; o catálogo representa essa versão como `21.0.13.9`.
- .NET SDK **10.0.404 LTS**, não apenas runtime; runtime associado **10.0.15**, confirmado nos metadados Microsoft.
- Node **24 LTS**, versão consultada **24.22.3**. Na consulta atual, `OpenJS.NodeJS.LTS` aponta para **26.13.1** e a versão 24.22.3 não foi encontrada nesse pacote:

```powershell
winget show --id OpenJS.NodeJS.LTS --exact --version 24.22.3 --source winget --disable-interactivity
# Resultado em 17/11/2026: No version found matching: 24.22.3 (exit 1).
```

Usar o instalador oficial `https://nodejs.org/dist/v24.22.3/node-v24.22.3-x64.msi`, após autorização. SHA-256 publicado no índice oficial consultado: `4a1ab5bdec5434bae58efae6c3e5077a011f6f1e76d2b47b7b10af043f7db545`. Baixar para uma subpasta nova em `C:\Users\sposi\AppData\Local\Temp\opencode`, comparar com `Get-FileHash -Algorithm SHA256` e conferir `Get-AuthenticodeSignature` antes de abrir o MSI. Interromper se houver divergência. O instalador ainda não foi baixado nem sua assinatura validada.

npm/npx acompanham Node; registrar suas versões efetivas após instalação. Deixar desmarcada a instalação adicional de ferramentas nativas (Python/Build Tools/Chocolatey), pois não é necessária para este preparo. Não instalar npm ou Expo CLI global separadamente.

Depois de abrir nova sessão e conferir versões, inicializar Git **na raiz existente**:

```powershell
git init -b main
git status --short
```

Configurar nome/e-mail local com valores fornecidos pelo usuário; não adivinhar identidade. Revisar arquivos antes do primeiro commit e fazer commits reais incrementais durante cada implementação. Não reconstruir histórico fictício para a avaliação Mobile.

Maven global é dispensável: gerar **Maven Wrapper** junto do futuro projeto Java e fixar Maven 3.10.1, release estável consultada. Isso não exige Gradle global. Gradle Wrapper Android poderá ser gerado pelo Expo no build nativo.

### Prioridade 2: infraestrutura local

```powershell
# Requer autorização para mudança no Windows e possível reinicialização:
wsl --install --no-distribution

# Após conferir WSL 2 e virtualização:
winget install --id Docker.DockerDesktop --exact --version 4.99.0 --source winget
```

Docker Desktop inclui o plugin Compose (`docker compose`, sem hífen). Não instalar Compose legado separadamente. Preferir modo por usuário com backend WSL 2; conferir o escopo oferecido pelo pacote antes de executar. Se o WinGet não oferecer esse modo, usar o instalador oficial verificado e a opção documentada `install --user --backend=wsl-2`. A habilitação inicial de WSL continua exigindo administrador. Não reiniciar automaticamente o computador: combinar a reinicialização com o usuário.

WSL **3.0.5** está disponível no catálogo; a versão do aplicativo WSL não deve ser confundida com o backend **WSL 2**. `wsl --install --no-distribution` instala a versão estável oferecida naquele momento, sem Ubuntu adicional; conferir a versão obtida. Docker requer WSL ≥2.1.5. Ler os termos do Docker Desktop (uso educacional contemplado) no instalador.

Revalidar SLAT/Windows/WSL antes da instalação: WMI retornou SLAT falso com hipervisor ativo. Não concluir que o processador é incompatível só por esse campo. Com 16 GB, iniciar apenas serviços necessários e preferir dispositivo Android físico em vez de somar um emulador pesado a todos os bancos.

Oracle: confirmar primeiro serviço disponibilizado pela disciplina, versão, rede e credenciais. Se não houver, planejar instalação/container oficial Oracle Free após verificar versão e termos. Não foi fornecido comando cego de imagem Oracle: a consulta à página comercial Free retornou **HTTP 403**, e nenhum ambiente Oracle foi testado.

SQL Server/mongosh/RabbitMQ poderão rodar nos containers, evitando instalações globais de servidor. SQL Server usa edição Developer para desenvolvimento/testes.

### Prioridade 3: nuvem e publicação

```powershell
winget install --id Microsoft.AzureCLI --exact --version 2.93.0 --source winget
```

Necessária para os scripts de DevOps, mas instalação não autoriza `az login`, criação de recursos ou cobrança. Azure Boards/Repos/Test Plans usam navegador; confirmar conta, permissões, créditos e acesso Test Plans antes do desenvolvimento dependente.

APK Android: decidir entre toolchain Android local (JDK exigido pelo Gradle/SDK do Expo, Android SDK e Build Tools) e build EAS autorizado. EAS é serviço externo; quotas/conta/tempo de fila devem ser verificados. Firebase App Distribution pode receber APK pelo console; CLI Firebase não é obrigatória. Expo Go sozinho não gera a entrega publicada.

### Opcionais/dispensáveis para a arquitetura

| Ferramenta | Quando faria sentido | Comando proposto se necessária |
|---|---|---|
| VS Code | Preferência de edição; linha de comando é suficiente | `winget install --id Microsoft.VisualStudioCode --exact` |
| Python 3.13 | Análise de dados independente, se surgir necessidade | `winget install --id Python.Python.3.13 --exact` |
| IntelliJ / Visual Studio completo | Preferência pessoal | Não necessário |
| Gradle/Maven globais | Wrapper indisponível em caso específico | Não necessário agora |
| GPU/modelo local | Se escolher inferência local após benchmark | Não necessário para API de modelo |
| PostgreSQL | Se arquitetura for revisada com justificativa | Não instalar |
| Extrator/OCR PDF | PDF sem texto legível | Não necessário neste PDF |

## 4. Verificação futura após instalação

```powershell
git --version
java -version
javac -version
dotnet --list-sdks
node --version
npm.cmd --version
wsl --version
docker --version
docker compose version
docker info
az version
```

Critérios: Java/javac na mesma linha 21; SDK .NET 10 presente; Node 24; Docker com engine Linux operacional; Compose atual; Oracle acessível com sessão SQL; ferramentas Android coerentes com SDK Expo antes do build APK.

Rever `Get-Command <nome> -All` para resolver conflitos. O principal conflito atual é alias Python aparentando instalação; futuros riscos são múltiplos JDKs (Java versus Android), `JAVA_HOME` divergente, Node LTS mudando de major e OpenCode mantendo PATH antigo após instalação.

## 5. OneDrive

A raiz atual está em OneDrive e foi preservada exatamente ali. Dependências, caches e volumes de banco podem ter alto volume de arquivos e travas de sincronização. `.gitignore` não controla OneDrive. O Compose usa volumes nomeados para dados; se surgirem problemas de sincronização/build, discutir uma cópia de trabalho fora do OneDrive antes de mover qualquer arquivo. Não houve mudança de pasta ou configuração do serviço.

## 6. Revalidação da Etapa 2 — 17/11/2026

### Diagnósticos executados

- `Get-Command -All`: Git, Java/javac, .NET, Node/npm/npx, Maven/Gradle, Docker, Azure CLI, IDEs, clientes SQL/Mongo e adb ausentes no PATH. `python.exe` é alias WindowsApps de **0 bytes**, não interpretador comprovado.
- Registro de desinstalação HKLM/HKCU e diretórios padrão: nenhuma instalação das ferramentas de desenvolvimento identificada; OpenCode **2.3.0** encontrado. Ausência nas localizações consultadas não exclui executáveis portáteis em outras pastas.
- `Test-Path .git` e `Test-Path .env`: ambos **False**. Git indisponível impede `git status`/diff; nenhum repositório inicializado.
- CIM: Windows 11 Pro x64, build **26300**; registro informa **26H2**, revisão **9974**. `ProductName` do registro ainda diz Windows 10 Pro; a identificação Windows 11 vem de `Win32_OperatingSystem`.
- Ryzen 5 5500X3D, **15,93 GiB RAM**, **217,55 GiB livres em C:**; firmware com virtualização ativa e hipervisor presente. SLAT e VMMonitorModeExtensions retornam False sob hipervisor: compatibilidade efetiva ainda depende de validação WSL/Docker.
- PowerShell **5.1.26100.9818**, WinGet **1.29.380**, sessão **sem administrador**. PATH e variáveis de SDK continuam sem ferramentas; políticas de execução em todos os escopos `Undefined`.
- `wsl --status`: informa não instalado, saída **50**. `wsl --version`: mesma mensagem, saída **1**. O executável Windows `wsl.exe` existe, mas isso não comprova WSL instalado.
- `Win32_OptionalFeature`: VirtualMachinePlatform, HypervisorPlatform e Microsoft-Windows-Subsystem-Linux com `InstallState=2` (desabilitados). `LanmanServer` em execução e início automático. Nenhum serviço Docker/WSL/SQL Server/Oracle/Mongo/RabbitMQ/PostgreSQL encontrado.
- `winget show --source winget --disable-interactivity`: consultas dos sete IDs abaixo bem-sucedidas (exit 0). Nenhum `winget install`, aceite automático de termos ou login executado.

| Pacote consultado | Versão disponível | Seleção para instalação |
|---|---|---|
| `Git.Git` | 2.56.0.4 | Essa versão x64 |
| `EclipseAdoptium.Temurin.21.JDK` | 21.0.13.9 | JDK 21.0.13+9 x64, API Adoptium confirma |
| `Microsoft.DotNet.SDK.10` | 10.0.404 | SDK x64, metadados Microsoft confirmam |
| `OpenJS.NodeJS.LTS` | 26.13.1 | Manter 24.22.3 pelo MSI oficial; consulta dessa versão no pacote falhou |
| `Docker.DockerDesktop` | 4.99.0 | x64, Compose incluído, após WSL |
| `Microsoft.WSL` | 3.0.5 | Release estável, backend WSL 2 |
| `Microsoft.AzureCLI` | 2.93.0 | x64; documentação Microsoft confirma |

Fontes públicas e compatibilidade: [versões e fontes](versoes-e-fontes.md). Consultar catálogo não verifica instalação, assinatura do arquivo baixado ou execução.

### Lotes planejados — A/B/C posteriormente autorizados

1. **A — base recomendada:** Git, Temurin JDK 21, .NET SDK 10 e Node 24/npm nas versões acima. Inclui integração PATH pelos instaladores e configuração de `JAVA_HOME` para o JDK efetivamente instalado, se necessária. Pode haver prompts UAC; sem alteração de política de execução.
2. **B — infraestrutura:** habilitar WSL/Virtual Machine Platform, possível reinicialização assistida pelo usuário e Docker Desktop com Compose. Validar Linux engine antes dos bancos.
3. **C — DevOps:** Azure CLI 2.93.0; instalação e consulta de versão, com acesso a contas autorizado separadamente.
4. **Serviços locais:** após B, confirmar aceite SQL Server Developer e autorização para criar credenciais locais; preparar `.env` ignorado, validar `docker compose --env-file .env config --quiet`, baixar imagens, iniciar por profile e conferir saúde. Usar SQL Server 2022 Developer, RabbitMQ 4.x e MongoDB 8.0; fixar patches/digests somente após resolução e teste reais. `mongosh` e `sqlcmd` podem ser usados nos próprios containers; Erlang acompanha a imagem RabbitMQ.
5. **Oracle:** perguntar se existe acesso institucional e versão. Escolher cliente SQLcl/SQL*Plus compatível e testar sessão SQL com `SELECT 1 FROM DUAL`; se não houver servidor, propor Oracle Free local com imagem, termos e recursos verificados antes de instalar. Não solicitar senha no chat.
6. **Android:** decidir build APK local ou EAS autorizado antes de fechar o ambiente Mobile. Local exige Android SDK/Platform Tools/Build Tools e JDK compatível com o Gradle/Expo selecionado; fixar a matriz nesse momento. Dispositivo físico recomendado com 16 GB. Firebase pelo console dispensa CLI global.

Maven Wrapper será criado com o projeto Java na etapa autorizada; bibliotecas Spring/EF/xUnit/Expo pertencem aos manifests futuros. IDEs, Python, Maven/Gradle globais, PostgreSQL, emulador e Firebase CLI não integram o lote mínimo.

### Critérios para concluir o preparo

- Registrar versões e caminhos reais em sessão nova; conferir `JAVA_HOME`, Java/javac 21, SDK .NET 10, Node 24 e npm/npx.
- Executar pequenos testes de compilação Java/.NET e execução Node em diretório temporário exclusivo, sem criar funcionalidades ou projetos da aplicação.
- Inicializar Git na raiz após instalação; obter nome/e-mail do usuário para configuração local e revisar ignorados antes do primeiro commit.
- Validar WSL, `docker info` com engine Linux, Compose, saúde dos serviços, consultas SQL/Mongo e versão/acesso Oracle; registrar tudo que permanecer bloqueado.
- Registrar rota de build Android e pendências de contas/acessos. Só declarar Etapa 2 concluída com critérios verificados ou escopo explicitamente revisto pelo usuário.

**Estado ao encerrar o diagnóstico inicial:** nenhuma instalação havia sido executada. A autorização posterior e os resultados estão abaixo.

## 7. Execução autorizada — pausa para reinicialização, 17/11/2026

Usuário autorizou A → B → C, PATH/JAVA_HOME e recursos Windows necessários ao WSL 2, sem remoções, software adicional, operações destrutivas ou implementação. Oracle deve permanecer pendente.

| Ferramenta | Resultado real | Verificação |
|---|---|---|
| Git | Instalado; WinGet 2.56.0.4, exit 0 | `git --version`: **2.56.0.windows.4**; init/status em repositório temporário passaram |
| Temurin JDK | Instalado; WinGet 21.0.13.9, exit 0 | `java -version`: **21.0.13+9 LTS**; `javac -version`: **21.0.13**; JShell executou asserção e imprimiu `JAVA_SMOKE_OK` |
| .NET SDK | Instalado; WinGet 10.0.404, exit 0 | `dotnet --list-sdks`: **10.0.404**; console temporário net10.0 restaurado, compilado e executado com `Hello, World!` |
| Node.js | MSI oficial instalado, exit 0 | **v24.22.3**; teste com `node:assert/strict` imprimiu `NODE_SMOKE_OK` |
| npm / npx | Incluídos no Node | Ambos **11.19.1**, via wrappers `.cmd` |
| WSL | Instalado após elevação, exit 0 | **3.0.5.0**, kernel **6.18.58.1-1**, versão padrão **2**; execução WSL 2 bloqueada antes do reboot |
| Docker Desktop / Compose | Não instalados ainda | Retomar após WSL 2 operacional |
| Azure CLI | Não instalado ainda | Lote C após B |

### Comandos, segurança e configuração efetiva

- Git/JDK/.NET: comandos WinGet da seção 3 com `--silent --disable-interactivity`; hashes dos três instaladores verificados pelo WinGet. Nenhuma opção de reinicialização automática utilizada.
- Node: download do MSI oficial da seção 3, SHA-256 conferido; `Get-AuthenticodeSignature` retornou **Valid**, signatário **OpenJS Foundation**. Instalação `msiexec /i ... /passive /norestart /L*v ...`, exit 0; sem ferramentas adicionais.
- Instaladores integraram os diretórios ao PATH. `JAVA_HOME` de máquina: `C:\Program Files\Eclipse Adoptium\jdk-21.0.13.9-hotspot\`; variável de usuário ausente, sem conflito observado.
- PATH de máquina/usuário e JAVA_HOME foram recarregados **somente no processo de diagnóstico** para testar as ferramentas, pois o OpenCode pode manter ambiente antigo. Reabrir o aplicativo/terminal após reiniciar.
- Caminhos resolvidos: Git em `C:\Program Files\Git\cmd`, JDK em `%JAVA_HOME%\bin`, .NET em `C:\Program Files\dotnet`, Node/npm/npx em `C:\Program Files\nodejs`.
- Primeira execução .NET informou criação automática de certificado de desenvolvimento ASP.NET Core HTTPS; não foi executado `dotnet dev-certs https --trust`. Nenhuma chave JWT, senha de aplicação ou credencial de conta externa criada.
- Testes isolados em `C:\Users\sposi\AppData\Local\Temp\opencode\citytech-smoke-ea0a6f8003c64b09a42ce9336db674f3`. Nenhum projeto de aplicação criado no monorepositório.
- MSI/log Node preservados em `C:\Users\sposi\AppData\Local\Temp\opencode\citytech-install-e906406807c44c76a20a614cf998a006` (`node-install.log`). Nenhum arquivo removido.

### Erro WSL e correção aplicada

1. `wsl --install --no-distribution` sem elevação retornou **1**, informando WSL não instalado.
2. Reexecutado com `Start-Process ... -Verb RunAs -Wait -PassThru`, mesmos argumentos; retornou **0**.
3. `wsl --version` confirmou aplicativo/kernel. `wsl --status` retornou 0, mas informou que **WSL 2 não pode iniciar**: código 0 não foi tratado como comprovação de saúde.
4. CIM: `VirtualMachinePlatform` agora `InstallState=1` (habilitado); componente legado `Microsoft-Windows-Subsystem-Linux` permanece 2 (WSL 1 não solicitado).
5. Registro `Component Based Servicing\RebootPending` presente; `WindowsUpdate\...\RebootRequired` ausente. A virtualização no firmware já havia sido confirmada. **Reinicializar antes de investigar mudanças adicionais.**

### Próxima ação exata

1. Usuário salva seus trabalhos e reinicia o Windows manualmente. Nenhum reboot foi executado pelo agente.
2. Reabrir OpenCode/terminal; verificar `wsl --version`, `wsl --status` e estado dos recursos. Não reinstalar lote A.
3. Instalar Docker Desktop 4.99.0/Compose conforme autorização e validar engine Linux, versões e container básico. Se WSL continuar falhando após reboot, investigar antes de instalar dependências adicionais.
4. Instalar Azure CLI 2.93.0 e executar `az version`/ajuda, sem login.
5. Git da raiz/identidade e serviços Compose continuam pendentes; testes Git anteriores foram apenas temporários. Credenciais locais e aceite SQL Server devem ser tratados antes de subir bancos.
6. Oracle: obter confirmação institucional, versão, host/porta/service name, requisitos de VPN/rede e forma segura de fornecer credenciais; escolher cliente compatível e testar `SELECT 1 FROM DUAL`. Não instalar Oracle local sem decisão posterior.
7. Decidir toolchain Android/build APK e registrar pendências de acesso. Não avançar à Etapa 3 sem autorização.

## 8. Pós-reinicialização — lotes B/C verificados, 17/11/2026

Usuário confirmou reboot e autorizou continuidade. Lote A não reinstalado nem seus testes repetidos.

| Verificação | Resultado real |
|---|---|
| WSL | 3.0.5.0, padrão 2; VirtualMachinePlatform=1, CBS RebootPending=False; erro anterior de virtualização desapareceu |
| Distribuição Docker | `wsl --list --verbose`: **docker-desktop Running, versão 2** |
| Docker Desktop | **4.99.0.245822**, instalado por usuário em `%LOCALAPPDATA%\Programs\DockerDesktop` |
| Docker CLI/engine | **29.9.3**, `docker info` exit 0; OS linux, kernel **6.18.58.1-microsoft-standard-WSL2** |
| Compose | **v5.7.0**, incluído no Desktop |
| Docker básico | Pull e execução hello-world: **Hello from Docker!**, exit 0; inspeção `exited`, ExitCode=0 |
| Compose básico | Arquivo temporário: `config --quiet` e `run` exit 0; container terminou com ExitCode=0 |
| Azure CLI | **2.93.0**, core 2.93.0, telemetry 1.1.0, extensões vazias; `az version` e ajuda completa exit 0 |

### Instalações e correções

- Docker: instalador oficial `https://desktop.docker.com/win/main/amd64/245822/Docker%20Desktop%20Installer.exe`; SHA-256 `a5e299131c9c53d60f3f752b162078945eb5faf6eedcf0be20a214c6e6cea444`, assinatura **Valid/Docker Inc**. Argumentos `install --user --backend=wsl-2 --quiet --accept-license`, exit 0. Sem login Docker Hub.
- Download inicial via Invoke-WebRequest excedeu timeout de 120s antes de instalar. Confirmada ausência de processo/instalação; repetido com curl nativo do Windows e prazo maior, conferindo hash/assinatura antes de executar.
- Inicialização por `Docker Desktop.exe` e `docker desktop start --timeout 120`. VM reportou 12 CPUs lógicas e 8.288.735.232 bytes de RAM disponíveis.
- Primeiro `docker run` falhou (127): helper `docker-credential-desktop` ausente no PATH antigo do processo. Recarregado PATH de máquina + usuário; helper localizado em `%LOCALAPPDATA%\Programs\DockerDesktop\resources\bin`; repetição passou. Nenhuma credencial alterada ou helper desabilitado.
- Azure: `winget install --id Microsoft.AzureCLI --exact --version 2.93.0 --source winget --silent --disable-interactivity`; hash verificado, exit 0. Caminho `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd`.
- Primeira ajuda Azure filtrada com `Select-Object -First` retornou -1 por interrupção do pipeline; ajuda completa redirecionada para arquivo temporário retornou 0. Nenhum `az login`, deploy ou recurso cloud executado.
- Nenhuma nova reinicialização necessária: CBS RebootPending=False ao final. Aviso WSL 1 é esperado, pois a estratégia utiliza WSL 2.

### Testes e artefatos preservados

- `docker run --name citytech-env-hello-20261117 hello-world`, exit 0.
- Imagem usada no Compose temporário fixada no digest real `sha256:1e4c05b897a751332ce85c7e9449da2d93514ea2dea6dbb0e2753c9e949b2bfa`.
- `docker compose -f <arquivo-temporário> config --quiet` e `run --name citytech-env-compose-hello-20261117 hello`, exit 0.
- Diretório base: `C:\Users\sposi\AppData\Local\Temp\opencode`. Arquivos: `citytech-compose-smoke-20261117.yml`, `citytech-az-help-20261117.txt` e `citytech-docker-97263856a7ca4acf90937c1365acfdb0\Docker Desktop Installer.exe`.
- Imagem, dois containers encerrados e rede `citytech-environment-smoke_default` preservados; sem remoções/prune/alterações destrutivas.
- Testes comprovam cliente/engine, pull público, Linux e Compose básico; **não comprovam o Compose de bancos do CityTech**.

### Próxima ação atual

Obter identidade Git; confirmar autorização de credenciais locais e aceite SQL Server antes de preparar `.env`/serviços Compose; resolver patches/digests dos bancos/broker; confirmar Oracle institucional e conexão conforme seção 7; decidir build Android/acessos. Nenhuma funcionalidade criada nem avanço à Etapa 3. Novos terminais herdam PATH atualizado; OpenCode já aberto pode precisar de reabertura.

## 9. Etapa 4A — execução do backend .NET, 17/11/2026

Verificado nesta sessão: SDK **10.0.404**, runtime **10.0.15**, Docker Engine **29.9.3** e SQL Server 2022 Developer **16.0.4325.4**. Os containers `citytech-sqlserver-1`, `citytech-mongodb-1` e `citytech-rabbitmq-1` estavam **running/healthy**. Nenhum container, volume ou banco foi removido.

### 9.1 Conexão e variáveis

O backend lê a conexão **somente** de `DOTNET_DB_CONNECTION`. O `.env` da raiz é ignorado pelo Git, mas **não é carregado automaticamente** pelo .NET; o valor precisa ser exportado no processo. Na sessão da 4A, `DOTNET_DB_CONNECTION` estava vazio no `.env`; a conexão foi montada apenas no processo a partir de `MSSQL_SA_PASSWORD` e `SQLSERVER_PORT`, sem alterar o arquivo e sem imprimir a senha.

Exemplo com placeholders (não versionar valores reais):

```powershell
$env:DOTNET_DB_CONNECTION = "Server=127.0.0.1,1433;Database=CityTech;User Id=<usuario-local>;Password=<senha-local>;TrustServerCertificate=True;Encrypt=True"
```

`TrustServerCertificate=True` vale apenas para o SQL Server local com certificado autoassinado; revisar antes de Azure SQL/produção.

### 9.2 Comandos e resultados

Executados em `backend-dotnet`:

```powershell
dotnet tool restore
dotnet restore CityTech.slnx
dotnet build CityTech.slnx
dotnet test CityTech.slnx

dotnet ef migrations add InitialCreate `
  --project src/CityTech.Infrastructure `
  --startup-project src/CityTech.Api `
  --output-dir Persistence/Migrations

dotnet ef database update `
  --project src/CityTech.Infrastructure `
  --startup-project src/CityTech.Api
```

| Verificação | Resultado real |
|---|---|
| Build | **0 avisos, 0 erros** |
| Testes | **61/61 aprovados** (40 domínio + 21 integração SQL Server) |
| Migration | `20261117072823_InitialCreate` aplicada ao banco `CityTech` |
| Schema | `accounts`, `follow_ups`, `idempotency_records`, `__EFMigrationsHistory`; índices únicos, checks e uma FK local |
| Banco de teste | `CityTech_Test` criado pela fixture e migrado; limpeza apenas de linhas |
| API | `GET /` → `CityTech.Api / ok`; `GET /health` → `Healthy` |

O `dotnet-ef` é ferramenta **local** (`backend-dotnet/dotnet-tools.json`, 10.0.15); não há instalação global. Para subir a API:

```powershell
dotnet run --project src/CityTech.Api
# por padrão, perfil http em http://localhost:5285/health
```

A API falha na inicialização com mensagem explícita se `DOTNET_DB_CONNECTION` estiver ausente. A migration só criou estruturas novas; não houve `EnsureCreated`, drop, deploy ou push. Detalhes de schema e testes: [backend-dotnet/README.md](../backend-dotnet/README.md).
