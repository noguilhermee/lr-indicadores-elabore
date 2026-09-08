# 07 — Regressão e conferência do arquivo anual gerado

**What to build:** Quem consome o Excel anual tem a garantia, verificada, de que nada do que existia mudou: as quatro abas atuais continuam idênticas, os campos de consistência continuam com os mesmos valores, o `Cálculo de Médias` continua com a mesma contagem de colunas, e o arquivo mensal e a ingestão no Supabase seguem intactos. E quem audita consegue **refazer no Excel** a conta de uma fazenda marcada e chegar exatamente ao mesmo resultado.

Esta é a seam principal do spec — o arquivo Excel anual exportado, o mesmo ponto que o roteiro de validação do projeto já usa: abrir o arquivo gerado e conferir abas, cabeçalhos, número de linhas e tipos. Cobre de uma vez o comportamento novo (três abas com os números esperados) e a não-regressão (quatro abas antigas idênticas).

A conferência manual de auditabilidade é obrigatória, não opcional: é ela que justifica ter mantido o método literal (média ± 2·DP amostral) em vez de log ou MAD. Pegar uma fazenda marcada, ler `n`, média, DP e limites na aba *Parâmetros de Outlier* para aquele `annual_period`, e refazer a conta à mão — tem de bater exatamente.

Desvio grande em relação aos números de referência indica **erro de agrupamento ou de filtro**, não mudança de dado. Os números de referência valem apenas contra a **mesma** base de entrada da exportação de 13/08; se a base mudar, eles mudam junto.

**Blocked by:** 04 — Aba "Outliers": consolidado por fazenda × indicador; 05 — Aba "Outliers por Consultor": resumo de carteira.

**Status:** ready-for-agent

- [ ] O arquivo anual gerado tem **sete abas**, com os nomes estáveis `Outliers`, `Parâmetros de Outlier` e `Outliers por Consultor` além das quatro atuais
- [ ] As quatro abas atuais têm os mesmos nomes, cabeçalhos e ordem de colunas da exportação anterior
- [ ] `annual_consistency_status` e `annual_consistency_id` idênticos à exportação anterior
- [ ] `Cálculo de Médias` com a mesma contagem de colunas e as mesmas linhas da exportação anterior
- [ ] A aba *Indicadores Anuais* não ganhou nenhuma coluna numérica zerada indevidamente pelo preenchimento de numéricos vazios com zero
- [ ] Arquivo mensal e ingestão no Supabase inalterados; as colunas de outlier não sobem para o banco
- [ ] Conferência manual: uma fazenda marcada refeita no Excel a partir da aba *Parâmetros de Outlier* bate exatamente
- [ ] Conferência manual: uma fazenda com `filter_1 == 2` aparece nos dois consultores no resumo, e o total geral não é a soma simples das linhas
- [ ] Unicidade na granularidade, contagem de propriedades e períodos antes/depois, nulos e divisões por zero conferidos conforme o roteiro de validação do projeto
