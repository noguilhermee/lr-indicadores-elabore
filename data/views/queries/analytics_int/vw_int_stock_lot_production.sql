/*
VIEW: analytics_int.vw_int_stock_lot_production

Finalidade:
Liga cada lote de estoque a TODAS as colheitas que entraram nele, com a
quantidade produzida de cada uma. É a base para custear o lote pela média
ponderada das safras quando o silo é mistura de mais de uma colheita.

Granularidade:
Uma linha por id_stock_control_item x id_production.

Fontes principais:
- public.StockControlMovement
- public.Production
- analytics_mart.vw_planted_culture_season

Regras de negócio:
- Só entram movimentos de entrada gravados pelo módulo de produção
  (source_module = 'PLANTED_CULTURE_PRODUCTION', movement_type = 'ENTRY').
- Diferente de analytics_int.vw_int_stock_lot_origin, esta view NÃO reduz para
  uma linha por lote. Quem consome precisa das duas: a origem para descrever o
  lote e esta para ratear o custo. Em 05/08/2026, 12 lotes tinham mais de uma
  colheita; nos demais as duas views entregam o mesmo resultado.
- quantity_produced é a quantidade da colheita, na unidade da produção, e serve
  de peso do rateio. movement_quantity é o que de fato entrou neste lote e pode
  divergir da colheita inteira quando a produção foi dividida entre lotes; fica
  projetado para conferência, mas o peso padrão é a produção, coerente com o
  custo unitário da safra, que é apurado sobre a produção total.
- Os joins com Production e com a safra são LEFT: movimento órfão continua
  aparecendo, com safra nula, em vez de sumir sem aviso.

Forma de consulta:
SELECT * FROM analytics_int.vw_int_stock_lot_production;
*/

CREATE OR REPLACE VIEW analytics_int.vw_int_stock_lot_production AS
SELECT
    m.id_stock_control_item,
    m.id_property,
    m.source_reference_id       AS id_production,
    m.movement_date,
    m.quantity                  AS movement_quantity,
    p.id_planted_culture,
    p.quantity_produced,
    p.harvested_area,
    p.produced_at,
    s.id_area,
    s.id_culture,
    s.harvest_season
FROM "StockControlMovement" m
LEFT JOIN "Production" p
       ON p.id_production = m.source_reference_id
LEFT JOIN analytics_mart.vw_planted_culture_season s
       ON s.id_planted_culture = p.id_planted_culture
WHERE m.source_module = 'PLANTED_CULTURE_PRODUCTION'::text
  AND m.movement_type = 'ENTRY'::"StockControlMovementType"
  AND m.is_active;
