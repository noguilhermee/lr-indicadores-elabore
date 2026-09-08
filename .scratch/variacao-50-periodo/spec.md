# Variação >±50% entre meses consecutivos da mesma fazenda (mensal apenas)

Status: ready-for-agent

## Context

Esta spec **substitui** a versão anterior (64 user stories, escopo mensal + anual), que permanece
no histórico do git. A regra de variação ±50% existe no papel desde aquela versão, mas **nunca foi
implementada**: só o ticket 01 rodou, criando duas células placeholder vazias (3.8 mensal e 4.5
anual) que declaram literalmente não alterar nenhum DataFrame. `calcular_variacao_periodo` não
existe, `LIMITE_VARIACAO_PERCENTUAL` tem zero ocorrências, as abas `Variações` nunca foram
exportadas.

O grilling reduziu o escopo em três pontos que divergem da versão anterior:

1. **Mensal apenas** — a seção anual (4.5) é abandonada; tickets 04 e 05 saem integralmente.
2. **Coloração laranja** na aba `Indicadores Mensais` — pedido novo, ausente da versão anterior.
3. **Âncora de regressão migra de 13/08 para 18/08** — a base mudou de fonte e os números da
   versão anterior (~500 mensal, ~1.683 anual, medidos fora do notebook) são inauditáveis hoje.

## Problem Statement

O consultor que digita os dados de uma fazenda não tem hoje nenhum sinal quando o dado da fazenda
salta em relação a ela mesma. As duas famílias de checagem existentes olham para fora da fazenda:
regras de limite (3.7 mensal / 4.2 anual) comparam contra um MÍN/MÁX absoluto; outliers (4.4)
comparam a fazenda contra o grupo do mesmo `annual_period`.

Um erro de digitação que caia dentro do limite absoluto **e** dentro da nuvem das outras fazendas
— rebanho que dobra de um mês para o outro, despesa com uma casa decimal a mais, área que muda de
patamar sem compra de terra — passa sem qualquer sinalização. Só se descobre por acaso, abrindo os
dois meses lado a lado.

Isso já é dívida documentada: a aba MENSAL do `PARAMETROS_INCONSISTENCIA.xlsx` tem as linhas 24–26
(variação mensal do preço do leite, da bonificação por qualidade, do gasto com dieta / preço do
leite) previstas e nunca implementadas.

## Solution

Uma seção nova no fluxo **mensal** do notebook (3.8) marca todo indicador que variou mais de +50%
ou menos de −50% em relação ao **mês imediatamente anterior da própria fazenda**.

A marcação é **estritamente aditiva**, na mesma postura da 4.4: não altera valor, não altera
`consistency_id`/`consistency_status`, não muda o `Cálculo de Médias`, não sobe para o Supabase.
Quem consome os arquivos hoje continua vendo exatamente os mesmos números nas abas atuais.

A entrega ao usuário é:

- **Coloração laranja** nas células já existentes da aba `Indicadores Mensais`, para quem só quer
  ver o problema onde ele está;
- aba **`Variações`** — o registro auditável da regra, série inteira, uma linha por fazenda ×
  indicador × mês marcado;
- aba **`Variações por Consultor`** — a carteira de cada consultor sobre a ocorrência mais recente
  de cada fazenda.

Consequência aceita conscientemente do recorte mensal-apenas: as rubricas de custo detalhadas
ficam sem verificação de variação contra si mesmas, cobertas só pela 4.4 (contra o grupo).

## User Stories

1. Como analista de qualidade, quero que a fazenda seja comparada com ela mesma no tempo, para que
   erros de digitação que passam nos limites absolutos e nos outliers sejam capturados.
2. Como analista de qualidade, quero um limiar único e explícito de ±50%, para que a regra seja
   explicável sem consultar tabela de parâmetros.
3. Como analista de qualidade, quero que a comparação use apenas meses **consecutivos**, para que
   uma lacuna no histórico não produza variação inventada.
