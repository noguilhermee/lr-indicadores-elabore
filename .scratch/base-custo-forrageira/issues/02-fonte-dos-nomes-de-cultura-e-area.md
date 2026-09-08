# 02 — Fonte para nome de cultura e nome de área

**Tipo:** `wayfinder:research` (AFK) · **Estado:** fechado em 31/08/2026 · **Bloqueia:** [03](03-layout-das-duas-abas.md)

## Question

De onde saem `culture_name` e o nome da área, para a chave `id_area + id_culture + harvest_season`,
sem quebrar a granularidade da base?

Uma base identificada só por UUID não se usa sem um dicionário do lado. Mas nenhuma das duas rotas
que a base consome carrega nome:

- `analytics_mart.vw_culture_expense_cost` projeta `id_area`, `id_culture`, `product_name` — e
  nenhum nome de cultura nem de área.
- `analytics_mart.vw_culture_production` **não tem nem `id_property`**, só
  `id_area + id_culture + harvest_season + product_name`.
- `culture_name` existe em `analytics_int.vw_int_forage_cost_items` e em
  `analytics_mart.vw_forage_production`, mas nas duas o grão é outro (item de custo, e produção).
- Nome de área **não aparece em view alguma** do repositório.

Fazenda e consultor já estão resolvidos: saem de `vw_dim_property_consultant`, que o notebook já
importa. Estes dois não.

## O que responder

1. `Culture` tem coluna de nome estável e única por `id_culture`? Um `LEFT JOIN` por `id_culture`
   preserva a cardinalidade, ou existe cultura com nome duplicado / versionado?
2. `Area` tem nome? Como ele se chama, é único por propriedade, quantas áreas estão sem nome
   preenchido, e ele identifica o talhão para um humano ou é rótulo genérico ("Área 1")?
3. O caminho é acrescentar as colunas às views existentes, criar uma view de dimensão nova
   (`vw_dim_area` / `vw_dim_culture`), ou resolver no pandas com um `read_sql` extra?
   Considerar que `AGENTS.md` exige cabeçalho de finalidade/granularidade/fontes em view nova, e
   que mexer em `analytics_int` tem de preservar os consumidores em `analytics_mart`.

## Resolução esperada

Para cada um dos dois nomes: a fonte, a cardinalidade medida, o caminho recomendado, e — se o nome
de área não existir de forma utilizável — dizer isso claramente, para a base seguir sem ele em vez
de esperar por ele.


## Resolution

Medido no banco de produção em 31/08/2026, somente leitura, sem criar nem alterar view.
Achado completo: [pesquisa-02-nomes-cultura-e-area.md](../pesquisa-02-nomes-cultura-e-area.md).

### Cultura — entra. Join por `id_culture`, no pandas.

Fonte: tabela `"Culture"`, coluna `name`, nunca nula nem vazia. `id_culture` é chave única de
verdade: 70 linhas, 70 ids distintos. Teste de `LEFT JOIN` contra `PlantedCulture` devolveu a
mesma contagem antes e depois (2.416 → 2.416) — sem fan-out.

**Ressalva que muda como a coluna pode ser usada:** o *nome* não é único por id — 52 nomes
distintos para 70 ids, com 15 nomes compartilhados por 2 ou 3 `id_culture` diferentes. A causa é
estrutural, não sujeira: `culture_type` (ANNUAL_MAIN × SECONDARY_CONSORTIUM × PERENNIAL_MAIN) e
registros históricos com `is_predecessor = true`. Consequência: a chave de junção é
`id_culture`, **nunca** `name`; e quem agrupar a base por nome de cultura vai fundir culturas
distintas sem perceber.

Caminho: um `read_sql_query` extra sobre as 70 linhas de `Culture`, merge por `id_culture` com
`validate="m:1"`. Não precisa de view nova. Uma `vw_dim_culture` seria segura no futuro, mas não
é necessária aqui.

### Área — **não entra como identificador.**

Fonte: tabela `"Area"`, coluna `name`, texto livre. `id_area` é chave única (6.221/6.221) e o
preenchimento é ótimo: só 0,05% vazio no total, 0,07% no universo real da base (1.441 áreas
usadas em `PlantedCulture`). O problema não é nulo — é que **o campo não identifica talhão**.

- Dentro da mesma propriedade o nome se repete: 372 grupos (propriedade, nome) colidem na tabela
  inteira, chegando a 14 áreas com o mesmo nome numa única fazenda. No universo da base, 43
  linhas (2,98%, 16 propriedades) ainda colidem.
- Só 24,24% dos nomes são globalmente únicos na tabela inteira (40,39% dentro do universo da
  base). Os valores mais frequentes são vocabulário de **uso do solo e de cultura** — reserva
  legal, APP, benfeitoria, pastagem, sede, e nomes de cultura literais — sobrepondo-se a
  `AreaUsage.name` e a `Culture.name`.

**Veredito explícito, como o ticket pediu: o nome de área não identifica o talhão de forma
utilizável. A base segue sem ele em vez de esperar por ele.** Se um rótulo descritivo for
desejado depois, resolve-se do mesmo jeito (merge por `id_area`, `validate="m:1"`), mas
documentado como não-único e nunca usado como chave de exibição ou de deduplicação. **Não criar
`vw_dim_area`**: empacotar isso como "dimensão" sugeriria uma limpeza que o dado não tem.
