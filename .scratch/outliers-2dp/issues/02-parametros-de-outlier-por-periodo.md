# 02 — Parâmetros de outlier por período e aba "Parâmetros de Outlier"

**What to build:** O analista abre o arquivo Excel anual e encontra uma aba nova, **Parâmetros de Outlier**, com uma linha por `annual_period` × indicador trazendo `n`, média, desvio padrão, limite inferior e limite superior. É a aba que torna qualquer marcação futura conferível à mão: sem ela, ninguém reconstrói por que uma fazenda foi marcada.

Esta fatia estabelece o caminho completo — configuração declarativa → cálculo estatístico → preparação para Excel → aba no arquivo — para os 6 indicadores anuais do spec, sem ainda classificar linha nenhuma.

Decisões que esta fatia implementa:

- **Base de cálculo dos parâmetros**: apenas linhas com `filter_1 == 1` (uma linha por fazenda-período; elimina o peso duplo das fazendas com dois ou mais consultores) **e** `annual_consistency_id == 0` (dado reconhecidamente ruim não define o próprio limite).
- **Agrupamento por `annual_period`**, para neutralizar tendência de preço e de safra entre janelas móveis.
- **Desvio padrão amostral** (`ddof=1`) e limites em `média ± 2·DP`. Sem transformação log, sem MAD — o método é literal e refazível à mão no Excel de propósito.
- **N mínimo de 30 fazendas por período**: períodos abaixo do mínimo não geram parâmetro. Períodos com uma única fazenda (DP indefinido) caem por esse mesmo caminho, sem quebrar a execução.
- **Multiplicador (2) e N mínimo (30) são parâmetros nomeados** da célula, não literais espalhados pela lógica.
- **Limites reais são expostos**, mesmo quando um dos lados é impossível na prática (limite inferior negativo em litros/hectare, limite superior acima de 100% em RBL/RBA). A limitação fica visível em vez de mascarada.

A configuração dos 6 indicadores vive numa **estrutura declarativa única** — rótulo em português, unidade e formato — no mesmo padrão das listas de regras de consistência já existentes no notebook, de modo que acrescentar ou remover um indicador seja editar só essa estrutura, sem tocar na lógica.

Toda a lógica fica numa **função pura** definida no topo da própria célula: recebe o DataFrame anual e a configuração (mais N mínimo e multiplicador), sem I/O, sem banco, sem SharePoint, sem estado global. Ela cresce nas fatias seguintes; aqui devolve os parâmetros.

A aba nova passa pela preparação para Excel **sem** o preenchimento de numéricos vazios com zero, para preservar a diferença entre "não avaliado" e "zero".

**Blocked by:** 01 — Backup do notebook, seção nova posicionada e renumeração.

**Status:** ready-for-agent

- [ ] Estrutura declarativa única configura os 6 indicadores com rótulo em português, unidade e formato
- [ ] N mínimo e multiplicador de desvios são parâmetros nomeados
- [ ] Base de parâmetros restrita a `filter_1 == 1` e `annual_consistency_id == 0`; sobre a base da exportação de 13/08 isso dá ≈ 3.152 das 7.566 linhas anuais
- [ ] Parâmetros agrupados por `annual_period`, com DP amostral (`ddof=1`)
- [ ] Períodos abaixo do N mínimo não geram parâmetro e não quebram a execução; períodos com uma única fazenda caem no mesmo caminho
- [ ] Sobre a base da exportação de 13/08, 20 dos 33 períodos produzem parâmetro
- [ ] Aba **Parâmetros de Outlier** presente no arquivo anual, com `annual_period`, indicador, `n`, média, DP, limite inferior e limite superior
- [ ] Limites aparecem com os valores reais, inclusive quando um dos lados é impossível na prática
- [ ] A aba nova não passa pelo preenchimento de numéricos vazios com zero
- [ ] As quatro abas atuais continuam com os mesmos nomes, cabeçalhos e ordem de colunas
- [ ] Rótulos e cabeçalhos da aba nova em português
