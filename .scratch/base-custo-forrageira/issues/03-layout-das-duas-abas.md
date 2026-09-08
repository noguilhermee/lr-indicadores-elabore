# 03 — Layout final das duas abas

**Tipo:** `wayfinder:grilling` (HITL)
**Estado:** FECHADO em 31/08/2026 — implementado no notebook (§5)
**Bloqueadores (ambos fechados):** [01](01-valores-reais-de-stage.md), [02](02-fonte-dos-nomes-de-cultura-e-area.md)

## Question

Quais são exatamente as colunas de cada aba — nome, ordem, unidade, tipo — e o nome do arquivo e
das abas?

Bloqueado de verdade: o ticket 01 decide se a aba de custo é larga ou longa, e o 02 decide se
existe coluna de nome de cultura e de área para posicionar no bloco de identificação. Especificar
antes seria escrever duas vezes.

## O que precisa sair fechado

**Aba de custo por etapa** — uma linha por `id_property + id_area + id_culture + harvest_season`
(se 01 confirmar o largo). Precisa decidir:

- ordem do bloco de identificação (ids × nomes × marca de universo ativo);
- nome de cada coluna de etapa em português ou o código cru (`PRE_PLANTIO` × `Pré-plantio`);
- se `tipo_custo` vira duas colunas por etapa (fertilização e manejo separados) ou fica só o total
  por etapa com uma aba/coluna de apoio;
- se entram `planted_area`, `qtd_plantios`, `area_colhida`;
- coluna de total, e se ela é soma das etapas ou vem independente da origem (as duas têm de bater).

**Aba de produção e custo** — uma linha por
`id_property + id_area + id_culture + harvest_season + feeding_category`. Precisa decidir:

- se `feeding_category` é linha (longo) ou vira colunas VOLUMOSO/CONCENTRADO lado a lado;
- quais colunas de `df_custo_unitario_forrageira` entram: `custo_rateado`, `quantidade_kg`,
  `area_colhida`, `custo_unitario_forrageira`, e se `produtividade_kg_ha` e `ms_media` de
  `vw_culture_production` valem a pena;
- como as marcas de situação aparecem: `tem_plantio_em_andamento`, custo sem produção, produção
  sem custo, `linhas_sem_conversao`, `unidades_origem`. Uma coluna de situação com vocabulário
  fechado, ou uma coluna booleana por caso;
- o que fazer com `feeding_category` nula, que hoje sai do rateio com um aviso.

**Arquivo.** Nome e padrão de data, coerente com `data/outputs/`. Nome das duas abas.

## Resolução esperada

A lista de colunas de cada aba, em ordem, com nome e unidade — pronta para uma sessão de
implementação transcrever sem inventar nada.


## O que os bloqueadores já fecharam (não reabrir)

- **Etapas:** 5 valores canônicos + NULL a 0,17%. Layout largo confirmado. Fertilização não
  lança nas duas etapas de colheita — separar por `tipo_custo` criaria duas colunas vazias.
- **Cultura:** entra, join por `id_culture` no pandas. O *nome* não é único por id (52 nomes /
  70 ids); não agrupar por nome.
- **Área:** o nome **não entra** como identificador. A linha é identificada pela tripla.

---

## Verdict — 31/08/2026

Decidido em entrevista e **implementado na mesma sessão**, a pedido do usuário. O mapa previa
handoff; o usuário mandou executar.

### Decisões

| # | Decisão |
|---|---|
| Q1 | **Português legível, com unidade no cabeçalho.** O destinatário é consultor de campo, não máquina. Minha recomendação inicial (snake_case técnico) estava errada e foi descartada. |
| Q2 | **Chave com custo e sem produção fica só na aba 1.** "Se não há produção, não é preciso inserir custo" — a aba 2 responde quanto custou o que foi produzido, e onde não houve produção não há resposta. O dinheiro dessas 566 chaves (R$ 288,84 mi) continua inteiro na aba 1. |
| Q3 | **Formato longo, uma linha por categoria.** VOLUMOSO e CONCENTRADO voltam os dois — já estavam em `df_custo_unitario_forrageira`, nada foi recalculado. |
| Q4 | **`tipo_custo` não desmembra a etapa.** Seis colunas continuam seis. |
| Q5 | **Aba de custo não carrega área nem R$/ha.** Escopo reduzido pelo usuário: só identificadores. `Área Colhida` está na aba 2. |
| Q6 | **Sem marcadores de auditoria.** O usuário pediu explicitamente para não revisar valores. As linhas de digitação errada do ticket 05 saem sem marca — escolha registrada, não descuido. |
| Q7 | **Nome da área entra como rótulo**, ao lado dos ids. O achado do ticket 02 continua valendo para agrupar; rotular é outro uso. |
| Q8 | **Aba de custo larga**, uma coluna por etapa + total. |
| Q9 | Ordem: `Fazenda`, `Código LR`, `Consultor`, `Área`, `Cultura`, `Safra`, dados, ids no fim. |

### Implementação

`app/Elabore Indicadores.ipynb`, nova **§5**, inserida entre a exportação anual (§4.6) e a
ingestão no Supabase (§4.7) — não no fim, para que o arquivo saia mesmo quando a execução é
interrompida antes do upsert em produção.

Backup: `app/backup/Elabore Indicadores_20260831_134142_pre_base_custo_forrageira.ipynb`.

Saída: `data/outputs/forrageira/{AAAA_MM_DD_HHMMSS}_base_custo_forrageira.xlsx`.

**Aba "Custo por Etapa"** — Fazenda · Código LR · Consultor · Área · Cultura · Safra ·
Pré-plantio (R$) · Plantio (R$) · Tratos Culturais (R$) · Colheita/Ensilagem Planta Inteira (R$) ·
Colheita/Ensilagem Grão (R$) · Etapa Não Informada (R$) · Custo Total (R$) ·
IdFazenda · IdÁrea · IdCultura

**Aba "Produção e Custo"** — Fazenda · Código LR · Consultor · Área · Cultura · Safra ·
Categoria · Quantidade Produzida (kg) · Área Colhida (hectare) · Custo da Produção (R$) ·
Custo Unitário (R$/kg) · IdFazenda · IdÁrea · IdCultura

### Defeito encontrado e corrigido durante o teste

A primeira versão usava `pivot_table`, que **descarta em silêncio toda linha com NaN em qualquer
nível do índice**. A view de custo tem 62 linhas sem `id_culture`, 10 sem `harvest_season` e 5 sem
`id_area` — o dinheiro delas sumiria da planilha sem aviso, violando a decisão do ticket 00 de que
órfão entra marcado. A conferência de conservação pegou (R$ 1,66 mi de diferença no teste). Trocado
por `groupby(..., dropna=False).unstack()`, com o motivo comentado no código.

### Conferências que rodam a cada execução, e falham duro

1. Soma das colunas de etapa == soma de `custo_deflacionado` na origem (tolerância R$ 0,01).
2. Uma linha por `id_property + id_area + id_culture + harvest_season` na aba 1.
3. A aba 2 não muda de tamanho ao receber identificadores (`validate="m:1"` em todo merge).
4. Etapa fora do vocabulário do ticket 01 é parada dura, não coluna nova ignorada.
