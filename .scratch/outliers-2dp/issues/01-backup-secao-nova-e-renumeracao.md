# 01 — Backup do notebook, seção nova posicionada e renumeração

**What to build:** O notebook principal roda de ponta a ponta e produz **exatamente o mesmo arquivo anual de hoje**, mas já com a seção nova de análise de outliers criada e posicionada entre a padronização de colunas anuais e a exportação anual. A seção existe (markdown de título + célula de código), ainda sem lógica de negócio, e as seções seguintes — exportação anual e ingestão no Supabase — foram renumeradas para que o notebook continue legível na ordem das células.

Este é o *prefactor* que torna as fatias seguintes fáceis: depois dele, cada ticket acrescenta comportamento dentro de uma célula que já está no lugar certo, sem mexer na numeração nem na célula de indicadores derivados anuais.

Antes de qualquer edição, gravar um backup do notebook na pasta de backup do app, com sufixo indicando o estado pré-alteração, conforme a praxe do projeto.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Backup do notebook gravado na pasta de backup do app, com sufixo indicando o estado pré-alteração
- [ ] Uma seção nova (markdown + uma célula de código) existe entre a padronização de colunas anuais e a exportação anual
- [ ] Exportação anual e ingestão no Supabase renumeradas; a numeração das seções segue a ordem das células sem saltos nem repetições
- [ ] A célula de indicadores derivados anuais e regras de consistência anual não foi tocada
- [ ] O notebook roda de ponta a ponta sem erro
- [ ] O arquivo anual gerado continua com as quatro abas atuais, com os mesmos nomes, cabeçalhos e ordem de colunas
- [ ] O arquivo mensal e a ingestão no Supabase permanecem inalterados
