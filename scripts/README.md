# Scripts — infraestrutura Azure e banco da entrega DevOps

Pasta exigida pelo enunciado (`/scripts`) para scripts de infraestrutura e o DDL do banco.

| Arquivo | Papel | Estado |
|---|---|---|
| `provision-azure.ps1` | Provisiona Resource Group, App Service Linux B1, Azure SQL (servidor + banco Basic), firewall e variáveis de ambiente. Dry-run por padrão; cria somente com `-Approved`. Reexecutável após falha parcial. | Validado: 42 verificações com Azure CLI simulado + consultas reais de existência; criação real pendente de autorização de custo |
| `tests/Invoke-ProvisionAzureMockTests.ps1` | Testes do provisionamento contra um `az` falso (recursos existentes, inexistentes, política regional e erros reais). Não toca no Azure | 48/48 aprovadas |
| `tests/az-mock.ps1` | Azure CLI simulado usado apenas pelos testes | — |
| `provision-azure.sh` | Equivalente para Bash/WSL/Linux (mesma configuração JSON): mesma classificação de "não existe" x falha real e confirmação final | Sintaxe validada (`bash -n`); não executado ponta a ponta aqui porque exige `jq` |
| `azure-config.example.json` | Modelo da configuração (sem segredos). Copie para `azure-config.local.json`, que é ignorado pelo Git | — |
| `script-bd.sql` | DDL **real** e idempotente: corpo gerado pelas migrations EF Core (`accounts`, `follow_ups`, `idempotency_records`, índices, FK e `__EFMigrationsHistory`) + cabeçalho explicativo de 16 linhas | Gerado e versionado; corpo idêntico ao artefato da CI (SHA-256 `AFF7B9B9…328532E9`) |
| `demo-crud-cloud.ps1` | Executa o CRUD HTTP da aplicação publicada e imprime status de cada chamada | Validado (parser); execução depende do deploy |
| `crud/accounts.json`, `crud/followups.json` | Exemplos JSON de requisição/resposta e SQL de CRUD por tabela | JSON validado |

## 1. Provisionar a infraestrutura (Windows 11 / PowerShell 5.1)

```powershell
az login
az account show --query "{conta:user.name, assinatura:name}" --output table

Copy-Item .\scripts\azure-config.example.json .\scripts\azure-config.local.json
notepad .\scripts\azure-config.local.json   # preencha IDs, nomes únicos e a senha do SQL

# 1) Dry-run: mostra o plano e o custo sem criar nada
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\provision-azure.ps1 -ConfigPath .\scripts\azure-config.local.json

# 2) Criação real (somente após autorização do grupo)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\provision-azure.ps1 -ConfigPath .\scripts\azure-config.local.json -Approved
```

O script é **reexecutável**: recursos existentes são preservados, a senha do servidor SQL existente não é
alterada e nenhuma exclusão é executada. A senha e as chaves PEM são enviadas por arquivo temporário, nunca
como argumento visível na linha de comando.

### Como o script trata recursos inexistentes

Cada recurso é **consultado antes** de ser criado (Resource Group, plano, servidor SQL, regra de firewall,
banco e App Service). A classificação da resposta é explícita:

| Resposta do Azure CLI | Tratamento |
|---|---|
| `exit 0` | Recurso existe: preservado |
| `ResourceGroupNotFound` (só na checagem do próprio grupo) | Ainda não existe: o grupo é criado |
| `ResourceNotFound` / `ParentResourceNotFound` / `exit 3` | Recurso ainda não existe: é criado |
| `Please run 'az login'`, `AuthorizationFailed`, `SubscriptionNotFound`, `SkuNotAvailable`, `QuotaExceeded`, `RequestDisallowedByPolicy` e afins | **Falha real**: o script para com mensagem específica |
| Qualquer outra resposta inesperada | **Falha real**: nada é criado e a saída do `az` é exibida |

Por que isso importa: no PowerShell 5.1, o stderr de um comando nativo vira `ErrorRecord` e, com
`$ErrorActionPreference = 'Stop'`, **qualquer** mensagem de erro do `az` — inclusive "recurso não
encontrado" e avisos em execuções bem-sucedidas — interromperia o script. Por isso o script isola a
preferência de erro durante a chamada e separa stdout de stderr pelo tipo do objeto.

