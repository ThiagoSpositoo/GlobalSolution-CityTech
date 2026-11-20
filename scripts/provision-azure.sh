#!/usr/bin/env bash
# Provisiona a infraestrutura Azure da API .NET do CityTech.
#
# Alternativa ao provision-azure.ps1 (Windows/PowerShell). No Git Bash/WSL/Linux:
#   bash scripts/provision-azure.sh scripts/azure-config.local.json --approved
#
# Sem --approved o script apenas valida a configuração e mostra o plano (dry-run).
# É reexecutável: recursos existentes são preservados e a senha do SQL existente não é alterada.
set -euo pipefail

config_path="${1:-scripts/azure-config.local.json}"
approved="${2:-}"

if [[ ! -f "$config_path" ]]; then
  printf 'Configuração não encontrada: %s\nCopie scripts/azure-config.example.json e preencha.\n' "$config_path" >&2
  exit 1
fi

command -v az >/dev/null || { printf 'Azure CLI (az) não encontrado.\n' >&2; exit 1; }
command -v jq >/dev/null || { printf 'jq é necessário para ler o JSON de configuração.\n' >&2; exit 1; }

get() { jq -r --arg key "$1" '.[$key] // ""' "$config_path"; }

subscription_id="$(get subscriptionId)"
resource_group="$(get resourceGroup)"
location="$(get location)"
webapp_name="$(get webAppName)"
sql_server="$(get sqlServerName)"
sql_database="$(get sqlDatabaseName)"
sql_admin="$(get sqlAdminUser)"
sql_password="$(get sqlAdminPassword)"
private_key_path="$(get jwtPrivateKeyPath)"
public_key_path="$(get jwtPublicKeyPath)"
jwt_issuer="$(get jwtIssuer)"
jwt_audience="$(get jwtAudience)"
jwt_key_id="$(get jwtKeyId)"
java_base_url="$(get javaApiBaseUrl)"

for name in subscriptionId resourceGroup location webAppName sqlServerName sqlDatabaseName sqlAdminUser sqlAdminPassword jwtPrivateKeyPath jwtPublicKeyPath; do
  if [[ -z "$(get "$name")" ]]; then
    printf 'Campo obrigatório ausente no JSON: %s\n' "$name" >&2
    exit 1
  fi
done

[[ -f "$private_key_path" && -f "$public_key_path" ]] || {
  printf 'Chaves JWT não encontradas: %s / %s\n' "$private_key_path" "$public_key_path" >&2
  exit 1
}

plan_name="${webapp_name}-plan"
connection="Server=tcp:${sql_server}.database.windows.net,1433;Database=${sql_database};User ID=${sql_admin};Password=${sql_password};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"

printf '\n== Plano de provisionamento ==\n'
printf 'Assinatura ......: %s\n' "$subscription_id"
printf 'Resource Group ..: %s (%s)\n' "$resource_group" "$location"
printf 'App Service .....: %s (plano %s, Linux B1)\n' "$webapp_name" "$plan_name"
printf 'Azure SQL .......: %s / banco %s (Basic)\n' "$sql_server" "$sql_database"
printf 'Java API ........: %s\n' "${java_base_url:-não informado (readiness e criação de acompanhamentos indisponíveis)}"
printf 'Custo estimado ..: ~US$ 18/mês (App Service B1 ~13 + Azure SQL Basic ~5)\n'

if [[ "$approved" != "--approved" ]]; then
  printf '\nDRY-RUN: nada foi criado. Repita com --approved para provisionar.\n'
  exit 0
fi

printf '\n== Conferindo autenticação ==\n'
if ! az account show --output none >/dev/null 2>&1; then
  printf 'Azure CLI sem sessão. Execute: az login\n' >&2
  exit 1
fi
az account show --query '{conta:user.name, assinatura:name, estado:state}' --output table
if ! az account set --subscription "$subscription_id" >/dev/null 2>&1; then
  printf 'Falha ao selecionar a assinatura %s (inexistente ou sem acesso).\n' "$subscription_id" >&2
  exit 1
fi

# Classifica a resposta do Azure CLI:
#   return 0 -> recurso existe
#   return 1 -> recurso ainda não existe (deve ser criado)
#   exit 1   -> falha real (login, permissão, assinatura, quota, SKU, política)
resource_exists() {
  local description="$1"
  shift
  local output status
  output="$(az "$@" --output none 2>&1)" && return 0
  status=$?

  case "$output" in
    *AuthorizationFailed*|*InsufficientPermissions*|*"az login"*|*SubscriptionNotFound*|\
    *InvalidSubscriptionId*|*SkuNotAvailable*|*QuotaExceeded*|*RequestDisallowedByPolicy*|\
    *LocationNotAvailableForResourceType*)
      printf 'FALHA REAL ao consultar %s (exit %s):\n%s\n' "$description" "$status" "$output" >&2
      exit 1
      ;;
  esac

  case "$output" in
    *ResourceGroupNotFound*|*ResourceNotFound*|*ParentResourceNotFound*|\
    *"was not found"*|*"could not be found"*|*"does not exist"*|*"doesn't exist"*)
      return 1
      ;;
  esac

  if [[ "$status" -eq 3 ]]; then
    return 1
  fi

  printf 'FALHA REAL ao consultar %s (exit %s):\n%s\n' "$description" "$status" "$output" >&2
  exit 1
}

printf '\n== Resource Group ==\n'
if resource_exists "Resource Group $resource_group" group show --name "$resource_group"; then
  printf 'Resource Group já existe; preservado.\n'
else
  az group create --name "$resource_group" --location "$location" --output none
  printf 'Resource Group criado.\n'
fi

