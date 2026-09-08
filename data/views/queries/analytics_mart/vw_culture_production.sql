/*
VIEW: analytics_mart.vw_culture_production

Finalidade:
Produção colhida por área, cultura e safra, convertida para quilos e
classificada entre VOLUMOSO e CONCENTRADO, para cruzar com o custo de cultura e
permitir o rateio do custo entre as categorias.

Granularidade:
Uma linha por id_area + id_culture + harvest_season + product_name.
Chave única, o que permite validate='m:1' no merge do pandas.

Fontes principais:
- analytics_int.vw_int_production_meta
- analytics_int.vw_int_planted_culture_season
- public."CultureHarvestProduct"

Regras de negócio relevantes:
- Production.is_active = true: aqui significa registro válido (false =
  excluído no app), diferente de PlantedCulture.
- Conversão de unidade a partir do código gravado no JSON: kg = 1,
  ton = 1.000, sc_60kg = 60, kg_ha = multiplicado pela área colhida, nulo
  tratado como kg. O código real é sc_60kg, divergente de saca_60kg do
  catálogo CultureHarvestProductUnitCatalog.
- feeding_category vem de CultureHarvestProduct por nome, com match
  case-insensitive. O segundo LEFT JOIN cobre divergências conhecidas de nome
  entre a produção e o catálogo (grão úmido vs grão úmido/reidratado).
- linhas_sem_conversao e unidades_origem existem para tornar visível o que não
  converteu, em vez de sumir com o registro.
- tem_plantio_em_andamento sinaliza safra ainda aberta: o custo já lançado
  aparece sem a produção correspondente e o custo por quilo fica sobrestimado.

Forma de consulta:
SELECT * FROM analytics_mart.vw_culture_production;
*/

CREATE OR REPLACE VIEW analytics_mart.vw_culture_production AS
WITH prod AS (
    SELECT
        pm.id_production,
        pm.id_planted_culture,
        pm.product_name,
        pm.quantity_unit,
        pm.dry_matter_estimate,
        pm.harvested_area,
        pm.quantity_produced,
        pcs.id_area,
        pcs.id_culture,
        pcs.harvest_season,
        pcs.em_andamento,
        CASE COALESCE(pm.quantity_unit, 'kg')
            WHEN 'kg'      THEN pm.quantity_produced
            WHEN 'ton'     THEN pm.quantity_produced * 1000
            WHEN 'sc_60kg' THEN pm.quantity_produced * 60
            WHEN 'kg_ha'   THEN pm.quantity_produced * pm.harvested_area
            ELSE NULL
        END AS quantidade_kg
    FROM analytics_int.vw_int_production_meta pm
    JOIN analytics_int.vw_int_planted_culture_season pcs
        ON pcs.id_planted_culture = pm.id_planted_culture
    WHERE pm.is_active = true
)
SELECT
    prod.id_area,
    prod.id_culture,
    prod.harvest_season,
    prod.product_name,
    COALESCE(chp.feeding_category::text, chp_alt.feeding_category::text) AS feeding_category,
    SUM(prod.quantidade_kg)                            AS quantidade_kg,
    SUM(prod.harvested_area)                           AS area_colhida,
    ROUND((SUM(prod.quantidade_kg)
           / NULLIF(SUM(prod.harvested_area), 0))::numeric, 1) AS produtividade_kg_ha,
    AVG(prod.dry_matter_estimate)                      AS ms_media,
    COUNT(DISTINCT prod.id_planted_culture)            AS qtd_plantios,
    COUNT(*)                                           AS qtd_producoes,
    COUNT(*) FILTER (WHERE prod.quantidade_kg IS NULL) AS linhas_sem_conversao,
    bool_or(prod.em_andamento)                         AS tem_plantio_em_andamento,
    string_agg(DISTINCT COALESCE(prod.quantity_unit, '(nulo)'), ', ') AS unidades_origem
FROM prod
-- match direto, case-insensitive: resolve "Cana-de-açúcar (Silagem)"
LEFT JOIN "CultureHarvestProduct" chp
    ON chp.id_culture = prod.id_culture
   AND lower(chp.name) = lower(prod.product_name)
   AND chp.is_active = true
-- match para nomes divergentes conhecidos
LEFT JOIN "CultureHarvestProduct" chp_alt
    ON chp.id_culture_harvest_product IS NULL
   AND chp_alt.id_culture = prod.id_culture
   AND chp_alt.is_active = true
   AND lower(chp_alt.name) = lower(
        CASE prod.product_name
            WHEN 'Milho (grão úmido)' THEN 'Milho (grão úmido/reidratado)'
            WHEN 'Sorgo (grão úmido)' THEN 'Sorgo (grão úmido/reidratado)'
            ELSE prod.product_name
        END)
GROUP BY 1,2,3,4,5;
