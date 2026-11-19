# Organização do código Mobile

- `app/`: rotas Expo Router públicas, protegidas, tabs, detalhe, edição, gestão e Sobre.
- `api/`: DTOs reais, clientes Axios separados, configuração, interceptores e normalização de erros.
- `auth/`: contexto de sessão e persistência em SecureStore.
- `components/`: design system enxuto, feedback de estado e cards.
- `features/`: formulários/componentes de domínio reutilizáveis.
- `styles/`: tokens institucionais de cor, tipografia, espaçamento e raio.
- `utils/`: validação, formatação, idempotência e testes unitários.

Regras de negócio e autorização permanecem nos backends. O app espelha validações para feedback imediato, mas sempre trata a resposta real das APIs.