No fim, o script **confirma cada recurso com uma nova consulta ao Azure** e falha se algo não existir.
Ele nunca declara sucesso com base apenas no que pediu, e nunca afirma que o código foi publicado — o
deploy é responsabilidade da pipeline.

### Testes locais do provisionamento (sem Azure)

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\tests\Invoke-ProvisionAzureMockTests.ps1
```

Executa 13 cenários contra um `az` simulado: nenhum recurso, todos existentes, retomada após falha
parcial, aviso em stderr com sucesso, `AuthorizationFailed`, sem login, grupo ausente em recurso filho,
dry-run, assinatura inexistente, firewall divergente e login admin divergente. Nenhum comando real do
Azure é executado.

### Variáveis de configuração

| Campo | Exemplo | Observação |
|---|---|---|
| `subscriptionId` | GUID da assinatura | `az account show --query id -o tsv` |
| `resourceGroup` | `rg-citytech-devops` | criado se não existir |
| `location` | `brazilsouth` | `eastus2` costuma ser mais barato |
| `webAppName` | `citytech-api-rm561694` | precisa ser globalmente único |
| `appServicePlanName` | vazio (opcional) | vazio = usa `<webAppName>-plan`; preencha só para reaproveitar um plano com outro nome |
| `sqlServerName` | `citytech-sql-rm561694` | globalmente único, apenas letras minúsculas/números/hífen |
| `sqlDatabaseName` | `citytechdb` | nome do banco |
| `sqlAdminUser` | `citytechadmin` | não pode ser `admin`, `sa`, `root` etc. |
| `sqlAdminPassword` | senha forte | 12+ caracteres, maiúscula, minúscula, número e símbolo |
| `jwtPrivateKeyPath` / `jwtPublicKeyPath` | `C:\Users\sposi\.citytech\keys\jwt-private.pem` | par RSA local, fora do repositório e ignorado pelo Git |
| `jwtIssuer` / `jwtAudience` / `jwtKeyId` | `citytech-identity` / `citytech-api` / `citytech-cloud-v1` | devem ser iguais aos usados pelo Java quando ele for publicado |
| `javaApiBaseUrl` | `https://...` ou vazio | vazio = Java não publicado (readiness e criação de acompanhamento retornam 503) |

## 2. Banco de dados

`script-bd.sql` não deve ser editado à mão. O arquivo versionado contém o corpo exato gerado pelas migrations
mais um cabeçalho de 16 linhas apenas explicativo; o corpo foi conferido por SHA-256 contra a saída da CI
(`AFF7B9B9…328532E9`). Para regenerar após uma nova migration:

```powershell
cd backend-dotnet
dotnet tool restore   # usa backend-dotnet/.config/dotnet-tools.json (dotnet-ef 10.0.15)
dotnet ef migrations script --idempotent --project src/CityTech.Infrastructure `
  --startup-project src/CityTech.Api --configuration Release --output ../scripts/script-bd.sql
```

A pipeline gera o mesmo script no stage CI (artefato `database`) e o aplica no Azure SQL no stage CD.
Aplicar o arquivo manualmente em um banco que já tem as migrations é seguro (é idempotente), mas não
substitui o controle de migrations do EF Core.

## 3. CRUD na aplicação publicada

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\demo-crud-cloud.ps1 `
  -BaseUrl https://SEU-APP.azurewebsites.net
```

O script cobre cadastro (CREATE em `accounts`), login, `/auth/me` (READ), listagem de acompanhamentos e,
quando houver acompanhamento, PATCH e DELETE. A criação de acompanhamento exige o Java publicado; sem ele a
API responde 503 e o CRUD de `follow_ups` é demonstrado por SQL no Azure SQL (consultas em
`crud/followups.json` e no `devops/README.md`).

## 4. Segurança

- Nunca versione `azure-config.local.json`, `.env`, PEM, PAT ou connection string.
- O PAT do Azure DevOps é usado só no processo (`az devops login`) e nunca em arquivo do repositório.
- Não imprima `az webapp config appsettings list` em gravações: ele expõe valores sensíveis.
- Use dados fictícios na demonstração.
