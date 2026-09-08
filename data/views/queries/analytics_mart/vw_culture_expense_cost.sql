/*
ATENÇÃO: Essa query cria a tabela de gastos com culturas plantadas.
Ela já possui os ids para relacionamento com a produção de forrageira.
O objetivo é termos todos os custos com a data em que foram adquiridos para deflacioná-los corretamente.
FAVOR NÃO ALTERAR SEM PRÉVIO CONSENTIMENTO.
Ass: Filipe Dalboni

VIEW: analytics_mart.vw_culture_expense_cost

Finalidade:
União dos custos de fertilização e de manejo de cultura, no grão do item, para
consumo pelo tratamento em Python.

Granularidade:
Uma linha por item consumido, ou por lote de origem quando o custo vem de baixa
de estoque. A chave de integração com a produção é
id_area + id_culture + harvest_season.

Fontes principais:
- analytics_int.vw_fertilization_cost
- analytics_int.vw_management_cost

Regras de negócio relevantes:
- Colunas listadas explicitamente, nunca SELECT *: se um dia uma das int ganhar
  coluna e a outra não, o UNION ALL falha na hora em vez de desalinhar dado em
  silêncio.
- Sem agregação: cada linha tem sua própria entry_date, necessária para
  deflacionar antes de somar.
- O custo não chega a id_planted_culture. As tabelas de despesa só têm id_area,
  id_culture e harvest_season, e uma área+cultura+safra pode ter vários
  plantios. Rateio por talhão não tem base no dado.

Forma de consulta:
SELECT * FROM analytics_mart.vw_culture_expense_cost;
*/

CREATE OR REPLACE VIEW analytics_mart.vw_culture_expense_cost AS
SELECT tipo_custo, id_product, id_lote_origem, id_parent, id_property,
       id_area, id_culture, harvest_season, operation, stage, product_name,
       unit, quantity, unit_cost, quantity_kg, unit_cost_kg, custo,
       entry_date, applied_at
FROM analytics_int.vw_fertilization_cost
UNION ALL
SELECT tipo_custo, id_product, id_lote_origem, id_parent, id_property,
       id_area, id_culture, harvest_season, operation, stage, product_name,
       unit, quantity, unit_cost, quantity_kg, unit_cost_kg, custo,
       entry_date, applied_at
FROM analytics_int.vw_management_cost;
