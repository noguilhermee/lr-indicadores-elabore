# 01 — Quais são os valores reais de `stage` no banco

**Tipo:** `wayfinder:research` (AFK) · **Estado:** fechado em 31/08/2026 · **Bloqueia:** [03](03-layout-das-duas-abas.md)

## Question

Qual é o conjunto real de valores de `stage` em `analytics_mart.vw_culture_expense_cost`, e ele é
pequeno e fechado o bastante para virar uma coluna por etapa na aba de custo?

A decisão de layout largo (uma linha por área-safra, uma coluna por etapa) foi tomada assumindo o
conjunto que aparece no código do notebook:

```
PRE_PLANTIO, PLANTIO, TRATOS_CULTURAIS,
COLHEITA_ENSILAGEM_GRAO, COLHEITA_ENSILAGEM_PLANTA_INTEIRA,
ETAPA_NAO_INFORMADA
```

Essa lista veio de `MAPA_ETAPAS_CUSTO` (célula 45) e das constantes da célula 47 — **nunca de um
`SELECT DISTINCT`**. Se o banco tiver 15 etapas, ou variações de caixa e acento, o layout largo
está errado e a decisão precisa voltar atrás.

## O que responder

Consulta somente-leitura no banco de produção, sobre `analytics_mart.vw_culture_expense_cost`:

1. `SELECT DISTINCT stage` — o conjunto bruto, sem normalizar, contado por linhas e por soma de
   `custo`, separado por `tipo_custo` (fertilização × manejo).
2. O mesmo depois de `upper(trim(stage))`, que é o que a célula 36 aplica antes do `groupby`.
   Quantos valores brutos colapsam em quantos normalizados.
3. Quanto do custo cai em `stage` nulo ou vazio — o que a célula 36 rotula `ETAPA_NAO_INFORMADA`.
4. Se fertilização e manejo usam o mesmo vocabulário de etapa ou vocabulários diferentes.

## Resolução esperada

A lista fechada de etapas com o custo de cada uma, e um veredito explícito: o layout largo se
sustenta, ou a aba de custo precisa voltar para o formato longo.


## Resolution

Medido no banco de produção em 31/08/2026, somente leitura, sobre
`analytics_mart.vw_culture_expense_cost` sem filtro nenhum.
Achado completo com as consultas: [pesquisa-01-valores-de-stage.md](../pesquisa-01-valores-de-stage.md).

**VEREDITO: o layout largo se sustenta.**

Existem exatamente **5 valores não nulos** de `stage`, e eles são idênticos, valor por valor, à
lista que o notebook já trata. Não há variação de caixa, acento ou espaço: `upper(trim(...))`
colapsa 1:1, não muda nenhum número. `stage` nulo é sempre `NULL`, nunca string vazia.

| stage | linhas | custo bruto (R$) |
|---|---:|---:|
| PLANTIO | 5.832 | 330.051.500 |
| TRATOS_CULTURAIS | 7.755 | 103.209.300 |
| COLHEITA_ENSILAGEM_PLANTA_INTEIRA | 3.855 | 48.570.070 |
| PRE_PLANTIO | 592 | 7.214.540 |
| COLHEITA_ENSILAGEM_GRAO | 135 | 903.782 |
| *(NULL)* → ETAPA_NAO_INFORMADA | 133 | 856.055 |
| **total** | **18.302** | **490.805.300** |

Etapa não informada é **0,17% do custo** — coluna residual, não buraco.

**Fertilização e manejo usam subconjuntos diferentes, não grafias diferentes.** Fertilização só
lança em PRE_PLANTIO, PLANTIO e TRATOS_CULTURAIS — nunca nas duas etapas de colheita, o que é
coerente com o domínio (não se aduba na colheita). Manejo usa as cinco. Nenhuma divergência de
grafia entre os dois lados para a mesma etapa. Consequência para o layout: se a base separar
custo por `tipo_custo`, duas das colunas de fertilizante serão estruturalmente vazias.

**Correção de premissa do próprio ticket.** Eu tinha escrito que a lista vinha de
`MAPA_ETAPAS_CUSTO` (célula 45). Está errado: aquele mapa pertence à rota antiga e incompleta
`vw_forage_cost`, usada só para comparação. A rota real — `df_custo_cultura_safra_etapa`, célula
36 — agrupa direto pela coluna `stage` de `vw_culture_expense_cost`, **sem lista fixa nenhuma**.
Ou seja, o notebook nunca dependeu da lista; quem passa a depender dela é a aba larga.

**Achado não pedido, virou o ticket [05](05-queda-do-custo-de-fertilizante.md):** o total medido
hoje não bate com a auditoria de 02/08/2026, e a diferença está toda em fertilizante.