printf '\n== App Service Plan ==\n'
if resource_exists "App Service Plan $plan_name" appservice plan show --resource-group "$resource_group" --name "$plan_name"; then
  printf 'Plano já existe; preservado.\n'
else
  az appservice plan create --resource-group "$resource_group" --name "$plan_name" \
    --location "$location" --is-linux --sku B1 --output none
  printf 'Plano criado (Linux B1).\n'
fi

printf '\n== Azure SQL Server ==\n'
if resource_exists "Azure SQL Server $sql_server" sql server show --resource-group "$resource_group" --name "$sql_server"; then
  printf 'Servidor SQL já existe; senha preservada (não é alterada).\n'
else
  az sql server create --resource-group "$resource_group" --name "$sql_server" \
    --location "$location" --admin-user "$sql_admin" --admin-password "$sql_password" --output none
  printf 'Servidor SQL criado.\n'
fi

printf '\n== Firewall do SQL ==\n'
if resource_exists "Regra AllowAzureServices" sql server firewall-rule show --resource-group "$resource_group" --server "$sql_server" --name AllowAzureServices; then
  printf 'Regra AllowAzureServices já existe; preservada.\n'
else
  az sql server firewall-rule create --resource-group "$resource_group" --server "$sql_server" \
    --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --output none
  printf 'Regra AllowAzureServices criada.\n'
fi

printf '\n== Banco de dados ==\n'
if resource_exists "Banco $sql_database" sql db show --resource-group "$resource_group" --server "$sql_server" --name "$sql_database"; then
  printf 'Banco já existe; preservado.\n'
else
  az sql db create --resource-group "$resource_group" --server "$sql_server" --name "$sql_database" \
    --edition Basic --service-objective Basic --output none
  printf 'Banco criado (Basic).\n'
fi

printf '\n== App Service ==\n'
if resource_exists "App Service $webapp_name" webapp show --resource-group "$resource_group" --name "$webapp_name"; then
  printf 'App Service já existe; preservado.\n'
else
  runtime="$(az webapp list-runtimes --os linux --output json | jq -r '[.[] | select(startswith("DOTNETCORE:10."))] | sort | last // "DOTNETCORE:10.0"')"
  printf 'Runtime selecionado: %s\n' "$runtime"
  az webapp create --resource-group "$resource_group" --plan "$plan_name" \
    --name "$webapp_name" --runtime "$runtime" --output none
  printf 'App Service criado.\n'
fi

printf '\n== Variáveis de ambiente ==\n'
settings_file="$(mktemp)"
chmod 600 "$settings_file"
trap 'rm -f "$settings_file"' EXIT

jq -n \
  --arg connection "$connection" \
  --arg private_pem "$(cat "$private_key_path")" \
  --arg public_pem "$(cat "$public_key_path")" \
  --arg issuer "$jwt_issuer" \
  --arg audience "$jwt_audience" \
  --arg key_id "$jwt_key_id" \
  --arg java_url "$java_base_url" \
  '[
     "DOTNET_DB_CONNECTION=\($connection)",
     "JWT_PRIVATE_KEY_PEM=\($private_pem)",
     "JWT_PUBLIC_KEY_PEM=\($public_pem)",
     "JWT_ISSUER=\($issuer)",
     "JWT_AUDIENCE=\($audience)",
     "JWT_KEY_ID=\($key_id)",
     "ASPNETCORE_ENVIRONMENT=Production",
     "ASPNETCORE_URLS=http://0.0.0.0:8080",
     "WEBSITES_PORT=8080"
   ] + (if $java_url == "" then [] else ["JAVA_API_BASE_URL=\($java_url)"] end)' > "$settings_file"

az webapp config appsettings set --resource-group "$resource_group" --name "$webapp_name" \
  --settings "@$settings_file" --output none
az webapp config set --resource-group "$resource_group" --name "$webapp_name" \
  --always-on true --min-tls-version 1.2 --output none
az webapp update --resource-group "$resource_group" --name "$webapp_name" --https-only true --output none
printf 'Configurações aplicadas sem imprimir segredos.\n'

printf '\n== Confirmação final (consulta real ao Azure) ==\n'
confirm_failed=0
confirm() {
  local description="$1"
  shift
  if az "$@" --output none >/dev/null 2>&1; then
    printf '  OK      %s\n' "$description"
  else
    printf '  FALHOU  %s\n' "$description" >&2
    confirm_failed=$((confirm_failed + 1))
  fi
}
confirm "Resource Group $resource_group" group show --name "$resource_group"
confirm "App Service Plan $plan_name" appservice plan show --resource-group "$resource_group" --name "$plan_name"
confirm "Azure SQL Server $sql_server" sql server show --resource-group "$resource_group" --name "$sql_server"
confirm "Regra AllowAzureServices" sql server firewall-rule show --resource-group "$resource_group" --server "$sql_server" --name AllowAzureServices
confirm "Banco $sql_database" sql db show --resource-group "$resource_group" --server "$sql_server" --name "$sql_database"
confirm "App Service $webapp_name" webapp show --resource-group "$resource_group" --name "$webapp_name"

if [[ "$confirm_failed" -ne 0 ]]; then
  printf '\nConfirmação falhou para %s recurso(s). Nada foi declarado concluído.\n' "$confirm_failed" >&2
  exit 1
fi
printf 'Infraestrutura confirmada no Azure.\n'

printf '\n== Recursos no Resource Group ==\n'
az resource list --resource-group "$resource_group" --query '[].{Nome:name,Tipo:type,Local:location}' --output table

printf '\nURL prevista: https://%s.azurewebsites.net\n' "$webapp_name"
printf 'O código é publicado pela pipeline azure-pipeline.yml, não por este script.\n'
