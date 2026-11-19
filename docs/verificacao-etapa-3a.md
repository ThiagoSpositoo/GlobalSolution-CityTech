# Etapa 3A — Git e infraestrutura local

Execução em **17/11/2026**. Escopo autorizado pelo usuário: versionamento local e SQL Server/MongoDB/RabbitMQ; nenhuma API, app, publicação ou recurso Azure.

**Estado: concluída e reverificada.** Os três serviços continuam em execução saudável, sem reinícios; `.env` permanece ignorado e o repositório local está em `main` com identidade configurada.

## Autorizações e Git

- Etapa 2 aceita pelo usuário como concluída no escopo das ferramentas. Pendências Oracle/Android/acessos permanecem explícitas.
- Git inicializado na raiz por `git init -b main`. Identidade local fornecida pelo usuário: Thiago Sposito / spositothiagoo@gmail.com. Configurada com `git config --local user.name` e `user.email`; sem alteração da identidade global. Sem remoto; commit inicial local criado ao final desta revisão.
- `.gitignore` revisado: `.env`, chaves, configurações locais, dependências, builds, logs e PDF original protegidos. Acrescentados temporários de editores e configurações locais potencialmente sensíveis de npm/NuGet. `.env.example` continua versionável.
- `git check-ignore` confirmou `.env`, `Enunciados/`, node_modules, target, bin, temporários e chaves; exemplo não ignorado.
- Usuário autorizou gerar senhas aleatórias locais e confirmou EULA SQL Server Developer para desenvolvimento/testes.
- `.env` criado uma única vez, a partir do exemplo, com gerador criptográfico e três senhas distintas, sem saída em logs; EULA=Y. Nenhuma chave IA/JWT ou credencial externa criada.

## Inspeção e configuração

Inicialmente só existiam os dois containers hello-world encerrados da Etapa 2; nenhum volume Docker listado, nenhum listener nas portas 1433/27017/5672/15672. Nenhum serviço CityTech duplicado.

O processo ainda tinha PATH anterior: `docker` não foi encontrado na primeira consulta. Recarregado PATH de máquina+usuário no processo; Docker funcional. Nenhuma reinstalação.

`docker pull` das famílias planejadas confirmou imagens **linux/amd64**, compatíveis com engine x86_64. Digests fixados nos defaults do Compose e em `.env.example`:

| Serviço | Família consultada | Digest real |
|---|---|---|
| SQL Server | `mcr.microsoft.com/mssql/server:2022-latest` | `sha256:4525e3efac9f3e241cb003bb2ff2a82818b502f37e12049d788b1a9fa7e13b7f` |
| MongoDB | `mongo:8.0` | `sha256:bdc216e9d5a6ec2cfdac789b5832fdab64cd32055f59885cae918a92de63c361` |
| RabbitMQ | `rabbitmq:4-management` | `sha256:753099a19b577c322117f793f864b3129cbba96d40317221a69d73976e3c843c` |

Mantidos profiles, portas loopback e volumes nomeados. RabbitMQ ganhou hostname estável `citytech-rabbitmq` para estabilizar o nome do nó nos dados persistidos. Healthcheck Mongo agora exige sucesso explícito da autenticação antes do ping. São ajustes de infraestrutura, sem mudança de arquitetura.

## Comandos e resultados

```powershell
docker compose --env-file .env config --quiet
docker compose --profile dotnet --profile database --profile java up -d --wait --wait-timeout 240
docker compose --profile dotnet --profile database --profile java ps
```

Validação e subida: **exit 0**, os três serviços **healthy**.

| Container | Versão consultada em execução | Portas do host | Volume principal |
|---|---|---|---|
| `citytech-sqlserver-1` | SQL Server **16.0.4325.4**, Developer Edition (64-bit) | `127.0.0.1:1433` | `citytech_sqlserver-data` → `/var/opt/mssql` |
| `citytech-mongodb-1` | MongoDB **8.0.38** | `127.0.0.1:27017` | `citytech_mongodb-data` → `/data/db` |
| `citytech-rabbitmq-1` | RabbitMQ **4.4.0** | `127.0.0.1:5672`, `127.0.0.1:15672` | `citytech_rabbitmq-data` → `/var/lib/rabbitmq` |

Mongo também criou um volume anônimo da imagem para `/data/configdb`, preservado. Rede `citytech_default` criada. Volumes montados confirmados com `docker inspect --format` restrito a `.Mounts`, sem exibir ambiente/segredos.

### Testes básicos

