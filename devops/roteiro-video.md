# Roteiro do vídeo — DevOps Tools & Cloud Computing (CityTech)

**Formato exigido:** YouTube, resolução mínima **720p**, **narração em voz** (legenda não substitui voz),
preferencialmente **contínuo, sem cortes**. Duração alvo: **9 a 12 minutos**.

## Preparação (antes de gravar — não aparece no vídeo)

1. `az login` e `az account show` funcionando.
2. Recursos provisionados (seção 5 do [README](README.md)) e pipeline já executada ao menos uma vez.
3. Tarefa criada no Boards (seção 6.5) com ID anotado — ex.: `82`.
4. Duas janelas abertas: **Portal do Azure** e **Azure DevOps**; terminal PowerShell na raiz do repositório.
5. Bloco de notas com: URL do App Service, ID da task, ID da pipeline, e-mail/senha fictícios da demonstração.
6. Feche abas com tokens, senhas, connection strings ou o arquivo `azure-config.local.json`.
7. Gravador em **1080p** (ou 720p), microfone testado, notificações do Windows desativadas.

---

## Bloco 1 — Apresentação e repositório (0:00 – 1:00)

**Tela:** README do repositório aberto (`README.md`).

**Narração sugerida:**
> "Este é o CityTech, plataforma CitizenTech de zeladoria urbana da Global Solution FIAP 2026/2.
> O grupo é formado por Thiago Sposito, RM 561694; Vitor Madrigrano, RM 564191; e Lucas Lopes, RM 563544.
> Nesta disciplina a solução avaliada é a API .NET, publicada em Azure App Service com banco Azure SQL,
> provisionada por scripts Azure CLI e entregue por uma pipeline CI/CD no Azure DevOps."

**Mostre:** estrutura de pastas — `backend-dotnet/`, `scripts/`, `azure-pipeline.yml`, `devops/`.

---

## Bloco 2 — Arquitetura macro (1:00 – 2:00)

**Tela:** `devops/README.md`, seção 3 (diagrama Mermaid renderizado) ou `docs/diagramas/devops-cloud.mmd`.

**Narração:**
> "O fluxo começa no commit. O Azure Repos privado guarda o código; a main é protegida por pull request,
> revisor obrigatório e vínculo de Work Item. O merge dispara a pipeline: o stage de CI restaura, compila,
> roda 79 testes xUnit contra um SQL Server efêmero e publica os artefatos — o ZIP da aplicação e o DDL
> idempotente. O stage de CD baixa exatamente esses artefatos, aplica o DDL no Azure SQL e publica o mesmo
> ZIP no App Service Linux. Em verde, os recursos criados por script na Azure; em laranja, a API Java com
> Oracle e RabbitMQ, que pertence ao projeto mas não foi publicada nesta entrega."

---

## Bloco 3 — Recursos reais no Portal Azure (2:00 – 3:00)

**Tela:** Portal do Azure → Resource Group `rg-citytech-devops` → *Overview*.

**Mostre, apontando com o mouse:**
1. App Service (`citytech-api-...`) e o plano Linux B1.
2. Azure SQL Server e o banco `citytechdb` (SKU **Basic**).
3. Abra o App Service → *Configuration*: `DOTNET_DB_CONNECTION`, `JWT_*`, `ASPNETCORE_ENVIRONMENT=Production`
   (não clique em "Show values").

**Narração:**
> "Todos esses recursos foram criados pelo script `scripts/provision-azure.ps1`, versionado no repositório,
> com Azure CLI. Nenhum recurso foi criado manualmente no Portal. As configurações sensíveis ficam nas
> Application Settings do App Service, não no código."

---

## Bloco 4 — Tarefa no Boards (3:00 – 3:45)

**Tela:** Azure DevOps → Boards → Work Items → a task criada.

**Narração:**
> "Esta é a tarefa 'Expor versão publicada da API .NET'. Ela está no estado Doing e vai receber o vínculo
> do commit, da branch e do pull request."

---

