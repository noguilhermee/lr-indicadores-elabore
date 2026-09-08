/*
VIEW: analytics_mart.vw_planted_culture_season

Finalidade:
Expor no mart a ponte entre o plantio e a chave de integração custo x produção.
As tabelas de despesa de cultura só têm id_area + id_culture + harvest_season;
a produção e os lançamentos de alimentação só têm id_planted_culture. Esta view
traduz um no outro para o tratamento em Python.

Granularidade:
Uma linha por id_planted_culture.

Fontes principais:
- analytics_int.vw_int_planted_culture_season

Regras de negócio relevantes:
- harvest_season é derivada de planted_at por analytics_int.calc_harvest_season,
  com corte em julho (plantio de julho em diante pertence à safra YY/YY+1).
  Não existe chave estrangeira de safra no modelo de origem.
- PlantedCulture.is_active significa "ciclo em andamento", e não "registro
  válido". Por isso a camada intermediária não filtra por ele e o expõe aqui
  como em_andamento: filtrar descartaria justamente o histórico já colhido.

Forma de consulta:
SELECT * FROM analytics_mart.vw_planted_culture_season;
*/

CREATE OR REPLACE VIEW analytics_mart.vw_planted_culture_season AS
SELECT
    id_planted_culture,
    id_area,
    id_culture,
    planted_area,
    planted_at,
    em_andamento,
    harvest_season
FROM analytics_int.vw_int_planted_culture_season;
