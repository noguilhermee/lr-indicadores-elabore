-- DDL das views de custo de cultura como estavam no banco antes da correcao D7 (02/08/2026).
-- Rollback: executar este arquivo inteiro.

CREATE OR REPLACE VIEW analytics_int.vw_management_cost AS
 SELECT 'manejo'::text AS tipo_custo,
    p.id_management_product AS id_product,
    sc.id_management_product_stock AS id_lote_origem,
    m.id_management AS id_parent,
    m.id_property,
    m.id_area,
    m.id_culture,
    m.harvest_season,
    p.operation::text AS operation,
    p.stage::text AS stage,
    p.product_name,
    p.unit,
    sc.quantity,
    sc.unit_cost,
    sc.quantity_kg,
    sc.unit_cost_kg,
    sc.line_total AS custo,
    origem.applied_at AS entry_date,
    p.applied_at
   FROM "CultureExpenseManagementStockConsumption" sc
     JOIN "CultureExpenseManagementProduct" p ON p.id_management_product = sc.id_management_product_consumer AND p.is_active = true
     JOIN "CultureExpenseManagementProduct" origem ON origem.id_management_product = sc.id_management_product_stock
     JOIN "CultureExpenseManagement" m ON m.id_management = p.id_management AND m.is_active = true
  WHERE sc.is_active = true
UNION ALL
 SELECT 'manejo'::text AS tipo_custo,
    p.id_management_product AS id_product,
    NULL::text AS id_lote_origem,
    m.id_management AS id_parent,
    m.id_property,
    m.id_area,
    m.id_culture,
    m.harvest_season,
    p.operation::text AS operation,
    p.stage::text AS stage,
    p.product_name,
    p.unit,
    p.quantity,
    p.unit_cost,
    p.quantity_kg,
    p.unit_cost_kg,
    p.line_total AS custo,
    p.applied_at AS entry_date,
    p.applied_at
   FROM "CultureExpenseManagementProduct" p
     JOIN "CultureExpenseManagement" m ON m.id_management = p.id_management AND m.is_active = true
  WHERE p.is_active = true AND p.operation::text IS DISTINCT FROM 'ESTOCAR'::text AND NOT (EXISTS ( SELECT 1
           FROM "CultureExpenseManagementStockConsumption" sc
          WHERE sc.id_management_product_consumer = p.id_management_product AND sc.is_active = true));

CREATE OR REPLACE VIEW analytics_int.vw_fertilization_cost AS
 SELECT 'fertilizante'::text AS tipo_custo,
    p.id_fertilization_product AS id_product,
    sc.id_fertilization_product_stock AS id_lote_origem,
    f.id_fertilization AS id_parent,
    f.id_property,
    f.id_area,
    f.id_culture,
    f.harvest_season,
    p.operation::text AS operation,
    p.stage::text AS stage,
    p.product_name,
    p.unit,
    sc.quantity,
    sc.unit_cost,
    sc.quantity_kg,
    sc.unit_cost_kg,
    sc.line_total AS custo,
    origem.applied_at AS entry_date,
    p.applied_at
   FROM "CultureExpenseFertilizationStockConsumption" sc
     JOIN "CultureExpenseFertilizationProduct" p ON p.id_fertilization_product = sc.id_fertilization_product_consumer AND p.is_active = true
     JOIN "CultureExpenseFertilizationProduct" origem ON origem.id_fertilization_product = sc.id_fertilization_product_stock
     JOIN "CultureExpenseFertilization" f ON f.id_fertilization = p.id_fertilization AND f.is_active = true
  WHERE sc.is_active = true
UNION ALL
 SELECT 'fertilizante'::text AS tipo_custo,
    p.id_fertilization_product AS id_product,
    NULL::text AS id_lote_origem,
    f.id_fertilization AS id_parent,
    f.id_property,
    f.id_area,
    f.id_culture,
    f.harvest_season,
    p.operation::text AS operation,
    p.stage::text AS stage,
    p.product_name,
    p.unit,
    p.quantity,
    p.unit_cost,
    p.quantity_kg,
    p.unit_cost_kg,
    p.line_total AS custo,
    p.applied_at AS entry_date,
    p.applied_at
   FROM "CultureExpenseFertilizationProduct" p
     JOIN "CultureExpenseFertilization" f ON f.id_fertilization = p.id_fertilization AND f.is_active = true
  WHERE p.is_active = true AND p.operation::text IS DISTINCT FROM 'ESTOCAR'::text AND NOT (EXISTS ( SELECT 1
           FROM "CultureExpenseFertilizationStockConsumption" sc
          WHERE sc.id_fertilization_product_consumer = p.id_fertilization_product AND sc.is_active = true));
