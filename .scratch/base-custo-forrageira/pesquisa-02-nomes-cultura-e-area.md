# Pesquisa 02 — Fonte de `culture_name` e nome de área

**Data da medição:** 31/08/2026
**Ticket:** `.scratch/base-custo-forrageira/issues/02-fonte-dos-nomes-de-cultura-e-area.md`
**Método:** conexão somente-leitura ao Postgres via SQLAlchemy/psycopg (`.env` da raiz do projeto),
consultas `pandas.read_sql_query`. Nenhuma view foi criada, alterada ou consultada com efeito
colateral. Nenhum nome real de área/propriedade aparece neste arquivo (regra de privacidade do
ticket) — apenas contagens, padrões estruturais e nomes de cultura (que não são dado de cliente).

---

## 1. Tabela `Culture`

### Schema medido

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name='Culture'
ORDER BY ordinal_position;
```

| coluna | tipo | nullable |
|---|---|---|
| id_culture | text | NO |
| name | text | NO |
| created_at | timestamp | NO |
| updated_at | timestamp | YES |
| is_active | boolean | NO |
| culture_type | enum (`ANNUAL_MAIN`, `PERENNIAL_MAIN`, `SECONDARY_CONSORTIUM`) | NO |
| is_predecessor | boolean | NO |

### Cardinalidade medida

```sql
SELECT COUNT(*) FROM "Culture";                                   -- 70
SELECT COUNT(DISTINCT id_culture) FROM "Culture";                 -- 70
SELECT id_culture, COUNT(*) FROM "Culture" GROUP BY id_culture HAVING COUNT(*) > 1;  -- 0 linhas
SELECT COUNT(DISTINCT name), COUNT(DISTINCT id_culture) FROM "Culture";  -- 52 nomes / 70 ids
```

- 70 linhas, 70 `id_culture` distintos → **`id_culture` é chave única** (nenhum id repetido).
- `name` **nunca é nulo nem vazio** (medido: 0 linhas com `name IS NULL OR trim(name)=''`).
- **`name` NÃO é único por `id_culture`**: existem só 52 nomes distintos para 70 ids. 15 nomes são
  compartilhados por 2 ou 3 `id_culture` diferentes (ex.: "Milho", "Sorgo", "Aveia", "Trigo",
  "Alfafa" — nomes de cultura, não dado de cliente, citados livremente). Inspecionando as linhas
  duplicadas:

```sql
SELECT c.name, c.id_culture, c.culture_type, c.is_active, c.is_predecessor
FROM "Culture" c
WHERE c.name IN (SELECT name FROM "Culture" GROUP BY name HAVING COUNT(DISTINCT id_culture) > 1)
ORDER BY c.name, c.culture_type;
```

A causa da duplicação de nome é estrutural, não erro de cadastro: o mesmo nome de cultura existe
como registros **`id_culture` diferentes por `culture_type`** (ex.: "Milho" como `ANNUAL_MAIN`
versus a mesma cultura usada como consórcio secundário teria `SECONDARY_CONSORTIUM` — quando
aplicável), e por **histórico/versão** (ex.: um `id_culture` de "Milho" com `is_active=False,
is_predecessor=True`, ou seja, um registro superado por outro id mais novo do mesmo nome).

### Teste de preservação de granularidade (o que o ticket pediu para medir)

```sql
SELECT
  (SELECT COUNT(*) FROM "PlantedCulture") AS pc_rows,
  (SELECT COUNT(*) FROM "PlantedCulture" pc LEFT JOIN "Culture" c ON pc.id_culture = c.id_culture) AS pc_rows_after_join;