4. Como analista de qualidade, quero que a primeira linha de cada fazenda seja `Não avaliado`, para
   que a entrada de uma fazenda nova não vire sinalização.
5. Como analista de qualidade, quero que a transição `0 → positivo` seja classificada como
   `Entrada`, para que o primeiro lançamento de uma despesa não seja lido como variação percentual.
6. Como analista de qualidade, quero que `positivo → 0` seja classificado como `Saída`, pelo mesmo
   motivo.
7. Como analista de qualidade, quero que `0 → 0` e qualquer nulo sejam `Não avaliado`, para que a
   ausência de dado nunca seja confundida com estabilidade.
8. Como analista de qualidade, quero que a razão exatamente 1,5 e exatamente 0,5 **não** marquem,
   para manter a mesma convenção estrita da regra de outliers.
9. Como analista de qualidade, quero que a base de comparação seja o valor já deflacionado por
   IGP-DI, para que inflação não gere sinalização.
10. Como analista de qualidade, quero saber o **lado** da variação (aumento ou redução), para
    priorizar a investigação.
11. Como consultor, quero ver a célula laranja na própria aba `Indicadores Mensais`, para achar o
    problema sem trocar de aba.
12. Como consultor, quero que só `Aumento` e `Redução` sejam coloridos, para que `Entrada`/`Saída`
    não pintem a planilha inteira no primeiro mês de lançamento de uma despesa.
13. Como consultor, quero que as colunas auxiliares de marcação fiquem **ocultas**, para que a aba
    continue legível.
14. Como auditor, quero conseguir desocultar essas colunas, para conferir por que uma célula está
    laranja.
15. Como auditor, quero a aba `Variações` com a série inteira, não só o mês corrente, para que a
    regra tenha registro histórico agora que o anual saiu de escopo.
16. Como auditor, quero a aba `Variações` ordenada do mês mais recente para o mais antigo, para ver
    primeiro o que ainda dá para corrigir.
17. Como auditor, quero em cada linha da aba `Variações` a fazenda, o consultor, o indicador, o
    período, o valor anterior, o valor atual, a variação (%) e o lado, para refazer a conta à mão.
18. Como auditor, quero refazer a razão de uma fazenda marcada manualmente e chegar no mesmo
    número, para confiar na regra.
19. Como coordenador, quero a aba `Variações por Consultor` no mesmo formato do resumo por
    consultor da 4.4, para não aprender um layout novo.
20. Como coordenador, quero que o resumo por consultor use a ocorrência **mais recente** de cada
    fazenda, para não contar a mesma fazenda várias vezes.
21. Como coordenador, quero que uma fazenda com dois consultores apareça para os dois, para que
    ninguém deixe de ver a própria carteira.
22. Como coordenador, quero o aviso de cabeçalho de que a soma das linhas excede o total de
    fazendas distintas, para não somar errado.
23. Como coordenador, quero a quebra por indicador no resumo, para saber que tipo de erro predomina
    na carteira.
24. Como responsável pelos dados, quero que `consistency_id` e `consistency_status` fiquem
    inalterados em 100% das linhas, para que nada a jusante mude de comportamento.
25. Como responsável pelos dados, quero que nenhum valor de indicador seja alterado — a regra
    sinaliza, não corrige.
26. Como responsável pelos dados, quero a mesma contagem de linhas, fazendas e meses distintos
    antes e depois, para garantir que a granularidade foi preservada.
27. Como responsável pelos dados, quero nenhuma duplicata na chave `id_property` + mês de
    referência após a mudança.
28. Como responsável pelo Supabase, quero que o payload tenha exatamente as mesmas colunas de
    antes, e que as colunas de variação não entrem em `tab_consistencia_mensal`.
29. Como responsável pelo Supabase, quero o `Cálculo de Médias` com as mesmas linhas e colunas.
30. Como consumidor dos arquivos, quero as abas antigas com os mesmos nomes, cabeçalhos, número de
    linhas e tipos.
