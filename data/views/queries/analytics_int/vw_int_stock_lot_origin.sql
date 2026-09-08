/*
VIEW: analytics_int.vw_int_stock_lot_origin

Finalidade:
Dimensão do lote de estoque com a origem produtiva resolvida. Responde, para
cada lote, de qual colheita ele veio e a que área, cultura e safra essa colheita
pertence. É a ponte que faltava entre o módulo de estoque e o custo da lavoura:
sem ela só era possível ligar consumo de alimentação à safra quando o próprio
lançamento de consumo carregava a produção.

Granularidade:
Uma linha por id_stock_control_item ativo.

Fontes principais:
- public.StockControlItem
- public.StockControlMovement
- public.Production
- analytics_mart.vw_planted_culture_season

Regras de negócio:
- A origem produtiva vem do movimento de entrada gravado pelo módulo de produção
  (source_module = 'PLANTED_CULTURE_PRODUCTION', movement_type = 'ENTRY'), cujo
  source_reference_id é o id_production. Medido em 05/08/2026: 1.355 movimentos
  desse tipo, todos casando com public.Production.
- Os joins são LEFT em toda a cadeia. Lote de compra não tem produção, e lote de
  colheita pode não ter o movimento gravado — em 05/08/2026, 4 dos 131 lotes de
  COLHEITA sem valor unitário estavam nessa situação. Com INNER JOIN esses lotes
  sumiriam da dimensão e o consumo correspondente ficaria sem qualquer âncora de
  preço.
- unit_price_kg = unit_value / unit_factor_kg. unit_value está na unidade do
  lançamento que originou o lote (R$/ton nos lotes em tonelada), então a divisão
  pelo fator entrega R$/kg. Mesma regra já usada em
  analytics_int.vw_int_feeding_entries_needing_unit_price.
- purchased_quantity e in_stock_quantity também estão na unidade do lote; as
  colunas *_kg aplicam o fator para permitir conciliar produção, consumo e saldo
  na mesma unidade do consumo de alimentação.
- producoes_no_lote conta quantas colheitas distintas entraram no mesmo lote. A
  view devolve uma linha por lote, escolhendo a colheita mais antiga; a coluna
  existe para que o consumidor saiba quando a safra atribuída é uma escolha e não
  a única possível. Em 05/08/2026 eram 16 lotes com mais de uma colheita.
- Lote de colheita entra no estoque com unit_value zerado quando a fazenda não
  digitou valor. Em 05/08/2026 eram 131 lotes e 45.845 toneladas. Quem consome
  esta view deve tratar unit_price_kg zerado como ausência de preço, não como
  alimento de graça.

Forma de consulta:
SELECT * FROM analytics_int.vw_int_stock_lot_origin;
*/

CREATE OR REPLACE VIEW analytics_int.vw_int_stock_lot_origin AS
WITH movimento_producao AS (
    SELECT m.id_stock_control_item,
        m.source_reference_id AS id_production,
        m.movement_date
    FROM "StockControlMovement" m
    WHERE m.source_module = 'PLANTED_CULTURE_PRODUCTION'::text
      AND m.movement_type = 'ENTRY'::"StockControlMovementType"
),
contagem_producao AS (
    SELECT mp.id_stock_control_item,
        count(DISTINCT mp.id_production) AS producoes_no_lote
    FROM movimento_producao mp
    GROUP BY mp.id_stock_control_item
),
producao AS (
    -- Uma linha por lote. Em 05/08/2026, 16 lotes tinham mais de uma colheita
    -- somada no mesmo lote; sem o DISTINCT ON eles multiplicavam as linhas de
    -- consumo que saem deste lote e dobravam o custo apropriado.
    SELECT DISTINCT ON (mp.id_stock_control_item)
        mp.id_stock_control_item,
        mp.id_production,
        cp.producoes_no_lote
    FROM movimento_producao mp
    JOIN contagem_producao cp ON cp.id_stock_control_item = mp.id_stock_control_item
    ORDER BY mp.id_stock_control_item, mp.movement_date, mp.id_production
)
SELECT
    i.id_stock_control_item,
    i.id_property,
    i.item_name,
    i.item_type::text            AS item_type,
    i.category,
    i.origin::text               AS origin,
    i.situation::text            AS situation,
    i.purchase_date,
    i.unit,
    i.unit_factor_kg,
    i.unit_value,
    (i.unit_value / NULLIF(i.unit_factor_kg, 0::double precision))::double precision
                                 AS unit_price_kg,
    i.purchased_quantity,
    i.in_stock_quantity,
    (i.purchased_quantity * COALESCE(i.unit_factor_kg, 1::double precision))::double precision
                                 AS purchased_quantity_kg,
    (i.in_stock_quantity * COALESCE(i.unit_factor_kg, 1::double precision))::double precision
                                 AS in_stock_quantity_kg,
    prod.id_production,
    p.id_planted_culture,
    s.id_area,
    s.id_culture,
    s.harvest_season,
    COALESCE(prod.producoes_no_lote, 0::bigint) AS producoes_no_lote
FROM "StockControlItem" i
LEFT JOIN producao prod
       ON prod.id_stock_control_item = i.id_stock_control_item
LEFT JOIN "Production" p
       ON p.id_production = prod.id_production
LEFT JOIN analytics_mart.vw_planted_culture_season s
       ON s.id_planted_culture = p.id_planted_culture
WHERE i.is_active;
