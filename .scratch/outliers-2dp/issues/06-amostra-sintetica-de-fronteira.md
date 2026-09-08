# 06 — Amostra sintética exercitando os casos de fronteira

**What to build:** Qualquer pessoa que abra o notebook consegue rodar a função de cálculo de outliers contra um DataFrame sintético pequeno e ver os casos de fronteira se comportarem como o spec descreve — sem depender de uma execução completa contra o banco e sem usar dado real de cliente.

A função de cálculo é a seam desenhada para isto: pura, definida no topo da célula da seção nova, recebendo o DataFrame anual e a configuração de indicadores (mais N mínimo e multiplicador) e devolvendo o DataFrame anotado e os três DataFrames de saída. Sem I/O, sem banco, sem SharePoint, sem estado global.

O teste verifica **comportamento externo observável** — os números que saem da função. Se a implementação for reescrita mantendo os mesmos números, o teste deve continuar passando; ele não verifica como as colunas foram montadas internamente nem a ordem das operações do pandas.

A função **não sobe** para o repositório compartilhado de funções: ela é específica deste relatório e ainda não está estabilizada. Se a análise virar rotina, a extração é um passo posterior.

**Blocked by:** 04 — Aba "Outliers": consolidado por fazenda × indicador; 05 — Aba "Outliers por Consultor": resumo de carteira.

**Status:** ready-for-agent

- [ ] Amostra sintética construída dentro do notebook, sem dado real de cliente
- [ ] Período com `n` exatamente no mínimo gera parâmetro; logo abaixo do mínimo, não
- [ ] Período com uma única fazenda (DP indefinido) sai como `Amostra insuficiente` sem quebrar a execução
- [ ] Indicador com valor ausente → `Não avaliado`, sem contar como violação
- [ ] Valor exatamente no limite não marca; imediatamente fora dele marca
- [ ] Fazenda com dois consultores entra uma vez só na base de parâmetros e aparece para os dois no resumo por consultor
- [ ] Fazenda marcada em várias janelas colapsa em uma linha por indicador, com primeira e última janela corretas e os números vindos da janela mais recente
- [ ] A verificação roda contra a função pura, sem I/O, banco, SharePoint ou estado global