## Bloco 5 — Branch e alteração real no código (3:45 – 5:30)

**Tela:** terminal na raiz do repositório.

```powershell
git checkout main
git pull azure main
git checkout -b feature/version-endpoint
```

**Narração:**
> "Criei a branch `feature/version-endpoint` a partir da main atualizada. Agora vou alterar o código-fonte,
> não o README."

**Tela:** abra `backend-dotnet/src/CityTech.Api/Program.cs` e adicione **antes** de `app.Run();`:

```csharp
app.MapGet("/api/v1/version", (IWebHostEnvironment environment) => Results.Ok(new
{
    service = "CityTech.Api",
    version = "1.1.0",
    environment = environment.EnvironmentName
})).AllowAnonymous();
```

**Narração:**
> "Adicionei um endpoint que devolve a versão publicada. Ele permite comprovar, no fim do vídeo, que o
> código que está na nuvem é exatamente o que passou pelo pull request."

```powershell
git add backend-dotnet/src/CityTech.Api/Program.cs
git commit -m "feat(api): expoe versao publicada da API AB#<ID_DA_TASK>"
git push azure feature/version-endpoint
```

**Mostre:** a saída do push com o link para criar o pull request.

---

## Bloco 6 — Pull Request e merge (5:30 – 6:45)

**Tela:** Azure DevOps → Repos → Pull requests → *New pull request* (ou o link do push).

1. Origem `feature/version-endpoint` → destino `main`.
2. Título: `Expoe versao publicada da API`.
3. Descrição: `AB#<ID_DA_TASK> - endpoint /api/v1/version para comprovar o deploy.`
4. **Work items:** vincule a task.
5. **Reviewers:** adicione o revisor.
6. *Create* → **Approve** → **Complete** (squash) → *Complete merge*.

**Narração:**
> "A main está protegida: sem pull request, sem revisor e sem Work Item vinculado o merge não é permitido.
> Ao completar, o merge gera um commit na main — e é esse merge que dispara a pipeline automaticamente."

**Mostre:** a política bloqueando (se aparecer) e o PR como `Completed`.

---

## Bloco 7 — CI automática (6:45 – 8:15)

**Tela:** Azure DevOps → Pipelines → execução em andamento.

**Mostre, em sequência:**
1. *Trigger*: `Individual CI` na branch `main` (sem clique manual).
2. Stage **CI**: `Subir SQL Server efêmero`, `Restaurar dependências e compilar`,
   `Executar testes xUnit (TRX)`, `Publicar pacote`, `Gerar DDL idempotente`.
3. Aba **Tests**: resultado dos testes (aprovados).
4. Aba **Artifacts**: `app` (citytech-api.zip) e `database` (script-bd.sql).

**Narração:**
> "A CI rodou sozinha depois do merge. Ela restaurou dependências, compilou em Release, subiu um SQL Server
> temporário só para os testes de integração, executou a suíte xUnit e publicou os resultados no Azure
> Pipelines. Também gerou dois artefatos: o pacote da aplicação e o script de banco idempotente."

---

## Bloco 8 — CD e deploy (8:15 – 9:15)

**Tela:** mesma execução → stage **CD**.

**Mostre:**
1. `Aplicar migrations idempotentes no Azure SQL`.
2. `Publicar pacote no App Service Linux`.
3. `Validar versão publicada por HTTPS` com a saída `Aplicacao respondendo em https://...`.

**Narração:**
> "O CD só roda se a CI passar. Ele baixa os artefatos aprovados, aplica o script de banco no Azure SQL e
> publica o mesmo ZIP no App Service. No fim, valida a aplicação por HTTPS."

---

## Bloco 9 — Aplicação publicada e CRUD (9:15 – 10:45)

**Tela:** navegador em `https://<webAppName>.azurewebsites.net/swagger`.

**Mostre:**
1. `GET /api/v1/version` → `version: 1.1.0` (prova do deploy da alteração).
2. `POST /api/v1/auth/register` → 201.
3. `POST /api/v1/auth/login` → copie o `accessToken` e clique em **Authorize**.
4. `GET /api/v1/auth/me` → 200.
5. `GET /api/v1/followups` → 200 (lista vazia ou com itens).