31. Como consumidor dos arquivos, quero que `Não avaliado` chegue no Excel como `Não avaliado`, e
    nunca convertido em `0` — `0` leria como "não variou".
32. Como consumidor dos arquivos, quero que o arquivo anual continue com as sete abas atuais,
    nenhuma aba nova e nenhuma cor.
33. Como consumidor dos arquivos, quero que o tamanho do arquivo mensal não exploda em relação à
    linha de base de 18 MB.
34. Como consumidor dos arquivos, quero que o tempo de exportação continue aceitável.
35. Como desenvolvedor, quero a lógica em uma **função pura**, para poder testá-la sem banco, sem
    SharePoint e sem estado global.
36. Como desenvolvedor, quero que a função faça cópia defensiva do DataFrame de entrada, para que o
    fluxo do notebook não dependa da ordem de execução.
37. Como desenvolvedor, quero a função **parametrizada** desde o início, para que o anual possa ser
    ligado depois sem reescrita.
38. Como desenvolvedor, quero reaproveitar os helpers já existentes na célula de outliers da 4.4
    (formatação numérica brasileira, dicionário de renomeação do consolidado, constante de aviso do
    resumo por consultor), em vez de criar variantes paralelas.
39. Como desenvolvedor, quero a lista de indicadores em uma estrutura declarativa `coluna →
    (rótulo, unidade, formato)`, no mesmo shape da configuração de outliers.
40. Como desenvolvedor, quero desfragmentar o DataFrame ao final, mesmo cuidado das seções 4.2/4.4.
41. Como desenvolvedor, quero uma célula de verificação com **amostra sintética**, no molde exato da
    célula 4.4.1, sem nenhum dado real de cliente, conforme `AGENTS.md`.
42. Como desenvolvedor, quero sondas de fronteira em 1,5 e 0,5 exatos e no menor incremento além de
    cada um (`np.nextafter`), porque é ali que a regra erra.
43. Como desenvolvedor, quero uma sonda de lacuna de mês, porque a continuidade é o ponto mais
    frágil da implementação.
44. Como desenvolvedor, quero uma sonda de pureza que confirme que o DataFrame de entrada não foi
    modificado.
45. Como desenvolvedor, quero que a célula de verificação levante `AssertionError` ao final se
    qualquer sonda falhar, para que a falha não passe despercebida numa execução completa.
46. Como responsável pela regra, quero **re-medir a taxa de marcação sobre a base de 18/08** antes
    de congelar a lista de indicadores, porque a base mudou de fonte depois de 13/08.
47. Como responsável pela regra, quero um critério de corte explícito de **10% das linhas
    marcadas** — acima disso o indicador sai da regra.
48. Como responsável pela regra, quero ver a tabela de taxas e **aprovar a lista final** antes de
    congelar a estrutura declarativa; nenhum indicador sai sem eu ver o número.
49. Como responsável pela regra, quero o delta entre 13/08 e 18/08, para saber se a mudança de
    fonte moveu as taxas.
50. Como responsável pela regra, quero que a re-medição rode em script **descartável** fora do
    notebook, para que nenhuma célula nova entre no fluxo de produção só para medir.
51. Como responsável pela regra, quero que o resultado da medição vire número documentado nesta
    spec, não código vivo.
52. Como responsável pelo notebook, quero backup em `app/backup/` com sufixo
    `_pre_variacao_50_mensal` antes de qualquer alteração, praxe do projeto.
53. Como responsável pelo notebook, quero as duas células placeholder da seção **4.5** apagadas e a
    `4.6 Exportação dos Arquivos Excel Anuais` renumerada de volta para `4.5`.
54. Como responsável pelo notebook, quero que essa renumeração toque só markdown — nenhuma célula
    executável muda.
55. Como responsável pelo notebook, quero que ele rode do início ao fim na ordem das células,
    parando **antes** do upsert no Supabase durante a validação.
