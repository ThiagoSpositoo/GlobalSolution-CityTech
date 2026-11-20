# Dockerfiles — por que esta entrega não usa container

O enunciado DevOps exige Dockerfiles nesta pasta **quando a solução avaliada for containerizada**
(ACI/ACR). A solução escolhida para esta entrega é a API .NET publicada por **zip deploy no App Service
Linux com runtime nativo**, portanto não há imagem de aplicação a construir.

| Situação | Exigência | Nesta entrega |
|---|---|---|
| App Service com runtime nativo | Dockerfile não é necessário | **É o caso**: `AzureWebApp@1` publica o ZIP gerado pela CI |
| ACI/ACR (container) | Dockerfile obrigatório em `/dockerfiles` | Não utilizado |

O Docker aparece apenas na **CI**, para subir um SQL Server efêmero que roda os testes de integração —
imagem oficial da Microsoft, sem build próprio.

Se o grupo optar por containerizar depois, o caminho é: `dockerfiles/dotnet-api.Dockerfile` multi-stage
(`mcr.microsoft.com/dotnet/sdk:10.0` → `mcr.microsoft.com/dotnet/aspnet:10.0`), push para ACR e troca do
`AzureWebApp@1` por `AzureContainerApps@1`/`AzureRmWebAppDeployment` com imagem. Isso não é necessário para
a rubrica atual e não foi implementado para não entregar arquivo não validado.
