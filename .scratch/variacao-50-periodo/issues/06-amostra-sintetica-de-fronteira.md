# 06 — Amostra sintética exercitando os casos de fronteira

**What to build:** Qualquer pessoa que abra o notebook consegue rodar a função
`calcular_variacao_periodo` contra um DataFrame sintético mensal pequeno e ver os casos de fronteira
se comportarem como o spec descreve, sem depender de uma execução completa contra o banco e sem usar
dado real de cliente.

Uma célula de verificação, no molde exato da célula de verificação da análise de outliers (4.4.1):
helper local que imprime `OK` / `FALHA` por sonda e levanta `AssertionError` ao final se houver
qualquer falha. O teste verifica **comportamento externo observável** — os valores e categorias que
saem da função — não como as colunas foram montadas internamente; se a implementação for reescrita
mantendo os mesmos números, o teste continua passando.

Sondas obrigatórias:

- razão **exatamente 1,5** e **exatamente 0,5** → **não** marca; o menor incremento além de cada uma
  (`np.nextafter`) → marca;
- `0 → positivo` = `Entrada`; `positivo → 0` = `Saída`; `0 → 0` e nulo = `Não avaliado`;
- **lacuna** de mês → `Não avaliado`, **nunca** comparação atravessando o buraco;
- **primeira linha** de cada fazenda → `Não avaliado`;
- fazenda com **dois consultores** → o resultado aparece para os dois no `df_por_consultor`, sem
  duplicar a linha de variação em si;
- **pureza**: o DataFrame de entrada não é modificado.

**Blocked by:** 03 — Função `calcular_variacao_periodo` e aba "Variações" no Excel mensal.

**Status:** ready-for-agent

- [x] Amostra sintética construída dentro do notebook, sem dado real de cliente
- [x] Razão exatamente 1,5 e 0,5 não marca; o menor incremento além de cada uma marca
- [x] `0 → positivo` = `Entrada`; `positivo → 0` = `Saída`; `0 → 0` e nulo = `Não avaliado`
- [x] Lacuna de mês produz `Não avaliado`, nunca comparação atravessando o buraco
- [x] Primeira linha de cada fazenda → `Não avaliado`
- [x] Fazenda com dois consultores aparece nos dois em `df_por_consultor`
- [x] Sonda de pureza confirma que o DataFrame de entrada não é modificado
- [x] A célula roda contra a função pura, sem I/O, banco, SharePoint ou estado global, e levanta
      `AssertionError` se qualquer sonda falhar (17/17 sondas OK na verificação local — ver
      `scripts/_cell_verificacao_code.py`)