56. Como responsável pelos parâmetros, quero apenas **conferir** que as linhas 24–26 da aba MENSAL
    do `PARAMETROS_INCONSISTENCIA.xlsx` têm MÍN −50 / MÁX +50 coerentes com o código.
57. Como responsável pelos parâmetros, quero que nenhuma edição seja feita na planilha sem novo aval
    — ela é documentação, nenhum código a lê.
58. Como responsável pela arquitetura, quero que `functions/` (o repositório compartilhado com
    `exportar_varias_abas_xlsx` e `aplicar_estilo_listrado_xlsx`) **não seja alterado** — a lógica
    de coloração fica local no notebook.
59. Como responsável pela arquitetura, quero **nenhuma aba de parâmetros** nova: o parâmetro é uma
    constante única, não há tabela a auditar.
60. Como responsável pela arquitetura, quero que a coloração use **formatação condicional por
    fórmula** via openpyxl, e não estilo célula a célula, porque a aba tem ~168 colunas × ~13 mil
    linhas.
61. Como responsável pela entrega, quero saber antes do fechamento se o volume da aba `Variações`
    ficou grande demais, para decidir se corto a série.
62. Como responsável pela entrega, quero que um desvio grande em relação à ordem de grandeza medida
    seja tratado como erro na regra de continuidade, não como mudança de dado.

## Implementation Decisions

**Escopo de tickets.** Entram 02, 03, 06, a parte mensal do 07, e o 08 rebaixado a conferência.
Saem 04 e 05 (anual) integralmente. O ticket 01 já foi executado e é parcialmente revertido
(remoção das células 4.5).

**Módulo alterado.** Apenas o notebook principal, seção 3.8 (mensal). Nada em `functions/`, nada em
`data/views/`. A seção 4.5 (anual) é removida e a numeração seguinte recuada.

**Interface da função** (célula de código da 3.8), modelada na função de outliers da 4.4:

```python
LIMITE_VARIACAO_PERCENTUAL = 50

calcular_variacao_periodo(
    df, indicadores, coluna_chave="id_property",
    coluna_ordem=..., limite_percentual=LIMITE_VARIACAO_PERCENTUAL,
    prefixo="variacao", colunas_informativas=None,
) -> (df_anotado, df_consolidado, df_por_consultor)
```

Pura: cópia defensiva na primeira linha, sem I/O, sem banco, sem SharePoint, sem estado global.
Parametrizada de nascença, para aceitar o anual sem reescrita se ele voltar como spec própria.

**Continuidade.** Ordenar por `[chave, ordem]` e comparar contra a linha anterior **só se**
`ano*12 + mês` tiver passo de exatamente 1. Reaproveitar a lógica de intervalo de períodos já usada
na agregação por janela móvel. Ponto mais frágil: passo frouxo inventa variação, passo restritivo
demais produz `Não avaliado` em massa e a feature some silenciosamente.

**Critério.** Razão `valor / valor_anterior`; marca se `> 1,5` ou `< 0,5`. Igualdade exata não
marca. Sem piso de materialidade. Base: valor bruto sobre a série já deflacionada por IGP-DI.

**Categorias.** `Aumento`, `Redução`, `Entrada` (0 → positivo), `Saída` (positivo → 0), `Normal`,
`Não avaliado` (ambos zero, qualquer nulo, lacuna de mês, primeira linha da fazenda).

**Lista de indicadores — MEDIDA E APROVADA (ticket 02).** Estrutura declarativa
`coluna → (rótulo, unidade, formato)`, mesmo shape da configuração de outliers. Medição rodada em
`.scratch/variacao-50-periodo/scripts/medir_taxa_marcacao_18_08.py` (descartável, fora do
notebook) sobre `data/outputs/monthly/2026_08_18_090514_indicadores_mensais.xlsx` — 13.303 linhas,
814 fazendas distintas, 44 meses distintos. Critério de corte: 10% das linhas marcadas.

