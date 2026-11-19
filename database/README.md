# Dados — responsabilidade por domínio

- [Oracle](oracle/README.md): domínio Java e avaliação PL/SQL.
- [SQL Server](sqlserver/README.md): domínio .NET; alvo Azure SQL de DevOps.
- [MongoDB](mongodb/README.md): snapshot documental dos dados Oracle.

Cada API é dona de seu banco. Não compartilhar tabela de usuários/senha, não escrever a mesma ocorrência nos dois backends e não apresentar snapshot Mongo como sincronização em tempo real.

SQL Server, Oracle e MongoDB possuem schemas, dados e testes locais executados. Oracle e MongoDB compartilham IDs fictícios estáveis e três relatórios comparáveis; consulte os READMEs de cada área para comandos, resultados e limites.
