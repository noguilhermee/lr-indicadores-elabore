# 02 — Re-medição da taxa de marcação e aprovação da lista final de indicadores mensais

**What to build:** O responsável pela regra recebe uma tabela — indicador × taxa de linhas que
teriam sido marcadas pela regra de variação ±50%, medida sobre a base de 18/08
(`data/outputs/monthly/2026_08_18_090514_indicadores_mensais.xlsx`) — junto com o delta em relação
aos números da medição anterior (13/08, que não é mais auditável no notebook). Aprova a lista final
de indicadores estruturais e de custo agregado que entram na regra, com corte explícito de 10% das
linhas marcadas: qualquer indicador acima do corte fica de fora.

A medição roda em um script descartável, fora do notebook — nenhuma célula nova entra no fluxo de
produção só para medir. O resultado (tabela de taxas, delta, lista aprovada) vira número documentado
na spec, não código vivo. Esta é a fatia que destrava a estrutura declarativa do ticket 03: sem lista
aprovada, a função de variação não tem o que codificar.

Referência da medição anterior (13/08), a revalidar: estruturais 0,2%–1,6% (Total de Vacas 0,2%,
Preço do leite 0,3%, Estoque de Capital 0,5–0,7%, Área 0,8%, Produção de Leite 1,6%); rubricas
detalhadas 37%–58% (fora do corte de 10%, portanto fora da regra).

**Blocked by:** None — can start immediately (roda fora do notebook, em paralelo com o ticket 01).

**Status:** ready-for-agent

- [x] Script descartável em `.scratch/variacao-50-periodo/` mede, sobre a base de 18/08, a taxa de
      linhas marcadas por indicador candidato (estruturais + custos agregados)
      (`scripts/medir_taxa_marcacao_18_08.py`)
- [x] Tabela de taxas por indicador, com o delta em relação à medição de 13/08, documentada na spec
- [x] Critério de corte de 10% das linhas marcadas aplicado; indicador acima do corte fica fora da
      lista (Custo de Concentrado e Mineral 10,14% e Outras Despesas Operacionais 25,48% ficaram fora)
- [x] Lista final de indicadores mensais apresentada ao responsável pela regra e aprovada por ele
      antes de qualquer estrutura declarativa ser escrita (aprovada em 19/08)
- [x] Nenhuma célula nova entra no notebook de produção como resultado desta medição
