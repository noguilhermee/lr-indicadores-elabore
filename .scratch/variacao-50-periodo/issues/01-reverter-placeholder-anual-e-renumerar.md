# 01 — Reverter placeholder anual e renumerar

**What to build:** O notebook principal roda de ponta a ponta e produz os mesmos dois arquivos de
hoje (mensal e anual), mas o bloco anual volta a ter só as seções que já existiam antes da spec
anterior: a seção placeholder "Verificação de Variação >±50% entre Períodos Consecutivos (Anual)"
é removida por inteiro (markdown + célula de código), e a seção seguinte — exportação dos arquivos
Excel anuais — recua de volta para o número que tinha antes dela existir. A renumeração toca só
texto de markdown; nenhuma célula executável muda de posição ou de conteúdo.

O placeholder mensal equivalente, no bloco mensal, **permanece** — ele é o ponto de partida para o
ticket 03. Só o lado anual é revertido, porque a extensão anual saiu de escopo.

Antes de qualquer edição, gravar um novo backup do notebook na pasta de backup do app, com sufixo
indicando o estado pré-alteração desta rodada (mensal-apenas).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] Backup do notebook gravado na pasta de backup do app, com sufixo indicando o estado
      pré-alteração desta rodada (`backup/Elabore Indicadores_20260819_110608_pre_variacao_50_mensal.ipynb`)
- [x] A seção placeholder de variação do bloco anual (markdown + célula de código) foi removida
      por inteiro
- [x] A seção de exportação dos arquivos Excel anuais recuou de volta para o número que tinha
      antes da seção placeholder existir; a numeração do bloco anual segue a ordem das células sem
      saltos nem repetições (4.5 Exportação, 4.6 Ingestão)
- [x] A seção placeholder de variação do bloco mensal não foi tocada (revisitada só no ticket 03,
      que substituiu o placeholder pela implementação real)
- [x] Nenhuma célula de regras de consistência (mensal ou anual), de indicadores derivados anuais
      ou de análise de outliers foi tocada
- [x] O notebook roda de ponta a ponta sem erro, parando antes do upsert no Supabase
      (rodado em 19/08, 86 células, 8,0 min, `exit code 0` — ver ticket 07)
- [x] Os arquivos mensal e anual gerados continuam com as mesmas abas de hoje, com os mesmos
      nomes, cabeçalhos e ordem de colunas (anual: 7 abas idênticas; mensal: 168 colunas antigas
      idênticas + acréscimos dos tickets 03/04/05 — ver ticket 07)
- [x] A ingestão no Supabase permanece inalterada (célula de ingestão nem chegou a rodar nesta
      validação — cortada de propósito; código da célula não foi tocado)
