# Análise de Outliers (média ± 2 desvios padrão) nos indicadores anuais

Status: ready-for-agent

> **⚠️ Atualizado em 19/08/2026 — ver [Addendum](#addendum-19082026--fusão-com-o-filtro-de-consistência-anual) no final do documento.**
> A premissa "estritamente aditivo, nunca mistura com consistência" (Problem Statement, Solution, User Story 26 e as duas primeiras linhas de Out of Scope) foi **revertida por decisão de negócio**: o outlier passou a alterar `annual_consistency_status` e a propagar para o Supabase. `annual_consistency_id` (numérico) e o nível mensal continuam intocados, exatamente como aqui descrito.

## Problem Statement

Hoje a consistência dos indicadores é avaliada só por **limites fixos**, calibrados à mão nas regras mensais (`REGRAS_DETALHADAS`, seção 3.7) e anuais (`REGRAS_ANUAIS_DETALHADAS`, seção 4.2). Esses limites são absolutos: valem igual para qualquer janela anual e para qualquer composição do grupo de fazendas.

Como consequência, o consultor não enxerga o caso mais comum de alerta útil: a fazenda que está **dentro** do limite absoluto e, ainda assim, **muito fora do padrão do grupo** naquela janela. Preço de concentrado, margem por litro e produtividade por área mudam de patamar entre safras e entre janelas de 12 meses; um teto fixo não acompanha esse movimento. Hoje, para descobrir quem destoa, o consultor teria que exportar o anual, montar média e desvio padrão por período no Excel e comparar fazenda a fazenda — trabalho manual, não repetível e não auditável.

Falta também um recorte por consultor: não há como olhar a carteira de um consultor e ver quantas das fazendas que ele atende estão fora do padrão do grupo, e em quais indicadores.

## Solution

Uma nova seção no notebook principal produz um **diagnóstico relativo, separado e não intrusivo**: para 6 indicadores anuais, calcula média e desvio padrão **por `annual_period`** e marca como *outlier* toda linha fora de `média ± 2·DP`.

O resultado é entregue como **três abas novas** no arquivo Excel anual já existente:

- **Outliers** — consolidado fazenda × indicador marcado, com número de janelas em que a fazenda caiu fora, primeira e última janela marcada e os números da janela mais recente. Separa "caiu fora uma vez" de "está fora há três anos".
- **Parâmetros de Outlier** — `annual_period` × indicador, com `n`, média, DP e os dois limites. É a aba que torna a marcação conferível à mão.
- **Outliers por Consultor** — resumo da carteira de cada consultor sobre a última janela de cada fazenda, com quebra pelos 6 indicadores.

O diagnóstico é **estritamente aditivo**: não altera `consistency_id` / `annual_consistency_id`, não muda o `Cálculo de Médias`, não muda o arquivo mensal e não muda o que sobe para o Supabase. Quem hoje consome o anual continua vendo exatamente os mesmos números nas quatro abas atuais.

Os 6 indicadores cobertos:

| # | Indicador | Coluna anual | Unidade |
|---|---|---|---|
| 1 | Preço médio do concentrado | `concentrate_mineral_price_annual` | R$/kg |
| 2 | Margem líquida unitária | `net_margin_liter_annual` | R$/litro |
| 3 | Produção/mão de obra total | `milk_total_labor_day_annual` | litros/trabalhador/dia |
| 4 | Produção/área destinada à atividade | `milk_hectare_activity_annual` | litros/hectare/ano |
| 5 | Produção/área considerando reserva | `milk_hectare_activity_com_reserva_annual` | litros/hectare/ano |
| 6 | Renda do leite/renda atividade | `rbl_rba_percentage_annual` | % |

## User Stories

1. Como consultor da Labor Rural, quero ver quais fazendas estão fora de média ± 2 desvios padrão do grupo em cada janela anual, para identificar casos que os limites fixos não pegam.
2. Como consultor, quero que essa análise use como referência apenas fazendas do **mesmo `annual_period`**, para que tendência de preço e de safra não contaminem a comparação.
3. Como consultor, quero um relatório **consolidado por fazenda**, para não precisar ler as até 40 janelas móveis da mesma fazenda uma a uma.
4. Como consultor, quero saber em **quantas janelas** a fazenda foi marcada em cada indicador, para distinguir um episódio isolado de um desvio persistente.
5. Como consultor, quero ver a **primeira e a última janela** em que a fazenda foi marcada, para saber quando o desvio começou e se ainda está aberto.
6. Como consultor, quero ver o **valor da fazenda, a média, o DP, os dois limites e o z** da janela mais recente marcada, para julgar a gravidade sem abrir outra aba.
7. Como consultor, quero saber se a fazenda ficou **acima** ou **abaixo** do limite, porque as duas pontas têm interpretações de negócio opostas.
8. Como consultor, quero uma **contagem de 0 a 6 indicadores** marcados por linha, para priorizar as fazendas que destoam em várias frentes ao mesmo tempo.
9. Como consultor, quero um **status por linha** (`Outlier` / `Normal` / `Amostra insuficiente`), para filtrar a planilha rapidamente.
10. Como consultor, quero uma coluna com a **lista dos indicadores marcados** em texto, para ler o motivo sem interpretar códigos.
11. Como consultor, quero um **detalhamento em texto** no mesmo formato de `annual_violated_consistency_details`, para reaproveitar a leitura que já faço da aba de consistência.
12. Como consultor, quero que indicador sem valor apareça como **`Não avaliado`**, e não como "dentro do padrão", para não confundir ausência de dado com normalidade.
13. Como analista da Labor Rural, quero uma aba com **`n`, média, DP e limites por período e indicador**, para conferir na mão por que uma fazenda foi marcada.
14. Como analista, quero refazer a conta de um caso no Excel a partir da aba de parâmetros e **chegar exatamente ao mesmo resultado**, porque auditabilidade é o motivo de o método ter sido mantido literal.
15. Como analista, quero que os parâmetros sejam calculados **só sobre `filter_1 == 1`**, para que as 133 fazendas com dois ou mais consultores não entrem com peso dobrado na média do grupo.
16. Como analista, quero que os parâmetros sejam calculados **só sobre `annual_consistency_id == 0`**, para que dado reconhecidamente ruim não defina o próprio limite.
17. Como analista, quero que a **classificação** seja aplicada a **todas** as linhas anuais — inclusive inconsistentes e duplicadas por consultor — mesmo que elas não entrem no cálculo dos parâmetros, para que nenhuma fazenda fique sem diagnóstico.
18. Como analista, quero um **N mínimo de 30 fazendas** por período, para não gerar limite a partir de amostra pequena demais.
19. Como analista, quero que períodos abaixo do N mínimo produzam `Amostra insuficiente` em vez de erro ou de valor inventado, para que a lacuna fique explícita.
20. Como analista, quero que períodos com uma única fazenda (DP indefinido) caiam nesse mesmo caminho, sem quebrar a execução.
21. Como gestor, quero um **resumo por consultor** com fazendas atendidas, fazendas marcadas e percentual, para enxergar a carteira de cada um.
22. Como gestor, quero que esse resumo considere a **última janela de cada fazenda**, para não contar a mesma fazenda várias vezes por causa das janelas móveis.
23. Como gestor, quero a quebra do resumo **pelos 6 indicadores**, para saber se o problema da carteira é de custo, de produtividade ou de composição de renda.
24. Como gestor, quero que uma fazenda com dois consultores apareça **para os dois**, porque a responsabilidade é compartilhada.
25. Como gestor, quero um aviso no cabeçalho de que, por isso, a soma das linhas **excede** o total de fazendas distintas, para não interpretar mal o total.
26. Como responsável pelos indicadores, quero que `consistency_id`, `annual_consistency_id`, `consistency_status` e `annual_consistency_status` fiquem **intactos**, porque a análise nova é diagnóstico, não regra de consistência.
27. Como responsável pelos indicadores, quero que as **regras fixas** de Produção/MDO e Produção/área continuem valendo como estão, sem serem substituídas pelo critério relativo.
28. Como responsável pelos indicadores, quero que o `Cálculo de Médias` continue com **as mesmas linhas e as mesmas colunas**, porque ele alimenta consumidores externos.
29. Como responsável pelos indicadores, quero que a **ingestão no Supabase** não mude, porque a análise nova não deve virar dado de sistema.
30. Como responsável pelos indicadores, quero que o **arquivo mensal** não seja afetado de forma alguma.
31. Como consumidor do Excel anual, quero que as **quatro abas atuais** continuem com os mesmos nomes, cabeçalhos e ordem, para não quebrar minhas planilhas e meus filtros.
32. Como consumidor do Excel anual, quero as três abas novas com **nomes estáveis** — `Outliers`, `Parâmetros de Outlier`, `Outliers por Consultor` — para poder referenciá-las.
33. Como analista, quero que as colunas anexadas à aba *Indicadores Anuais* sejam **texto e contagem inteira**, nunca z-score, porque o preenchimento de numéricos vazios com zero transformaria "não avaliado" em "exatamente na média".
34. Como analista, quero que os **z-scores** existam apenas nas abas novas, que não passam por esse preenchimento com zero.
35. Como analista, quero ver os **limites reais** na aba de parâmetros mesmo quando um dos lados é impossível na prática (limite inferior negativo em litros/hectare, limite superior acima de 100% em RBL/RBA), para que a limitação fique visível em vez de escondida.
36. Como analista, quero que o método seja **média ± 2·DP amostral**, sem transformação log e sem MAD, para que a conta seja refazível à mão por qualquer pessoa da equipe.
37. Como analista, quero que a análise rode **apenas no nível anual**, porque cinco dos seis indicadores só existem no bloco anual e versões mensais improvisadas não bateriam com os números anuais publicados.
38. Como desenvolvedor do notebook, quero que a seção nova **apenas leia** os DataFrames anuais já montados e devolva colunas e DataFrames novos, sem tocar na célula de 34 mil caracteres da 4.2.
39. Como desenvolvedor do notebook, quero que a seção nova fique **entre a padronização e a exportação anual**, para que a exportação já encontre tudo pronto.
40. Como desenvolvedor do notebook, quero que as seções seguintes sejam **renumeradas** de forma consistente (exportação e ingestão), para o notebook continuar legível na ordem das células.
41. Como desenvolvedor do notebook, quero um **backup do notebook** antes da edição, conforme a praxe da pasta de backup.
42. Como desenvolvedor do notebook, quero que a configuração dos 6 indicadores fique numa **estrutura declarativa única** com rótulo em português, unidade e formato, no mesmo padrão das listas de regras já existentes.
43. Como desenvolvedor do notebook, quero poder **acrescentar ou remover um indicador** editando só essa estrutura, sem mexer na lógica.
44. Como desenvolvedor do notebook, quero que o **N mínimo e o multiplicador de desvios** sejam parâmetros nomeados, para calibrar sem reescrever a célula.
45. Como responsável pela validação, quero **números de referência** medidos sobre a exportação de 13/08 para comparar após a implementação, e saber que desvio grande indica erro de agrupamento ou filtro, não mudança de dado.
46. Como responsável pela validação, quero uma **regressão explícita** comparando status e ids de consistência e a contagem de colunas do `Cálculo de Médias` com a exportação anterior.
47. Como responsável pela validação, quero **abrir o arquivo gerado** e confirmar as sete abas e que a aba de indicadores anuais não ganhou coluna numérica indevidamente zerada.
48. Como consultor, quero entender que ~26% das linhas marcadas é **estrutural** (6 indicadores × ~5% cada, sobre janelas móveis sobrepostas), para não interpretar o volume como falha do método.
49. Como consultor, quero que o relatório seja **consolidado por fazenda justamente por causa disso**, para que o volume de linhas não inviabilize o uso.
50. Como usuário dos arquivos da Labor Rural, quero que todos os rótulos, cabeçalhos e textos novos estejam **em português**, coerentes com o restante do notebook e dos arquivos exportados.

## Implementation Decisions

### Escopo e posicionamento

- A análise é um **diagnóstico paralelo**, não uma regra de consistência. Nenhum campo de consistência existente (mensal ou anual) muda de valor, de tipo ou de significado.
- A análise roda **somente no nível anual**. Levantamento feito sobre o notebook: dos 6 indicadores pedidos, só `milk_total_labor_day` existe hoje no nível mensal; `net_margin_liter_annual` depende de `cot_annual`, montado apenas na seção de indicadores derivados anuais, e "produção/área" é litros/hectare/**ano** por definição. Criar versões mensais improvisadas produziria números que não batem com os anuais.
- Uma seção nova (um markdown + uma célula de código) entra **entre a padronização de colunas anuais e a exportação anual**. As seções seguintes (exportação e ingestão no Supabase) são renumeradas. O notebook continua executável na ordem das células.
- A célula de indicadores derivados anuais e regras de consistência anual **não é tocada**. A seção nova apenas **lê** o DataFrame de indicadores anuais e o DataFrame anual completo (que carrega `filter_1` e o consultor) e **devolve** colunas e DataFrames novos.
- Backup do notebook antes da edição, na pasta de backup do app, com sufixo indicando o estado pré-alteração.

### Método estatístico

- **Agrupamento por `annual_period`** — neutraliza tendência de preço e de safra entre janelas móveis.
- **Base de cálculo dos parâmetros**: linhas com `filter_1 == 1` (uma linha por fazenda-período, elimina o peso duplo das fazendas com dois ou mais consultores) **e** `annual_consistency_id == 0` (dado inconsistente não define o próprio limite). Na exportação de 13/08 isso dá 3.152 das 7.566 linhas anuais.
- **N mínimo = 30 fazendas por período.** Períodos abaixo do mínimo não geram parâmetro; suas linhas saem como `Amostra insuficiente`. Na base atual, 13 dos 33 períodos ficam de fora, mas isso atinge só 68 linhas (0,9%) — 9 desses períodos têm uma única fazenda, onde o DP é indefinido.
- **Critério**: `valor < média − 2·DP` ou `valor > média + 2·DP`, com **DP amostral** (`ddof=1`, o padrão do pandas).
- **Sem transformação log e sem MAD.** Decisão consciente: mantém o método literal pedido e refazível à mão no Excel. A auditabilidade foi considerada mais valiosa que a robustez estatística adicional, dado que o produto é um relatório de conversa com o consultor.
- **Classificação aplicada a todas as linhas anuais** (inclusive inconsistentes e duplicadas por consultor), contra os parâmetros da base filtrada.
- **Uma violação já marca a linha** como `Outlier`; a contagem de 0 a 6 serve para ordenar gravidade. Indicador com valor ausente vira `Não avaliado` naquele indicador e não conta como violação.
- **Multiplicador (2) e N mínimo (30) são parâmetros nomeados** da célula, não literais espalhados pela lógica.

### Configuração dos indicadores

Estrutura declarativa única, no mesmo padrão das listas de regras já existentes no notebook (tupla com rótulo em português, unidade e formato). Acrescentar ou remover indicador é editar só esta estrutura:

```python
INDICADORES_OUTLIER = {
    "concentrate_mineral_price_annual":          ("Preço médio do concentrado", "R$/kg", ".2f"),
    "net_margin_liter_annual":                   ("Margem líquida unitária", "R$/litro", ".2f"),
    "milk_total_labor_day_annual":               ("Produção/mão de obra total", "litros/trabalhador/dia", ".1f"),
    "milk_hectare_activity_annual":              ("Produção/área destinada à atividade", "litros/hectare/ano", ".0f"),
    "milk_hectare_activity_com_reserva_annual":  ("Produção/área destinada à atividade considerando reserva", "litros/hectare/ano", ".0f"),
    "rbl_rba_percentage_annual":                 ("Renda do leite/renda atividade", "%", ".2f"),
}
```

### Colunas anexadas à base anual

Anexadas ao DataFrame de indicadores anuais (e, portanto, visíveis na aba *Indicadores Anuais*):

- `is_outlier_<coluna>` — uma por indicador, **texto**: `Acima` / `Abaixo` / `Normal` / `Não avaliado`;
- `outlier_count_annual` — **inteiro** de 0 a 6;
- `outlier_status_annual` — `Outlier` / `Normal` / `Amostra insuficiente`;
- `outlier_indicators_annual` — lista dos rótulos marcados em texto, ou `Nenhum`;
- `outlier_details_annual` — texto no mesmo formato de `annual_violated_consistency_details`, por exemplo: `Preço médio do concentrado (Acima: 4,10 R$/kg; faixa 0,50 a 3,30; z=+3,1)`.

**Nenhuma coluna de z-score é anexada à base anual.** Motivo: o preenchimento de numéricos vazios com zero aplicado na exportação preenche NaN com 0 em toda coluna numérica que tenha algum dado — um z ausente ("não avaliado") viraria `0`, que lê como "exatamente na média". Os z-scores vivem apenas nas abas novas, que passam pela preparação para Excel **sem** esse preenchimento.

### DataFrames de saída

1. **Consolidado de outliers** — granularidade **fazenda × indicador marcado**. Traz identificação da fazenda, consultor, indicador, número de janelas marcadas, primeira e última janela marcada e valor/média/DP/limites/z **da janela mais recente marcada**. Colapsa as até 40 repetições da mesma fazenda em uma linha por indicador e separa desvio episódico de desvio persistente.
2. **Parâmetros de outlier** — granularidade `annual_period` × indicador: `n`, média, DP, limite inferior, limite superior. É o que torna a marcação conferível; sem ela ninguém reconstrói por que uma fazenda foi marcada.
3. **Resumo por consultor** — granularidade consultor, sobre a **última janela de cada fazenda**: fazendas atendidas, fazendas marcadas, percentual e quebra pelos 6 indicadores. Cada vínculo conta (fazenda com dois consultores aparece para os dois), com nota no cabeçalho de que a soma excede o total de fazendas distintas.

### Exportação

Três abas acrescentadas à chamada de exportação multi-abas anual já existente, sem alterar as quatro atuais nem seus nomes:

- `Outliers`
- `Parâmetros de Outlier`
- `Outliers por Consultor`

As abas novas passam pela preparação para Excel **sem** o preenchimento de numéricos vazios com zero, para preservar a diferença entre "não avaliado" e "zero".

### Limitação conhecida e aceita

Em 3 dos 6 indicadores, um dos lados nunca dispara na base atual: `milk_hectare_activity_annual` produz limite inferior negativo (−6.079 litros/hectare/ano) e `rbl_rba_percentage_annual` produz limite superior de 106,4% (acima do teto natural de 100%). A decisão é **expor os limites na aba de parâmetros** em vez de mascarar o efeito — a limitação fica visível para quem lê o relatório.

### Efeito esperado (medido sobre a exportação de 13/08)

~1.950 linhas marcadas (25,8% de 7.566), ~5% por indicador, 232 das 460 fazendas marcadas em alguma janela. O volume é estrutural (6 indicadores × ~5% cada, sobre janelas móveis sobrepostas) e é exatamente o motivo de o relatório principal ser consolidado por fazenda, e não por janela.

## Testing Decisions

### O que é um bom teste aqui

O projeto **não tem suíte de testes automatizados** — o fluxo é um notebook executado de ponta a ponta contra o banco. Um bom teste, neste contexto, verifica **comportamento externo observável**: os números do relatório e o conteúdo do arquivo exportado. Não verifica como as colunas foram montadas internamente, nem a ordem das operações do pandas. A regra prática: se a implementação for reescrita mantendo os mesmos números e as mesmas abas, o teste deve continuar passando.

### Seams (poucas, e as mais altas possíveis)

**Seam principal — existente: o arquivo Excel anual exportado.** É o produto final e o mesmo ponto que a validação do projeto já usa (o AGENTS.md exige, ao final, abrir o arquivo gerado e conferir abas, cabeçalhos, número de linhas e tipos). Cobre de uma vez o comportamento novo (três abas com os números esperados) e a garantia de não-regressão (quatro abas antigas idênticas). Nenhuma seam nova é necessária para isso.

**Seam secundária — nova, uma só: uma função pura de cálculo de outliers.** Toda a lógica da célula nova fica numa função única, definida no topo da própria célula, que recebe o DataFrame anual e a configuração de indicadores (mais N mínimo e multiplicador) e devolve o DataFrame anotado e os três DataFrames de saída. Sem I/O, sem banco, sem SharePoint, sem estado global. Isso permite exercitá-la com um DataFrame sintético pequeno dentro do próprio notebook, verificando os casos de fronteira sem depender de uma execução completa.

Justificativa de não subir a função para o repositório compartilhado de funções (`lr-functions`): ela é específica deste relatório e ainda não está estabilizada; movê-la agora criaria acoplamento entre repositórios para ganho nenhum. Se a análise virar rotina e for reaproveitada, a extração é um passo posterior.

### Verificações de comportamento novo

Executar o notebook a partir da seção de agregação anual (a seção nova depende dos DataFrames anuais já montados) e conferir, sobre a mesma base de entrada da exportação de 13/08:

- base de parâmetros ≈ **3.152** linhas em **20** períodos válidos (de 33);
- linhas com `Amostra insuficiente` ≈ **68**;
- linhas com status `Outlier` ≈ **1.950** (25,8%);
- por indicador, entre **363 e 539** linhas marcadas;
- distribuição da contagem: ~1.308 linhas com 1 indicador, 427 com 2, 166 com 3, 29 com 4, 20 com 5.

Desvio grande em relação a esses números indica **erro de agrupamento ou de filtro**, não mudança de dado.

Casos de fronteira a exercitar com amostra sintética pequena (sem dado real de cliente, conforme AGENTS.md):

- período com `n` exatamente no mínimo e logo abaixo dele;
- período com uma única fazenda (DP indefinido);
- indicador com valor ausente → `Não avaliado`, sem contar como violação;
- valor exatamente no limite (não marca) e imediatamente fora dele (marca);
- fazenda com dois consultores: entra uma vez só na base de parâmetros e aparece para os dois no resumo por consultor;
- fazenda marcada em várias janelas: colapsa em uma linha por indicador, com primeira e última janela corretas e os números vindos da janela mais recente.

### Verificações de regressão (obrigatórias)

- `annual_consistency_status`, `annual_consistency_id` e a contagem de colunas do `Cálculo de Médias` **idênticos** à exportação anterior;
- o arquivo gerado tem **sete abas**, e a aba *Indicadores Anuais* **não ganhou nenhuma coluna numérica zerada indevidamente**;
- o arquivo mensal e a ingestão no Supabase inalterados.

### Conferência manual (auditabilidade)

Pegar uma fazenda marcada, ler `n`, média, DP e limites na aba *Parâmetros de Outlier* para aquele `annual_period` e **refazer a conta no Excel**. Tem de bater exatamente — é essa auditabilidade que justificou manter o método literal em vez de log ou MAD. Conferir também, no resumo por consultor, que uma fazenda com `filter_1 == 2` aparece nos dois consultores e que o total geral não é a soma simples das linhas.

### Prior art

- Formato de detalhamento em texto: `annual_violated_consistency_details`, montado na seção de regras anuais.
- Estrutura declarativa de configuração: `REGRAS_ANUAIS_DETALHADAS` e `REGRAS_DETALHADAS`.
- Preparação e exportação multi-abas: a exportação anual atual, com suas quatro abas.
- Roteiro de validação: a seção "Validação antes de concluir" do AGENTS.md (unicidade na granularidade, contagem de propriedades e períodos antes/depois, nulos e divisões por zero, conferência do arquivo gerado).

## Out of Scope

- **Nível mensal.** Nenhuma versão mensal dos indicadores é criada, e a análise não roda sobre a base mensal.
- **Alteração das regras de consistência.** Os limites fixos mensais e anuais continuam como estão; a análise nova não substitui, não relaxa e não endurece nenhum deles.
- **Alteração de `consistency_id`, `annual_consistency_id` e dos status correspondentes.**
- **`Cálculo de Médias`** — nenhuma linha excluída, nenhuma coluna acrescentada.
- **Ingestão no Supabase** — as colunas de outlier não sobem para o banco.
- **Arquivo mensal** — intacto.
- **Métodos estatísticos alternativos** — log, MAD, IQR, winsorização, z robusto: fora de escopo por decisão explícita de auditabilidade.
- **Agrupamentos alternativos** — por sistema de produção, por faixa de tamanho, por região: o agrupamento é só por `annual_period`.
- **Multiplicador configurável pelo usuário final** ou parametrização via planilha externa: o multiplicador é parâmetro de código, não de configuração de negócio.
- **Extração da lógica para o repositório compartilhado de funções.**
- **Envio automático do relatório a consultores** (e-mail, SharePoint, notificação): a entrega é o arquivo Excel anual.
- **Interface, dashboard ou visualização** dos outliers.
- **Ação corretiva sobre as fazendas marcadas** — o produto é diagnóstico.

## Further Notes

- Os números de referência (3.152 linhas de base, ~1.950 marcadas, 68 insuficientes) foram medidos sobre `data/outputs/annual/2026_08_13_144244_indicadores_anuais.xlsx`. Se a base de entrada mudar, eles mudam junto — servem como âncora de regressão apenas contra a **mesma** exportação.
- O volume de ~26% de linhas marcadas não é sinal de erro: com 6 indicadores a ~5% cada e janelas móveis sobrepostas, o acúmulo é esperado. O consolidado por fazenda existe exatamente para tornar esse volume utilizável.
- A escolha de `filter_1 == 1` na base de parâmetros e "todos os vínculos" no resumo por consultor é deliberadamente assimétrica: a estatística do grupo precisa de uma linha por fazenda-período; a responsabilidade sobre a fazenda é compartilhada entre os consultores.
- O ponto mais frágil da implementação é o preenchimento de numéricos vazios com zero na exportação. Qualquer coluna numérica nova anexada à base anual passa a ser afetada por ele. Se no futuro alguém quiser o z-score na aba *Indicadores Anuais*, terá de tratar a exceção nesse preenchimento — não basta anexar a coluna.
- Se em algum momento o critério relativo se mostrar mais confiável que os limites fixos para Produção/MDO e Produção/área, a substituição é uma decisão de negócio separada, com seu próprio spec.

## Addendum (19/08/2026) — Fusão com o filtro de consistência anual

Decisão de negócio posterior a este spec: o diagnóstico de outlier deixou de ser puramente aditivo/paralelo e passou a **alterar o próprio filtro de consistência anual**. Este addendum documenta o que mudou e o que continua valendo do spec original.

**O que mudou:**

- `annual_consistency_status` (texto) passa a ter **três** valores em vez de dois: `Inconsistente`, `Consistente`, `Outlier`. Uma fazenda que hoje seria `Consistente` mas está marcada `outlier_status_annual == "Outlier"` em pelo menos 1 dos 6 indicadores rastreados passa a ser classificada como `Outlier`.
- **Prioridade**: `Inconsistente` sempre vence sobre `Outlier` — uma fazenda só vira `Outlier` se `annual_consistency_id == 0`.
- Como `Status - Ind. Anuais` (aba `Cálculo de Médias`) e a ingestão no Supabase (`consistencia_anual` em `tab_consistencia_anual`) leem `annual_consistency_status`, **ambas passam a receber o valor `Outlier` também** — isto reverte especificamente os itens "Ingestão no Supabase" e a garantia de `Cálculo de Médias` inalterado no texto de `Out of Scope` abaixo (as colunas e a contagem de linhas continuam as mesmas; só o *valor* de uma coluna existente muda).

**O que continua valendo, sem alteração:**

- `annual_consistency_id` (numérico, 0/1) **permanece binário e intocado** — continua sendo usado apenas internamente pela seção 4.4 para filtrar a população de referência (`filter_1 == 1 & annual_consistency_id == 0`) do cálculo de média/desvio. Não foi estendido para 3 valores, para não criar um ciclo (o outlier depende dele; ele não pode depender do outlier).
- `consistency_id` / `consistency_status` (nível **mensal**) continuam intocados — a fusão é só no nível anual.
- As regras fixas mensais e anuais de consistência (`REGRAS_DETALHADAS`, `REGRAS_ANUAIS_DETALHADAS`) não mudam.
- O método estatístico do outlier (média ± 2 DP amostral por `annual_period`, N mínimo 30, base `filter_1==1 & annual_consistency_id==0`) não muda — só o que se faz com o resultado (`outlier_status_annual`) muda.
- As três abas novas (`Outliers`, `Parâmetros de Outlier`, `Outliers por Consultor`) e as colunas anexadas à base anual (`is_outlier_<coluna>`, `outlier_count_annual`, `outlier_status_annual`, `outlier_indicators_annual`, `outlier_details_annual`) continuam existindo sem alteração — a fusão só lê `outlier_status_annual`, não substitui nenhuma delas.
- O arquivo mensal continua intacto.

**Implementação**: nova seção "4.4.2 Consolidação do Filtro de Consistência Anual" em `app/Elabore Indicadores.ipynb`, inserida entre a verificação sintética de outliers (4.4.1) e a exportação Excel (4.5). Sincroniza tanto `df_indicadores_anuais["annual_consistency_status"]` quanto `df_calculo_medias["Status - Ind. Anuais"]` (por chave `id_property`+`annual_period`, não por posição — ver nota técnica no plano de implementação).
