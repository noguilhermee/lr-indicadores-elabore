/*
ATENÇÃO: Essa query tem por objetivo vincular os custos da cultura plantada (que não são fertilizantes)
aos ids que permitem identificar onde elas foram usadas.
A saber: id_property, id_area, harvest_season
NÃO ALTERAR SEM PRÉVIO CONSENTIMENTO.
Ass: Filipe Dalboni

VIEW: analytics_int.vw_management_cost

Finalidade:
Camada intermediária do custo de manejo de cultura no grão do item consumido,
com a data de compra (entry_date) preservada para permitir deflacionar cada
linha antes de somar.

Granularidade:
Uma linha por item consumido, ou por lote de origem quando o custo vem de baixa
de estoque.

Fontes principais:
- public."CultureExpenseManagement"
- public."CultureExpenseManagementProduct"
- public."CultureExpenseManagementStockConsumption"

Regras de negócio relevantes:
- is_active = true em todas as três tabelas: o app desativa e recria em vez de
  fazer UPDATE, e sem o filtro cada edição vira duplicata.
- Ramo 1 (baixa de estoque): o custo é o do lote consumido, e entry_date é o
  applied_at do lote de origem, ou seja, a data em que o insumo foi comprado.
- Ramo 2 (compra e uso no mesmo lançamento): entry_date = applied_at do próprio
  item. Exclui ESTOCAR puro, que vira custo só quando consumido, e exclui itens
  que já têm baixa de estoque associada, para não contar duas vezes.
- O Ramo 2 lança o CONSUMIDO, não o comprado: custo = consumed_quantity *
  unit_cost. Em ESTOCAR_CONSUMIR a compra costuma ser maior que o uso, e a sobra
  fica em estoque até ser baixada — quando vira custo pelo Ramo 1. Projetar
  line_total aqui contava o mesmo insumo duas vezes (defeito D7, 02/08/2026:
  R$ 30,9 milhões, 19% do custo de manejo).
- Unidades: unit_cost é o preço por unidade do lançamento, logo pareia com
  consumed_quantity bruta; unit_cost_kg pareia com consumed_quantity_kg. Não
  entra fator de conversão no meio.
- A view não agrega de propósito: agregar aqui destruiria a possibilidade de
  deflacionar por data no Python.

Forma de consulta:
SELECT * FROM analytics_int.vw_management_cost;
*/

CREATE OR REPLACE VIEW analytics_int.vw_management_cost AS

-- Ramo 1: custo vindo de baixa de estoque (ESTOCAR -> CONSUMIR)
SELECT
    'manejo'::text                  AS tipo_custo,
    p.id_management_product         AS id_product,
    sc.id_management_product_stock  AS id_lote_origem,
    m.id_management                 AS id_parent,
    m.id_property,
    m.id_area,
    m.id_culture,
    m.harvest_season,
    p.operation::text               AS operation,
    p.stage::text                   AS stage,
    p.product_name,
    p.unit,
    sc.quantity,
    sc.unit_cost,
    sc.quantity_kg,
    sc.unit_cost_kg,
    sc.line_total                   AS custo,
    origem.applied_at               AS entry_date,
    p.applied_at
FROM "CultureExpenseManagementStockConsumption" sc
JOIN "CultureExpenseManagementProduct" p
    ON p.id_management_product = sc.id_management_product_consumer
   AND p.is_active = true
JOIN "CultureExpenseManagementProduct" origem
    ON origem.id_management_product = sc.id_management_product_stock
JOIN "CultureExpenseManagement" m
    ON m.id_management = p.id_management
   AND m.is_active = true
WHERE sc.is_active = true

UNION ALL

-- Ramo 2: compra e uso no mesmo lançamento (exclui ESTOCAR puro)
SELECT
    'manejo'::text,
    p.id_management_product,
    NULL::text,
    m.id_management,
    m.id_property,
    m.id_area,
    m.id_culture,
    m.harvest_season,
    p.operation::text,
    p.stage::text,
    p.product_name,
    p.unit,
    COALESCE(p.consumed_quantity, p.quantity),
    p.unit_cost,
    COALESCE(p.consumed_quantity_kg, p.quantity_kg),
    p.unit_cost_kg,
    COALESCE(p.consumed_quantity, p.quantity) * p.unit_cost,
    p.applied_at,
    p.applied_at
FROM "CultureExpenseManagementProduct" p
JOIN "CultureExpenseManagement" m
    ON m.id_management = p.id_management
   AND m.is_active = true
WHERE p.is_active = true
  AND p.operation::text IS DISTINCT FROM 'ESTOCAR'
  AND NOT EXISTS (
      SELECT 1 FROM "CultureExpenseManagementStockConsumption" sc
      WHERE sc.id_management_product_consumer = p.id_management_product
        AND sc.is_active = true
  );
