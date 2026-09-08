# Pesquisa 01 — Valores reais de `stage` em `analytics_mart.vw_culture_expense_cost`

**Data da medição:** 31/08/2026, consulta direta ao banco de produção (somente leitura, via
`psycopg`/`sqlalchemy`, mesmo padrão de conexão da célula 4 de `app/Elabore Indicadores.ipynb`).
Nenhum objeto do banco foi criado, alterado ou removido.

Responde ao ticket [`issues/01-valores-reais-de-stage.md`](issues/01-valores-reais-de-stage.md).

## Contexto de onde a lista hoje vem do código

Duas listas de etapas aparecem no notebook e **não são a mesma coisa**:

- `MAPA_ETAPAS_CUSTO` (célula 45) mapeia as cinco *colunas* da view antiga `vw_forage_cost`
  (`pre_planting_cost`, `planting_cost`, `cultural_treatments_cost`, `harvest_grain_cost`,
  `harvest_whole_plant_cost`) para os cinco rótulos de etapa. Essa é a rota **antiga, incompleta**
  (só cobre `CultureExpenseManagement`, nunca fertilização) e serve só para a comparação da seção
  3.4.2.1-C.
- A rota real para a base de custo por etapa é `df_custo_cultura_safra_etapa` (célula 36,
  §3.4.1), que agrupa pela coluna `stage` **de `vw_culture_expense_cost`** (união de fertilização
  + manejo), normalizada com `.astype("string").str.strip().str.upper().fillna("ETAPA_NAO_INFORMADA")`
  — sem nenhuma lista fixa de valores aceitos. É essa coluna `stage`, bruta, que este documento
  investiga.

## Consultas usadas

Todas contra `analytics_mart.vw_culture_expense_cost`. Executadas em 31/08/2026.

### Q1 — `SELECT DISTINCT stage` bruto, contado por linhas e soma de `custo`, por `tipo_custo`

```sql
SELECT
    tipo_custo,
    stage AS stage_bruto,
    COUNT(*)      AS n_linhas,
    SUM(custo)    AS soma_custo
FROM analytics_mart.vw_culture_expense_cost
GROUP BY tipo_custo, stage
ORDER BY tipo_custo, n_linhas DESC;
```

**Resultado:**

| tipo_custo | stage_bruto | n_linhas | soma_custo (R$) |
|---|---|---:|---:|
| fertilizante | TRATOS_CULTURAIS | 1.630 | 71.378.700,00 |
| fertilizante | PLANTIO | 1.599 | 282.683.100,00 |
| fertilizante | PRE_PLANTIO | 117 | 815.880,80 |
| fertilizante | *(NULL)* | 36 | 499.477,60 |
| manejo | TRATOS_CULTURAIS | 6.125 | 31.830.620,00 |
| manejo | PLANTIO | 4.233 | 47.368.410,00 |
| manejo | COLHEITA_ENSILAGEM_PLANTA_INTEIRA | 3.855 | 48.570.070,00 |
| manejo | PRE_PLANTIO | 475 | 6.398.660,00 |
| manejo | COLHEITA_ENSILAGEM_GRAO | 135 | 903.781,70 |
| manejo | *(NULL)* | 97 | 356.577,70 |

(Valores de `soma_custo` arredondados na tabela; os números exatos estão nos CSVs gerados pelo
script de pesquisa, mantidos fora do repositório.)

Totais agregados (sem separar `tipo_custo`):

| stage_bruto | n_linhas | soma_custo (R$) |
|---|---:|---:|
| TRATOS_CULTURAIS | 7.755 | 103.209.300,00 |
| PLANTIO | 5.832 | 330.051.500,00 |
| COLHEITA_ENSILAGEM_PLANTA_INTEIRA | 3.855 | 48.570.070,00 |
| PRE_PLANTIO | 592 | 7.214.540,00 |
| COLHEITA_ENSILAGEM_GRAO | 135 | 903.781,70 |
| *(NULL)* | 133 | 856.055,30 |

**Total geral medido:** 18.302 linhas, R$ 490.805.300,00 de custo (soma bruta, não deflacionada).

