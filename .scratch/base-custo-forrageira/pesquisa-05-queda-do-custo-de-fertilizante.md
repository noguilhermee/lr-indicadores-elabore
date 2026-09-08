# Pesquisa 05 — A queda de 40% no custo de fertilizante

Medições feitas em 31/08/2026, somente-leitura, no banco de produção, na própria sessão
(o subagente que tinha sido disparado morreu em limite de sessão antes de medir nada).

## Resposta curta

O custo de fertilizante **não é um agregado**: é uma soma dominada por **oito linhas de erro de
digitação**. Oito linhas carregam R$ 264,87 mi dos R$ 355,38 mi da view — **74,5%**. Todas são
`unit_cost` em ordem de grandeza errada: fertilizante mineral a **R$ 3.900,00 por quilo**,
R$ 4.086,29/kg, R$ 4.020,00/kg, calcário a R$ 231,06/kg. O preço real anda na casa de
R$ 0,20 a R$ 5,00 por quilo — as próprias linhas normais da view mostram isso.

Com essa estrutura, **uma única linha apagada no app move o total em centenas de milhões**. A
maior sozinha vale R$ 124,80 mi. A diferença inteira de R$ 237,40 mi entre 02/08 e 31/08 cabe em
uma ou duas dessas linhas.

Não é regressão de código, e não é correção progressiva do D7. É a fragilidade de um número
governado por outliers de digitação.

## Pergunta 4 primeiro (era a hipótese principal, e caiu)

**Não há divergência entre repositório e banco.** Comparei `pg_get_viewdef` das três views com o
`.sql` do repositório: `analytics_int.vw_fertilization_cost`, `analytics_int.vw_management_cost` e
`analytics_mart.vw_culture_expense_cost` são idênticas ao arquivo versionado, coluna por coluna,
filtro por filtro. O D5 da auditoria não se repetiu aqui.

O `vw_fertilization_cost.sql.20260802.bak` é a versão **pré-D7**; o único delta contra o arquivo
atual é exatamente o D7 (`COALESCE(consumed_quantity, quantity)` e
`custo = COALESCE(consumed_quantity, quantity) * unit_cost` no lugar de `line_total`). Ou seja: a
definição de view que produziu os R$ 592,78 mi em 02/08 é **a mesma** que produz R$ 355,38 mi hoje.
Mesmo código, dado diferente.

## Pergunta 3: o D7 não é o mecanismo

| | 02/08/2026 (auditoria) | 31/08/2026 (medido) |
|---|---:|---:|
| efeito D7 no fertilizante | R$ 13,3 mi | R$ 8,24 mi |
| % do custo de fertilizante | 2,2% | 2,3% |

O D7 encolheu **na mesma proporção** do total. Hoje, das 3.208 linhas do Ramo 2 de fertilização,
`consumed_quantity` **nunca é nulo** e 218 têm consumo menor que a compra. O efeito é estável em
~2,3% e não vai crescendo conforme os clientes preenchem — a hipótese de "correção progressiva"
está descartada.

## Perguntas 1 e 2: onde o dinheiro está, e o que sobrou de rastro

### Foto de hoje, `vw_culture_expense_cost`

| tipo | ramo | linhas | custo |
|---|---|---:|---:|
| fertilizante | baixa de estoque | 174 | R$ 4.797.879,73 |
| fertilizante | compra e uso | 3.208 | R$ 350.579.284,41 |
| manejo | baixa de estoque | 311 | R$ 1.070.602,71 |
| manejo | compra e uso | 14.609 | R$ 134.357.513,30 |

Total 18.302 linhas / R$ 490.805.280,15. Confere com o ticket 01.

### Concentração — o achado

| faixa de valor da linha | fertilizante | | manejo | |
|---|---:|---:|---:|---:|
| | linhas | custo | linhas | custo |
| ≥ R$ 10 mi | **8** | **R$ 264.873.440** | 0 | R$ 0 |
| R$ 1 a 10 mi | 5 | R$ 25.737.700 | 2 | R$ 3.706.842 |
| R$ 100 mil a 1 mi | 99 | R$ 15.033.595 | 185 | R$ 38.422.864 |
| < R$ 100 mil | 3.270 | R$ 49.732.430 | 14.733 | R$ 93.298.410 |

**Manejo não tem nenhuma linha acima de R$ 10 mi.** É por isso que manejo se comporta (+2,8% em um
mês, como qualquer série de lançamento novo) e fertilizante não. São dois regimes estatísticos
diferentes dentro da mesma view.

### As oito linhas

