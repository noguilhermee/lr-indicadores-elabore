/*
VIEW: analytics_int.vw_int_planted_culture_season

Finalidade:
Expor cada plantio com a safra derivada de planted_at, para servir de ponte
entre o lado do custo (id_area + id_culture + harvest_season) e o lado da
produção e dos lançamentos de alimentação (id_planted_culture).

Granularidade:
Uma linha por id_planted_culture.

Fontes principais:
- public."PlantedCulture"
- analytics_int.calc_harvest_season

Regras de negócio relevantes:
- SEM filtro de is_active. Em PlantedCulture is_active significa "ciclo em
  andamento": false quer dizer que a cultura foi colhida e finalizada.
  Filtrar = true descartaria justamente o histórico que interessa. A coluna é
  exposta como em_andamento para deixar isso explícito no consumo.
- harvest_season é derivada, não armazenada. Ver analytics_int.calc_harvest_season.

Forma de consulta:
SELECT * FROM analytics_int.vw_int_planted_culture_season;
*/

CREATE OR REPLACE VIEW analytics_int.vw_int_planted_culture_season AS
SELECT
    id_planted_culture,
    id_area,
    id_culture,
    planted_area,
    planted_at,
    is_active AS em_andamento,
    analytics_int.calc_harvest_season(planted_at) AS harvest_season
FROM "PlantedCulture";
