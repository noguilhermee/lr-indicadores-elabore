# 03 — Função `calcular_variacao_periodo` e aba "Variações" no Excel mensal

**What to build:** O auditor abre o arquivo Excel mensal e encontra uma aba nova, **Variações**,
com a série inteira — uma linha por fazenda × indicador × mês marcado, ordenada do mês mais recente
para o mais antigo — cobrindo a lista de indicadores aprovada no ticket 02. Cada linha traz fazenda,
consultor, indicador, período, valor anterior, valor atual, variação (%) e lado (Aumento/Redução),
para o auditor refazer a razão à mão.

A lógica vive em uma função pura, testável sem banco, sem SharePoint e sem estado global, modelada
na função de outliers da 4.4 (mesmos helpers de formatação numérica brasileira e de renomeação do
consolidado). Nasce parametrizada desde o início — coluna-chave, coluna de ordem, limite percentual,
prefixo — mesmo sem consumidor anual hoje:

```python
LIMITE_VARIACAO_PERCENTUAL = 50

calcular_variacao_periodo(
    df, indicadores, coluna_chave="id_property",
    coluna_ordem=..., limite_percentual=LIMITE_VARIACAO_PERCENTUAL,
    prefixo="variacao", colunas_informativas=None,
) -> (df_anotado, df_consolidado, df_por_consultor)
```

Decisões que esta fatia implementa:

- **Continuidade**: ordenar por fazenda e período; comparar contra a linha anterior **só se** o mês
  for calendário consecutivo (`ano*12 + mês` com passo de exatamente 1). Lacuna de mês produz
  `Não avaliado`, nunca uma comparação atravessando o buraco.
- **Critério**: razão `valor / valor_anterior`; marca se `> 1,5` ou `< 0,5`. Igualdade exata em 1,5
  ou 0,5 **não** marca.
- **Categorias**: `Aumento` / `Redução` / `Entrada` (zero → positivo) / `Saída` (positivo → zero) /
  `Normal` / `Não avaliado` (ambos zero, qualquer nulo, lacuna de período, ou primeira linha da
  fazenda). Sem piso de materialidade.
- **Base do cálculo**: valor bruto do indicador, sobre a série já deflacionada por IGP-DI.
- **Sem** as colunas "Períodos marcados" / "Primeiro período marcado" da versão anterior da spec —
  ninguém filtra por elas.
- A aba nova passa pela preparação para Excel **sem** o preenchimento de numéricos vazios com zero,
  para que `Não avaliado` chegue como texto, nunca como `0`.
- **Nenhuma coluna nova é anexada à aba "Indicadores Mensais"** nesta fatia — isso é o ticket 04.
  Toda a informação por indicador vive só na aba "Variações".

**Blocked by:** 01 — Reverter placeholder anual e renumerar; 02 — Re-medição e aprovação da lista
final de indicadores mensais.

**Status:** ready-for-agent

- [x] Função pura recebe DataFrame, configuração de indicadores, coluna-chave, coluna de ordem,
      limite percentual e prefixo, e devolve o DataFrame anotado mais os dois DataFrames de saída
      (consolidado e por consultor); faz cópia defensiva do DataFrame de entrada e não o modifica
- [x] Estrutura declarativa `coluna → (rótulo, unidade, formato)` configura exatamente a lista
      aprovada no ticket 02
- [x] Continuidade exige mês calendário consecutivo; lacuna produz `Não avaliado`
- [x] Razão exatamente 1,5 ou 0,5 não marca; fora desses limites marca
- [x] `0 → positivo` = `Entrada`; `positivo → 0` = `Saída`; `0 → 0` e nulo = `Não avaliado`; primeira
      linha da fazenda = `Não avaliado`
- [x] Aba **Variações** presente no arquivo mensal: série inteira, uma linha por fazenda ×
      indicador × mês marcado, ordenada do mês mais recente para o mais antigo, com fazenda,
      consultor, indicador, período, valor anterior, valor atual, variação (%) e lado
- [x] A aba nova não passa pelo preenchimento de numéricos vazios com zero
- [x] A aba **Indicadores Mensais** continua com os mesmos nomes, cabeçalhos, ordem e tipos de hoje
- [x] `consistency_id` e `consistency_status` inalterados em 100% das linhas (não são tocados —
      só lidos; verificação de regressão fim-a-fim no ticket 07)
- [x] Rótulos e cabeçalhos da aba nova em português
