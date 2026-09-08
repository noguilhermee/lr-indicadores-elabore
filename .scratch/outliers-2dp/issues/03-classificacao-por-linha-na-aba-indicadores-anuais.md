# 03 — Classificação por linha e colunas de outlier na aba Indicadores Anuais

**What to build:** O consultor abre a aba *Indicadores Anuais* do arquivo anual e vê, para cada linha fazenda-janela, se ela está fora do padrão do grupo: em quais dos 6 indicadores, para qual lado, quantos ao todo, e o motivo em texto legível. Um filtro por `outlier_status_annual` já separa a planilha.

Colunas anexadas ao DataFrame de indicadores anuais:

- `is_outlier_<coluna>` — uma por indicador, **texto**: `Acima` / `Abaixo` / `Normal` / `Não avaliado`;
- `outlier_count_annual` — **inteiro** de 0 a 6;
- `outlier_status_annual` — `Outlier` / `Normal` / `Amostra insuficiente`;
- `outlier_indicators_annual` — lista dos rótulos marcados em texto, ou `Nenhum`;
- `outlier_details_annual` — texto no mesmo formato de `annual_violated_consistency_details`, por exemplo: `Preço médio do concentrado (Acima: 4,10 R$/kg; faixa 0,50 a 3,30; z=+3,1)`.

Decisões que esta fatia implementa:

- A **classificação é aplicada a todas as linhas anuais** — inclusive as inconsistentes e as duplicadas por consultor — contra os parâmetros da base filtrada do ticket 02. Nenhuma fazenda fica sem diagnóstico, mesmo que não entre no cálculo dos parâmetros.
- **Uma violação já marca a linha** como `Outlier`; a contagem de 0 a 6 serve para ordenar gravidade.
- **Indicador sem valor vira `Não avaliado`** naquele indicador e não conta como violação — ausência de dado não é sinônimo de normalidade.
- Linhas de período sem parâmetro (abaixo do N mínimo) saem como `Amostra insuficiente`, com a lacuna explícita em vez de erro ou valor inventado.
- Valor **exatamente no limite não marca**; imediatamente fora dele marca.
- **Nenhuma coluna de z-score é anexada à base anual.** O preenchimento de numéricos vazios com zero da exportação transformaria um z ausente em `0`, que lê como "exatamente na média". Os z-scores vivem só nas abas novas, que não passam por esse preenchimento.

Nada de consistência muda: `consistency_id`, `annual_consistency_id`, `consistency_status` e `annual_consistency_status` ficam intactos, as regras fixas de Produção/MDO e Produção/área continuam valendo como estão, o `Cálculo de Médias` mantém as mesmas linhas e colunas, e as colunas novas não sobem para o Supabase.

**Blocked by:** 02 — Parâmetros de outlier por período e aba "Parâmetros de Outlier".

**Status:** ready-for-agent

- [ ] As cinco famílias de colunas acima anexadas ao DataFrame de indicadores anuais e visíveis na aba *Indicadores Anuais*
- [ ] `is_outlier_<coluna>` e as colunas de status/lista/detalhe são texto; `outlier_count_annual` é inteiro; nenhuma coluna de z-score anexada à base anual
- [ ] Classificação aplicada a todas as linhas anuais, inclusive inconsistentes e duplicadas por consultor
- [ ] Indicador sem valor → `Não avaliado`, sem contar como violação
- [ ] Valor exatamente no limite não marca; imediatamente fora dele marca
- [ ] Linhas de período sem parâmetro → `Amostra insuficiente`; sobre a base de 13/08, ≈ 68 linhas
- [ ] Sobre a base de 13/08: ≈ 1.950 linhas com status `Outlier` (25,8% de 7.566); entre 363 e 539 linhas marcadas por indicador; distribuição da contagem ≈ 1.308 com 1 indicador, 427 com 2, 166 com 3, 29 com 4, 20 com 5
- [ ] `outlier_details_annual` segue o mesmo formato de `annual_violated_consistency_details`
- [ ] `consistency_id`, `annual_consistency_id`, `consistency_status` e `annual_consistency_status` inalterados
- [ ] `Cálculo de Médias` com as mesmas linhas e as mesmas colunas; arquivo mensal e ingestão no Supabase inalterados