| Indicador | Grupo | Taxa 18/08 | Ref. 13/08 | Delta (pp) | Corte 10% |
|---|---|---|---|---|---|
| Total de Vacas (cabeças) | estrutural | 0,19% | 0,2% | −0,01 | dentro |
| Preço Unitário do Leite (R$/litro) | estrutural | 0,24% | 0,3% | −0,06 | dentro |
| Área Total da Propriedade (ha) | estrutural | 0,63% | 0,8% | −0,17 | dentro |
| Produção Total de Leite (litros) | estrutural | 1,42% | 1,6% | −0,18 | dentro |
| Estoque de Capital Total (R$) | estrutural | 1,54% | 0,5–0,7% | +0,94 (vs. ponto médio 0,6) | dentro |
| Custo Total Mão de Obra (R$) | custo agregado | 3,86% | sem referência 13/08 | — | dentro |
| Custo Total com Alimentação (R$) | custo agregado | 8,46% | sem referência 13/08 | — | dentro |
| Custo de Concentrado e Mineral (R$) | custo agregado | 10,14% | sem referência 13/08 | — | **fora** |
| Outras Despesas Operacionais (R$) | custo agregado | 25,48% | sem referência 13/08 | — | **fora** |

**Lista final aprovada (7 indicadores)**, a codificar na estrutura declarativa do ticket 03:
Total de Vacas, Preço Unitário do Leite, Área Total da Propriedade, Produção Total de Leite,
Estoque de Capital Total, Custo Total Mão de Obra, Custo Total com Alimentação. Fora da lista:
Custo de Concentrado e Mineral e Outras Despesas Operacionais (ambos acima do corte de 10%).
Aprovação obtida do responsável pela regra em 19/08. As taxas estruturais de 13/08 seguem estáveis
(delta pequeno, sinal negativo — a mudança de fonte não infla marcações); Estoque de Capital Total
subiu 0,94pp mas segue bem abaixo do corte. Rubricas de custo detalhado (fora deste script,
confirmadas como fora de escopo pelo recorte mensal-apenas da spec) permanecem cobertas só pela
4.4.

Referência de 13/08 original (a que a re-medição validou): estruturais 0,2%–1,6% (Total de Vacas
0,2%, Preço do leite 0,3%, Estoque de Capital 0,5–0,7%, Área 0,8%, Produção de Leite 1,6%);
rubricas detalhadas 37%–58% (Acessórios e Despesas Gerais 57,9%, Reparos 54,2%, Material de
Ordenha 40,6%, Medicamentos 40,1%, Reprodução 37,4%).

**Coloração.** Colunas auxiliares prefixo `_var_`, uma por indicador colorido, agrupadas no fim da
aba `Indicadores Mensais` e ocultas. Formatação condicional por fórmula via openpyxl lendo essas
colunas. Laranja só em `Aumento` e `Redução`. Nenhuma coloração no arquivo anual.

**Abas novas (nomes estáveis).** `Variações` — série toda, uma linha por fazenda × indicador × mês
marcado, ordenada do mais recente para o mais antigo; colunas: fazenda, consultor, indicador,
período, valor anterior, valor atual, variação (%), lado. **Sem** `Períodos marcados` e `Primeiro
período marcado` que a versão anterior pedia — ninguém filtra por elas. `Variações por Consultor` —
formato do resumo por consultor da 4.4, sobre a ocorrência mais recente de cada fazenda, quebra por
indicador, fazenda com dois consultores aparece nos dois, com aviso de cabeçalho.

**Preparação para Excel.** As abas novas passam pela preparação **sem** o preenchimento de
numéricos vazios com zero — senão `Não avaliado` vira `0` e lê como "não variou". Segundo ponto
frágil, já registrado na spec de outliers.

**Contrato a jusante.** Payload do Supabase com exatamente as mesmas colunas; colunas de variação
fora de `tab_consistencia_mensal`; `Cálculo de Médias` intocado.

