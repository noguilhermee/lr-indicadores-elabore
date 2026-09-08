# 00 — Destino e premissas da base

**Tipo:** `wayfinder:grilling` · **Estado:** fechado · **Bloqueado por:** nada

## Question

O que é o artefato, em que chave ele vive, o que entra no custo, em que base monetária, e como
sai o R$/kg da produção.

## Resolution

Decidido na sessão de cartografia, com o usuário.

**Artefato.** Arquivo Excel novo e independente, gravado em `data/outputs/`, com data no nome.
Não é aba das exportações mensal ou anual: o grão aqui é *área × cultura × safra*, que não é nem
`id_property + reference_month` nem `id_property + ano`. Duas abas — custo por etapa, e produção
com custo.

**Chave da linha de custo.** `id_area + id_culture + harvest_season`, com `id_property` junto.
Não `id_planted_culture`. Razão: as tabelas de despesa de cultura não guardam o plantio, e o
vínculo custo→plantio de `vw_int_forage_cost_items` é heurístico (escolhe um plantio por
proximidade de data), não chave estrangeira. `planted_area` e a lista de plantios podem entrar
como atributo informativo, nunca como chave.

**Escopo do custo.** Inclui fertilização. Fonte é `analytics_mart.vw_culture_expense_cost`
(UNION de `vw_fertilization_cost` + `vw_management_cost`), não `vw_forage_cost_stage`, que só lê
`CultureExpenseManagementProduct`. Pela auditoria de 02/08/2026, fertilizante é R$ 592,78 mi
contra R$ 131,70 mi de manejo — sem ele a base seria ~18% do custo real. A coluna `tipo_custo` é
preservada para permitir separar.

**Base monetária.** Deflacionada por IGP-DI, como o notebook já faz: cada item pela sua própria
`entry_date`, antes de somar. Não expor coluna nominal paralela.

**R$/kg da produção.** Regra de rateio por etapa já implantada (D7): colheita/ensilagem de planta
inteira → 100% VOLUMOSO; colheita/ensilagem de grão → 100% CONCENTRADO; pré-plantio, plantio,
tratos culturais e etapa não informada → proporção da área colhida, com os fatores normalizados
dentro de propriedade+área+cultura+safra+etapa. É a mesma regra que alimenta `feeding_cost` hoje.

**Universo.** Tudo que vem do banco — todas as propriedades, todas as safras — com uma coluna
marcando quais propriedades estão no universo ativo dos indicadores. Cortar linha na origem é
irreversível para quem consome.

**Linhas órfãs.** Custo sem produção correspondente e produção sem custo lançado **entram na base
marcadas** com coluna de situação. Hoje a §3.4.2.1-B descarta o custo sem produção e só imprime um
aviso. Sumir com essas linhas faz a base parecer completa quando não é, e impede auditar o total
contra `vw_culture_expense_cost`.

**Safra em andamento.** `tem_plantio_em_andamento` vira flag na base e a linha permanece, com o
`custo_unitario_forrageira` calculado normalmente. A base entrega o dado e a marca; anular o valor
seria a base tomando decisão de indicador.

**Gatilho.** A exportação roda toda vez que o notebook roda. Sem flag de configuração — não é
arquivo demonstrativo no sentido do `AGENTS.md`, é produto do fluxo, e flag que fica `False` vira
código morto que ninguém percebe que quebrou.

**Bloco de identificação.** Nome de fazenda e consultor entram (vêm de `vw_dim_property_consultant`,
já em memória). Nome de cultura e nome de área não têm fonte pronta na rota de custo — viram o
ticket [02](02-fonte-dos-nomes-de-cultura-e-area.md).
