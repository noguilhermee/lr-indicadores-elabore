/*
FUNÇÃO: analytics_int.calc_harvest_season(timestamp) -> text

Finalidade:
Derivar o rótulo de safra (YY/YY) a partir de uma data de plantio.

Granularidade:
Escalar. Uma safra por data.

Fontes principais:
Nenhuma. Função pura, IMMUTABLE.

Regras de negócio relevantes:
- Não existe chave estrangeira de safra no modelo de origem. "HarvestSeason" é
  catálogo de rótulos, sem datas. Nas despesas a safra é texto direto em
  CultureExpense*.harvest_season; em PlantedCulture só existe planted_at.
- Corte em julho: plantio de julho em diante pertence à safra YY/YY+1.
- Validado com casos reais: plantio 10/2025 -> 25/26; 10/2024 -> 24/25;
  02/2026 -> 25/26; 04/2025 -> 24/25.

Forma de consulta:
SELECT analytics_int.calc_harvest_season('2025-10-15'::timestamp);
*/

CREATE OR REPLACE FUNCTION analytics_int.calc_harvest_season(p_date timestamp)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN EXTRACT(MONTH FROM p_date) >= 7
            THEN LPAD((EXTRACT(YEAR FROM p_date)::int % 100)::text, 2, '0') || '/' ||
                 LPAD(((EXTRACT(YEAR FROM p_date)::int + 1) % 100)::text, 2, '0')
        ELSE LPAD(((EXTRACT(YEAR FROM p_date)::int - 1) % 100)::text, 2, '0') || '/' ||
             LPAD((EXTRACT(YEAR FROM p_date)::int % 100)::text, 2, '0')
    END
$$;
