"""
Roda o notebook principal ate antes da ingestao no Supabase, para validacao
(ticket 07 de .scratch/variacao-50-periodo/issues/). Corta as duas ultimas
celulas (markdown + codigo da 4.6 Ingestao Automatica) e executa o resto com
nbclient, com cwd = pasta app (o notebook deriva RAIZ_PROJETO de Path.cwd()).

Uso: python rodar_validacao_notebook.py
Salva uma copia executada em .scratch/variacao-50-periodo/ para inspecao dos
outputs/erros, sem sobrescrever o notebook original.
"""
import sys
import time
from pathlib import Path

import nbformat
from nbclient import NotebookClient

APP_DIR = Path(__file__).resolve().parents[3] / "app"
NOTEBOOK_ORIGINAL = APP_DIR / "Elabore Indicadores.ipynb"
SAIDA_EXECUTADO = Path(__file__).resolve().parent.parent / "notebook_validacao_executado.ipynb"


def main():
    nb = nbformat.read(NOTEBOOK_ORIGINAL, as_version=4)

    total_celulas = len(nb.cells)
    ultimas_duas = nb.cells[-2:]
    assert ultimas_duas[0].cell_type == "markdown" and "Ingest" in "".join(ultimas_duas[0].source), \
        f"Celula -2 nao e o markdown de ingestao: {ultimas_duas[0].source[:80]!r}"
    assert ultimas_duas[1].cell_type == "code" and "upsert" in "".join(ultimas_duas[1].source).lower(), \
        f"Celula -1 nao e o codigo de ingestao: {ultimas_duas[1].source[:80]!r}"

    nb.cells = nb.cells[:-2]
    print(f"Notebook original: {total_celulas} celulas. Executando {len(nb.cells)} "
          f"(cortadas as 2 ultimas: markdown + codigo de ingestao no Supabase).")

    client = NotebookClient(
        nb,
        timeout=1800,
        kernel_name="python3",
        resources={"metadata": {"path": str(APP_DIR)}},
    )

    inicio = time.time()
    try:
        client.execute()
    finally:
        nbformat.write(nb, SAIDA_EXECUTADO)
        duracao = time.time() - inicio
        print(f"Duracao: {duracao/60:.1f} min. Saida gravada em: {SAIDA_EXECUTADO}")


if __name__ == "__main__":
    sys.exit(main())
