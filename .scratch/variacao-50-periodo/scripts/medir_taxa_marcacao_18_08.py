"""
Script DESCARTAVEL - ticket 02 de .scratch/variacao-50-periodo/issues/.

Mede, sobre a base de 18/08 (data/outputs/monthly/2026_08_18_090514_indicadores_mensais.xlsx),
a taxa de linhas marcadas (Aumento ou Reducao) pela regra de variacao >+-50% entre meses
consecutivos da mesma fazenda, para uma lista de indicadores candidatos (estruturais +
custos agregados). Nao entra no notebook de producao - roda isolado e o resultado vira
numero documentado na spec, nao codigo vivo.

Uso: python medir_taxa_marcacao_18_08.py
"""
from pathlib import Path

import numpy as np
import pandas as pd

ARQUIVO = (
    Path(__file__).resolve().parents[3]
    / "data"
    / "outputs"
    / "monthly"
    / "2026_08_18_090514_indicadores_mensais.xlsx"
)

COLUNA_CHAVE = "IdFazenda"
COLUNA_MES = "Mês de Referência"
LIMITE_PERCENTUAL = 50

# Candidatos: estruturais (referência 13/08) + custos agregados (não rubricas detalhadas).
CANDIDATOS = {
    "Total de Vacas (cabeças)": "estrutural",
    "Preço Unitário do Leite (R$/litro)": "estrutural",
    "Estoque de Capital Total (R$)": "estrutural",
    "Área Total da Propriedade (ha)": "estrutural",
    "Produção Total de Leite (litros)": "estrutural",
    "Custo Total com Alimentação (R$)": "custo agregado",
    "Custo Total Mão de Obra (R$)": "custo agregado",
    "Custo de Concentrado e Mineral (R$)": "custo agregado",
    "Outras Despesas Operacionais (R$)": "custo agregado",
}

# Referência de 13/08 documentada na spec (para o delta), onde disponível.
REFERENCIA_13_08 = {
    "Total de Vacas (cabeças)": 0.2,
    "Preço Unitário do Leite (R$/litro)": 0.3,
    "Estoque de Capital Total (R$)": 0.6,  # spec: faixa 0,5-0,7%; ponto médio p/ delta
    "Área Total da Propriedade (ha)": 0.8,
    "Produção Total de Leite (litros)": 1.6,
}

CORTE_PERCENTUAL = 10.0


def classificar_variacao(df, coluna_valor, coluna_chave, coluna_ordem):
    df = df.sort_values([coluna_chave, coluna_ordem]).copy()
    ordem_num = df[coluna_ordem]
    valor = pd.to_numeric(df[coluna_valor], errors="coerce")

    mesma_fazenda = df[coluna_chave].eq(df[coluna_chave].shift(1))
    passo = ordem_num - ordem_num.shift(1)
    consecutivo = mesma_fazenda & passo.eq(1)

    valor_anterior = valor.shift(1).where(consecutivo)
    valor_atual = valor.where(consecutivo)

    ambos_validos = valor_anterior.notna() & valor_atual.notna()
    ambos_zero = ambos_validos & valor_anterior.eq(0) & valor_atual.eq(0)
    entrada = ambos_validos & valor_anterior.eq(0) & valor_atual.gt(0)
    saida = ambos_validos & valor_anterior.gt(0) & valor_atual.eq(0)

    razao = valor_atual / valor_anterior.replace(0, np.nan)
    avaliavel = ambos_validos & ~ambos_zero & ~entrada & ~saida & razao.notna()
    aumento = avaliavel & (razao > 1.5)
    reducao = avaliavel & (razao < 0.5)

    categoria = pd.Series("Não avaliado", index=df.index)
    categoria[ambos_zero] = "Não avaliado"
    categoria[entrada] = "Entrada"
    categoria[saida] = "Saída"
    categoria[avaliavel] = "Normal"
    categoria[aumento] = "Aumento"
    categoria[reducao] = "Redução"

    return categoria


def main():
    df = pd.read_excel(ARQUIVO, sheet_name="Indicadores Mensais")
    df[COLUNA_MES] = pd.to_datetime(df[COLUNA_MES], errors="coerce")
    df["_ordem"] = df[COLUNA_MES].dt.year * 12 + df[COLUNA_MES].dt.month

    total_linhas = len(df)
    print("=" * 88)
    print(f"Base: {ARQUIVO.name}")
    print(f"Total de linhas: {total_linhas:,} | Fazendas distintas: {df[COLUNA_CHAVE].nunique():,} | "
          f"Meses distintos: {df['_ordem'].nunique()}")
    print("=" * 88)

    linhas_tabela = []
    for coluna, grupo in CANDIDATOS.items():
        if coluna not in df.columns:
            print(f"[AUSENTE] coluna nao encontrada na base: {coluna!r}")
            continue
        categoria = classificar_variacao(df, coluna, COLUNA_CHAVE, "_ordem")
        marcadas = categoria.isin(["Aumento", "Redução"]).sum()
        taxa = 100.0 * marcadas / total_linhas
        ref = REFERENCIA_13_08.get(coluna)
        delta = (taxa - ref) if ref is not None else None
        linhas_tabela.append({
            "indicador": coluna,
            "grupo": grupo,
            "linhas_marcadas": int(marcadas),
            "taxa_%": round(taxa, 2),
            "ref_13_08_%": ref,
            "delta_pp": round(delta, 2) if delta is not None else None,
            "dentro_do_corte_10%": taxa <= CORTE_PERCENTUAL,
        })

    tabela = pd.DataFrame(linhas_tabela)
    tabela = tabela.sort_values("taxa_%")
    pd.set_option("display.width", 120)
    pd.set_option("display.max_colwidth", 45)
    print()
    print(tabela.to_string(index=False))

    aprovados = tabela.loc[tabela["dentro_do_corte_10%"], "indicador"].tolist()
    reprovados = tabela.loc[~tabela["dentro_do_corte_10%"], "indicador"].tolist()
    print()
    print(f"Dentro do corte de {CORTE_PERCENTUAL:.0f}% ({len(aprovados)}):")
    for c in aprovados:
        print(f"  - {c}")
    if reprovados:
        print(f"Acima do corte de {CORTE_PERCENTUAL:.0f}% ({len(reprovados)}), fora da lista final:")
        for c in reprovados:
            print(f"  - {c}")

    saida_csv = Path(__file__).resolve().parent.parent / "medicao_18_08_resultado.csv"
    tabela.to_csv(saida_csv, index=False, encoding="utf-8-sig")
    print()
    print(f"Tabela salva em: {saida_csv}")


if __name__ == "__main__":
    main()