**Narração:**
> "A aplicação está na nuvem, com Swagger, cadastro, login e JWT funcionando. A versão 1.1.0 é exatamente
> a alteração que entrou pelo pull request. A criação de acompanhamento exige a API Java, que não foi
> publicada nesta entrega; por isso o CRUD de acompanhamentos será demonstrado direto no banco."

---

## Bloco 10 — CRUD e SELECT no Azure SQL (10:45 – 12:00)

**Tela:** Portal → banco `citytechdb` → **Query editor**.

```sql
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
SELECT id, name, email, role, version FROM accounts ORDER BY created_at DESC;
```

**Narração:**
> "Aqui está a persistência real: as tabelas criadas pelo pipeline e a conta que acabei de cadastrar pela API.
> Não é um GET, é um SELECT no banco em nuvem."

```sql
UPDATE accounts SET name = N'Cidadão Demonstração Atualizado', updated_at = SYSUTCDATETIME(), version = version + 1
 WHERE email_normalized = N'cidadao.demo@citytech.local';

DECLARE @userId uniqueidentifier = (SELECT id FROM accounts WHERE email_normalized = N'cidadao.demo@citytech.local');
INSERT INTO follow_ups (id, user_id, occurrence_id, note, created_at, updated_at, version)
VALUES (NEWID(), @userId, NEWID(), N'Acompanhamento criado via SQL para evidência DevOps', SYSUTCDATETIME(), SYSUTCDATETIME(), 0);

SELECT f.id, a.email, f.occurrence_id, f.note, f.version
  FROM follow_ups f INNER JOIN accounts a ON a.id = f.user_id;
```

**Narração:**
> "Atualizei a conta, criei um acompanhamento relacionado a ela pela chave estrangeira e comprovei com SELECT.
> Agora atualizo e removo o acompanhamento, também direto no banco."

```sql
UPDATE follow_ups SET note = N'Observação atualizada via SQL', updated_at = SYSUTCDATETIME(), version = version + 1;
SELECT id, note, version FROM follow_ups;
DELETE FROM follow_ups WHERE id = (SELECT TOP 1 id FROM follow_ups ORDER BY created_at DESC);
SELECT COUNT(*) AS restantes FROM follow_ups;
```

**Narração:**
> "CRUD completo nas duas tabelas: contas e acompanhamentos, com persistência comprovada por SELECT no
> Azure SQL."

---

## Bloco 11 — Encerramento no Boards (12:00 – 12:30)

**Tela:** Azure DevOps → task → *Links* → *Development*.

**Mostre:** o commit da branch, o pull request e o merge vinculados; estado da task atualizado para **Done**.

**Narração:**
> "A tarefa está concluída e mostra os vínculos reais: branch, commit e pull request. Encerro assim a
> disciplina DevOps do CityTech: código no Azure Repos privado, main protegida, CI com testes e artefatos,
> CD automático, aplicação e banco na Azure, CRUD comprovado por SELECT."

---

## Checklist final (assistir antes de entregar)

- [ ] Resolução ≥ 720p e áudio audível em fones e caixas.
- [ ] Narração por voz em todo o vídeo.
- [ ] Tarefa criada, branch criada, alteração **no código-fonte** (não README).
- [ ] Commit com `AB#<id>`, PR vinculada, merge na main.
- [ ] Pipeline disparada automaticamente pelo merge.
- [ ] Testes e artefatos visíveis.
- [ ] CD concluído e aplicação aberta na URL da Azure.
- [ ] CRUD e SELECT nas **duas** tabelas (`accounts` e `follow_ups`).
- [ ] Task concluída com links de commit/PR.
- [ ] Nenhum token, senha, connection string ou PEM aparece na tela.
- [x] Vídeo publicado no YouTube e link inserido no PDF: <https://youtu.be/ZeVsvk4luIM>.
