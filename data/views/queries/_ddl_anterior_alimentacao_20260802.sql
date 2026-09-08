-- DDL vigente em 20260802_171413, antes da correcao de alimentacao
CREATE OR REPLACE VIEW analytics_int.vw_int_feeding_expense AS
 SELECT f.id_expense_entry,
    f.id_property,
    f.unit_price AS current_unit_price,
    date_trunc('month'::text, e.reference_month)::date AS reference_month,
    f.category_code,
    f.purchased_quantity *
        CASE
            WHEN lower(TRIM(BOTH FROM e.unit)) = 'ton'::text THEN 1000
            WHEN lower(TRIM(BOTH FROM e.unit)) = 'feeding-unit-saca-1778245226249'::text THEN 25
            ELSE 1
        END::double precision AS purchased_quantity_kg,
    f.consumed_quantity *
        CASE
            WHEN lower(TRIM(BOTH FROM e.unit)) = 'ton'::text THEN 1000
            WHEN lower(TRIM(BOTH FROM e.unit)) = 'feeding-unit-saca-1778245226249'::text THEN 25
            ELSE 1
        END::double precision AS consumed_quantity_kg,
    e.amount_total
   FROM "FeedingExpenseEntry" f
     JOIN "ExpenseEntry" e ON f.id_expense_entry = e.id_expense_entry
  WHERE e.is_active = true AND f.operation <> 'ESTOCAR'::"ExpenseOperation";

CREATE OR REPLACE VIEW analytics_int.vw_int_feeding_entries_needing_unit_price AS
 WITH producao AS (
         SELECT s.id_stock_control_item,
            s.source_reference_id AS id_production
           FROM "StockControlMovement" s
          WHERE s.source_module = 'PLANTED_CULTURE_PRODUCTION'::text AND s.movement_type = 'ENTRY'::"StockControlMovementType"
        ), consumo AS (
         SELECT s.id_stock_control_item,
            s.source_reference_id AS id_expense_entry
           FROM "StockControlMovement" s
          WHERE s.source_module = 'EXPENSES'::text AND s.movement_type = 'EXIT'::"StockControlMovementType"
        )
 SELECT fe.id_expense_entry,
    fe.id_property,
    fe.category_code,
    fe.consumed_quantity_kg,
    fe.current_unit_price,
    fe.reference_month AS consumption_reference_month,
    prod.id_production
   FROM consumo c
     JOIN producao prod ON c.id_stock_control_item = prod.id_stock_control_item
     JOIN analytics_int.vw_int_feeding_expense fe ON c.id_expense_entry = fe.id_expense_entry
  WHERE fe.current_unit_price = 0::double precision OR fe.current_unit_price IS NULL;

CREATE OR REPLACE VIEW analytics_mart.vw_feeding AS
 SELECT feb.id_property,
    feb.reference_month,
    sum(
        CASE
            WHEN feb.category_code = 'VOLUMOSO'::text THEN feb.purchased_quantity_kg
            ELSE 0::double precision
        END) AS voluminous_purchased_quantity,
    sum(
        CASE
            WHEN feb.category_code = 'VOLUMOSO'::text THEN feb.consumed_quantity_kg
            ELSE 0::double precision
        END) AS voluminous_consumed_quantity,
    sum(
        CASE
            WHEN feb.category_code = 'VOLUMOSO'::text THEN feb.amount_total
            ELSE 0::double precision
        END) AS voluminous_amount_total,
    sum(
        CASE
            WHEN feb.category_code = 'CONCENTRADO'::text THEN feb.purchased_quantity_kg
            ELSE 0::double precision
        END) AS concentrate_purchased_quantity,
    sum(
        CASE
            WHEN feb.category_code = 'CONCENTRADO'::text THEN feb.consumed_quantity_kg
            ELSE 0::double precision
        END) AS concentrate_consumed_quantity,
    sum(
        CASE
            WHEN feb.category_code = 'CONCENTRADO'::text THEN feb.amount_total
            ELSE 0::double precision
        END) AS concentrate_amount_total,
    sum(
        CASE
            WHEN feb.category_code = 'MINERAIS'::text THEN feb.purchased_quantity_kg
            ELSE 0::double precision
        END) AS mineral_purchased_quantity,
    sum(
        CASE
            WHEN feb.category_code = 'MINERAIS'::text THEN feb.consumed_quantity_kg
            ELSE 0::double precision
        END) AS mineral_consumed_quantity,
    sum(
        CASE
            WHEN feb.category_code = 'MINERAIS'::text THEN feb.amount_total
            ELSE 0::double precision
        END) AS mineral_amount_total
   FROM analytics_int.vw_int_feeding_expense feb
  GROUP BY feb.id_property, feb.reference_month
  ORDER BY feb.id_property, feb.reference_month;

CREATE OR REPLACE VIEW analytics_mart.vw_feeding_entries_needing_unit_price AS
 SELECT int_f.id_expense_entry,
    int_f.id_property,
    int_f.consumed_quantity_kg,
    int_f.current_unit_price,
    int_f.consumption_reference_month,
    int_f.id_production,
    p.id_planted_culture,
    p.id_culture_harvest_product
   FROM analytics_int.vw_int_feeding_entries_needing_unit_price int_f
     JOIN analytics_mart.vw_forage_production p ON int_f.id_production = p.id_production
  WHERE int_f.id_property = p.id_property;