**Parâmetros.** `PARAMETROS_INCONSISTENCIA.xlsx` linhas 24–26 da aba MENSAL: apenas conferência de
MÍN −50 / MÁX +50. Nenhuma edição sem novo aval.

## Testing Decisions

**O que faz um bom teste aqui.** Testar comportamento externo da função — entrada de DataFrame,
saída de classificação e das três tabelas — nunca a forma como a continuidade é calculada por
dentro. Nenhum dado real de cliente, conforme `AGENTS.md`.

**Costura única.** A função pura `calcular_variacao_periodo` é o único ponto de teste. Todo o resto
(coloração, exportação, ordenação de abas) é verificado por conferência do arquivo gerado, não por
teste automatizado — é o que a 4.4 já faz e não vale abrir uma segunda costura.

**Prior art.** A célula de verificação de outliers (4.4.1): helper local que imprime `OK`/`FALHA`
por sonda e levanta `AssertionError` ao final. A nova célula de verificação copia esse molde.

**Sondas obrigatórias.** Razão exatamente 1,5 e exatamente 0,5 → não marca; o menor incremento além
de cada uma (`np.nextafter`) → marca; `0 → positivo` = `Entrada`; `positivo → 0` = `Saída`; `0 → 0`
e nulo = `Não avaliado`; lacuna de mês → `Não avaliado`, nunca comparação atravessando o buraco;
primeira linha de cada fazenda → `Não avaliado`; pureza — o DataFrame de entrada não é modificado.

**Regressão contra 18/08.** Isolamento: `consistency_id`, `consistency_status`,
`annual_consistency_id`, `annual_consistency_status` inalterados em 100% das linhas. Granularidade:
contagem de linhas, fazendas e meses distintos idêntica; nenhuma duplicata em `id_property` + mês.
Arquivos: abas antigas com mesmos nomes/cabeçalhos/linhas/tipos; abas novas com `Não avaliado`
preservado; laranja nas células certas; `_var_` ocultas; tamanho e tempo de exportação conferidos
contra a linha de base de 18 MB. Arquivo anual: sete abas intactas, nenhuma aba nova, nenhuma cor.
Execução: notebook do início ao fim, parando **antes** do upsert no Supabase.

**Conferência manual.** Uma fazenda marcada, abrir os dois meses no arquivo exportado e refazer a
razão à mão. No resumo por consultor, conferir a fazenda com dois consultores e que o total geral
não é a soma simples das linhas.

## Out of Scope

- **Toda a extensão anual** (tickets 04 e 05, seção 4.5): função sobre janelas anuais, aba
  `Variações` anual, aba `Variações por Consultor` anual, coloração no arquivo anual.
- Alteração de `functions/` — `exportar_varias_abas_xlsx` e `aplicar_estilo_listrado_xlsx` não são
  tocados; extrair a lógica de coloração para lá fica para depois.
- Alteração de `consistency_id`/`consistency_status` ou de qualquer valor de indicador.
- Envio das colunas de variação ao Supabase.
- Aba de parâmetros para o limiar.
- Edição do `PARAMETROS_INCONSISTENCIA.xlsx` (só conferência).
- Piso de materialidade por indicador.
- Colunas de histórico `Períodos marcados` / `Primeiro período marcado`.

## Further Notes

- Esta é a **terceira família de checagem** e não substitui nenhuma: limite compara com um teto
  absoluto, outlier compara com o grupo, variação compara a fazenda com ela mesma no tempo.
- Os números da versão anterior desta spec vieram de medição feita **fora** do notebook, sobre
  exportações de 13/08, e a base mudou de fonte desde então — por isso a re-medição bloqueia a
  lista final de indicadores.
- Consequência aceita do recorte: as rubricas de custo detalhadas ficam sem verificação contra si
  mesmas no tempo.
- Se o volume da aba `Variações` (série inteira) ficar grande demais na medição, reportar antes de
  fechar, em vez de cortar por conta própria.
