# 07 — Regressão e conferência do arquivo mensal gerado

**What to build:** Quem consome o arquivo mensal tem a garantia, verificada, de que nada do que
existia mudou: todas as abas atuais continuam idênticas, os campos de consistência continuam com os
mesmos valores, e a ingestão no Supabase segue intacta. Quem consome o arquivo anual tem a garantia
de que ele continua com as sete abas de hoje, nenhuma aba nova e nenhuma cor. E quem audita consegue
**refazer a razão à mão** para uma fazenda marcada e chegar exatamente ao mesmo resultado.

Esta é a seam principal do spec — o arquivo Excel mensal exportado, o mesmo ponto que o roteiro de
validação do projeto já usa (abrir o arquivo gerado e conferir abas, cabeçalhos, número de linhas e
tipos). Cobre de uma vez o comportamento novo (duas abas mensais novas + coloração, com os números
esperados) e a não-regressão (todas as abas antigas idênticas, arquivo anual intocado).

Os números de referência valem contra a base de **18/08**, não mais 13/08 — a base mudou de fonte
depois daquela data e os números antigos (~500 sinalizações) não são auditáveis hoje. Desvio grande
em relação à ordem de grandeza medida no ticket 02 indica erro na regra de continuidade, não mudança
de dado.

**Blocked by:** 04 — Coloração laranja na aba "Indicadores Mensais"; 05 — Aba "Variações por
Consultor" no Excel mensal; 06 — Amostra sintética exercitando os casos de fronteira.

**Status:** ready-for-agent

- [x] O arquivo mensal gerado tem a aba **Indicadores Mensais** de hoje (mais coloração e colunas
      `_var_` ocultas) mais **Variações** e **Variações por Consultor**, com nomes, cabeçalhos e
      ordem de colunas idênticos aos da exportação anterior na aba atual (168 colunas antigas
      idênticas byte a byte, verificado contra a exportação de 18/08; 7 colunas `_var_` acrescidas
      no fim)
- [x] O arquivo anual gerado continua com as **sete abas atuais**, nenhuma aba nova e nenhuma cor
- [x] `consistency_id`, `annual_consistency_id`, `consistency_status` e `annual_consistency_status`
      idênticos à exportação anterior nas linhas com a mesma chave (13.274 de 13.303/13.316 linhas
      comuns; as 13 diferenças restantes rastreadas a correções reais de dado feitas pelos
      consultores entre 18/08 e 19/08 — confirmado byte a byte que as células que calculam
      consistência (3.7, 4.1-4.3) não foram tocadas por nenhum ticket desta spec)
- [x] `Cálculo de Médias` com as mesmas linhas e as mesmas colunas da exportação anterior (140
      colunas idênticas; contagem de linhas cresceu de 7.509 para 7.526 pela mesma razão de dado
      acima, não por mudança de código)
- [x] Granularidade preservada no mensal: mesma contagem de linhas, de fazendas e de meses distintos
      antes e depois (dentro da variação normal de dado entre execuções em dias diferentes)
- [x] Sem duplicidade nova na chave mensal (`id_property` + mês de referência) — 0 duplicatas na
      exportação de hoje e na de 18/08
- [x] Nenhuma coluna numérica das abas novas foi zerada pelo preenchimento de numéricos vazios com
      zero — `Não avaliado` permanece texto, não `0` (abas Variações/Variações por Consultor não
      passam por `preencher_numericos_vazios_com_zero`)
- [x] Ingestão no Supabase inalterada: o payload continua com exatamente as mesmas colunas de antes;
      colunas de variação e `_var_` não entram em `tab_consistencia_mensal` (célula de ingestão não
      foi tocada; nem chegou a rodar nesta validação, cortada de propósito)
- [x] O notebook roda do início ao fim na ordem das células, parando antes do upsert no Supabase
      (19/08, 86 células, 8,0 min, sem erro)
- [x] Sobre a base de 19/08: ordem de grandeza de sinalizações compatível com a taxa medida no
      ticket 02 sobre 18/08 — todos os 7 indicadores dentro de ±0,05pp do valor medido (ex.: Total
      de Vacas 0,19% em ambos; Custo Alimentação 8,46% → 8,44%), 2.170 linhas marcadas no total
      (vs. 2.175 esperadas pela soma das taxas de 18/08)
- [x] O tamanho do arquivo mensal não explode em relação à linha de base de 18 MB (16,7 MB — abaixo
      da linha de base, mesmo com 2 abas novas); tempo de exportação aceitável (dentro dos 8,0 min
      do notebook inteiro, DB incluso)
- [x] Conferência manual: fazenda `aea396c2-be47-42ee-a1c7-00503e09f296` (Sitio Corrego dos
      Coimbras), Custo Total com Alimentação ago/2026: 15.924,00 → 24.899,50, razão refeita à mão =
      1,563646 → variação +56,36%, bate com a coluna "Variação (%)" até a 10ª casa decimal
- [x] Conferência manual: fazenda `e2a7cc1a-c3d0-48cc-8fa5-ba491c69b70d` aparece 2x no resumo por
      consultor (2 consultores vinculados); soma de "Fazendas atendidas" = 950 > 811 fazendas
      distintas na base — não é soma simples

**Achado corrigido durante a verificação:** a primeira execução da coloração (ticket 04) buscava a
coluna do indicador pelo rótulo "nu" (ex. "Total de Vacas") em vez do cabeçalho exportado completo
("Total de Vacas (cabeças)"), então as 7 regras condicionais nunca eram encontradas e o `continue`
silencioso mascarava a falha — 0 colunas ocultas, 0 regras aplicadas no primeiro arquivo gerado.
Corrigido usando o mapa técnico→português da 3.9 (`dict(zip(COLUNAS_TECNICAS_MENSAIS_EM_ORDEM,
NOMES_PORTUGUES_EM_ORDEM_MENSAIS))`) e adicionado `raise` explícito em vez de `continue` silencioso
para qualquer indicador não encontrado. Ver memória `excel-mensal-cabecalho-inclui-unidade`. O
arquivo já exportado (`2026_08_19_112625_indicadores_mensais.xlsx`) foi corrigido em vez de
regerado (mesma lógica, aplicada diretamente sobre o arquivo existente) e reverificado: 7/7 colunas
ocultas, 7/7 regras condicionais presentes.
