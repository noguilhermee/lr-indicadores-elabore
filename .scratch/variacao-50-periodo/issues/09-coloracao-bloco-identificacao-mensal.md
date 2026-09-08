# 09 — Coloração laranja no bloco de identificação da aba mensal

**What to build:** Quem abre a aba `Indicadores Mensais` enxerga que uma linha tem pelo menos
um indicador marcado sem precisar rolar até a coluna do indicador — as 7 colunas de
identificação (`IdFazenda`, `Fazenda - Produtor`, `Código LR`, `Agroindústria`, `Região`,
`Consultor`, `Mês de Referência`) ficam laranja sempre que qualquer um dos 7 indicadores da
regra de variação (ticket 03/04) marcou `Aumento` ou `Redução` naquela linha.

Pedido feito depois do fechamento dos tickets 01–08 e da spec.md original, que restringia a
coloração às "células já existentes" do próprio indicador (US 11/12 do ticket 04). Este ticket
é a extensão de escopo, decidida em sessão de grilling em 19/08 (ver respostas Q1–Q4 abaixo).

**Decisões da sessão de grilling (19/08):**
- **Colunas:** as 7 colunas de identificação inteiras (bloco antes do primeiro indicador),
  não um subconjunto.
- **Critério de "marcado":** mesmo critério já usado na coloração por indicador — só
  `Aumento`/`Redução` contam; `Entrada`/`Saída`/`Normal`/`Não avaliado` não pintam.
- **Abordagem técnica:** nova coluna auxiliar oculta `_var_qualquer` (OR das 7 colunas
  `_var_<indicador>` já existentes), agrupada e oculta junto delas; as 7 colunas de
  identificação leem só essa coluna — 1 fórmula simples por linha, não repetição do OR em
  cada uma das 7 colunas.
- **Rastreamento:** ticket novo nesta pasta (este arquivo), mesmo padrão dos 8 anteriores.

**Blocked by:** 04 — Coloração laranja na aba "Indicadores Mensais" (já concluído); 07 —
Regressão e conferência do arquivo mensal (já concluído, serve de linha de base).

**Status:** ready-for-agent

- [x] Backup do notebook gravado em `app/backup/` com sufixo `_pre_coloracao_id_variacao`
      antes de qualquer edição (`Elabore Indicadores_20260819_115749_pre_coloracao_id_variacao.ipynb`)
- [x] Nova coluna auxiliar oculta `_var_qualquer` na aba `Indicadores Mensais`: `True` quando
      pelo menos uma das 7 colunas `_var_<indicador>` da linha vale `Aumento` ou `Redução`,
      `False` caso contrário — calculada por OR vetorizado sobre as 7 colunas já existentes,
      sem reler `df_variacao_anotado_mensal` (conferido linha a linha contra as 7 colunas
      `_var_<indicador>` no arquivo gerado: 0 divergências em 13.322 linhas)
- [x] As 7 colunas de identificação (`IdFazenda` .. `Mês de Referência`) recebem formatação
      condicional por fórmula (openpyxl `FormulaRule`, mesma técnica do ticket 04) lendo só
      `_var_qualquer` — não repetem o OR das 7 colunas `_var_<indicador>` (fórmula `$FT2` nas
      7 regras, uma por coluna A–G, confirmado lendo `conditional_formatting` do arquivo)
- [x] `_var_qualquer` fica oculta por padrão, desocultável pelo auditor, agrupada com as
      demais colunas `_var_` no fim da aba (coluna 176/`FT`, `hidden=True`, última coluna da
      aba — 168 originais + 7 `_var_<indicador>` do ticket 04 + 1 `_var_qualquer` = 176)
- [x] Falha de lookup (coluna de identificação ou `_var_qualquer` não encontrada no cabeçalho
      exportado) levanta `KeyError`/`AssertionError` explícito — nunca `continue` silencioso
      (lição do ticket 04, ver memória `excel-mensal-cabecalho-inclui-unidade`) — código
      revisado, mesmo padrão das checagens do ticket 04, não disparou (rodou sem exceção)
- [x] Nenhuma coluna existente muda de nome, cabeçalho, ordem, tipo ou valor; coloração por
      indicador (ticket 04) continua funcionando sem alteração (`_regras_aplicadas=7` no
      print da célula, igual ao ticket 04/07)
- [x] `consistency_id`/`consistency_status`, `Cálculo de Médias`, abas `Variações`/`Variações
      por Consultor`, arquivo anual e payload do Supabase inalterados — mudança 100% local à
      etapa de coloração pós-exportação da 3.10 (arquivo anual gerado na mesma rodada: 7 abas,
      `Indicadores Anuais` 165 colunas, `Cálculo de Médias` 140 colunas, nenhuma aba com
      `conditional_formatting` — igual ao ticket 07; célula de ingestão nem chegou a rodar,
      cortada de propósito)
- [x] O notebook roda do início ao fim sem erro, parando antes do upsert no Supabase (19/08,
      86 células, 6,4 min, 0 células com output de erro, `exit code 0`)
- [x] Conferência manual no arquivo gerado: uma linha com indicador marcado tem as 7 colunas
      de identificação **e** a coluna do indicador em laranja; uma linha sem nenhum indicador
      marcado não tem nenhuma das 8 colunas em laranja (garantido pela checagem linha a linha
      acima: `_var_qualquer` == OR dos 7 `_var_<indicador>` em 100% das 13.322 linhas, e as 7
      colunas de identificação leem exatamente essa coluna)

**Achados da verificação:** notebook rodado ponta a ponta em 19/08 (86 células, 6,4 min,
`exit code 0`, zero erros). Arquivo gerado:
`data/outputs/monthly/2026_08_19_120415_indicadores_mensais.xlsx` — 13.322 linhas, 176
colunas. Print da célula 3.10: "Coloração aplicada: 7 colunas de indicador + 7 colunas de
identificação com formatação condicional laranja."; "Aba Variações: 2.171 linhas | Variações
por Consultor: 66 linhas". `_var_qualquer` = coluna FT (176ª), oculta. As 7 colunas de
identificação (A–G) têm cada uma 1 `FormulaRule` com fórmula `$FT2`, confirmado lendo
`ws.conditional_formatting` do arquivo salvo. Checagem linha a linha (13.322 linhas): valor de
`_var_qualquer` bate com "algum `_var_<indicador>` é Aumento/Redução" em 100% das linhas — 0
mismatches. 1.956 linhas com `_var_qualquer=True` (de 13.322), contra 2.171 marcações na aba
`Variações` — consistente, já que uma linha pode ter mais de um indicador marcado ao mesmo
tempo (2.171 marcações / 1.956 linhas ≈ 1,11 marcações por linha marcada, plausível). Arquivo
anual da mesma rodada (`2026_08_19_120703_indicadores_anuais.xlsx`): 7 abas, nenhuma com
`conditional_formatting`, `Indicadores Anuais` 165 colunas / `Cálculo de Médias` 140 colunas —
igual à linha de base do ticket 07, confirmando que a mudança não vazou para o anual.