**Conjunto bruto de `stage`, sem normalizar: exatamente 5 valores não nulos** —
`PRE_PLANTIO`, `PLANTIO`, `TRATOS_CULTURAIS`, `COLHEITA_ENSILAGEM_GRAO`,
`COLHEITA_ENSILAGEM_PLANTA_INTEIRA` — mais `NULL`. Nenhuma variação de caixa, acento ou grafia
apareceu já no dado bruto.

### Q2 — mesmo, após `upper(trim(stage))` (reproduz a normalização da célula 36)

```sql
SELECT
    tipo_custo,
    upper(trim(stage)) AS stage_normalizado,
    COUNT(*)      AS n_linhas,
    SUM(custo)    AS soma_custo
FROM analytics_mart.vw_culture_expense_cost
GROUP BY tipo_custo, upper(trim(stage))
ORDER BY tipo_custo, n_linhas DESC;
```

E o colapso bruto → normalizado:

```sql
SELECT
    upper(trim(stage)) AS stage_normalizado,
    COUNT(DISTINCT stage) AS n_variantes_brutas,
    string_agg(DISTINCT stage, ' | ') AS variantes_brutas
FROM analytics_mart.vw_culture_expense_cost
GROUP BY upper(trim(stage))
ORDER BY n_variantes_brutas DESC;
```

**Resultado:** os números de `n_linhas` e `soma_custo` por `stage_normalizado` são **idênticos**
aos de Q1 por `stage_bruto` (comparação linha a linha nos CSVs). O colapso bruto→normalizado deu
**1 variante bruta para cada 1 valor normalizado**, em todos os 5 casos — nenhum valor bruto
colapsa com outro. Ou seja: `upper(trim(...))` não muda nada neste banco. Não há
`Pre_Plantio`/`pre_plantio`/`PRE-PLANTIO`/etc. coexistindo — só a grafia canônica já gravada.

### Q3 — quanto do custo cai em `stage` nulo ou vazio (`ETAPA_NAO_INFORMADA`)

```sql
SELECT
    CASE WHEN stage IS NULL OR trim(stage) = '' THEN 'NULO_OU_VAZIO' ELSE 'INFORMADO' END AS categoria,
    COUNT(*)   AS n_linhas,
    SUM(custo)::numeric AS soma_custo,
    ROUND(100.0 * SUM(custo)::numeric / SUM(SUM(custo)::numeric) OVER (), 2) AS pct_do_custo_total
FROM analytics_mart.vw_culture_expense_cost
GROUP BY categoria
ORDER BY categoria;
```

**Resultado:**

| categoria | n_linhas | soma_custo (R$) | % do custo total |
|---|---:|---:|---:|
| INFORMADO | 18.169 | 489.949.200,00 | 99,83% |
| NULO_OU_VAZIO (→ `ETAPA_NAO_INFORMADA`) | 133 | 856.055,30 | 0,17% |

Verificação complementar (contagem direta de `NULL` vs string vazia não-nula):

```sql
SELECT
    COUNT(*) AS total_linhas,
    SUM(custo)::numeric AS total_custo,
    COUNT(*) FILTER (WHERE stage IS NULL) AS n_stage_null,
    COUNT(*) FILTER (WHERE stage IS NOT NULL AND trim(stage) = '') AS n_stage_vazio_nao_null,
    COUNT(DISTINCT stage) AS n_distinct_stage_raw
FROM analytics_mart.vw_culture_expense_cost;
```

`total_linhas = 18.302`, `total_custo = 490.805.300,00`, `n_stage_null = 133`,
`n_stage_vazio_nao_null = 0`, `n_distinct_stage_raw = 5`.

Não existe string vazia (`''`) em `stage` neste banco — todo caso de "não informado" é `NULL`
puro. As 133 linhas nulas se dividem em 36 de fertilização (R$ 499.477,60) e 97 de manejo
(R$ 356.577,70).

### Q4 — fertilização e manejo usam o mesmo vocabulário de etapa?

