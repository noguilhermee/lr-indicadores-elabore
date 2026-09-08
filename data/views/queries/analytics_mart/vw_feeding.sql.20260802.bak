/*
VIEW: analytics_mart.vw_feeding

Finalidade:
Consolida mensalmente as despesas e quantidades de alimentos comprados e
consumidos pelas propriedades, separando volumosos, concentrados e minerais.

Granularidade:
Uma linha por propriedade e mês (id_property + reference_month).

Fontes principais:
- analytics_int.vw_int_feeding_expense

Regras de negócio:
- Consome da view intermediária analytics_int.vw_int_feeding_expense (já filtrada por is_active = true, sem ESTOCAR e com unidades convertidas).
- Agrupa todas as quantidades e valores em nível mensal por propriedade.
- Indicadores: quantidade comprada (kg), quantidade consumida (kg) e valor total (R$),
  separados entre volumoso, concentrado e mineral.

Forma de consulta:
SELECT * FROM analytics_mart.vw_feeding;
*/

SELECT feb.id_property,
    feb.reference_month,
    sum(CASE WHEN feb.category_code = 'VOLUMOSO'   ::text THEN feb.purchased_quantity_kg ELSE 0::double precision END) AS voluminous_purchased_quantity,
    sum(CASE WHEN feb.category_code = 'VOLUMOSO'   ::text THEN feb.consumed_quantity_kg  ELSE 0::double precision END) AS voluminous_consumed_quantity,
    sum(CASE WHEN feb.category_code = 'VOLUMOSO'   ::text THEN feb.amount_total          ELSE 0::double precision END) AS voluminous_amount_total,
    sum(CASE WHEN feb.category_code = 'CONCENTRADO'::text THEN feb.purchased_quantity_kg ELSE 0::double precision END) AS concentrate_purchased_quantity,
    sum(CASE WHEN feb.category_code = 'CONCENTRADO'::text THEN feb.consumed_quantity_kg  ELSE 0::double precision END) AS concentrate_consumed_quantity,
    sum(CASE WHEN feb.category_code = 'CONCENTRADO'::text THEN feb.amount_total          ELSE 0::double precision END) AS concentrate_amount_total,
    sum(CASE WHEN feb.category_code = 'MINERAIS'   ::text THEN feb.purchased_quantity_kg ELSE 0::double precision END) AS mineral_purchased_quantity,
    sum(CASE WHEN feb.category_code = 'MINERAIS'   ::text THEN feb.consumed_quantity_kg  ELSE 0::double precision END) AS mineral_consumed_quantity,
    sum(CASE WHEN feb.category_code = 'MINERAIS'   ::text THEN feb.amount_total          ELSE 0::double precision END) AS mineral_amount_total
    
    FROM analytics_int.vw_int_feeding_expense feb
    GROUP BY feb.id_property, feb.reference_month
    ORDER BY feb.id_property, feb.reference_month;