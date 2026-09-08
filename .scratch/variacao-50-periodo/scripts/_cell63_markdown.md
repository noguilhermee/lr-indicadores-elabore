## 3.8 Verificação de Variação >±50% entre Períodos Consecutivos (Mensal)

Diagnóstico **relativo** e **estritamente aditivo**, no mesmo espírito da análise de
outliers da 4.4: marca todo indicador que variou mais de +50% ou menos de −50% em relação
ao mês calendário imediatamente anterior (M−1) da própria fazenda.

Cobre a lista de indicadores **estruturais e de custo agregado** aprovada na re-medição do
ticket 02 sobre a base de 18/08 (`.scratch/variacao-50-periodo/`): Total de Vacas, Preço
Unitário do Leite, Área Total da Propriedade, Produção Total de Leite, Estoque de Capital
Total, Custo Total Mão de Obra e Custo Total com Alimentação — todos abaixo do corte de 10%
das linhas marcadas. As rubricas de custo detalhadas ficaram de fora (acima do corte) e
seguem cobertas só pela 4.4 (contra o grupo).

Nada de consistência muda aqui (`consistency_id` e `consistency_status` são apenas lidos);
`df_consistencia` não é alterado — a função lê uma cópia e devolve três DataFrames novos.
As colunas novas não sobem para o Supabase. A coloração na aba **Indicadores Mensais**
(colunas auxiliares `_var_`) chega no ticket 04; a aba **Variações por Consultor**, no
ticket 05 — ambos de `.scratch/variacao-50-periodo/`.
