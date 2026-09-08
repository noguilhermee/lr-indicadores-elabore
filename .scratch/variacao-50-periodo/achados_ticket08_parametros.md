# Achados — ticket 08 (conferência de PARAMETROS_INCONSISTENCIA.xlsx, aba MENSAL)

Conferência feita em 19/08/2026, sem nenhuma edição na planilha. Achados para decisão do
Filipe (planilha é o documento de contrato dele; nenhuma linha foi alterada).

## 1. MÍN/MÁX das linhas 24–26 — coerente com o código

| Linha | Item | MÍN | MÁX |
|---|---|---|---|
| 24 | 24. Variação mensal do preço do leite (%) | −50 | 50 |
| 25 | 25. Variação mensal da bonificação por qualidade do leite (%) | −50 | 50 |
| 26 | 26. Variação mensal do gasto com dieta / Preço do leite (%) | −50 | 50 |

`LIMITE_VARIACAO_PERCENTUAL = 50` no notebook (3.8) marca razão `> 1,5` ou `< 0,5`, o
equivalente a variação `> +50%` ou `< −50%`. **Coerente** com MÍN −50 / MÁX +50 das três
linhas.

## 2. Divergência entre os 3 itens da planilha e os 7 indicadores aprovados no ticket 02

As linhas 24–26 da planilha antecipavam **três** indicadores específicos de variação
mensal: preço do leite, bonificação por qualidade do leite, e a razão gasto com
dieta/preço do leite. A lista aprovada no ticket 02 (medição data-driven sobre a base de
18/08, corte de 10% das linhas marcadas) resultou em **sete** indicadores diferentes:

- Total de Vacas, Área Total da Propriedade, Produção Total de Leite, Estoque de Capital
  Total, Custo Total Mão de Obra, Custo Total com Alimentação — **nenhum dos seis** consta
  nas linhas 24–26 (nem em nenhuma outra linha de variação da planilha; ela só tem essas
  três linhas de variação mensal).
- Preço Unitário do Leite (aprovado no ticket 02) **coincide em espírito** com a linha 24
  ("variação mensal do preço do leite"), mas não foi conferido campo a campo se é
  exatamente a mesma fonte de dado.
- Bonificação por qualidade do leite (linha 25) e a razão gasto com dieta/preço do leite
  (linha 26) **não entraram** na regra implementada — não fizeram parte da lista de
  candidatos medida no ticket 02 (essa lista veio dos indicadores estruturais + custo
  agregado da spec nova, não das linhas pré-existentes da planilha).

**Causa raiz:** a spec atual (`.scratch/variacao-50-periodo/spec.md`) substituiu a versão
anterior de 64 user stories e escolheu a lista de indicadores por medição de taxa de
marcação sobre a base real, não pelos três itens que a planilha já antecipava desde antes
da spec existir. A planilha nunca foi atualizada para refletir essa mudança de critério.

## 3. Decisão pendente do Filipe

Esta fatia (ticket 08) não edita a planilha. Fica para o Filipe decidir, sem obrigação de
nenhuma das opções:

- Deixar a planilha como está (ela é só documentação; nenhum código a lê hoje) e aceitar
  que ela descreve uma intenção antiga, não a regra hoje implementada;
- Atualizar as linhas 24–26 para os 7 indicadores do ticket 02 (perde a granularidade dos
  3 itens originais, ganha coerência com o código);
- Acrescentar novas linhas para os indicadores que a planilha não cobre, mantendo 24–26
  como estão (bonificação e dieta/preço-leite ficam documentados como **não
  implementados**, não como divergência).
