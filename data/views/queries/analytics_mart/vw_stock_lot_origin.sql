/*
VIEW: analytics_mart.vw_stock_lot_origin

Finalidade:
Camada mart do lote de estoque com origem produtiva. Serve à auditoria de
forrageira produzida do notebook de indicadores: permite acompanhar o caminho
colheita -> lote -> consumo de alimentação e conferir quanto do custo da lavoura
já virou custo de alimentação e quanto ainda está em estoque.

Granularidade:
Uma linha por id_stock_control_item ativo.

Fontes principais:
- analytics_int.vw_int_stock_lot_origin

Regras de negócio:
- Projeção direta da view intermediária, sem filtro adicional. Lotes de compra
  entram junto com os de colheita porque a auditoria precisa dos dois lados para
  fechar o consumo do mês.
- unit_price_kg zerado significa lote sem preço registrado, não alimento sem
  custo. Ver a documentação da view intermediária.

Forma de consulta:
SELECT * FROM analytics_mart.vw_stock_lot_origin;
*/

CREATE OR REPLACE VIEW analytics_mart.vw_stock_lot_origin AS
SELECT
    l.id_stock_control_item,
    l.id_property,
    l.item_name,
    l.item_type,
    l.category,
    l.origin,
    l.situation,
    l.purchase_date,
    l.unit,
    l.unit_factor_kg,
    l.unit_value,
    l.unit_price_kg,
    l.purchased_quantity,
    l.in_stock_quantity,
    l.purchased_quantity_kg,
    l.in_stock_quantity_kg,
    l.id_production,
    l.id_planted_culture,
    l.id_area,
    l.id_culture,
    l.harvest_season,
    l.producoes_no_lote
FROM analytics_int.vw_int_stock_lot_origin l;
