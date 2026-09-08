/*
VIEW: analytics_mart.vw_feeding_entries_needing_unit_price

Finalidade:
Camada mart final que consome da view intermediária analytics_int.vw_int_feeding_entries_needing_unit_price
e junta com analytics_mart.vw_forage_production para exposição analítica das entradas que necessitam de preço unitário.
São os consumos de alimento sem valor financeiro na origem: entram com preço
zero e recebem o custo adiante, no notebook (seção 3.4.2.2).

Granularidade:
Uma linha por item de despesa de alimentação (id_expense_entry) e lote de estoque
consumido. Lançamentos que sacam de mais de um lote aparecem repetidos — em
02/08/2026 eram 20 de 3.501.

Fontes principais:
- analytics_int.vw_int_feeding_entries_needing_unit_price
- analytics_mart.vw_forage_production

Regras de negócio:
- Consome da view intermediária analytics_int.vw_int_feeding_entries_needing_unit_price.
- Associa id_planted_culture e id_culture_harvest_product via vw_forage_production.
  O join é LEFT: o lote pode não ter vindo de colheita própria, e nesse caso não
  há produção para associar. Até 02/08/2026 esse era o caso de 935 dos 4.428
  consumos com preço zero — com INNER JOIN eles desapareciam e o alimento ia
  para o indicador custando zero.
- Quem não tem produção associada é precificado pelo lote, com
  stock_unit_price_kg. O consumidor deve usar o custo da safra quando ele
  existir e cair no preço do lote apenas na falta dele.
- category_code permite classificar volumoso/concentrado/mineral nas linhas sem
  produção, onde feeding_category não existe.
- As colunas projetadas são exatamente as que a view intermediária entrega.
  Versões anteriores deste arquivo pediam raw_consumed_quantity e unit, que a
  intermediária não projeta, e derrubavam a view ao serem executadas.
- As colunas lot_* e stock_item_name (05/08/2026) descrevem o lote de onde o
  consumo saiu: a safra que originou o lote e o produto do lote. id_planted_culture
  continua vindo da produção apontada pelo lançamento; lot_id_planted_culture vem
  do lote. Os dois divergem quando o lançamento saca de um lote antigo.

Forma de consulta:
SELECT * FROM analytics_mart.vw_feeding_entries_needing_unit_price;
*/

DROP VIEW IF EXISTS analytics_mart.vw_feeding_entries_needing_unit_price;

CREATE VIEW analytics_mart.vw_feeding_entries_needing_unit_price AS
SELECT int_f.id_expense_entry,
    int_f.id_property,
    int_f.category_code,
    int_f.consumed_quantity_kg,
    int_f.current_unit_price,
    int_f.consumption_reference_month,
    int_f.id_production,
    p.id_planted_culture,
    p.id_culture_harvest_product,
    int_f.id_stock_control_item,
    int_f.stock_origin,
    int_f.stock_purchase_date,
    int_f.stock_unit_value,
    int_f.stock_unit_factor_kg,
    int_f.stock_unit_price_kg,
    int_f.stock_item_name,
    int_f.stock_in_stock_quantity_kg,
    int_f.stock_purchased_quantity_kg,
    int_f.lot_id_production,
    int_f.lot_id_planted_culture,
    int_f.lot_id_area,
    int_f.lot_id_culture,
    int_f.lot_harvest_season
FROM analytics_int.vw_int_feeding_entries_needing_unit_price int_f
LEFT JOIN analytics_mart.vw_forage_production p
       ON int_f.id_production = p.id_production
      AND int_f.id_property = p.id_property;
