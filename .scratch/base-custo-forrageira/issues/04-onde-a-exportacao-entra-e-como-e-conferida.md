# 04 — Onde a exportação entra no notebook e como ela é conferida

**Tipo:** `wayfinder:grilling` (HITL) · **Estado:** fechado em 31/08/2026 · **Bloqueado por:** nada

## Question

Em que ponto do notebook a nova seção de exportação vive, e qual é a conferência que prova que a
base está certa?

Independente do layout — é sobre estrutura do notebook e sobre prova, não sobre colunas. Pode ser
resolvido em paralelo com [01](01-valores-reais-de-stage.md) e [02](02-fonte-dos-nomes-de-cultura-e-area.md).

## O tensionamento

Os dois DataFrames nascem **no meio do bloco mensal**: `df_custo_cultura_safra_etapa` na célula 36
(§3.4.1) e `df_custo_unitario_forrageira` na célula 47 (§3.4.2.1-B). As duas exportações que
existem hoje ficam no fim dos seus blocos — §3.10 (mensal) e §4.5 (anual). Mas esta base não é nem
mensal nem anual: é por safra.

Opções aparentes:

1. Nova seção de topo **§5**, depois do anual, referenciando DataFrames criados lá atrás em §3.4.
   Lê bem, mas cria dependência longa: quem mexer em §3.4 não vê que §5 depende dela.
2. Subseção **§3.4.2.6**, logo depois do rateio, junto de onde o dado nasce. Fica perto da origem,
   mas enterra uma exportação no meio de um bloco de tratamento.
3. Nova seção de topo que **recomputa** as duas agregações a partir das views importadas, sem
   depender do estado de §3.4. Independente, mas duplica regra — e regra duplicada diverge.

Também precisa decidir: o notebook tem de continuar rodando até o fim se a exportação falhar, ou a
falha é fatal?

## O que precisa sair fechado

- Onde a seção vive e por quê.
- A conferência mínima antes de dar o arquivo por bom. Candidatos: total da aba de custo bate com
  a soma de `vw_culture_expense_cost` deflacionada; nenhuma chave duplicada nas duas abas; soma do
  `custo_rateado` por chave igual ao `custo_deflacionado` da chave (a §3.4.2.1-B já tem essa trava
  — reaproveitar em vez de reescrever); contagem de linhas órfãs igual ao que os `print` de aviso
  já reportam hoje.
- Uma fazenda de referência para conferir à mão, como `Morro Feio` foi na auditoria de 02/08.
- Backup do notebook antes de editar, conforme `AGENTS.md`.

## Resolução esperada

O ponto de inserção decidido com a razão, e a lista de conferências que a sessão de implementação
tem de rodar e reportar.


## Resolution

Decidido com o usuário em 31/08/2026.

### Onde a seção vive: nova seção de topo **§5**, depois do anual

Lê `df_custo_cultura_safra_etapa` (célula 36) e `df_custo_unitario_forrageira` (célula 47),
criados lá atrás em §3.4.

Por que não §3.4.2.6, que era a opção "junto de onde o dado nasce": **ela é tecnicamente
inviável hoje.** `preparar_dataframe_para_excel` e `preencher_numericos_vazios_com_zero` são
definidas na **célula 67 (§3.9)**, depois de §3.4. Exportar em §3.4.2.6 exigiria mover ou
duplicar as duas — refatoração do bloco mensal inteiro, que este esforço não pediu.
(`exportar_varias_abas_xlsx` e `aplicar_estilo_listrado_xlsx` vêm de `excel_format`, importadas
na §1.1, e essas sim estão disponíveis desde o começo.)

Por que não recomputar a partir das views: duplicaria a regra de rateio, e regra duplicada
diverge. É o defeito que o mapa põe explicitamente fora de escopo.

A dependência longa de §5 para §3.4 é real — quem mexer em §3.4 não vê que §5 depende dela. Fica
aceita porque a casa já convive com ela: a §3.4.2.5 monta três abas de auditoria de forrageira
que só são exportadas na §3.10, com o mesmo padrão. **Mitigação obrigatória:** a §5 começa
verificando a existência dos dois DataFrames e falha com mensagem explícita se algum sumiu, em
vez de estourar com `NameError`.

### Arquivo independente, confirmado

Reaberto à luz do precedente da §3.4.2.5 (que pôs abas de forrageira *dentro* do arquivo mensal)
e mantido. Aquelas abas são auditoria de lançamento, grão de lançamento e de lote, que o
consultor abre junto dos indicadores do mês. Esta base é por safra e cobre toda propriedade,
inclusive fora do universo ativo — dentro do mensal contaminaria um arquivo cuja unidade é
`id_property + reference_month`.

### `preencher_numericos_vazios_com_zero`: **não aplicar**

Só `preparar_dataframe_para_excel`. Na base, ausência é significado: `custo_unitario_forrageira`
nulo quer dizer *não deu para calcular* (sem produção, sem conversão de unidade), não R$ 0,00/kg;
`quantidade_kg` nulo quer dizer *não converteu*, não zero quilo. Mesma decisão já tomada nas abas
de outlier da §4.5, pelo mesmo motivo registrado lá: "um z ausente virando 0 leria como
exatamente na média".

### Falha na exportação é **fatal**

§5 é a última seção; não há nada depois para preservar, e a ingestão no Supabase (§4.6) já rodou.
Falha silenciosa numa exportação que roda toda vez é como se descobre três semanas depois que o
arquivo está velho.

### Conferências obrigatórias

1. Soma do custo da aba de etapas bate com `vw_culture_expense_cost` deflacionada, tolerância
   R$ 0,01. **O valor-alvo depende do ticket [05](05-queda-do-custo-de-fertilizante.md)** — ver
   ressalva abaixo.
2. Zero chave duplicada nas duas abas.
3. Reaproveitar a trava de conservação que a §3.4.2.1-B já tem (custo rateado × custo
   deflacionado da chave), em vez de reescrever uma nova.
4. Contagem de linhas órfãs igual ao que os `print` de aviso da §3.4.1 e da §3.4.2.1-B já
   reportam hoje.
5. Uma fazenda conferida à mão: **Morro Feio**, que já tem números publicados em
   `data/views/docs/fluxo_custo_alimentacao.md`.

**Ressalva registrada, não resolvida:** Morro Feio foi escolhida na auditoria de 02/08 para
auditar *alimentação*, não *custo de cultura*. Ela serve como referência porque tem número
publicado, mas uma fazenda com muita forrageira própria e safra fechada seria melhor. Se
aparecer uma candidata melhor durante a implementação, trocar.

**Ressalva na conferência 1:** o ticket 05 mediu que o total de `vw_culture_expense_cost` se moveu
32% em quatro semanas. Enquanto a causa não for conhecida, essa trava confere contra alvo móvel.
A implementação deve rodá-la, mas a forma final (valor fixo × recomputado na hora × faixa de
tolerância) só se decide com o 05 fechado.
