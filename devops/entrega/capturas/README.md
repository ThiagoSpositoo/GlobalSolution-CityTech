# Capturas de evidência — DevOps

Salve aqui as capturas **reais** da execução na Azure, com nomes ordenáveis. O gerador
`devops/entrega/gerar-pdf-devops.ps1` incorpora automaticamente todas as imagens `.png`/`.jpg`
desta pasta no PDF de entrega.

Sugestão de ordem e conteúdo (nenhuma captura deve mostrar token, senha, connection string ou PEM):

| Nome sugerido | O que mostrar |
|---|---|
| `01_recursos_azure.png` | Resource Group com App Service, plano, SQL Server e banco |
| `02_appservice_config.png` | Application Settings (sem revelar valores) |
| `03_boards_task.png` | Task criada no Boards |
| `04_branch_commit.png` | Branch e commit com `AB#id` |
| `05_pr_merge.png` | Pull Request concluído com revisor e Work Item |
| `06_ci_testes.png` | Stage CI com testes aprovados |
| `07_ci_artefatos.png` | Artefatos `app` e `database` |
| `08_cd_deploy.png` | Stage CD concluído e validação HTTPS |
| `09_swagger.png` | Swagger da aplicação publicada |
| `10_sql_select_accounts.png` | `SELECT` em `accounts` no Query Editor |
| `11_sql_crud_followups.png` | `INSERT/UPDATE/DELETE` + `SELECT` em `follow_ups` |
| `12_task_done.png` | Task concluída com links de commit e PR |

Depois de salvar, regenere o PDF:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\devops\entrega\gerar-pdf-devops.ps1 -VideoUrl "https://youtu.be/SEU_VIDEO"
```
