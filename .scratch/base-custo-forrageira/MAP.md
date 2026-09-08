# Base de Dados do Custo de Forrageira

`wayfinder:map` — rastreador local em markdown. Os tickets são os arquivos de `issues/`.
Um ticket está **livre** quando está aberto, sem responsável e com todos os bloqueadores fechados.

## Destination

Um arquivo Excel novo e independente, gerado pelo notebook em `data/outputs/`, com duas abas:
**custo por etapa** para cada área plantada–safra, e **produção** com quantidade produzida e o
custo daquela produção. O mapa termina quando a especificação do arquivo estiver fechada o
bastante para uma sessão de implementação escrever a seção do notebook sem mais nenhuma decisão
pendente.

## Notes

- Domínio: custo de cultura e produção de forrageira do banco Elabore. Ler `AGENTS.md` na raiz
  (regras de granularidade, exportação, backup obrigatório do notebook) e
  `data/views/docs/fluxo_custo_alimentacao.md` (auditoria de 02/08/2026 — D1 a D7).
- Skills que toda sessão deve consultar: `metodologia-lr`; e, quando a decisão for de conversa,
  `grilling` + `domain-modeling`.
- **Nada é construído por este mapa.** Os tickets resolvem decisões; a implementação é o handoff.
- Subagentes só com pedido explícito do usuário. O ticket 05 foi tentado em subagente e o
  subagente morreu em limite de sessão; foi medido na própria sessão. Pesquisa em sessão funciona
  e é o caminho padrão aqui.
- Convenção da casa: `.scratch/<esforço>/issues/NN-slug.md`, como em `variacao-50-periodo`.

### Ponto de partida factual (levantado ao cartografar)

As duas metades pedidas **já existem em memória no notebook** e nenhuma é exportada:

| Metade | DataFrame | Célula | Chave |
|---|---|---|---|
| custo por etapa | `df_custo_cultura_safra_etapa` | 36, §3.4.1 | `id_property + id_area + id_culture + harvest_season + stage` |
| produção e custo dela | `df_custo_unitario_forrageira` | 47, §3.4.2.1-B | `id_property + id_area + id_culture + harvest_season + feeding_category` |

Ambos já vêm deflacionados por IGP-DI: o custo pela `entry_date` de cada item, antes de somar.
A §3.4.2.1-B tem trava de conservação que estoura se o custo rateado não fechar com o
deflacionado da chave.

## Decisions so far

- [Destino, chave, escopo e base do custo](issues/00-destino-e-premissas.md) — arquivo Excel novo
  e independente, duas abas; chave `id_area + id_culture + harvest_season` (não `id_planted_culture`);
  custo inclui fertilização via `vw_culture_expense_cost`; valores deflacionados; R$/kg pela regra
  de rateio por etapa que já vale hoje (D7).
- [Universo, órfãos, safra aberta e gatilho](issues/00-destino-e-premissas.md) — universo completo
  com coluna marcando o recorte ativo; linhas órfãs e safra em andamento **entram marcadas**, nunca
  descartadas; exportação roda toda vez, sem flag.
- [Quais são os valores reais de `stage` no banco](issues/01-valores-reais-de-stage.md) — 5 valores
  fechados, já canônicos, mais NULL em 0,17% do custo: **o layout largo se sustenta**. Fertilização
  e manejo usam subconjuntos diferentes do mesmo vocabulário, não grafias diferentes.
- [Fonte para nome de cultura e nome de área](issues/02-fonte-dos-nomes-de-cultura-e-area.md) —
  cultura entra por join em `id_culture` (chave única, sem fan-out), mas o *nome* não é único por
  id: nunca agrupar por nome. **Nome de área não entra**: é vocabulário de uso do solo, não
  identificador de talhão — só 24% dos nomes são globalmente únicos e há até 14 áreas homônimas
  numa mesma fazenda.
- [Onde a exportação entra no notebook e como é conferida](issues/04-onde-a-exportacao-entra-e-como-e-conferida.md)
  — nova seção de topo §5 (a §3.4.2.6 é inviável: as funções de preparo nascem só na §3.9);
  arquivo independente confirmado; sem `preencher_numericos_vazios_com_zero`, porque ausência é
  significado; falha fatal; cinco conferências, com Morro Feio como fazenda de referência.
- [Por que o custo de fertilizante caiu 40% desde 02/08](issues/05-queda-do-custo-de-fertilizante.md)
  — **não é regressão**: repositório e banco batem, o D7 é estável em 2,3%, e o total é governado
  por **oito linhas de erro de digitação** que carregam 74,5% do custo de fertilizante (fertilizante
  mineral a R$ 3.900,00 **por quilo**). A conferência 1 do ticket 04 passa a ser **recomputada na
  hora**, nunca valor fixo; e a base **marca** custo unitário implausível em vez de entregar em
  silêncio.

- [Layout final das duas abas](issues/03-layout-das-duas-abas.md) — **implementado**: português
  legível para consultor de campo; aba de custo larga (uma coluna por etapa); aba de produção
  longa, uma linha por categoria; chave sem produção só na aba 1; nome de área como rótulo ao lado
  dos ids; sem marcadores de auditoria, por decisão explícita do usuário.

## Not yet specified

- Se a base tem consumidor além do Excel (Supabase, Power BI) e o que isso exige de estabilidade
  de nome de coluna. Só dá para dizer depois que o layout estiver fechado.
- Formatação do Excel (larguras, congelamento, bloco de identificação colorido). O repo tem padrão
  nas exportações mensal e anual; se ele se aplica a uma base de dados é outra conversa.
- Se o custo por etapa também deve sair em R$/ha, e sobre qual área (plantada ou colhida).
  Ficou fora da §5 por redução de escopo.
- Se a base deve marcar o custo unitário implausível do ticket 05. O usuário decidiu **não**
  revisar valores nesta versão; as linhas de digitação errada saem cruas.
- Uma fazenda de referência melhor que Morro Feio — com muita forrageira própria e safra fechada.
  Morro Feio serve por ter número publicado, mas foi escolhida para auditar alimentação.

### Estado

Todos os tickets fechados. A §5 está no notebook e testada; falta o usuário rodar o notebook de
ponta a ponta para gerar o arquivo com os dados reais.

## Out of scope

- Alterar a regra de rateio entre VOLUMOSO e CONCENTRADO. A regra do D7 está implantada e é a
  mesma que alimenta `feeding_cost`; mudá-la aqui criaria duas verdades na mesma casa.
- Resolver os defeitos residuais do fluxo de custo apontados na auditoria (os 78 lançamentos sem
  lote consultável, os 5,5 M kg sem preço possível). A base os expõe; não os corrige.
- Mudar qualquer coisa na origem Elabore para produzir nome de área.
