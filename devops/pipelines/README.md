# Pipelines — apoio

O arquivo exigido pelo enunciado é **`azure-pipeline.yml` na raiz** do repositório usado pelo Azure Repos.
Ele contém CI e CD completos (build, testes, artefatos, Azure SQL e App Service).

Esta pasta é reservada a templates reutilizáveis. Não há template aqui porque a pipeline é única e pequena;
duplicar o YAML criaria duas fontes de verdade.

Quando fizer sentido extrair etapas, os candidatos são:

- `templates/dotnet-build.yml` — restore, build e testes com TRX;
- `templates/sql-ephemeral.yml` — container SQL Server para testes de integração;
- `templates/deploy-appservice.yml` — deploy do artefato no App Service.

Qualquer extração deve manter `azure-pipeline.yml` na raiz como ponto de entrada e ser validada com uma
execução real antes de substituir o conteúdo atual.