| prop | produto | unid. | quantidade | `unit_cost` | linha | safra | criada em |
|---|---|---|---:|---:|---:|---|---|
| `462d3fac` | Fertilizante mineral | KG | 32.000 | **3.900,00** | R$ 124.800.000 | 25/26 | 11/11/2025 |
| `d59f3e01` | Fertilizante mineral | KG | 8.000 | **3.600,00** | R$ 28.800.000 | 25/26 | 19/03/2026 |
| `d59f3e01` | Fertilizante mineral | KG | 7.000 | **4.086,29** | R$ 28.604.030 | 25/26 | 19/03/2026 |
| `774cfc68` | Composto orgânico | KG | 95.000 | **231,06** | R$ 21.950.700 | 25/26 | 04/09/2025 |
| `9eedc24f` | Fertilizante mineral | KG | 5.000 | **4.020,00** | R$ 20.100.000 | 25/26 | 12/03/2026 |
| `441b6e50` | Fertilizante mineral | KG | 6.000 | **3.000,00** | R$ 18.000.000 | 23/24 | 25/07/2024 |
| `9eedc24f` | Fertilizante mineral | KG | 5.000 | **3.445,00** | R$ 17.225.000 | 25/26 | 12/03/2026 |
| `17cea1fd` | Fertilizante mineral | KG | 4.000 | **3.000,00** | R$ 12.000.000 | 25/26 | 16/12/2025 |

Todas com `unit = 'KG'` e `unit_cost` na ordem de grandeza de **preço por tonelada ou por saco**.
Todas com cadastro de propriedade válido — não são órfãs. Sete das oito na safra 25/26, que
sozinha responde por R$ 290,44 mi dos R$ 355,38 mi (81,7%).

O padrão aparece também no que já foi desativado: a maior linha inativa é calcário a R$ 225,00/kg,
R$ 40,25 mi. Ou seja, o app **já vem corrigindo** esse tipo de lançamento, uma linha por vez.

### O rastro do que sumiu

| medida | linhas | valor |
|---|---:|---:|
| fertilização criada antes de 02/08, **qualquer** `is_active`, valores de hoje | 3.507 | R$ 421,49 mi |
| view hoje (só ativas) | 3.382 | R$ 355,38 mi |
| desativado depois de 02/08 | 27 | R$ 0,50 mi |
| ativo, mas **editado** depois de 02/08 | 485 | R$ 21,76 mi |
| auditoria de 02/08 | ~17.809 no total | R$ 592,78 mi |

Somando tudo que ainda existe no banco em qualquer estado, criado antes de 02/08, chega-se a
**R$ 421,49 mi**. Faltam **R$ 171,29 mi** que não têm representante nenhum no banco hoje — nem
ativo, nem inativo.

E `is_active` não explica: só R$ 0,50 mi foi desativado depois de 02/08. Edição também não: o teto
do que foi tocado depois de 02/08 é R$ 21,76 mi, e mesmo assim seria preciso que essas edições
fossem todas para baixo e somassem dez vezes mais.

**Conclusão medida:** as linhas foram *apagadas de verdade* — sumiram da tabela `public`, não foram
marcadas inativas. Dado o tamanho das oito remanescentes, apagar uma ou duas linhas de digitação
errada cobre os R$ 171 mi com folga. É a explicação que sobra depois que as outras três caem, e é
coerente com o total de linhas ter **subido** no mesmo período (manejo entrando).

Não dá para provar qual linha era: o banco não guarda `deleted_at` e não há snapshot de 02/08.
Isso fica registrado como **não medido**, com o motivo.

## O que isso significa para a base de custo de forrageira

1. **A conferência 1 do ticket 04 não pode ser um valor fixo.** O alvo se move em centenas de
   milhões sem que nada do código mude. Tem que ser recomputada na hora, contra a mesma leitura da
   view usada na execução.
2. **A base vai exportar R$/kg absurdos.** Uma dessas linhas rateada sobre a produção de uma safra
   produz custo unitário de forrageira em ordem de grandeza errada. Está dentro do escopo do mapa
   decidir se a base **marca** isso — não corrigir, que é `Out of scope`, mas não entregar em
   silêncio.
3. **O universo ativo não filtra nada disso.** As oito propriedades têm cadastro. A coluna de
   recorte ativo decidida no ticket 00 não vai segurar esses valores.

## O que não foi medido, e por quê

- **Qual linha exatamente sumiu.** Sem `deleted_at` e sem snapshot de 02/08, não é reconstruível.
- **Se o mesmo padrão existe em manejo.** Manejo não tem linha acima de R$ 10 mi, então o risco é
  de outra ordem; não foi investigado a fundo.
- **Se a auditoria de 02/08 mediu certo.** É a hipótese alternativa que sobra, e não é
  descartável. Reconciliar exigiria o snapshot que não existe.
