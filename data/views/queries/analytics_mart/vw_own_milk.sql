/*
VIEW: analytics_mart.vw_own_milk

Finalidade:
Consolida mensalmente os lançamentos relacionados ao uso interno ou ao custo
de oportunidade do leite produzido na propriedade.

Granularidade:
Uma linha por propriedade e mês (id_property + reference_month).

Fontes principais:
- analytics_int.vw_int_expense

Regras de negócio:
- Consome da view intermediária analytics_int.vw_int_expense (já filtrada por is_active = true e sem ESTOCAR).
- Considera apenas registros da aba OWN_MILK.
- Utiliza o maior preço unitário encontrado no mês (MAX, não média ponderada).
- Indicadores: preço unitário do leite, leite para mão de obra contratada,
  leite descartado, leite para bezerros, leite para mão de obra familiar,
  com quantidades e valores totais separados para cada finalidade.

Forma de consulta:
SELECT * FROM analytics_mart.vw_own_milk;
*/

SELECT eb.id_property,
    eb.reference_month,
    rev.weighted_avg_price AS unit_price,
    sum(
        CASE
            WHEN eb.line_code = 'hired-labor'::text THEN COALESCE(eb.quantity, 0::double precision)
            ELSE 0::double precision
        END) AS hired_labor_quantity,
    sum(
        CASE
            WHEN eb.line_code = 'hired-labor'::text THEN COALESCE(eb.amount_total, 0::double precision)
            ELSE 0::double precision
        END) AS hired_labor_amount_total,
    sum(
        CASE
            WHEN eb.line_code = 'discarded'::text THEN COALESCE(eb.quantity, 0::double precision)
            ELSE 0::double precision
        END) AS discarded_quantity,
    sum(
        CASE
            WHEN eb.line_code = 'discarded'::text THEN COALESCE(eb.amount_total, 0::double precision)
            ELSE 0::double precision
        END) AS discarded_amount_total,
    sum(
        CASE
            WHEN eb.line_code = 'calves'::text THEN COALESCE(eb.quantity, 0::double precision)
            ELSE 0::double precision
        END) AS calves_quantity,
    sum(
        CASE
            WHEN eb.line_code = 'calves'::text THEN COALESCE(eb.amount_total, 0::double precision)
            ELSE 0::double precision
        END) AS calves_amount_total,
    sum(
        CASE
            WHEN eb.line_code = 'family-labor'::text THEN COALESCE(eb.quantity, 0::double precision)
            ELSE 0::double precision
        END) AS family_labor_quantity,
    sum(
        CASE
            WHEN eb.line_code = 'family-labor'::text THEN COALESCE(eb.amount_total, 0::double precision)
            ELSE 0::double precision
        END) AS family_labor_amount_total
   FROM analytics_int.vw_int_expense eb
   LEFT JOIN (
       SELECT id_property,
           reference_month,
           sum(amount_total) / NULLIF(sum(payload_quantity), 0) AS weighted_avg_price
       FROM analytics_int.vw_int_revenue
       WHERE type = 'MILK_SOLD'
         AND amount_total IS NOT NULL
         AND payload_quantity IS NOT NULL
         AND payload_quantity > 0
       GROUP BY id_property, reference_month
   ) rev
     ON rev.id_property = eb.id_property
    AND rev.reference_month = eb.reference_month
  WHERE eb.tab = 'OWN_MILK'::"ExpenseTab"
  GROUP BY eb.id_property, eb.reference_month, rev.weighted_avg_price
  ORDER BY eb.id_property, eb.reference_month;