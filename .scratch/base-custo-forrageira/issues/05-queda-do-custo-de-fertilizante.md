# 05 — O custo de fertilizante caiu 40% desde a auditoria de 02/08

**Tipo:** `wayfinder:research` (AFK) · **Estado:** FECHADO em 31/08/2026
**Bloqueado por:** nada · **Bloqueia:** a conferência do ticket [04](04-onde-a-exportacao-entra-e-como-e-conferida.md)

## Question

Por que `analytics_mart.vw_culture_expense_cost` tem hoje **mais linhas e muito menos dinheiro** do
que tinha em 02/08/2026, com a diferença inteira do lado do fertilizante? A queda é correção
legítima na origem, ou regressão?

## O que foi medido

Achado colateral do ticket [01](01-valores-reais-de-stage.md), que mediu a view inteira, sem
filtro, em 31/08/2026. Comparado com `data/views/docs/fluxo_custo_alimentacao.md`, que registra a
medição pós-implantação do D7 em 02/08/2026.

| | 02/08/2026 (auditoria) | 31/08/2026 (medido) | variação |
|---|---:|---:|---|
| linhas | 17.809 | 18.302 | **+493** |
| custo total | R$ 724,48 mi | R$ 490,81 mi | **−R$ 233,67 mi (−32%)** |
| manejo | R$ 131,70 mi | R$ 135,43 mi | +R$ 3,73 mi (+2,8%) |
| fertilizante | R$ 592,78 mi | R$ 355,38 mi | **−R$ 237,40 mi (−40%)** |

**Manejo se comporta como esperado** para um mês de lançamentos novos. **Fertilizante perdeu 40%
do valor enquanto o total de linhas subia.** As duas coisas juntas não se explicam por lançamento
novo.

Nenhuma das duas medições tem filtro de período: `vw_culture_expense_cost` não tem
`reference_month`, e a consulta de 31/08 rodou sobre a view inteira. A comparação é direta.

## Por que isso bloqueia a conferência

O ticket 04 propõe conferir a base contra a soma de `vw_culture_expense_cost`. Se o número da view
se mexe 40% em quatro semanas, essa trava confere a base contra um alvo móvel — passa hoje e
estoura amanhã sem que nada da base tenha mudado. É preciso saber se o movimento é normal antes de
escolher a conferência.

## O que responder

1. A queda está concentrada em quais propriedades, safras e produtos? É difusa ou são poucos
   lançamentos grandes?
2. É `is_active` virando `false` na origem (lançamento excluído no app), mudança de
   `consumed_quantity`, ou mudança de `unit_cost`?
3. O D7 mudou o Ramo 2 para `COALESCE(consumed_quantity, quantity)` e
   `custo = consumed_quantity * unit_cost`. A queda é o efeito do D7 aparecendo conforme os
   clientes preenchem `consumed_quantity` — ou seja, esperada e progressiva — ou é outra coisa?
   Medir quantas linhas de fertilizante têm `consumed_quantity` menor que `quantity`, e quanto
   dinheiro isso responde.
4. Houve alteração nas views `analytics_int` depois de 02/08? Conferir `git log` de
   `data/views/queries/analytics_int/vw_fertilization_cost.sql` e comparar o arquivo do repositório
   com o DDL que está no banco — o D5 da auditoria mostra que os dois já divergiram antes.

## Cuidado

Isto **não é um defeito confirmado**. É uma divergência entre duas medições em datas diferentes.
Pode ser correção legítima de dado na origem. Não escrever "regressão" em lugar nenhum antes de
medir a causa. Nada de alterar view ou dado — só medir e relatar.

---

## Verdict — 31/08/2026

Medições completas em [pesquisa-05-queda-do-custo-de-fertilizante.md](../pesquisa-05-queda-do-custo-de-fertilizante.md).

**Não é regressão.** O custo de fertilizante é uma soma governada por **oito linhas de erro de
digitação** que carregam **74,5% do total** (R$ 264,87 mi de R$ 355,38 mi). Todas com `unit = 'KG'`
e `unit_cost` em ordem de grandeza de preço por tonelada: fertilizante mineral a R$ 3.900,00 **por
quilo**, R$ 4.086,29/kg, R$ 4.020,00/kg; calcário a R$ 231,06/kg. A maior sozinha vale
R$ 124,80 mi. Apagar uma ou duas cobre a diferença inteira de R$ 237,40 mi.

Respostas às quatro perguntas:

1. **Concentração.** Extrema. Oito linhas ≥ R$ 10 mi = 74,5%; a safra 25/26 = 81,7% do total.
   Manejo, para comparação, **não tem nenhuma linha acima de R$ 10 mi** — daí ele se comportar
   (+2,8%) enquanto fertilizante despenca. São dois regimes estatísticos na mesma view.
2. **Mecanismo.** Nem `is_active`, nem edição de valor. Só R$ 0,50 mi foi desativado depois de
   02/08 e no máximo R$ 21,76 mi foi editado. Somando **tudo** que ainda existe no banco criado
   antes de 02/08, em qualquer estado, chega-se a R$ 421,49 mi — faltam **R$ 171,29 mi sem
   representante nenhum**. As linhas foram apagadas de verdade, não marcadas inativas. Qual linha
   era é **não medido**: não há `deleted_at` nem snapshot de 02/08.
3. **D7.** Descartado. O efeito era 2,2% do custo de fertilizante em 02/08 e é 2,3% hoje —
   encolheu na mesma proporção do total. `consumed_quantity` nunca é nulo; 218 de 3.208 linhas do
   Ramo 2 têm consumo menor que a compra. Não é correção progressiva.
4. **Repositório × banco.** **Nenhuma divergência.** `pg_get_viewdef` das três views bate com o
   `.sql` versionado. O `.bak` de 02/08 é a versão pré-D7, e o único delta contra o arquivo atual
   é o próprio D7. Mesmo código produziu R$ 592,78 mi e produz R$ 355,38 mi. O D5 não se repetiu.

### Decisões que este ticket fecha

- **A conferência 1 do ticket 04 é recomputada na hora**, contra a mesma leitura de
  `vw_culture_expense_cost` usada na execução — nunca contra valor fixo nem faixa de tolerância.
  O alvo se move em centenas de milhões sem uma linha de código mudar.
- **A base marca custo unitário implausível.** Rateada sobre a produção de uma safra, cada uma
  dessas linhas produz R$/kg de forrageira em ordem de grandeza errada. Corrigir é `Out of scope`;
  entregar em silêncio não é aceitável. A forma da marcação pertence ao layout, no ticket 03.
- **O recorte ativo não protege.** As oito propriedades têm cadastro válido; a coluna de universo
  ativo decidida no ticket 00 não segura nenhum desses valores.

### Hipótese que fica de pé, sem prova

Que a própria medição de 02/08 esteja errada. Não é descartável e não é reconciliável sem o
snapshot que não existe.
