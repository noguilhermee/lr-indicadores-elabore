# 08 — Conferência da planilha `PARAMETROS_INCONSISTENCIA.xlsx` (sem edição)

**What to build:** O responsável pelos parâmetros recebe a confirmação de que as linhas 24–26 da
aba MENSAL do `PARAMETROS_INCONSISTENCIA.xlsx` — variação mensal do preço do leite, da bonificação
por qualidade, do gasto com dieta/preço do leite — têm MÍN −50 / MÁX +50 coerentes com o que o
código implementa. É **conferência, não edição**: a planilha é documentação, nenhum código a lê, e
nenhuma linha ou valor é alterado sem novo aval — ela é o documento de contrato do Filipe.

Se a conferência encontrar divergência (linhas em branco, valores diferentes de −50/+50, ou
indicadores da lista aprovada no ticket 02 ausentes da planilha), o achado é reportado ao Filipe para
decisão dele sobre editar ou não — esta fatia não edita por conta própria.

**Blocked by:** 02 — Re-medição e aprovação da lista final de indicadores mensais.

**Status:** ready-for-agent

- [x] Linhas 24–26 da aba MENSAL conferidas contra o código: MÍN −50 / MÁX +50 confirmado nas três
      linhas (24. preço do leite, 25. bonificação por qualidade, 26. gasto com dieta/preço do leite)
- [x] Lista final de indicadores mensais (ticket 02) conferida contra as linhas existentes na aba
      MENSAL; divergência encontrada e documentada (ver `achados_ticket08_parametros.md`) — 6 dos 7
      indicadores aprovados não constam na planilha, e 2 dos 3 itens da planilha (bonificação,
      dieta/preço-leite) não entraram na regra implementada
- [x] Nenhuma linha ou valor da planilha foi alterado nesta fatia
- [x] Achados de divergência levados ao Filipe para decisão, antes de qualquer edição futura
      (`.scratch/variacao-50-periodo/achados_ticket08_parametros.md`)