- SQL: `docker compose exec -T sqlserver sh`, script por stdin exportando `SQLCMDPASSWORD` do ambiente interno; `sqlcmd -S localhost -U sa -C -b` executou `SERVERPROPERTY`, `SELECT 1`, criação/inserção/contagem de tabela **temporária** `#probe`. Conectividade=1 e contagem=1, exit 0. Nenhum schema de negócio criado.
- Mongo: `docker compose exec -T mongodb mongosh --quiet`, JavaScript por stdin autenticando com variáveis internas; versão 8.0.38, ping=1, um usuário autenticado, exit 0.
- RabbitMQ: `rabbitmq-diagnostics -q check_running`, `check_port_connectivity` e `server_version` dentro do serviço; nó iniciado, portas internas acessíveis, versão 4.4.0.
- RabbitMQ HTTP: GET `/api/overview` com Basic Auth construído em memória a partir do `.env`, sem imprimir cabeçalho/senha; sucesso. Mesma rota sem autenticação retornou **401**.
- Conexões TCP do Windows por `TcpClient` a 127.0.0.1 nas quatro portas: todas passaram.
- Persistência **configurada por volumes e mounts verificados**; não foi alegado teste de dados após recriação/reboot. Teste SQL de escrita foi temporário. Fluxo AMQP produtor/consumidor da aplicação ainda não implementado.

## Revisão final — 17/11/2026

Reverificação somente de leitura, sem reinstalar ferramentas, recriar containers, remover volumes ou alterar arquitetura.

| Item | Resultado observado |
|---|---|
| Docker CLI / Compose | **29.9.3** / **v5.7.0** |
| `citytech-sqlserver-1` | running/**healthy**, 0 reinícios; `127.0.0.1:1433` |
| `citytech-mongodb-1` | running/**healthy**, 0 reinícios; `127.0.0.1:27017` |
| `citytech-rabbitmq-1` | running/**healthy**, 0 reinícios; `127.0.0.1:5672` e `15672` |
| Volumes | `citytech_sqlserver-data`, `citytech_mongodb-data`, `citytech_rabbitmq-data` + volume anônimo do Mongo (`/data/configdb`) |
| SQL | `sqlcmd` conectou, `@@VERSION` = **16.0.4325.4 Developer**, `SELECT 1` = 1, exit 0 |
| Mongo | autenticou, versão **8.0.38**, ping 1, 1 usuário autenticado, exit 0 |
| RabbitMQ | nó `rabbit@citytech-rabbitmq` booted; portas 5672/15672/15692/25672 conectáveis; versão **4.4.0**, exit 0 |
| `.env` | existe, ignorado por `.gitignore:2` (`git check-ignore -v`) |
| `.env.example` | **não** ignorado (exit 1 do `check-ignore`), permanece versionável |
| Git | repositório na raiz, branch `main`, identidade local Thiago Sposito / spositothiagoo@gmail.com, **sem remoto**; commit inicial **`2d4053c`**, 41 arquivos, árvore limpa |
| Portas no host | todas em `127.0.0.1`; nenhuma exposta em `0.0.0.0` |

Nenhum dado de negócio foi criado. A escrita SQL anterior foi em tabela temporária; esta revisão não alterou dados. Containers não foram recriados e volumes não foram tocados. Nova conferência antes de encerrar a documentação confirmou os mesmos três serviços healthy, com 0 reinícios, `main` com histórico local e árvore limpa.

## Pendências e itens fora do escopo

**A Etapa 3A não possui pendência técnica aberta.** O que resta está separado por natureza:

- **Verificações adiadas, dependentes de implementação:** persistência dos dados após recriação dos containers ou reboot do Windows; fluxo AMQP produtor/consumidor real; schemas e scripts de negócio. Não são falhas atuais nem foram declarados como testados.
- **Decisões e acessos externos:** ambiente Oracle institucional (versão, host/porta/serviço e VPN), toolchain Android/build APK, contas e permissões GitHub/Azure/Firebase e provedor de IA. Nenhum foi provisionado ou publicado.
- **Fase seguinte:** backlog, critérios de aceite e contratos HTTP/JWT antes da modelagem e dos backends. Depende de autorização explícita do usuário.
- **Operação local:** manter credenciais somente no `.env` ignorado, não executar `down -v`/prune e não alterar senhas apenas no arquivo após a inicialização. O `.env` continua sujeito à sincronização do OneDrive; a configuração do OneDrive não foi alterada.
- **Fora de autorização:** implementar APIs, app, IA, pipelines ou deploy; criar recursos pagos; publicar o repositório.

## Operação e limites

- Credenciais somente no `.env` local ignorado. Não usar `docker compose config` sem `--quiet` nem compartilhar `docker inspect` completo: esses comandos podem revelar senhas.
- Não alterar senhas apenas no `.env` após inicialização: os usuários já persistidos exigem procedimento próprio de rotação.
- Para pausar preservando dados: `docker compose --profile dotnet --profile database --profile java stop`. Para retomar, usar o comando `up` acima. Não executar `down -v`, prune ou remover volumes.
- Serviços deixados em execução; nenhuma remoção de ferramentas/containers/volumes e nenhuma instalação global realizada.
- `.env` ignorado pelo Git não é excluído automaticamente da sincronização OneDrive. Configuração OneDrive não alterada; não compartilhar a pasta local com segredos.
- Próximo trabalho recomendado: backlog, critérios de aceite e contratos HTTP/JWT; depois modelagem. Oracle institucional e build Android continuam pendentes. Backends dependem de nova autorização.
