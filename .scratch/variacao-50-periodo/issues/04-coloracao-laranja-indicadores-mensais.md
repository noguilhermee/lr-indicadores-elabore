# 04 — Coloração laranja na aba "Indicadores Mensais"

**What to build:** O consultor abre o arquivo Excel mensal e vê, na própria aba **Indicadores
Mensais** — sem trocar de aba — a célula pintada de laranja em todo indicador que a regra de
variação classificou como `Aumento` ou `Redução` naquela fazenda × mês. `Entrada` e `Saída` não
pintam, para não colorir a planilha inteira no primeiro mês de lançamento de uma despesa.

A marcação por trás da cor fica em colunas auxiliares, prefixo `_var_`, uma por indicador colorido,
agrupadas no fim da aba e **ocultas** por padrão — o auditor consegue desocultá-las para conferir por
que uma célula está laranja, mas o consultor não precisa vê-las para achar o problema. A coloração
usa formatação condicional por fórmula via openpyxl lendo essas colunas — não estilo célula a célula
— porque a aba tem ~168 colunas × ~13 mil linhas. `functions/` não é alterado; a lógica de coloração
fica local no notebook.

**Blocked by:** 03 — Função `calcular_variacao_periodo` e aba "Variações" no Excel mensal.

**Status:** ready-for-agent

- [x] Colunas auxiliares `_var_`, uma por indicador colorido, presentes no fim da aba **Indicadores
      Mensais**, populadas a partir do DataFrame anotado da função do ticket 03
- [x] Colunas `_var_` ocultas por padrão, mas desocultáveis pelo usuário
- [x] Formatação condicional por fórmula (openpyxl) pinta de laranja a célula do indicador
      correspondente quando a categoria é `Aumento` ou `Redução`
- [x] `Entrada`, `Saída`, `Normal` e `Não avaliado` não pintam nenhuma célula (fórmula só testa
      `="Aumento"` ou `="Redução"`)
- [x] A aba **Indicadores Mensais** continua com os mesmos nomes, cabeçalhos, ordem e tipos das
      colunas de hoje — as colunas `_var_` são acréscimo, não substituição
- [x] `functions/` (`exportar_varias_abas_xlsx`, `aplicar_estilo_listrado_xlsx`) não foi alterado —
      a coloração roda local na 3.10, depois que essas funções já salvaram o arquivo
- [x] O arquivo anual não recebe nenhuma coloração nem coluna `_var_` (etapa só existe na célula de
      exportação mensal)
