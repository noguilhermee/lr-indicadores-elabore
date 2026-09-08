# 04 — Aba "Outliers": consolidado por fazenda × indicador

**What to build:** O consultor abre a aba nova **Outliers** e lê, em **uma linha por fazenda × indicador marcado**, quem destoa do grupo e com que gravidade — sem precisar percorrer as até 40 janelas móveis da mesma fazenda uma a uma. É o relatório principal da análise, e a razão de ele ser consolidado é o volume: ~26% das linhas anuais são marcadas, o que é estrutural (6 indicadores a ~5% cada, sobre janelas móveis sobrepostas), não falha do método.

Cada linha traz:

- identificação da fazenda e o consultor;
- o indicador marcado, pelo rótulo em português;
- o **número de janelas** em que a fazenda foi marcada naquele indicador — é o que separa um episódio isolado de um desvio persistente de três anos;
- a **primeira e a última janela** marcadas — quando o desvio começou e se ainda está aberto;
- da **janela mais recente marcada**: o valor da fazenda, a média, o DP, os dois limites, o z e o lado (`Acima` / `Abaixo`) — para julgar a gravidade sem abrir outra aba.

Os z-scores aparecem aqui porque esta aba passa pela preparação para Excel **sem** o preenchimento de numéricos vazios com zero.

**Blocked by:** 03 — Classificação por linha e colunas de outlier na aba Indicadores Anuais.

**Status:** ready-for-agent

- [ ] Aba **Outliers** presente no arquivo anual, na granularidade fazenda × indicador marcado
- [ ] Uma fazenda marcada em várias janelas colapsa em uma linha por indicador, com contagem de janelas correta
- [ ] Primeira e última janela marcadas corretas
- [ ] Valor, média, DP, limite inferior, limite superior, z e lado vêm da janela **mais recente** marcada
- [ ] Sobre a base de 13/08, 232 das 460 fazendas aparecem marcadas em alguma janela
- [ ] A aba não passa pelo preenchimento de numéricos vazios com zero
- [ ] Rótulos e cabeçalhos em português; indicadores identificados pelo rótulo, não pelo nome da coluna
- [ ] As quatro abas atuais continuam com os mesmos nomes, cabeçalhos e ordem de colunas
