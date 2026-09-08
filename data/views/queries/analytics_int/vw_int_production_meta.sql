/*
VIEW: analytics_int.vw_int_production_meta

Finalidade:
Extrair os campos estruturados que o aplicativo grava como JSON dentro de
Production.observation, que a tela mostra mas o modelo relacional não expõe:
nome do produto colhido, unidade da quantidade, estimativa de matéria seca e
forma de colheita.

Granularidade:
Uma linha por id_production.

Fontes principais:
- public."Production"

Regras de negócio relevantes:
- O JSON é duplamente aninhado: observation traz o marcador
  PA_PRODUCTION_META::{...}, e dentro dele a chave observation traz outro JSON
  escapado com o marcador PA_HARVEST_META::{...}. Cobertura de 100%.
- O LIKE do marcador vem antes do cast para jsonb: registros antigos têm
  observação em texto livre e quebrariam o ::jsonb.
- is_active é repassado sem filtro. Nesta tabela significa "registro válido"
  (false = excluído no app) e o filtro é aplicado no mart.
- quantity_unit usa o código real gravado no JSON (sc_60kg), divergente de
  saca_60kg que consta em CultureHarvestProductUnitCatalog.
- dry_matter_estimate passa por NULLIF antes do cast: 79 produções gravam
  string vazia nesse campo, e o cast direto para double precision quebrava
  qualquer SELECT * sobre esta view e sobre analytics_mart.vw_culture_production.
  Vazio recebe o mesmo tratamento do ausente, que é nulo. Nenhum valor
  numérico é alterado.

Forma de consulta:
SELECT * FROM analytics_int.vw_int_production_meta;
*/

CREATE OR REPLACE VIEW analytics_int.vw_int_production_meta AS
SELECT
    p.id_production,
    p.id_planted_culture,
    p.quantity_produced,
    p.harvested_area,
    p.produced_at,
    p.is_active,
    p.created_at,
    p.updated_at,
    prod.j->>'product_name'                                        AS product_name,
    harv.j->'metadata'->>'quantity_unit'                           AS quantity_unit,
    NULLIF(harv.j->'metadata'->>'dry_matter_estimate', '')::double precision AS dry_matter_estimate,
    harv.j->'metadata'->>'harvest_means'                           AS harvest_means
FROM "Production" p
LEFT JOIN LATERAL (
    SELECT CASE WHEN p.observation LIKE 'PA_PRODUCTION_META::%'
           THEN substring(p.observation from 'PA_PRODUCTION_META::(.*)$')::jsonb END AS j
) prod ON true
LEFT JOIN LATERAL (
    SELECT CASE WHEN prod.j->>'observation' LIKE 'PA_HARVEST_META::%'
           THEN substring(prod.j->>'observation' from 'PA_HARVEST_META::(.*)$')::jsonb END AS j
) harv ON true;
