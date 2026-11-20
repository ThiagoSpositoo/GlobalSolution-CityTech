# Entrega Compliance, Quality Assurance & Tests

Estado: **PDF/TXT/ZIP gerados com os dados reais do Azure DevOps; capturas e execução manual ainda ausentes e explicitamente registradas no PDF**.

Conteúdo:

- `documentacao-backlog.md`: escopo e regras da documentação.
- `matriz-features-test-cases.md`: cobertura planejada dos 24 casos.
- `modelo-relatorio-execucao.md`: formulário para resultados reais.
- `roteiro-capturas.md`: capturas exigidas e revisão de segurança.
- `estrutura-pdf.md`: ordem sugerida para o PDF único.
- `identificacao.txt`: identificação do grupo para o ZIP.
- `Compliance_CityTech.html`: fonte regenerável do PDF.
- `capturas/`: ponto de inserção automática de evidências reais.

Entrega gerada em `entregas/Entrega_Compliance_CityTech.zip`. Para incorporar capturas reais, salve-as em `capturas/` e execute `qa/scripts/New-ComplianceDelivery.ps1`. Esta pasta não comprova execução nem substitui Azure Boards/Test Plans.

Variante sob demanda: `entregas/Compliance_CityTech_sem_pagina_46.pdf` remove a seção 9 (checklist de evidências) e renumera a conclusão para 9; `entregas/Entrega_Compliance_CityTech_sem_pagina_46.zip` contém essa versão e o TXT. O pacote completo de 47 páginas permanece preservado.