```

Resultado: **2.416 linhas antes e 2.416 depois do `LEFT JOIN`** — nenhum fan-out. Também não há
`id_culture` órfão (usado em `PlantedCulture` mas ausente em `Culture`): 0.

### Veredito — cultura

- **Fonte:** tabela `"Culture"`, coluna `name` (não schema `analytics_int`/`analytics_mart` — é
  tabela de origem do Elabore).
- **Cardinalidade medida:** `id_culture` é chave única (1 linha por id, 70/70). Um
  `LEFT JOIN ... ON x.id_culture = c.id_culture` é **seguro e 1:1**, comprovado pelo teste de
  contagem antes/depois. O nome em si **não é único** (repete entre ids diferentes por
  `culture_type`/histórico), então o join deve ser sempre por `id_culture`, nunca por `name`.
- **Caminho recomendado:** como o destino é uma base nova e independente montada no notebook (não
  uma view de produção — ver `MAP.md`, "Nada é construído por este mapa"), a rota de menor raio de
  impacto é **resolver no pandas**: um `read_sql_query('SELECT id_culture, name AS culture_name,
  culture_type FROM "Culture"')` (70 linhas, praticamente estático) mesclado à base final por
  `id_culture` com `validate="m:1"`. Isso evita tocar em `analytics_int`/`analytics_mart` e nas
  regras do `AGENTS.md` sobre cabeçalho de view nova. Se no futuro o time quiser reutilizar isso em
  mais de um lugar, `"Culture"` é pequena, estável e 1:1 o bastante para justificar uma
  `analytics_mart.vw_dim_culture` seguindo o modelo de `vw_dim_property.sql` (cabeçalho de
  finalidade/granularidade/fontes, `SELECT` explícito, `ORDER BY id_culture`) — mas isso não é
  necessário para fechar este ticket.

---

## 2. Tabela `Area`

### Schema medido

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name='Area'
ORDER BY ordinal_position;
```

Colunas relevantes: `id_area` (text, NO), `id_property` (text, NO), `id_area_usage` (text, NO),
`name` (text, NO), `hectares_owned`, `hectares_rented`, `raw_land_value`, `is_active`,
`started_at`, `finished_at`, `is_irrigated`, etc. **`Area` tem coluna `name`** (chama-se
literalmente `name`, texto livre, não nulo no schema).

### Cardinalidade e nulos

```sql
SELECT COUNT(*), COUNT(DISTINCT id_area) FROM "Area";     -- 6221 / 6221
SELECT id_area, COUNT(*) FROM "Area" GROUP BY id_area HAVING COUNT(*)>1;  -- 0 linhas
SELECT COUNT(*) FROM "Area" WHERE name IS NULL OR trim(name)='';         -- 3 de 6221 (0,05%)
```

`id_area` é chave única (6.221 linhas = 6.221 ids). `name` é NOT NULL no schema, mas 3 linhas têm
string vazia (`''`) — praticamente irrelevante em volume.

Restringindo às áreas que de fato entram na chave da base (`id_area` presente em
`"PlantedCulture"`, universo = 1.441 áreas distintas):

```sql
SELECT COUNT(*) FROM "Area" a
WHERE (a.name IS NULL OR trim(a.name)='')
  AND a.id_area IN (SELECT DISTINCT id_area FROM "PlantedCulture");
-- 1 de 1441 (0,07%)
```

Ou seja: **nome preenchido em praticamente 100% das áreas que a base usa.** Preenchimento não é o
problema.

### Unicidade do nome dentro da propriedade

```sql
SELECT id_property, name, COUNT(*) AS n
FROM "Area"
GROUP BY id_property, name
HAVING COUNT(*) > 1;
```

- Na tabela `Area` inteira: **372 grupos** (id_property, name) com nome repetido, somando **1.103
  linhas** em **120 propriedades**, com até **14 áreas da mesma propriedade compartilhando o
  mesmo nome**.
- Restrito ao universo que a base usa (`id_area` em `PlantedCulture`, 1.441 áreas): **43 linhas
  (2,98%)** ainda colidem com outra área de mesmo nome na mesma propriedade, em **16
  propriedades**.

**Conclusão parcial: nome de área NÃO é único dentro da propriedade** — em ~3% das áreas do
universo da base, duas ou mais áreas físicas diferentes de uma mesma fazenda têm exatamente o
mesmo `name`.

### O nome identifica o talhão, ou é rótulo genérico? (medição de padrão)

Duas medições independentes, sem expor nenhum nome real:

**(a) Classificação por padrão estrutural** (regex sobre nome normalizado — minúsculo, sem
acento), aplicada às 6.221 linhas de `Area`:

| categoria | critério | n | % |
|---|---|---|---|
| `generic_template` | só palavra genérica + número, ex. padrão "Área"/"Talhão"/"Piquete" + N | 182 | 2,93% |
| `pure_number` | só um número | 15 | 0,24% |
| `letter_number_code` | código curto tipo letra+número | 17 | 0,27% |
| `generic_word_plus_text` | contém palavra genérica de uso do solo + texto extra | 1.562 | 25,11% |
| `other_proper_name` | não bate com nenhum padrão acima | 4.442 | 71,40% |
| vazio | — | 3 | 0,05% |

À primeira vista, 71% cairia em "nome próprio". Mas essa classificação por template morfológico
**superestima o quanto o nome identifica um talhão** — porque não captura vocabulário de uso do
solo/cultura que não é um template numérico. A segunda medição corrige isso:

**(b) Frequência do nome normalizado (minúsculo, sem acento) — o teste que realmente importa**:

```sql
-- feito em pandas sobre SELECT name FROM "Area"
```

- 6.221 linhas → apenas **1.955 valores de nome distintos** no sistema inteiro.
- Só **1.508 desses 1.955 valores (77%) ocorrem uma única vez**; em número de linhas, isso cobre
  **1.508/6.221 = 24,24%** — ou seja, **apenas 1 em cada 4 áreas tem um nome que não se repete em
  nenhuma outra área do banco inteiro.**
- Os 40 nomes mais frequentes (com contagem de até 247 ocorrências) **não são identificadores de
  talhão** — são vocabulário de uso do solo/cultura: rótulos do tipo "reserva legal", "app"
  (área de preservação permanente), "benfeitorias", "pastagem", nomes de cultura como milho,
  cana-de-açúcar, braquiária, sorgo, além de rótulos administrativos como "sede". Vários desses
  termos **coincidem literalmente com os valores de `AreaUsage.name`** (a categoria de uso já
  usada em `mvw_area_land_summary.sql` — "Reserva Legal e APP", "Benfeitorias e Estradas",
  "Forrageiras") e com nomes de cultura da própria `Culture`.

Repetindo a mesma medição **só nas 1.441 áreas que entram no universo da base** (id_area presente
em `PlantedCulture`):

- 717 valores distintos de nome entre 1.441 linhas; **582 (40,39%) são globalmente únicos**.
- Os nomes mais frequentes continuam sendo vocabulário de cultura/uso do solo (lavoura, milho,
  milho para silagem, pastagem, capim-elefante, braquiária, sorgo, cana-de-açúcar, sede, "área
  total", "área de plantio"), não topônimos específicos de um talhão.

**Leitura:** `Area.name` funciona, na prática, muito mais como um **rótulo do que está plantado
ou de para que serve a área** (redundante com `id_culture` e com `AreaUsage.name`) do que como um
**identificador estável do talhão físico** para um humano. Em ~60-76% dos casos (dependendo do
recorte) o mesmo texto aparece em mais de uma área do banco, e em ~3% dos casos no universo da
base ele se repete dentro da própria propriedade — ou seja, não dá para usar `name` sozinho para
diferenciar duas áreas da mesma fazenda em uma fração relevante de casos.

### Veredito — área

- **Fonte:** tabela `"Area"`, coluna `name` (texto livre, cadastrado pelo usuário do Elabore).
- **Cardinalidade medida:** `id_area` é chave única (6.221/6.221, sem duplicidade). `name` está
  preenchido em ~99,95% das linhas (99,93% no universo da base) — **não é o problema de nulo**.
  O problema é de **unicidade semântica**: não é único por propriedade (372 grupos duplicados no
  total, 43 linhas — 2,98% — no universo da base), e globalmente **a maioria dos valores de nome
  se repete** (só 24-40% são globalmente únicos, a depender do recorte), porque o campo é usado
  como rótulo de cultura/uso do solo, não como identificador de talhão.
- **O nome NÃO identifica o talhão de forma confiável para um humano.** Ele existe, quase nunca é
  nulo, mas é fraco como identificador: é predominantemente vocabulário genérico de cultura/uso do
  solo que se repete entre áreas diferentes — inclusive, numa fração medida, dentro da mesma
  fazenda. A base pode e deve seguir sem depender dele como chave de leitura humana única; se for
  exposto, precisa vir acompanhado de algo que desambigue (o próprio `id_area`, ou um fragmento
  dele) e documentado como "nome de uso, não nome único do talhão".
- **Caminho recomendado:** mesma lógica da cultura — **resolver no pandas**, não criar
  `vw_dim_area`. Um `read_sql_query('SELECT id_area, id_property, name AS area_name FROM "Area"')`
  (pode ser restrito a `id_area` do universo da base para reduzir volume) mesclado por `id_area`
  com `validate="m:1"` (a chave é única, então o merge é 1:1 e não altera granularidade). Ao
  contrário da cultura, **não recomendo empacotar isso numa view de dimensão nova** — dado que o
  nome não é confiavelmente único, uma `vw_dim_area` correria o risco de parecer uma dimensão
  "limpa" quando na verdade carrega essa ambiguidade; se algum dia for criada, o cabeçalho exigido
  pelo `AGENTS.md` teria que documentar explicitamente essa limitação (não confundir com
  identificador único do talhão) para não induzir outro consumidor a erro.

---

## Resumo para o mapa (`MAP.md`)

| | Cultura (`Culture.name`) | Área (`Area.name`) |
|---|---|---|
| Existe coluna de nome? | Sim | Sim |
| `id_*` é chave única? | Sim (70/70, medido) | Sim (6221/6221, medido) |
| Nome nulo/vazio? | 0% | ~0,05% total / 0,07% no universo da base |
| `LEFT JOIN` por id preserva granularidade? | Sim, testado (2.416 → 2.416 linhas) | Sim (join 1:1 pela PK, sem teste de fan-out necessário — cardinalidade de `Area` já é 1 linha por `id_area`) |
| Nome é único pela chave? | Não (52 nomes / 70 ids — versão/consórcio) | Não (só 24-40% dos nomes são globalmente únicos; 2,98% colide dentro da mesma propriedade no universo da base) |
| Identifica a "coisa" para um humano? | Sim, para a cultura (é o nome da cultura) | Fraco — funciona como rótulo de uso do solo/cultura, não como nome do talhão |
| Caminho recomendado | `read_sql` extra (70 linhas) + merge por `id_culture` no pandas | `read_sql` extra + merge por `id_area` no pandas, documentando a limitação |
| Criar view de dimensão nova? | Não necessário agora; viável no futuro (`vw_dim_culture`, dado limpo) | Não recomendado (nome não é confiável o bastante para "dimensão") |

Nenhuma view foi criada, alterada nem consultada com efeito colateral durante esta pesquisa.
