# Auditoria local de Compliance / QA

Data: **19/11/2026**.

## Estado observado

- Projeto Azure informado: `RM561694/GlobalSolution-CityTech`.
- Base remota informada pelo usuário: **56 Work Items**, sendo 5 Epics, 12 Features e 39 PBIs.
- Base local de planejamento: **8 Epics, 21 Features e 60 PBIs** em `docs/backlog.md`.
- A base local não pode ser importada nem correlacionada por sequência sem duplicar ou associar itens incorretamente.
- A exportação REST autenticada foi executada pelo usuário sem armazenar ou exibir o token.
- **Work Items encontrados: 56**, sendo 5 Epics, 12 Features e 39 PBIs.
- IDs, títulos, revisões e relações reais estão em `azure-work-items.json` e foram usados no mapeamento canônico.
- Nenhuma escrita, convite, push, publicação ou mudança de estado foi realizada.

## Funcionalidades confirmadas no repositório

Cadastro/login e JWT RS256; idempotência/rate limiting/health; categorias; CRUD lógico, paginação e histórico de ocorrências; acompanhamentos; triagem, estados e indicadores; outbox/RabbitMQ; sugestão IA com fallback e revisão humana; Mobile consumindo as duas APIs; Oracle e MongoDB.

Anexos/fotos, mapas e geolocalização não estão implementados no MVP. LLM externo, execução Mobile manual/Android, Firebase, cloud, Test Plans e evidências finais permanecem pendentes.

## Documentação pendente

O inventário mostrou 95 campos ausentes: 17 em Features e 78 nos 39 PBIs. Sete campos remotos já válidos serão preservados. As 51 documentações desejadas estão preparadas localmente; nenhuma foi enviada ao Azure.

## Resultado local

- Módulo REST e quatro fluxos: inventário, template de mapeamento, sincronização dry-run/Apply e verificação.
- Catálogo: **24 Test Cases planejados**, sendo um positivo e um negativo para cada uma das 12 chaves de Feature.
- Dry-run offline com fixture descartável 5/12/39: **51 atualizações documentais candidatas, 24 criações de Test Case e 0 conflitos**, sem chamadas remotas.
- Dry-run com o inventário real: 49 Work Items candidatos, 95 campos, 24 Test Cases, 7 conteúdos válidos preservados e 0 conflitos não resolvidos.
- A sincronização remota permanece bloqueada até autorização explícita de `-Apply`.
