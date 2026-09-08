/*
VIEW: analytics_int.vw_int_feeding_expense

Finalidade:
Camada intermediária de despesas de alimentação. Combina lançamentos de
FeedingExpenseEntry e ExpenseEntry, converte unidades para quilogramas e projeta
as colunas consumidas pelas views filhas e analíticas.

Granularidade:
Uma linha por item de despesa de alimentação (id_expense_entry).
Confirmado em 02/08/2026: FeedingExpenseEntry não tem mais de uma linha por
id_expense_entry, portanto o join com ExpenseEntry não gera fan-out.

Fontes principais:
- public.FeedingExpenseEntry
- public.ExpenseEntry

Regras de negócio:
- Considera somente lançamentos ativos (ExpenseEntry.is_active = true).
- Exclui operações de armazenamento (ESTOCAR): o item estocado só vira custo
  quando é consumido, por meio de um lançamento CONSUMIR posterior. O filtro usa
  FeedingExpenseEntry.operation, que é a operação do item de alimentação.
  Conferido em 05/08/2026: a coluna não tem nulo (67.362 ESTOCAR_CONSUMIR,
  11.015 CONSUMIR, 1.011 ESTOCAR), então a comparação direta não descarta linha
  por NULL.
- Converte toneladas para kg (fator 1.000).
- Converte saca ('feeding-unit-saca-1778245226249') para kg (fator 25).
- CUSTO PELO CONSUMO (regra adotada em 02/08/2026)
  amount_total passa a ser unit_price * consumed_quantity, e não mais
  ExpenseEntry.amount_total.

  Motivo: ExpenseEntry.amount_total registra o valor da COMPRA. Em
  ESTOCAR_CONSUMIR o produtor compra e consome no mesmo lançamento, mas a
  quantidade comprada costuma ser maior que a consumida, e a sobra vai para o
  estoque. O valor cheio da compra entrava no custo do mês; depois, quando a
  sobra era consumida, o lançamento CONSUMIR trazia outro amount_total e o
  mesmo dinheiro era contado duas vezes. Auditoria de 02/08/2026: 3.585
  lançamentos em 324 propriedades, R$ 76.952.694 desde 01/2024.

  A conta usa consumed_quantity BRUTA, sem o fator de conversão, porque
  unit_price é por unidade do lançamento (R$/ton nos lançamentos em tonelada) e
  não por quilo. Aplicar o fator inflaria em 1.000x os lançamentos em tonelada.

  Consequência esperada: o custo total de alimentação cai cerca de 5,4% e passa
  a acompanhar o mês do consumo, não o da compra.

- Lançamentos com unit_price zerado continuam com amount_total zero. É o caso da
  forrageira produzida na própria fazenda, precificada adiante por
  analytics_int.vw_int_feeding_entries_needing_unit_price e pelo notebook.
- purchase_amount_total preserva o valor de compra original, para reconciliação
  com a tela do app e com as versões anteriores do indicador.

Forma de consulta:
SELECT * FROM analytics_int.vw_int_feeding_expense;
*/

CREATE OR REPLACE VIEW analytics_int.vw_int_feeding_expense AS
SELECT
    f.id_expense_entry,
    f.id_property,
    f.unit_price AS current_unit_price,
    date_trunc('month'::text, e.reference_month)::date AS reference_month,
    f.category_code,
    (f.purchased_quantity * CASE
        WHEN lower(TRIM(BOTH FROM e.unit)) = 'ton'::text THEN 1000
        WHEN lower(TRIM(BOTH FROM e.unit)) = 'feeding-unit-saca-1778245226249'::text THEN 25
        ELSE 1
    END)::double precision AS purchased_quantity_kg,
    (f.consumed_quantity * CASE
        WHEN lower(TRIM(BOTH FROM e.unit)) = 'ton'::text THEN 1000
        WHEN lower(TRIM(BOTH FROM e.unit)) = 'feeding-unit-saca-1778245226249'::text THEN 25
        ELSE 1
    END)::double precision AS consumed_quantity_kg,
    -- Custo do que foi consumido no mês, na unidade em que o preço foi digitado.
    (COALESCE(f.unit_price, 0::double precision)
     * COALESCE(f.consumed_quantity, 0::double precision))::double precision AS amount_total,
    -- Valor da compra, mantido apenas para conferência.
    e.amount_total AS purchase_amount_total
FROM "FeedingExpenseEntry" f
JOIN "ExpenseEntry" e ON f.id_expense_entry = e.id_expense_entry
WHERE e.is_active = true
  AND f.operation <> 'ESTOCAR'::"ExpenseOperation";
