# Testes xUnit do backend .NET

**Estado: 77 testes implementados e aprovados** — 61 casos da fundação/domínio/persistência e 16 casos adicionais de seed e endpoints HTTP. A fixture deriva o banco de teste com sufixo `_Test`, aplica as migrations e limpa somente linhas das tabelas; não remove bancos nem volumes.

Cobertura adicional: cadastro válido/inválido/duplicado; login e claims JWT; `401`; propriedade; CRUD e versão; idempotência com replay/payload divergente/`Location`; `429` e `Retry-After`; Swagger; health saudável/indisponível; JSON malformado; seed de gestor; CORS Development; e mapeamento das respostas `404/403/503` do Java por handler controlado. A integração positiva entre processos .NET e Java continua pendente.

Execução: exportar `DOTNET_DB_CONNECTION` e rodar `dotnet test CityTech.slnx` em `backend-dotnet`. Sem a variável, os testes de integração falham com mensagem explícita.