```sql
WITH normalizado AS (
    SELECT DISTINCT tipo_custo, upper(trim(stage)) AS stage_normalizado
    FROM analytics_mart.vw_culture_expense_cost
)
SELECT
    COALESCE(f.stage_normalizado, m.stage_normalizado) AS stage_normalizado,
    (f.stage_normalizado IS NOT NULL) AS existe_em_fertilizante,
    (m.stage_normalizado IS NOT NULL) AS existe_em_manejo
FROM (SELECT stage_normalizado FROM normalizado WHERE tipo_custo = 'fertilizante') f
FULL OUTER JOIN (SELECT stage_normalizado FROM normalizado WHERE tipo_custo = 'manejo') m
    ON f.stage_normalizado = m.stage_normalizado
ORDER BY 1;
```

**Resultado:**

| stage_normalizado | existe em fertilizante | existe em manejo |
|---|---|---|
| COLHEITA_ENSILAGEM_GRAO | não | sim |
| COLHEITA_ENSILAGEM_PLANTA_INTEIRA | não | sim |
| PLANTIO | sim | sim |
| PRE_PLANTIO | sim | sim |
| TRATOS_CULTURAIS | sim | sim |
| *(NULL)* | não | não *(ambos os lados têm NULL, mas `NULL = NULL` não casa no `FULL OUTER JOIN`; aparece em duas linhas separadas — artefato de SQL, não dois valores nulos diferentes)* |

**Conclusão:** os vocabulários **são diferentes, mas por subconjunto, não por grafia divergente**.
Fertilização nunca lança as duas etapas de colheita/ensilagem (`COLHEITA_ENSILAGEM_GRAO`,
`COLHEITA_ENSILAGEM_PLANTA_INTEIRA`) — o que é coerente com o domínio: não se aplica fertilizante
no momento da colheita. Manejo usa as 5 etapas. Nenhum dos dois lados usa um rótulo que o outro
não reconheça.

## Achados consolidados

1. **Conjunto fechado e pequeno**: exatamente 5 valores brutos de `stage` + `NULL`. São
   `PRE_PLANTIO`, `PLANTIO`, `TRATOS_CULTURAIS`, `COLHEITA_ENSILAGEM_GRAO`,
   `COLHEITA_ENSILAGEM_PLANTA_INTEIRA` — **idêntico, valor por valor, à lista hardcoded no
   notebook** (`ETAPA_NAO_INFORMADA` é o rótulo aplicado ao `NULL`, não um valor de banco).
2. **Normalização é inócua neste banco**: `upper(trim(stage))` não colapsa nada — 1 variante
   bruta para 1 valor normalizado em todos os casos. Não há problema de caixa/acento/espaço a
   resolver hoje.
3. **Custo em etapa não informada é pequeno**: 133 linhas de 18.302 (0,73% das linhas),
   R$ 856.055,30 de R$ 490.805.300,00 (**0,17% do custo total**). Toda a ausência é `NULL`; não
   existe string vazia.
4. **Fertilização e manejo usam vocabulários diferentes, mas por subconjunto**: fertilização usa
   3 das 5 etapas (nunca as de colheita/ensilagem); manejo usa as 5. Não há grafia divergente
   entre os dois lados para a mesma etapa.

## Limitações desta medição

- Consulta rodada uma única vez em 31/08/2026 contra o banco de produção; não foi comparado
  com uma medição anterior (não há uma para comparar, este é o primeiro `SELECT DISTINCT` real
  sobre esta coluna neste esforço).
- Os CSVs brutos de cada consulta (`q1_*.csv`, `q2_*.csv`, `q3_*.csv`, `q4_*.csv`) ficaram no
  diretório de scratch da sessão do agente, não neste repositório — não fazem parte da entrega
  versionada, só serviram de apoio para montar as tabelas acima.
- Não foi medido: distribuição por `harvest_season` ou por `tipo_custo` cruzado com etapa nula
  isoladamente por propriedade (fora do escopo das 4 perguntas do ticket).

## Veredito

**O layout largo se sustenta.** O conjunto real de `stage` em
`analytics_mart.vw_culture_expense_cost` tem exatamente 5 valores não nulos, todos já na grafia
canônica que o notebook espera, mais `NULL` (0,17% do custo) que vira `ETAPA_NAO_INFORMADA`. Isso
bate exatamente com a lista de 6 colunas (5 etapas + não informada) assumida no código hoje —
uma coluna por etapa numa aba larga cobre 100% dos valores observados, sem coluna "outros" e sem
risco de a normalização (`upper`/`trim`) esconder uma variante que hoje não existe.
