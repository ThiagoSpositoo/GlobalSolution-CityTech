# Mobile CityTech — React Native / Expo

Aplicativo cidadão/gestor em **Expo SDK 58**, React Native 0.88, React 19.3, TypeScript 6, Expo Router e Axios. Consome diretamente a API .NET para identidade/acompanhamentos e a API Java para categorias/ocorrências/gestão/IA, sem dados mockados como fallback.

## Funcionalidades

- Boas-vindas, login e cadastro real de `CIDADAO` pela API .NET.
- JWT RS256 persistido em `expo-secure-store` no Android/iOS; Web usa `localStorage` com fallback em memória. A sessão é restaurada por `/auth/me`, com expiração, logout e guarda de rotas.
- Dashboard por papel com totais reais, ocorrências recentes e acesso ao painel do gestor.
- Lista Java paginada com busca e filtros por status, prioridade e categoria.
- Criação, detalhe, edição e cancelamento lógico de ocorrência com `version` otimista.
- Histórico Java e revisão humana de sugestão IA, incluindo polling limitado e fallback explícito.
- CRUD completo de acompanhamentos .NET, hidratado com o detalhe atual do Java e modo degradado quando este falha.
- Triagem, transições e indicadores para `GESTOR` conforme os contratos reais.
- Tela **Sobre o App** com versão e hash do commit injetado no build.
- Tratamento explícito de `400`, `401`, `403`, `404`, conflitos `409`, `429`/`Retry-After`, `5xx` e falhas de rede.

## Configuração

Crie `mobile/.env` local a partir de `.env.example` (o arquivo real é ignorado pelo Git):

```text
EXPO_PUBLIC_DOTNET_API_URL=http://localhost:8081
EXPO_PUBLIC_JAVA_API_URL=http://localhost:8080
EXPO_PUBLIC_GIT_COMMIT_HASH=development
```

O prefixo `/api/v1` é acrescentado pelos clientes. As variáveis `EXPO_PUBLIC_*` são públicas e nunca devem conter senha, token ou chave privada.

### Endereço por ambiente

| Ambiente | Host das APIs |
|---|---|
| Expo Web no computador | `localhost` |
| Android Emulator | `10.0.2.2` (encaminha ao host) |
| Dispositivo físico / Expo Go | IP LAN da máquina, por exemplo `192.168.1.50` |
| APK de avaliação | URLs HTTPS estáveis e publicamente alcançáveis |

As portas locais são fixadas para evitar conflito: Java `8080`, .NET `8081` e Metro/Expo Web `19006`. No dispositivo físico, computador e celular precisam estar na mesma rede e as APIs devem escutar em interface alcançável. `localhost` no celular aponta para o próprio aparelho.

Para Web ou acesso por IP LAN, inclua a origem exata do frontend em `CORS_ALLOWED_ORIGINS` ao iniciar os dois backends e ative `SPRING_PROFILES_ACTIVE=local` no Java. Não use origem curinga. Apps Android/iOS não aplicam CORS, mas ainda dependem de binding, rota e firewall alcançáveis.

## Execução

```bash
cd mobile
npm install
npm start
```

Atalhos: `npm run android`, `npm run ios` e `npm run web`; todos fixam o servidor Expo em `19006`. Os dois backends e suas dependências devem estar ativos para os fluxos funcionarem; indisponibilidade é exibida ao usuário, não substituída por conteúdo fictício.

## Verificações

```bash
npm run typecheck
npm run lint
npm test -- --runInBand
npx expo install --check
npx expo-doctor
```

Resultado local em 17/11/2026: TypeScript e lint sem erros; **8/8 testes** aprovados; dependências compatíveis; Expo Doctor **20/20**; export Web concluído com todas as rotas. Isso comprova scaffold, tipagem, testes e bundle, não substitui integração real em Android/iOS.

## Hash do build

Antes do APK publicado, injete o commit real:

```bash
EXPO_PUBLIC_GIT_COMMIT_HASH=$(git rev-parse --short HEAD) npx expo export
```

No pipeline/build Android, configure a mesma variável para que **Sobre o App** corresponda exatamente ao código publicado. Firebase App Distribution, assinatura do APK e convite do professor continuam etapas externas sujeitas a autorização.

## Limites verificados

- Não há refresh token no contrato; `401` limpa a sessão e retorna ao login.
- O Java real ainda depende de Oracle configurado; a integração ponta a ponta Mobile → .NET → Java não foi executada nesta etapa.
- O CORS local foi implementado e testado nos dois backends; a prova em navegador/dispositivo com todos os processos simultâneos continua pendente.
- `localStorage` não oferece a proteção do Keychain/Keystore; o fallback Web existe para desenvolvimento e não substitui a segurança do aplicativo nativo publicado.
- Fotos, mapa/GPS e push permanecem fora do MVP.
