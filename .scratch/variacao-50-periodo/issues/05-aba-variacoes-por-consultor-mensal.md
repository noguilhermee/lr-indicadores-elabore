# 05 — Aba "Variações por Consultor" no Excel mensal

**What to build:** O coordenador abre o arquivo Excel mensal e encontra a aba nova **Variações por
Consultor**, no mesmo formato do resumo por consultor da análise de outliers (4.4): a carteira de
cada consultor sobre a ocorrência mais recente de cada fazenda, com a quebra pelos indicadores
mensais cobertos (os mesmos do ticket 03), para saber que tipo de erro predomina na carteira.

Decisões que esta fatia implementa:

- O resumo considera a **ocorrência mais recente de cada fazenda**, para não contar a mesma fazenda
  várias vezes.
- **Cada vínculo conta**: uma fazenda com dois consultores aparece para os dois, porque a
  responsabilidade é compartilhada.
- **Aviso no cabeçalho** de que, por isso, a soma das linhas excede o total de fazendas distintas —
  reaproveitando a constante de aviso já usada no resumo por consultor da análise de outliers.
- A aba passa pela preparação para Excel **sem** o preenchimento de numéricos vazios com zero.

**Blocked by:** 03 — Função `calcular_variacao_periodo` e aba "Variações" no Excel mensal.

**Status:** ready-for-agent

- [x] Aba **Variações por Consultor** presente no arquivo mensal, na granularidade consultor, no
      mesmo formato do resumo por consultor da 4.4
- [x] Colunas de fazendas atendidas, fazendas marcadas e quebra pelos indicadores mensais, com
      rótulos em português
- [x] O resumo considera apenas a ocorrência mais recente de cada fazenda
- [x] Fazenda com dois consultores aparece nos dois; a soma das linhas excede o total de fazendas
      distintas (consultant_name mensal é dividido por vínculo — ver sonda `SONDA-DUPLA` no ticket 06)
- [x] Aviso no cabeçalho explicando por que a soma excede o total de fazendas distintas
      (`AVISO_SOMA_CONSULTOR`, mesmo texto da 4.4)
- [x] A aba não passa pelo preenchimento de numéricos vazios com zero
- [x] As abas **Indicadores Mensais** e **Variações** continuam com os mesmos nomes, cabeçalhos e
      ordem de colunas dos tickets anteriores
