/*
VIEW: analytics_mart.vw_stock_lot_production

Finalidade:
Camada mart do vínculo lote x colheita. O notebook de indicadores usa esta view
para custear o lote pela média ponderada das safras que entraram nele, em vez de
escolher uma delas.

Granularidade:
Uma linha por id_stock_control_item x id_production.

Fontes principais:
- analytics_int.vw_int_stock_lot_production

Forma de consulta:
SELECT * FROM analytics_mart.vw_stock_lot_production;
*/

CREATE OR REPLACE VIEW analytics_mart.vw_stock_lot_production AS
SELECT
    lp.id_stock_control_item,
    lp.id_property,
    lp.id_production,
    lp.movement_date,
    lp.movement_quantity,
    lp.id_planted_culture,
    lp.quantity_produced,
    lp.harvested_area,
    lp.produced_at,
    lp.id_area,
    lp.id_culture,
    lp.harvest_season
FROM analytics_int.vw_int_stock_lot_production lp;
