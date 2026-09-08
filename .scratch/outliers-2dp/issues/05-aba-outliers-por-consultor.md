# 05 — Aba "Outliers por Consultor": resumo de carteira

**What to build:** O gestor abre a aba nova **Outliers por Consultor** e enxerga a carteira de cada consultor: quantas fazendas ele atende, quantas estão fora do padrão do grupo, o percentual, e a quebra pelos 6 indicadores — para saber se o problema da carteira é de custo, de produtividade ou de composição de renda.

Decisões que esta fatia implementa:

- O resumo considera a **última janela de cada fazenda**, para não contar a mesma fazenda várias vezes por causa das janelas móveis.
- **Cada vínculo conta**: uma fazenda com dois consultores aparece para os dois, porque a responsabilidade é compartilhada. Isso é deliberadamente assimétrico em relação ao cálculo dos parâmetros, que usa `filter_1 == 1` justamente para não dar peso dobrado à mesma fazenda na estatística do grupo.
- Por causa disso, um **aviso no cabeçalho** registra que a soma das linhas **excede** o total de fazendas distintas, para que ninguém interprete o total como contagem de fazendas.

A aba passa pela preparação para Excel **sem** o preenchimento de numéricos vazios com zero.

**Blocked by:** 03 — Classificação por linha e colunas de outlier na aba Indicadores Anuais.

**Status:** ready-for-agent

- [ ] Aba **Outliers por Consultor** presente no arquivo anual, na granularidade consultor
- [ ] Colunas de fazendas atendidas, fazendas marcadas e percentual
- [ ] Quebra pelos 6 indicadores, com rótulos em português
- [ ] O resumo considera apenas a última janela de cada fazenda
- [ ] Fazenda com dois consultores aparece nos dois; a soma das linhas excede o total de fazendas distintas
- [ ] Aviso no cabeçalho explicando por que a soma excede o total de fazendas distintas
- [ ] A aba não passa pelo preenchimento de numéricos vazios com zero
- [ ] As quatro abas atuais continuam com os mesmos nomes, cabeçalhos e ordem de colunas
