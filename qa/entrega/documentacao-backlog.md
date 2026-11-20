# Documentação do backlog Azure

## Fonte real

O inventário oficial é `qa/relatorios/azure-work-items.json`, gerado pela REST API em 19/11/2026. Ele confirmou 5 Epics, 12 Features e 39 PBIs. O mapeamento completo, incluindo pais e filhos, está em `qa/data/azure-mapping.json`; os códigos de `docs/backlog.md` continuam sendo apenas referência funcional.

## Regras de conteúdo

Cada uma das 12 Features e cada um dos 39 PBIs deve possuir:

1. descrição específica do valor e comportamento CityTech;
2. ator, limite e dependências pertinentes;
3. critérios de aceite observáveis, mensuráveis e verificáveis;
4. autorização e códigos HTTP quando aplicáveis;
5. indicação transparente de funcionalidade planejada, implementada ou bloqueada.

Conteúdo existente válido não será substituído automaticamente. Anexos/fotos, mapa/GPS, cloud, Firebase e LLM externo não podem ser descritos como concluídos sem evidência.

## Situação

As 51 documentações foram preparadas em `qa/data/work-item-content.json`. O dry-run preserva conteúdo remoto já válido e propõe apenas o preenchimento dos campos ausentes. Anexos, recuperação de senha, push, gráficos avançados e exportação de relatório estão identificados como planejados/não implementados.
