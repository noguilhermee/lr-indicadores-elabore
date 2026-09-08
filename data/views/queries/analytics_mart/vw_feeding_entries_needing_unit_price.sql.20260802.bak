/*
VIEW: analytics_mart.vw_feeding_entries_needing_unit_price

Finalidade:
Camada mart final que consome da view intermediária analytics_int.vw_int_feeding_entries_needing_unit_price
e junta com analytics_mart.vw_forage_production para exposição analítica das entradas que necessitam de preço unitário.

Granularidade:
Uma linha por item de despesa de alimentação (id_expense_entry).

Fontes principais:
- analytics_int.vw_int_feeding_entries_needing_unit_price
- analytics_mart.vw_forage_production

Regras de negócio:
- Consome da view intermediária analytics_int.vw_int_feeding_entries_needing_unit_price.
- Associa id_planted_culture e id_culture_harvest_product via vw_forage_production.

Forma de consulta:
SELECT * FROM analytics_mart.vw_feeding_entries_needing_unit_price;
*/

DROP VIEW IF EXISTS analytics_mart.vw_feeding_entries_needing_unit_price;

CREATE VIEW analytics_mart.vw_feeding_entries_needing_unit_price AS
SELECT int_f.id_expense_entry,
    int_f.id_property,
    int_f.consumed_quantity_kg,
    int_f.raw_consumed_quantity,
    int_f.unit,
    int_f.current_unit_price,
    int_f.consumption_reference_month,
    int_f.id_production,
    p.id_planted_culture,
    p.id_culture_harvest_product
FROM analytics_int.vw_int_feeding_entries_needing_unit_price int_f
JOIN analytics_mart.vw_forage_production p ON int_f.id_production = p.id_production
WHERE int_f.id_property = p.id_property;