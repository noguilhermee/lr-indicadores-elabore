/*
VIEW: analytics_int.vw_int_feeding_entries_needing_unit_price

Finalidade:
Especialização que identifica apenas os lançamentos de vw_int_feeding_expense que possuem
preço unitário zerado e os conecta com a produção de forrageira de origem (id_production)
via movimentação de estoque.

Granularidade:
Uma linha por lançamento de consumo (id_expense_entry) e lote de estoque
(id_stock_control_item) de onde ele saiu. Lançamentos que sacam de mais de um
lote aparecem repetidos.

Regras de negócio:
- Só entram lançamentos com current_unit_price zerado ou nulo, ou seja, alimento
  que não tem valor financeiro na origem.
- O lote é encontrado pelo movimento de saída (source_module = 'EXPENSES',
  movement_type = 'EXIT'). O DISTINCT evita contar duas vezes o mesmo lote quando
  o app grava saídas parciais.
- id_production vem de analytics_int.vw_int_stock_lot_origin, que devolve uma
  linha por lote e escolhe a colheita mais antiga quando o lote recebeu mais de
  uma (16 lotes em 05/08/2026). Antes a produção era buscada aqui com um DISTINCT
  simples, e esses lotes multiplicavam as linhas de consumo — 20 linhas a mais,
  com o custo do mesmo alimento contado duas ou três vezes.
- id_production só existe quando o lote entrou no estoque pela colheita
  (source_module = 'PLANTED_CULTURE_PRODUCTION'). O join é LEFT: até 02/08/2026
  havia 935 consumos com preço zero cujo lote não tinha essa entrada (601 lotes
  de COLHEITA sem ENTRY, 232 de COMPRA com ENTRY de EXPENSES, 161 de COMPRA sem
  ENTRY, 57 sem lote). Com INNER JOIN esses consumos sumiam das duas rotas e
  entravam no indicador com custo zero — 62,4 milhões de kg desde 01/2024.

- PREÇO DE FALLBACK (regra adotada em 02/08/2026)
  stock_unit_price_kg = StockControlItem.unit_value / unit_factor_kg.

  Conferido em 02/08/2026: unit_value é o mesmo unit_price do lançamento que
  originou o lote, na unidade do lançamento — lotes em tonelada trazem 311,50
  com unit_factor_kg 1.000, os mesmos 311,50 do FeedingExpenseEntry de origem.
  Dividir pelo fator entrega R$/kg em 68.536 dos 68.536 lotes conferidos.

  O consumidor deve preferir o custo da safra (rota do id_production), que é
  apurado com a despesa real da cultura, e usar stock_unit_price_kg apenas
  quando aquele não existir.

- stock_purchase_date é a data em que o dinheiro do lote saiu. É a data correta
  para deflacionar o preço de fallback, e não o mês do consumo.

- category_code é projetado para que o consumidor consiga classificar o
  lançamento mesmo sem id_production — sem ele, a categoria só viria do produto
  colhido e as linhas de fallback ficariam sem coluna de destino.

- ORIGEM DO LOTE (regra adotada em 05/08/2026)
  As colunas lot_* vêm de analytics_int.vw_int_stock_lot_origin e descrevem a
  safra que originou o lote, não a safra apontada pelo lançamento. Servem para
  precificar o consumo quando o lançamento não traz produção, e para conciliar
  produção, consumo e saldo por lote na auditoria.

  stock_item_name é o produto do lote. É a chave de último recurso para
  precificar: sem produção e sem valor no lote, o consumidor cai no preço
  mediano do mesmo produto na propriedade e, na falta dele, na base inteira.
  Medido em 05/08/2026: dos 83 consumos sem nenhuma âncora, 77 têm preço do
  mesmo produto na própria fazenda e os 83 têm na base.

Fontes principais:
- analytics_int.vw_int_feeding_expense
- analytics_int.vw_int_stock_lot_origin
- public.StockControlMovement
- public.StockControlItem

Forma de consulta:
SELECT * FROM analytics_int.vw_int_feeding_entries_needing_unit_price;
*/

CREATE OR REPLACE VIEW analytics_int.vw_int_feeding_entries_needing_unit_price AS
WITH consumo AS (
    SELECT DISTINCT s.id_stock_control_item,
        s.source_reference_id AS id_expense_entry
    FROM "StockControlMovement" s
    WHERE s.source_module = 'EXPENSES'::text
      AND s.movement_type = 'EXIT'::"StockControlMovementType"
)
SELECT
    fe.id_expense_entry,
    fe.id_property,
    fe.category_code,
    fe.consumed_quantity_kg,
    fe.current_unit_price,
    fe.reference_month AS consumption_reference_month,
    lot.id_production,
    c.id_stock_control_item,
    sci.origin::text AS stock_origin,
    sci.purchase_date AS stock_purchase_date,
    sci.unit_value AS stock_unit_value,
    sci.unit_factor_kg AS stock_unit_factor_kg,
    (sci.unit_value / NULLIF(sci.unit_factor_kg, 0::double precision))::double precision
        AS stock_unit_price_kg,
    sci.item_name AS stock_item_name,
    lot.in_stock_quantity_kg AS stock_in_stock_quantity_kg,
    lot.purchased_quantity_kg AS stock_purchased_quantity_kg,
    lot.id_production AS lot_id_production,
    lot.id_planted_culture AS lot_id_planted_culture,
    lot.id_area AS lot_id_area,
    lot.id_culture AS lot_id_culture,
    lot.harvest_season AS lot_harvest_season
FROM consumo c
LEFT JOIN "StockControlItem" sci ON sci.id_stock_control_item = c.id_stock_control_item
LEFT JOIN analytics_int.vw_int_stock_lot_origin lot ON lot.id_stock_control_item = c.id_stock_control_item
JOIN analytics_int.vw_int_feeding_expense fe ON c.id_expense_entry = fe.id_expense_entry
WHERE fe.current_unit_price = 0 OR fe.current_unit_price IS NULL;
